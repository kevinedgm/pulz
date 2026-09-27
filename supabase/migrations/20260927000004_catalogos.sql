-- 0004 · Catálogos con semilla copiada por empresa (PULZ_MAESTRO.md §10.2).
--
-- Reemplaza el patrón de pulz_esquema.sql (filas con organization_id NULL +
-- tablas *_hidden + vistas *_for_org) por el de la rama saas:
--   1. Plantillas de plataforma en tablas propias, sin organization_id.
--   2. catalog_items / movement_concepts / species con organization_id NOT
--      NULL y unique (organization_id, id): la llave foránea compuesta es lo
--      único que el motor garantiza.
--   3. seed_organization_catalogs(org) copia las plantillas activas a la
--      empresa; cada fila copiada guarda template_id.
--   4. Ocultar = active = false en la fila de la empresa.
--   5. Referencias tipadas compuestas + trigger que verifica el catálogo.
--   6. propagate_template(template_id) agrega una plantilla nueva a quien no
--      la tenga, sin tocar las que la empresa ya editó.

-- ---------------------------------------------------------------------
-- Plantillas de plataforma (solo el admin de plataforma las edita)
-- ---------------------------------------------------------------------
create table catalog_item_templates (
  id          uuid primary key default gen_random_uuid(),
  catalog     catalog_kind not null,
  name        text not null,
  sort_order  smallint not null default 100,
  active      boolean not null default true,
  created_at  timestamptz not null default now(),
  unique (catalog, name)
);

create table movement_concept_templates (
  id                uuid primary key default gen_random_uuid(),
  direction         concept_direction not null,
  name              text not null,
  source_lot        source_lot_rule not null default 'no_aplica',
  creates_lot       boolean not null default false,
  asks_result       boolean not null default false,
  asks_counterparty boolean not null default false,
  sort_order        smallint not null default 100,
  active            boolean not null default true,
  created_at        timestamptz not null default now(),
  unique (direction, name),
  check (direction = 'entrada' or (source_lot = 'no_aplica' and not creates_lot and not asks_result))
);

