-- 0005 · Lo que la empresa tiene de verdad (no son semilla): predios,
-- proveedores e insumos. (PULZ_MAESTRO.md §10.3 "Catálogos")
-- Las referencias a catalog_items son compuestas (§10.2.5) y un trigger
-- verifica que el elemento sea del catálogo correcto.

create table predios (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  name            text not null,
  municipality    text,
  owner_name      text,
  notes           text,
  active          boolean not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  unique (organization_id, id)
);
create trigger predios_updated_at before update on predios
  for each row execute function set_updated_at();

create table suppliers (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references organizations(id) on delete cascade,
  name             text not null,
  type_item_id     uuid,                           -- catálogo tipo_proveedor
  phone            text,
  notes            text,
  active           boolean not null default true,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  unique (organization_id, id),
  foreign key (organization_id, type_item_id) references catalog_items(organization_id, id)
);
create trigger suppliers_updated_at before update on suppliers
  for each row execute function set_updated_at();

create function suppliers_check_type() returns trigger
language plpgsql set search_path = public as $$
begin
  perform assert_catalog_item(new.organization_id, new.type_item_id, 'tipo_proveedor');
  return new;
end $$;
create trigger suppliers_check_type before insert or update of type_item_id, organization_id on suppliers
  for each row execute function suppliers_check_type();

create table supplies (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references organizations(id) on delete cascade,
  name             text not null,
  unit_item_id     uuid not null,                  -- catálogo unidad_insumo
  active           boolean not null default true,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  unique (organization_id, id),
  foreign key (organization_id, unit_item_id) references catalog_items(organization_id, id)
);
create trigger supplies_updated_at before update on supplies
  for each row execute function set_updated_at();

create function supplies_check_unit() returns trigger
language plpgsql set search_path = public as $$
begin
  perform assert_catalog_item(new.organization_id, new.unit_item_id, 'unidad_insumo');
  return new;
end $$;
create trigger supplies_check_unit before insert or update of unit_item_id, organization_id on supplies
  for each row execute function supplies_check_unit();