create table species_templates (
  id              uuid primary key default gen_random_uuid(),
  common_name     text not null unique,
  scientific_name text,
  active          boolean not null default true,
  created_at      timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- Catálogos de cada empresa (copiados de la plantilla o propios)
-- ---------------------------------------------------------------------
create table catalog_items (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  template_id     uuid references catalog_item_templates(id),   -- null = propio de la empresa
  catalog         catalog_kind not null,
  name            text not null,
  sort_order      smallint not null default 100,
  active          boolean not null default true,   -- ocultar = false; nunca se borra
  created_at      timestamptz not null default now(),
  created_by      uuid references auth.users(id),
  updated_at      timestamptz not null default now(),
  unique (organization_id, id),                    -- destino de las FK compuestas
  unique (organization_id, catalog, name),
  unique (organization_id, template_id)            -- una copia por plantilla y empresa
);
create index catalog_items_org_catalog on catalog_items (organization_id, catalog);
create trigger catalog_items_updated_at before update on catalog_items
  for each row execute function set_updated_at();

-- Movimientos de entrada y salida de granel: catálogo con comportamiento (§5.2)
create table movement_concepts (
  id                uuid primary key default gen_random_uuid(),
  organization_id   uuid not null references organizations(id) on delete cascade,
  template_id       uuid references movement_concept_templates(id),
  direction         concept_direction not null,
  name              text not null,                 -- 'Muestra de laboratorio'
  source_lot        source_lot_rule not null default 'no_aplica', -- ¿de qué lote viene?
  creates_lot       boolean not null default false, -- compra / carga inicial
  asks_result       boolean not null default false, -- pide volumen y % Alc. resultantes
  asks_counterparty boolean not null default false, -- cliente, laboratorio, proveedor
  sort_order        smallint not null default 100,
  active            boolean not null default true,
  created_at        timestamptz not null default now(),
  created_by        uuid references auth.users(id),
  updated_at        timestamptz not null default now(),
  unique (organization_id, id),
  unique (organization_id, direction, name),
  unique (organization_id, template_id),
  check (direction = 'entrada' or (source_lot = 'no_aplica' and not creates_lot and not asks_result))
);
create trigger movement_concepts_updated_at before update on movement_concepts
  for each row execute function set_updated_at();

create table species (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  template_id     uuid references species_templates(id),
  common_name     text not null,
  scientific_name text,
  active          boolean not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  unique (organization_id, id),
  unique (organization_id, common_name),
  unique (organization_id, template_id)
);
create trigger species_updated_at before update on species
  for each row execute function set_updated_at();

-- ---------------------------------------------------------------------
-- Verificación de que una referencia tipada apunta al catálogo correcto
-- (§10.2.5). La FK compuesta garantiza la empresa; esto garantiza el tipo.
-- ---------------------------------------------------------------------
create function assert_catalog_item(p_org uuid, p_item uuid, p_catalog catalog_kind) returns void
language plpgsql stable as $$
begin
  if p_item is null then
    return;
  end if;
  if not exists (
    select 1 from catalog_items c
     where c.organization_id = p_org and c.id = p_item and c.catalog = p_catalog
  ) then
    raise exception 'El elemento de catálogo no es de tipo %', p_catalog
      using errcode = '23514';                     -- check_violation
  end if;
end $$;

-- ---------------------------------------------------------------------
-- Copiar la semilla de plataforma a una empresa (la llama provision_organization
-- en el alta, Fase 2; en la semilla local se llama directo).
-- ---------------------------------------------------------------------
create function seed_organization_catalogs(p_org uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  insert into catalog_items (organization_id, template_id, catalog, name, sort_order, active)
  select p_org, t.id, t.catalog, t.name, t.sort_order, true
    from catalog_item_templates t
   where t.active
  on conflict (organization_id, template_id) do nothing;

  insert into movement_concepts (organization_id, template_id, direction, name, source_lot,
                                 creates_lot, asks_result, asks_counterparty, sort_order, active)
  select p_org, t.id, t.direction, t.name, t.source_lot,
         t.creates_lot, t.asks_result, t.asks_counterparty, t.sort_order, true
    from movement_concept_templates t
   where t.active
  on conflict (organization_id, template_id) do nothing;

  insert into species (organization_id, template_id, common_name, scientific_name, active)
  select p_org, t.id, t.common_name, t.scientific_name, true
    from species_templates t
   where t.active
  on conflict (organization_id, template_id) do nothing;
end $$;
revoke execute on function seed_organization_catalogs(uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- Una plantilla nueva no se propaga sola (§10.2.6): el admin de plataforma
-- la agrega a las empresas que no la tengan. Las filas que la empresa ya
-- editó no se tocan (on conflict do nothing sobre (organization_id, template_id)).
-- Busca el id en las tres tablas de plantillas; solo existe en una.
-- ---------------------------------------------------------------------
create function propagate_template(p_template_id uuid) returns integer
language plpgsql security definer set search_path = public as $$
declare
  n integer := 0;
  k integer;
begin
  if not exists (select 1 from platform_admins where user_id = auth.uid()) then
    raise exception 'Solo el admin de plataforma puede propagar plantillas' using errcode = 'P0001';
  end if;

  insert into catalog_items (organization_id, template_id, catalog, name, sort_order, active)
  select o.id, t.id, t.catalog, t.name, t.sort_order, true
    from catalog_item_templates t cross join organizations o
   where t.id = p_template_id and t.active
  on conflict (organization_id, template_id) do nothing;
  get diagnostics k = row_count; n := n + k;

  insert into movement_concepts (organization_id, template_id, direction, name, source_lot,
                                 creates_lot, asks_result, asks_counterparty, sort_order, active)
  select o.id, t.id, t.direction, t.name, t.source_lot,
         t.creates_lot, t.asks_result, t.asks_counterparty, t.sort_order, true
    from movement_concept_templates t cross join organizations o
   where t.id = p_template_id and t.active
  on conflict (organization_id, template_id) do nothing;
  get diagnostics k = row_count; n := n + k;

  insert into species (organization_id, template_id, common_name, scientific_name, active)
  select o.id, t.id, t.common_name, t.scientific_name, true
    from species_templates t cross join organizations o
   where t.id = p_template_id and t.active
  on conflict (organization_id, template_id) do nothing;
  get diagnostics k = row_count; n := n + k;

  return n;                                        -- filas agregadas
end $$;
revoke execute on function propagate_template(uuid) from public, anon;
