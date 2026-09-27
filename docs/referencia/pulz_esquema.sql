-- =====================================================================
-- PULZ · Esquema relacional (Postgres / Supabase) · v3
-- Sin JSON/JSONB: todo en columnas y tablas.
--
-- Cambios v3 (respuestas del palenque de referencia)
--   * Catálogos con semilla: filas con organization_id NULL son de la
--     plataforma (las mantiene el admin de sistema); cada empresa agrega
--     las suyas y oculta las que no usa sin borrarlas.
--   * Catálogo editable de movimientos de entrada y salida de granel
--     (agua, puntas, unión con otro lote, laboratorio, autoconsumo, merma…).
--   * El sistema NO calcula el grado: el usuario declara volumen y % Alc.
--     resultantes. Si el volumen declarado no cuadra con el ledger, se
--     registra un movimiento de conciliación automático.
--   * Toda acción es una fila de operations: quién, cuándo (en campo) y
--     cuándo se sincronizó. Movimientos, lotes, linaje y etapas la citan.
--   * Al juntar lotes el usuario decide: conservar un folio o renombrar.
--   * La carga al alambique consume el líquido (el alambique no guarda saldo).
--   * Las RPC son security definer con verificación de rol explícita
--     (en v2 eran security invoker y no tenían política de INSERT).
--   * Portal por empresa (/e/<slug>): usuario simple para trabajadores,
--     slug renombrable con historial, freno de intentos, bienvenida por enlace.
--   * Ninguna política 'for all': una por operación.
--   * Un colector sólo acumula en su lote vivo si ese lote no fue cargado
--     a la misma corrida; si no, nace lote nuevo (evita linaje circular).
--
-- Convenciones
--   * Tablas de negocio con organization_id NOT NULL (catálogos: NULL = semilla).
--   * Hijos con llaves foráneas compuestas (organization_id, id).
--   * Volúmenes sólo en el ledger; nada se borra, se corrige con otro movimiento.
-- =====================================================================

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------
-- 0001 · Tipos de dominio. Sólo lo que la lógica necesita fijo.
-- Todo lo que un palenque nombra a su manera es catálogo (0003).
-- ---------------------------------------------------------------------
create type member_role         as enum ('admin', 'productor', 'operador');
create type member_status       as enum ('invitado', 'activo', 'suspendido');
create type subscription_status as enum ('gratis', 'prueba', 'activa', 'vencida', 'cancelada');
create type resource_kind       as enum ('horno', 'molino', 'tina', 'alambique', 'colector', 'tanque');
create type capacity_policy     as enum ('estricta', 'flexible', 'libre');
create type material_kind       as enum ('maguey', 'agave_cocido', 'formulacion', 'fermentado', 'destilado', 'granel');
create type liquid_class        as enum ('mezcal', 'ordinario', 'colas', 'puntas');
create type lot_origin          as enum ('producido', 'compra', 'carga_inicial', 'mezcla');
create type lot_status          as enum ('activo', 'agotado', 'cerrado');
create type history_level       as enum ('completa', 'parcial', 'declarada', 'sin_historia');
create type run_status          as enum ('abierta', 'cerrada');
create type distillation_pass   as enum ('primera', 'segunda');
create type cycle_status        as enum ('fermentando', 'lista', 'en_vaciado', 'cerrado');
create type measurement_mode    as enum ('minimo', 'completo');
create type reading_variable    as enum ('temperatura', 'brix', 'dulzor', 'acidez');
create type reading_zone        as enum ('unica', 'superficie', 'fondo');
create type folio_decision      as enum ('conservar', 'renombrar');
create type concept_direction   as enum ('entrada', 'salida');
create type source_lot_rule     as enum ('no_aplica', 'opcional', 'requerido');

-- Qué catálogos existen (los valores dentro de cada uno son editables)
create type catalog_kind as enum (
  'tipo_horno', 'tipo_molino', 'tipo_tina', 'tipo_alambique', 'tipo_colector',
  'tipo_tanque', 'tipo_proveedor', 'tipo_adjunto', 'unidad_insumo');

-- Qué hace cada operación (la mecánica, no la etiqueta que ve el usuario)
create type operation_kind as enum (
  'recepcion_maguey', 'entrada_directa', 'abrir_horneado', 'cerrar_horneado',
  'formulacion', 'medicion', 'tina_lista', 'abrir_corrida', 'corte',
  'cerrar_corrida', 'transferencia', 'movimiento_granel', 'completar_historia',
  'correccion');

-- Tipos de pata en el ledger
create type movement_type as enum (
  'entrada',          -- algo entra al sistema (source null)
  'salida',           -- algo sale del sistema (dest null)
  'transferencia',    -- mismo lote cambia de recurso
  'carga_alambique',  -- sale de tina/colector y se consume en la corrida
  'corte',            -- nace en la corrida y entra a un colector (source null)
  'consumo',          -- un lote se absorbe en otro (unión, renombre)
  'conciliacion',     -- diferencia entre volumen declarado y ledger
  'correccion');

-- ---------------------------------------------------------------------
-- 0002 · Plataforma: empresas, miembros, planes, suscripciones
-- ---------------------------------------------------------------------
-- Nombres de portal que ninguna empresa puede tomar
create table reserved_slugs (
  slug    text primary key,
  reason  text not null
);
insert into reserved_slugs (slug, reason) values
  ('admin','panel de plataforma'), ('api','infraestructura'), ('app','infraestructura'),
  ('www','infraestructura'), ('e','prefijo de portales'), ('acceso','ruta pública'),
  ('login','ruta pública'), ('registro','ruta pública'), ('bienvenida','ruta pública'),
  ('soporte','operación'), ('ayuda','operación'), ('precios','sitio'), ('blog','sitio'),
  ('static','infraestructura'), ('assets','infraestructura'), ('cdn','infraestructura'),
  ('mail','infraestructura'), ('usuarios','subdominio de correos sintéticos'),
  ('pulz','marca'), ('demo','empresa de demostración');

-- Cada empresa tiene su portal: pulz.mx/e/<slug>
create table organizations (
  id              uuid primary key default gen_random_uuid(),
  name            text not null,                   -- nombre comercial, cambia cuando quieran
  slug            text not null unique
                    check (slug ~ '^[a-z0-9]([a-z0-9-]{1,38}[a-z0-9])$' and slug !~ '-{2}'),
  state           text,
  -- Marca del portal (lo único que se ve antes de iniciar sesión)
  brand_color     text check (brand_color ~ '^#[0-9A-Fa-f]{6}$'),
  logo_path       text,                            -- bucket público 'branding/<org_id>/…'
  welcome_message text check (length(welcome_message) <= 140),
  created_at      timestamptz not null default now(),
  created_by      uuid references auth.users(id)
);

-- El slug SÍ se puede cambiar: el viejo redirige para siempre y nadie más
-- puede tomarlo (evita que otro se quede con enlaces e iconos instalados).
create table organization_slug_history (
  slug            text primary key,
  organization_id uuid not null references organizations(id) on delete cascade,
  retired_at      timestamptz not null default now(),
  retired_by      uuid references auth.users(id)
);

create function organizations_slug_guard() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'UPDATE' and new.slug is not distinct from old.slug then
    return new;
  end if;
  if exists (select 1 from reserved_slugs where slug = new.slug) then
    raise exception 'Ese nombre de portal está reservado' using errcode = 'P0001';
  end if;
  if exists (select 1 from organization_slug_history
              where slug = new.slug and organization_id <> new.id) then
    raise exception 'Ese nombre de portal ya no está disponible' using errcode = 'P0001';
  end if;
  if tg_op = 'UPDATE' then
    insert into organization_slug_history (slug, organization_id, retired_by)
    values (old.slug, old.id, auth.uid())
    on conflict (slug) do nothing;
    delete from organization_slug_history      -- regresar a un nombre propio anterior
     where slug = new.slug and organization_id = new.id;
  end if;
  return new;
end $$;
create trigger organizations_slug_guard before insert or update of slug on organizations
  for each row execute function organizations_slug_guard();

create table profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  full_name   text not null,
  phone       text,
  created_at  timestamptz not null default now()
);

create table platform_admins (
  user_id     uuid primary key references auth.users(id) on delete cascade,
  created_at  timestamptz not null default now()
);

-- Dos clases de persona:
--   titular      entra con su correo real; recupera acceso por correo.
--   colaborador  entra con usuario simple ('ana.lopez') en el portal de su
--                empresa. En Auth su correo es sintético y nunca recibe nada:
--                ana.lopez@<organization_id>.usuarios.pulz.mx
--                (con el id y no el slug: renombrar el portal no toca cuentas).
create table organization_members (
  organization_id      uuid not null references organizations(id) on delete cascade,
  user_id              uuid not null references auth.users(id) on delete cascade,
  role                 member_role not null,
  status               member_status not null default 'invitado',
  username             text check (username ~ '^[a-z0-9]([a-z0-9._-]{1,28}[a-z0-9])$'),
  must_change_password boolean not null default false, -- la baja el servidor
  created_at           timestamptz not null default now(),
  primary key (organization_id, user_id),
  unique (organization_id, username)               -- una 'ana.lopez' por palenque
);

-- Bienvenida por enlace: el dueño manda por WhatsApp un enlace de un solo uso
-- y el trabajador elige su contraseña. Alternativa a dictarla en persona.
create table member_invitations (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  user_id         uuid not null,
  token_hash      text not null unique,            -- sha256; el token nunca se guarda
  expires_at      timestamptz not null default now() + interval '72 hours',
  used_at         timestamptz,
  created_by      uuid not null references auth.users(id),
  created_at      timestamptz not null default now(),
  foreign key (organization_id, user_id)
    references organization_members(organization_id, user_id) on delete cascade
);

-- Freno a quien adivina contraseñas: por cuenta, dentro de Postgres.
-- Lo escribe sólo el hook de verificación de contraseña de Auth (abajo).
create table login_throttle (
  user_id         uuid primary key references auth.users(id) on delete cascade,
  failed_count    smallint not null default 0,
  last_failed_at  timestamptz,
  locked_until    timestamptz
);

create table organization_settings (
  organization_id            uuid primary key references organizations(id) on delete cascade,
  record_puntas              boolean not null default false,  -- casi nadie las captura (<300 mL)
  measurement_mode           measurement_mode not null default 'minimo',
  warn_mixed_second_pass     boolean not null default true,   -- avisa y pide nota; nunca bloquea
  fermentation_expected_days smallint not null default 7,     -- sólo referencia visual
  measurement_reminder_hour  smallint not null default 9 check (measurement_reminder_hour between 0 and 23),
  default_folio_decision     folio_decision not null default 'conservar',
  updated_at                 timestamptz not null default now()
);

create table plans (
  id               uuid primary key default gen_random_uuid(),
  code             text not null unique,
  name             text not null,
  price_mxn_month  numeric(10,2) not null default 0,
  stripe_price_id  text unique,
  is_public        boolean not null default true
);

create table plan_limits (
  plan_id     uuid not null references plans(id) on delete cascade,
  limit_key   text not null,
  limit_value integer,                             -- null = ilimitado
  primary key (plan_id, limit_key)
);

create table plan_features (
  plan_id     uuid not null references plans(id) on delete cascade,
  feature_key text not null,
  primary key (plan_id, feature_key)
);

create table subscriptions (
  organization_id        uuid primary key references organizations(id) on delete cascade,
  plan_id                uuid not null references plans(id),
  status                 subscription_status not null default 'gratis',
  stripe_customer_id     text unique,
  stripe_subscription_id text unique,
  current_period_end     timestamptz,
  updated_at             timestamptz not null default now()
);

create table stripe_events (
  id           text primary key,
  type         text not null,
  received_at  timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 0003 · Catálogos con semilla
-- organization_id NULL = semilla de plataforma (la ve todo el mundo).
-- organization_id con valor = agregado por esa empresa.
-- Ocultar una semilla = fila en *_hidden (no se borra, no rompe historia).
-- ---------------------------------------------------------------------
create table catalog_items (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid references organizations(id) on delete cascade,
  catalog         catalog_kind not null,
  name            text not null,
  sort_order      smallint not null default 100,
  active          boolean not null default true,   -- la empresa desactiva las suyas
  created_at      timestamptz not null default now(),
  created_by      uuid references auth.users(id),
  unique (catalog, id),                            -- destino de FK tipadas
  unique nulls not distinct (organization_id, catalog, name)
);

create table catalog_item_hidden (
  organization_id uuid not null references organizations(id) on delete cascade,
  item_id         uuid not null references catalog_items(id) on delete cascade,
  hidden_at       timestamptz not null default now(),
  hidden_by       uuid references auth.users(id),
  primary key (organization_id, item_id)
);

-- Movimientos de entrada y salida de granel: catálogo con comportamiento.
create table movement_concepts (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid references organizations(id) on delete cascade,
  direction        concept_direction not null,
  name             text not null,                  -- 'Muestra de laboratorio'
  source_lot       source_lot_rule not null default 'no_aplica', -- ¿de qué lote viene?
  creates_lot      boolean not null default false, -- compra / carga inicial
  asks_result      boolean not null default false, -- pide volumen y % Alc. resultantes
  asks_counterparty boolean not null default false, -- cliente, laboratorio, proveedor
  sort_order       smallint not null default 100,
  active           boolean not null default true,
  created_at       timestamptz not null default now(),
  created_by       uuid references auth.users(id),
  unique nulls not distinct (organization_id, direction, name),
  check (direction = 'entrada' or (source_lot = 'no_aplica' and not creates_lot and not asks_result))
);

create table movement_concept_hidden (
  organization_id uuid not null references organizations(id) on delete cascade,
  concept_id      uuid not null references movement_concepts(id) on delete cascade,
  hidden_at       timestamptz not null default now(),
  hidden_by       uuid references auth.users(id),
  primary key (organization_id, concept_id)
);

create table species (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid references organizations(id) on delete cascade,
  common_name     text not null,
  scientific_name text,
  active          boolean not null default true,
  unique nulls not distinct (organization_id, common_name)
);

create table species_hidden (
  organization_id uuid not null references organizations(id) on delete cascade,
  species_id      uuid not null references species(id) on delete cascade,
  primary key (organization_id, species_id)
);

-- Lo que la empresa tiene de verdad (no son semilla)
create table predios (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  name            text not null,
  municipality    text,
  owner_name      text,
  notes           text,
  active          boolean not null default true,
  unique (organization_id, id)
);

create table suppliers (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references organizations(id) on delete cascade,
  name             text not null,
  type_catalog     catalog_kind not null default 'tipo_proveedor' check (type_catalog = 'tipo_proveedor'),
  type_item_id     uuid,
  phone            text,
  notes            text,
  active           boolean not null default true,
  unique (organization_id, id),
  foreign key (type_catalog, type_item_id) references catalog_items(catalog, id)
);

create table supplies (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references organizations(id) on delete cascade,
  name             text not null,
  unit_catalog     catalog_kind not null default 'unidad_insumo' check (unit_catalog = 'unidad_insumo'),
  unit_item_id     uuid not null,
  active           boolean not null default true,
  unique (organization_id, id),
  foreign key (unit_catalog, unit_item_id) references catalog_items(catalog, id)
);

-- ¿Puede esta empresa usar este elemento de catálogo?
create function catalog_visible(org uuid, item uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select item is null or exists (
    select 1 from catalog_items c
     where c.id = item and (c.organization_id is null or c.organization_id = org));
$$;

create function concept_visible(org uuid, concept uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from movement_concepts m
     where m.id = concept and (m.organization_id is null or m.organization_id = org));
$$;

-- Lo que ve cada empresa en sus listas: semillas no ocultas + las suyas activas
create view catalog_for_org with (security_invoker = true) as
select o.id as organization_id, c.id, c.catalog, c.name, c.sort_order,
       (c.organization_id is null) as is_seed
  from organizations o
  join catalog_items c on c.organization_id is null or c.organization_id = o.id
 where c.active
   and not exists (select 1 from catalog_item_hidden h
                    where h.organization_id = o.id and h.item_id = c.id);

create view concepts_for_org with (security_invoker = true) as
select o.id as organization_id, m.id, m.direction, m.name, m.source_lot,
       m.creates_lot, m.asks_result, m.asks_counterparty, m.sort_order,
       (m.organization_id is null) as is_seed
  from organizations o
  join movement_concepts m on m.organization_id is null or m.organization_id = o.id
 where m.active
   and not exists (select 1 from movement_concept_hidden h
                    where h.organization_id = o.id and h.concept_id = m.id);

-- ---------------------------------------------------------------------
-- 0004 · Infraestructura. El recurso es lo físico ("Alambique 1", 250 L);
-- su tipo sale del catálogo ("Alambique de cobre").
-- ---------------------------------------------------------------------
create table resources (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  kind            resource_kind not null,
  code            text not null,                   -- como le dicen: 'Alambique 1'
  type_catalog    catalog_kind,
  type_item_id    uuid,
  capacity        numeric(12,2),
  capacity_unit   text not null default 'L',
  capacity_policy capacity_policy not null default 'flexible',
  liquid_class    liquid_class,                    -- sólo colectores
  location        text,
  active          boolean not null default true,
  created_at      timestamptz not null default now(),
  unique (organization_id, id),
  unique (organization_id, code),
  foreign key (type_catalog, type_item_id) references catalog_items(catalog, id),
  check ((type_item_id is null and type_catalog is null) or type_catalog = case kind
           when 'horno' then 'tipo_horno'::catalog_kind
           when 'molino' then 'tipo_molino'::catalog_kind
           when 'tina' then 'tipo_tina'::catalog_kind
           when 'alambique' then 'tipo_alambique'::catalog_kind
           when 'colector' then 'tipo_colector'::catalog_kind
           when 'tanque' then 'tipo_tanque'::catalog_kind end),
  check ((kind = 'colector') = (liquid_class is not null))
);

-- ---------------------------------------------------------------------
-- 0005 · Operaciones: quién, cuándo y por qué, una sola vez
-- ---------------------------------------------------------------------
create table operations (
  id                uuid primary key default gen_random_uuid(),
  organization_id   uuid not null references organizations(id) on delete cascade,
  kind              operation_kind not null,
  concept_id        uuid references movement_concepts(id), -- sólo movimiento_granel / entrada_directa
  occurred_at       timestamptz not null,          -- cuándo pasó en el palenque
  recorded_at       timestamptz not null default now(), -- cuándo llegó al servidor
  recorded_by       uuid not null references auth.users(id),
  idempotency_key   uuid not null,                 -- lo genera el teléfono (offline)
  -- Lo que el usuario DECLARA que quedó (el sistema no calcula grado)
  result_resource_id uuid,
  result_lot_id      uuid,
  result_volume_l    numeric(12,3) check (result_volume_l >= 0),
  result_abv         numeric(5,2) check (result_abv between 0 and 100),
  folio_decision     folio_decision,               -- al juntar lotes
  counterparty       text,                         -- cliente, laboratorio, proveedor
  document_ref       text,                         -- factura, remisión, folio de análisis
  correction_of_id   uuid references operations(id),
  note               text,
  unique (organization_id, id),
  unique (organization_id, idempotency_key),
  foreign key (organization_id, result_resource_id) references resources(organization_id, id)
);
create index on operations (organization_id, occurred_at desc);
create index on operations (organization_id, recorded_by);

-- Reglas blandas que el usuario decidió saltarse, con su nota
create table operation_warnings (
  operation_id    uuid not null,
  organization_id uuid not null,
  code            text not null,                   -- 'mezcla_clases_2a', 'excede_capacidad'...
  note            text not null,
  primary key (operation_id, code),
  foreign key (organization_id, operation_id) references operations(organization_id, id)
);

-- ---------------------------------------------------------------------
-- 0006 · Lotes, linaje y ledger
-- ---------------------------------------------------------------------
create table lots (
  id               uuid primary key default gen_random_uuid(),
  organization_id  uuid not null references organizations(id) on delete cascade,
  operation_id     uuid not null,                  -- la operación que lo creó
  folio            text not null,
  material         material_kind not null,
  liquid_class     liquid_class,
  origin           lot_origin not null,
  status           lot_status not null default 'activo',
  history          history_level not null default 'sin_historia',
  unit             text not null check (unit in ('kg', 'L')),
  initial_quantity numeric(12,3),                  -- sólidos; líquidos usan ledger
  declared_origin  text,
  notes            text,
  unique (organization_id, id),
  unique (organization_id, folio),
  foreign key (organization_id, operation_id) references operations(organization_id, id)
);

-- Referencia circular (la operación crea el lote y declara su resultado):
-- se revisa al final de la transacción.
alter table operations
  add foreign key (organization_id, result_lot_id) references lots(organization_id, id)
  deferrable initially deferred;

create table lot_lineage (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  operation_id    uuid not null,
  child_lot_id    uuid not null,
  parent_lot_id   uuid not null,
  quantity        numeric(12,3) not null check (quantity > 0),
  unit            text not null check (unit in ('kg', 'L')),
  abv             numeric(5,2),                    -- declarado, si lo dieron
  retroactive     boolean not null default false,
  foreign key (organization_id, operation_id)  references operations(organization_id, id),
  foreign key (organization_id, child_lot_id)  references lots(organization_id, id),
  foreign key (organization_id, parent_lot_id) references lots(organization_id, id),
  check (child_lot_id <> parent_lot_id)
  -- sin unique(child, parent): el mismo lote puede aportar dos veces (dos uniones)
);
create index on lot_lineage (organization_id, child_lot_id);
create index on lot_lineage (organization_id, parent_lot_id);

create table lot_external_sources (
  lot_id              uuid primary key,
  organization_id     uuid not null,
  supplier_id         uuid,
  supplier_name       text,
  certificate_folio   text,                        -- opcional, nunca bloquea
  certifying_body     text,
  declared_species_id uuid references species(id),
  declared_predio     text,
  foreign key (organization_id, lot_id)      references lots(organization_id, id) on delete cascade,
  foreign key (organization_id, supplier_id) references suppliers(organization_id, id)
);

create table maguey_receptions (
  lot_id          uuid primary key,
  organization_id uuid not null,
  species_id      uuid references species(id),
  predio_id       uuid,
  supplier_id     uuid,
  pina_count      integer check (pina_count >= 0),
  weight_kg       numeric(12,3) not null check (weight_kg > 0),
  quality_note    text,
  foreign key (organization_id, lot_id)      references lots(organization_id, id) on delete cascade,
  foreign key (organization_id, predio_id)   references predios(organization_id, id),
  foreign key (organization_id, supplier_id) references suppliers(organization_id, id)
);

-- Ledger inmutable. Cada fila es una pata de una operación.
create table liquid_movements (
  id                 uuid primary key default gen_random_uuid(),
  organization_id    uuid not null,
  operation_id       uuid not null,
  movement_type      movement_type not null,
  lot_id             uuid not null,
  source_resource_id uuid,                         -- null = viene de fuera / nace
  dest_resource_id   uuid,                         -- null = sale / se consume
  volume_l           numeric(12,3) not null check (volume_l > 0),
  abv                numeric(5,2) check (abv between 0 and 100), -- declarado, opcional
  correction_of_id   uuid references liquid_movements(id),
  unique (organization_id, id),
  foreign key (organization_id, operation_id)       references operations(organization_id, id),
  foreign key (organization_id, lot_id)             references lots(organization_id, id),
  foreign key (organization_id, source_resource_id) references resources(organization_id, id),
  foreign key (organization_id, dest_resource_id)   references resources(organization_id, id),
  check (source_resource_id is not null or dest_resource_id is not null),
  check (source_resource_id is distinct from dest_resource_id)
);
create index on liquid_movements (organization_id, lot_id);
create index on liquid_movements (organization_id, source_resource_id);
create index on liquid_movements (organization_id, dest_resource_id);
create index on liquid_movements (organization_id, operation_id);

create table attachments (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  operation_id    uuid not null,
  lot_id          uuid not null,
  kind_catalog    catalog_kind not null default 'tipo_adjunto' check (kind_catalog = 'tipo_adjunto'),
  kind_item_id    uuid not null,
  storage_path    text not null,
  caption         text,
  foreign key (organization_id, operation_id) references operations(organization_id, id),
  foreign key (organization_id, lot_id)       references lots(organization_id, id),
  foreign key (kind_catalog, kind_item_id)    references catalog_items(catalog, id)
);

-- ---------------------------------------------------------------------
-- 0007 · Etapas. Cada una cita la operación que la abrió y la que la cerró.
-- ---------------------------------------------------------------------
create table roasting_runs (
  id                  uuid primary key default gen_random_uuid(),
  organization_id     uuid not null,
  operation_id        uuid not null,
  closed_operation_id uuid,
  folio               text not null,
  oven_id             uuid not null,
  status              run_status not null default 'abierta',
  started_at          timestamptz not null,
  ended_at            timestamptz,
  cooked_kg           numeric(12,3),
  fuel_note           text,
  output_lot_id       uuid,
  unique (organization_id, id),
  unique (organization_id, folio),
  foreign key (organization_id, operation_id)        references operations(organization_id, id),
  foreign key (organization_id, closed_operation_id) references operations(organization_id, id),
  foreign key (organization_id, oven_id)             references resources(organization_id, id),
  foreign key (organization_id, output_lot_id)       references lots(organization_id, id)
);

create table roasting_run_inputs (
  run_id          uuid not null,
  organization_id uuid not null,
  lot_id          uuid not null,
  quantity_kg     numeric(12,3) not null check (quantity_kg > 0),
  primary key (run_id, lot_id),
  foreign key (organization_id, run_id) references roasting_runs(organization_id, id),
  foreign key (organization_id, lot_id) references lots(organization_id, id)
);

create table formulations (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  operation_id    uuid not null,
  folio           text not null,
  mill_id         uuid,
  method_note     text,
  water_l         numeric(12,3),
  result_volume_l numeric(12,3),
  output_lot_id   uuid,
  unique (organization_id, id),
  unique (organization_id, folio),
  foreign key (organization_id, operation_id)  references operations(organization_id, id),
  foreign key (organization_id, mill_id)       references resources(organization_id, id),
  foreign key (organization_id, output_lot_id) references lots(organization_id, id)
);

create table formulation_inputs (
  formulation_id  uuid not null,
  organization_id uuid not null,
  lot_id          uuid not null,
  quantity_kg     numeric(12,3) not null check (quantity_kg > 0),
  primary key (formulation_id, lot_id),
  foreign key (organization_id, formulation_id) references formulations(organization_id, id),
  foreign key (organization_id, lot_id)         references lots(organization_id, id)
);

create table formulation_supplies (
  formulation_id  uuid not null,
  organization_id uuid not null,
  supply_id       uuid not null,
  quantity        numeric(12,3) not null check (quantity > 0),
  primary key (formulation_id, supply_id),
  foreign key (organization_id, formulation_id) references formulations(organization_id, id),
  foreign key (organization_id, supply_id)      references supplies(organization_id, id)
);

-- Sin duración fija: dura lo que dure (4, 6, 7 o más días).
create table fermentation_cycles (
  id                  uuid primary key default gen_random_uuid(),
  organization_id     uuid not null,
  operation_id        uuid not null,
  ready_operation_id  uuid,                        -- quién la declaró lista y cuándo
  tina_id             uuid not null,
  lot_id              uuid not null,
  formulation_id      uuid,
  status              cycle_status not null default 'fermentando',
  unique (organization_id, id),
  foreign key (organization_id, operation_id)       references operations(organization_id, id),
  foreign key (organization_id, ready_operation_id) references operations(organization_id, id),
  foreign key (organization_id, tina_id)            references resources(organization_id, id),
  foreign key (organization_id, lot_id)             references lots(organization_id, id),
  foreign key (organization_id, formulation_id)     references formulations(organization_id, id)
);
create unique index one_open_cycle_per_tina
  on fermentation_cycles (tina_id) where status <> 'cerrado';

create table fermentation_measurements (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  operation_id    uuid not null unique,            -- quién midió y cuándo
  cycle_id        uuid not null,
  day_no          smallint not null check (day_no >= 0), -- día del ciclo, sin tope
  mode            measurement_mode not null,
  activity        smallint check (activity between 1 and 10),
  notes           text,
  unique (organization_id, id),
  foreign key (organization_id, operation_id) references operations(organization_id, id),
  foreign key (organization_id, cycle_id)     references fermentation_cycles(organization_id, id)
);

create table measurement_readings (
  measurement_id  uuid not null,
  organization_id uuid not null,
  variable        reading_variable not null,
  zone            reading_zone not null,
  reading_no      smallint not null default 1 check (reading_no between 1 and 3),
  value           numeric(6,2) not null,
  primary key (measurement_id, variable, zone, reading_no),
  foreign key (organization_id, measurement_id)
    references fermentation_measurements(organization_id, id) on delete cascade
);

-- La corrida se abre cuando hay olla libre, con lo que haya: sin umbral.
create table distillation_runs (
  id                  uuid primary key default gen_random_uuid(),
  organization_id     uuid not null,
  operation_id        uuid not null,
  closed_operation_id uuid,
  folio               text not null,
  still_id            uuid not null,
  pass                distillation_pass not null,
  status              run_status not null default 'abierta',
  unique (organization_id, id),
  unique (organization_id, folio),
  foreign key (organization_id, operation_id)        references operations(organization_id, id),
  foreign key (organization_id, closed_operation_id) references operations(organization_id, id),
  foreign key (organization_id, still_id)            references resources(organization_id, id)
);

create table distillation_run_inputs (
  run_id          uuid not null,
  organization_id uuid not null,
  movement_id     uuid not null,                   -- pata 'carga_alambique'
  primary key (run_id, movement_id),
  foreign key (organization_id, run_id)      references distillation_runs(organization_id, id),
  foreign key (organization_id, movement_id) references liquid_movements(organization_id, id)
);

-- Cortes. 'mezcal' en 1ª pasada es normal ("ya mezcal"): va directo a granel.
-- Puntas sin captura no generan fila.
create table distillation_cuts (
  run_id          uuid not null,
  organization_id uuid not null,
  movement_id     uuid not null,                   -- pata 'corte'
  cut_class       liquid_class not null,
  primary key (run_id, movement_id),
  foreign key (organization_id, run_id)      references distillation_runs(organization_id, id),
  foreign key (organization_id, movement_id) references liquid_movements(organization_id, id)
);

-- ---------------------------------------------------------------------
-- 0008 · Auditoría (sin JSON). La idempotencia vive en operations.
-- ---------------------------------------------------------------------
create table audit_events (
  id              bigint generated always as identity primary key,
  organization_id uuid references organizations(id),
  actor_id        uuid references auth.users(id),
  table_name      text not null,
  record_id       uuid not null,
  action          text not null check (action in ('insert', 'update')),
  occurred_at     timestamptz not null default now()
);

create table audit_changes (
  event_id        bigint not null references audit_events(id) on delete cascade,
  column_name     text not null,
  old_value       text,
  new_value       text,
  primary key (event_id, column_name)
);

-- ---------------------------------------------------------------------
-- 0009 · Vistas de lectura
-- ---------------------------------------------------------------------
-- Volumen por recurso y lote (sale del ledger)
create view resource_lot_balances with (security_invoker = true) as
select organization_id, resource_id, lot_id, sum(delta_l) as volume_l
from (
  select organization_id, dest_resource_id as resource_id, lot_id, volume_l as delta_l
    from liquid_movements where dest_resource_id is not null
  union all
  select organization_id, source_resource_id, lot_id, -volume_l
    from liquid_movements where source_resource_id is not null
) m
group by organization_id, resource_id, lot_id
having sum(delta_l) <> 0;

-- Grado vigente: el último que el usuario declaró. No se calcula.
create view lot_declared_abv with (security_invoker = true) as
select distinct on (x.organization_id, x.lot_id)
       x.organization_id, x.lot_id, x.abv, x.occurred_at, x.recorded_by
from (
  select o.organization_id, o.result_lot_id as lot_id, o.result_abv as abv,
         o.occurred_at, o.recorded_by
    from operations o where o.result_abv is not null and o.result_lot_id is not null
  union all
  select m.organization_id, m.lot_id, m.abv, o.occurred_at, o.recorded_by
    from liquid_movements m join operations o on o.id = m.operation_id
   where m.abv is not null and m.movement_type in ('entrada', 'corte')
) x
order by x.organization_id, x.lot_id, x.occurred_at desc;

-- Bitácora legible: cada pata con quién y cuándo
create view movement_log with (security_invoker = true) as
select m.organization_id, m.id as movement_id, o.id as operation_id, o.kind,
       mc.name as concept, m.movement_type, l.folio, m.volume_l, m.abv,
       rs.code as source, rd.code as destination,
       o.occurred_at, o.recorded_at, p.full_name as recorded_by, o.note
  from liquid_movements m
  join operations o  on o.id = m.operation_id
  join lots l        on l.id = m.lot_id
  left join movement_concepts mc on mc.id = o.concept_id
  left join resources rs on rs.id = m.source_resource_id
  left join resources rd on rd.id = m.dest_resource_id
  left join profiles p   on p.id = o.recorded_by;

create view solid_lot_balances with (security_invoker = true) as
select l.organization_id, l.id as lot_id,
       l.initial_quantity
       - coalesce((select sum(quantity_kg) from roasting_run_inputs r where r.lot_id = l.id), 0)
       - coalesce((select sum(quantity_kg) from formulation_inputs f where f.lot_id = l.id), 0)
         as remaining_kg
from lots l
where l.material in ('maguey', 'agave_cocido');

-- ---------------------------------------------------------------------
-- 0009b · Portal por empresa (lo único que ve alguien sin sesión)
-- ---------------------------------------------------------------------
-- Estado del portal según la suscripción:
--   gratis, prueba, activa  -> abierto
--   vencida                 -> abierto en sólo lectura (no se secuestran datos)
--   cancelada o inexistente -> 404 idéntico (no revela qué empresas existen)
create function portal_branding(p_slug text)
returns table (organization_id uuid, slug text, name text, logo_path text,
               brand_color text, welcome_message text, read_only boolean,
               redirect_to text)
language sql stable security definer set search_path = public as $$
  with target as (
    select o.* from organizations o where o.slug = lower(p_slug)
    union all
    select o.* from organization_slug_history h
      join organizations o on o.id = h.organization_id
     where h.slug = lower(p_slug)
  )
  select t.id, t.slug, t.name, t.logo_path, t.brand_color, t.welcome_message,
         s.status = 'vencida',
         case when t.slug <> lower(p_slug) then t.slug end
    from target t
    join subscriptions s on s.organization_id = t.id
   where s.status <> 'cancelada'
   limit 1;
$$;
revoke execute on function portal_branding(text) from public;
grant execute on function portal_branding(text) to anon, authenticated;

-- Correo sintético de un colaborador. No es secreto: el portal ya publica
-- su organization_id y el usuario lo teclea la persona. Por eso el navegador
-- inicia sesión DIRECTO contra Supabase Auth, sin función intermedia:
--   * cada intento cuenta contra la IP real de quien lo hace, no contra la
--     IP compartida de un servidor que hablaría en nombre de todos;
--   * Auth responde lo mismo si el usuario no existe o la contraseña falla.
-- La función manage-member lo usa al crear la cuenta.
create function member_login_email(p_org uuid, p_username text) returns text
language sql immutable as $$
  select lower(p_username) || '@' || p_org::text || '.usuarios.pulz.mx';
$$;

-- Hook de Auth «Password verification attempt»: 5 fallos seguidos bloquean
-- la cuenta 15 minutos (30 si reincide). Un acierto limpia el contador.
-- La interfaz del hook es jsonb por contrato de Supabase; no se guarda nada
-- en jsonb. Habilitarlo en config.toml ([auth.hook.password_verification_attempt])
-- y confirmar que el plan de Supabase lo incluye.
create function auth_password_attempt(event jsonb) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  uid   uuid := (event->>'user_id')::uuid;
  ok    boolean := (event->>'valid')::boolean;
  t     login_throttle%rowtype;
begin
  select * into t from login_throttle where user_id = uid for update;
  if found and t.locked_until > now() then
    return jsonb_build_object('decision', 'reject', 'should_logout_user', false,
      'message', 'Demasiados intentos. Espera unos minutos o pide a tu encargado que te desbloquee.');
  end if;
  if ok then
    delete from login_throttle where user_id = uid;
    return jsonb_build_object('decision', 'continue');
  end if;
  insert into login_throttle (user_id, failed_count, last_failed_at)
  values (uid, 1, now())
  on conflict (user_id) do update
    set failed_count   = case when login_throttle.last_failed_at < now() - interval '1 hour'
                              then 1 else login_throttle.failed_count + 1 end,
        last_failed_at = now(),
        locked_until   = case when login_throttle.failed_count + 1 >= 5
                              then now() + case when login_throttle.locked_until is not null
                                                then interval '30 minutes' else interval '15 minutes' end
                              end;
  return jsonb_build_object('decision', 'continue');
end $$;
grant execute on function auth_password_attempt(jsonb) to supabase_auth_admin;
revoke execute on function auth_password_attempt(jsonb) from authenticated, anon, public;
grant select, insert, update, delete on login_throttle to supabase_auth_admin;

-- El encargado desbloquea a alguien de su empresa sin esperar
create function desbloquear_miembro(p_org uuid, p_user uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not has_role(p_org, array['admin']::member_role[]) then
    raise exception 'Sólo el administrador puede desbloquear' using errcode = 'P0001';
  end if;
  delete from login_throttle t
   using organization_members m
   where t.user_id = p_user and m.user_id = p_user and m.organization_id = p_org;
end $$;

-- ---------------------------------------------------------------------
-- 0010 · Seguridad: RLS
-- ---------------------------------------------------------------------
create function is_member(org uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from organization_members
                  where organization_id = org and user_id = auth.uid() and status = 'activo');
$$;

create function has_role(org uuid, roles member_role[]) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from organization_members
                  where organization_id = org and user_id = auth.uid()
                    and status = 'activo' and role = any(roles));
$$;

create function is_platform_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from platform_admins where user_id = auth.uid());
$$;

-- Lectura para miembros. Escritura de producción: sólo vía RPC (0011).
do $$
declare t text;
begin
  foreach t in array array[
    'predios','suppliers','supplies','resources','operations','operation_warnings',
    'lots','lot_lineage','lot_external_sources','maguey_receptions','liquid_movements',
    'attachments','roasting_runs','roasting_run_inputs','formulations','formulation_inputs',
    'formulation_supplies','fermentation_cycles','fermentation_measurements',
    'measurement_readings','distillation_runs','distillation_run_inputs','distillation_cuts',
    'catalog_item_hidden','movement_concept_hidden','species_hidden']
  loop
    execute format('alter table %I enable row level security', t);
    execute format('create policy %I on %I for select using (is_member(organization_id))',
                   t || '_select', t);
  end loop;
end $$;

-- Catálogos: semillas visibles para todos; sólo el admin de plataforma las edita
do $$
declare t text;
begin
  foreach t in array array['catalog_items','movement_concepts','species'] loop
    execute format('alter table %I enable row level security', t);
    execute format('create policy %I on %I for select using (organization_id is null or is_member(organization_id))',
                   t || '_select', t);
    execute format('create policy %I on %I for insert with check ((organization_id is null and is_platform_admin()) or has_role(organization_id, array[''admin'']::member_role[]))', t || '_insert', t);
    execute format('create policy %I on %I for update using ((organization_id is null and is_platform_admin()) or has_role(organization_id, array[''admin'']::member_role[]))', t || '_update', t);
    -- sin DELETE: se desactiva, no se borra
  end loop;
  foreach t in array array['catalog_item_hidden','movement_concept_hidden','species_hidden'] loop
    execute format('create policy %I on %I for insert with check (has_role(organization_id, array[''admin'']::member_role[]))', t || '_insert', t);
    execute format('create policy %I on %I for delete using (has_role(organization_id, array[''admin'']::member_role[]))', t || '_delete', t);
  end loop;
end $$;

-- Infraestructura y catálogos propios: el tipo debe ser semilla o de la empresa
create policy resources_insert on resources for insert
  with check (has_role(organization_id, array['admin']::member_role[]) and catalog_visible(organization_id, type_item_id));
create policy resources_update on resources for update
  using (has_role(organization_id, array['admin']::member_role[])) with check (has_role(organization_id, array['admin']::member_role[]) and catalog_visible(organization_id, type_item_id));
create policy predios_insert on predios for insert with check (has_role(organization_id, array['admin','productor']::member_role[]));
create policy predios_update on predios for update using (has_role(organization_id, array['admin','productor']::member_role[])) with check (has_role(organization_id, array['admin','productor']::member_role[]));
create policy suppliers_insert on suppliers for insert with check (has_role(organization_id, array['admin','productor']::member_role[]) and catalog_visible(organization_id, type_item_id));
create policy suppliers_update on suppliers for update using (has_role(organization_id, array['admin','productor']::member_role[])) with check (has_role(organization_id, array['admin','productor']::member_role[]) and catalog_visible(organization_id, type_item_id));
create policy supplies_insert on supplies for insert with check (has_role(organization_id, array['admin','productor']::member_role[]) and catalog_visible(organization_id, unit_item_id));
create policy supplies_update on supplies for update using (has_role(organization_id, array['admin','productor']::member_role[])) with check (has_role(organization_id, array['admin','productor']::member_role[]) and catalog_visible(organization_id, unit_item_id));

alter table organizations         enable row level security;
alter table organization_members  enable row level security;
alter table organization_settings enable row level security;
alter table subscriptions         enable row level security;
alter table profiles              enable row level security;
alter table plans                 enable row level security;
alter table plan_limits           enable row level security;
alter table plan_features         enable row level security;

create policy org_select      on organizations for select using (is_member(id) or is_platform_admin());
-- El admin edita nombre, marca y slug del portal (el trigger guarda el historial)
create policy org_update      on organizations for update
  using (has_role(id, array['admin']::member_role[]))
  with check (has_role(id, array['admin']::member_role[]));
create policy members_select  on organization_members for select using (is_member(organization_id));
alter table member_invitations enable row level security;  -- sin políticas: sólo service_role
alter table login_throttle     enable row level security;  -- sin políticas: sólo el hook
create policy throttle_auth_select on login_throttle for select to supabase_auth_admin using (true);
create policy throttle_auth_insert on login_throttle for insert to supabase_auth_admin with check (true);
create policy throttle_auth_update on login_throttle for update to supabase_auth_admin using (true);
create policy throttle_auth_delete on login_throttle for delete to supabase_auth_admin using (true);
alter table organization_slug_history enable row level security;
create policy slug_history_select on organization_slug_history for select using (is_member(organization_id));
alter table reserved_slugs enable row level security;       -- lo consulta el trigger (definer)
-- Altas de miembros: sólo por la función manage-member (crea también la
-- cuenta de Auth). Aquí el admin sólo cambia rol o estado.
create policy members_update  on organization_members for update
  using (has_role(organization_id, array['admin']::member_role[]))
  with check (has_role(organization_id, array['admin']::member_role[]));
create policy settings_select on organization_settings for select using (is_member(organization_id));
create policy settings_admin  on organization_settings for update
  using (has_role(organization_id, array['admin']::member_role[]));
create policy subs_select     on subscriptions for select using (is_member(organization_id));
-- Nombres de compañeros de empresa visibles (para "quién lo hizo")
create policy profile_self    on profiles for select using (id = auth.uid());
create policy profile_update  on profiles for update using (id = auth.uid()) with check (id = auth.uid());
create policy profile_peers   on profiles for select using (exists (
  select 1 from organization_members a join organization_members b
    on a.organization_id = b.organization_id
   where a.user_id = auth.uid() and a.status = 'activo' and b.user_id = profiles.id));
create policy plans_public    on plans for select using (is_public or is_platform_admin());
create policy limits_public   on plan_limits for select using (true);
create policy features_public on plan_features for select using (true);

-- ---------------------------------------------------------------------
-- 0011 · Comandos (RPC). Firmas; cuerpos en migrations/0011_rpc.sql
-- Todas: security definer + set search_path = public, verifican
-- has_role() al inicio, buscan idempotency_key en operations antes de
-- hacer nada, insertan la operación y sus patas en una transacción.
-- ---------------------------------------------------------------------
-- registrar_recepcion_maguey(org, idem, fecha, especie, predio, proveedor, piñas, kg, nota) -> lot_id
-- registrar_entrada(org, idem, fecha, etapa, clase, recurso, volumen|kg, abv,
--                   origen, proveedor, folio_certificado, nota) -> lot_id
-- abrir_horneado / cerrar_horneado(...)            -> lote agave_cocido + linaje
-- registrar_formulacion(..., reparto a tinas)       -> ciclos + lotes fermentado + 'entrada'
-- registrar_medicion(org, idem, fecha, ciclo, día, modo, actividad, lecturas como filas)
-- declarar_tina_lista(org, idem, fecha, ciclo)
-- abrir_corrida(org, idem, fecha, alambique, pasada, orígenes: recurso+lote+volumen)
--     -> patas 'carga_alambique' (dest null); aviso si mezcla ordinario y colas
-- registrar_corte(org, idem, fecha, corrida, clase, volumen, abv, colector)
--     -> pata 'corte'; nace lote o se suma al lote vivo del colector
-- cerrar_corrida(org, idem, fecha, corrida)
-- transferir(org, idem, fecha, origen, destino, lote, volumen, decisión_folio, folio_nuevo)
-- registrar_movimiento_granel(org, idem, fecha, concepto, tanque, lote, volumen,
--     lote_origen?, volumen_resultante?, abv_resultante?, decisión_folio?, contraparte?, doc?)
--     -> patas + linaje; si volumen_resultante ≠ ledger, pata 'conciliacion'
-- completar_historia(org, idem, lote_hijo, lote_padre | datos declarados)
-- corregir_operacion(org, idem, operación, nuevos valores, motivo)
--
-- Duras (bloquean): saldo negativo, capacidad 'estricta', otra empresa,
--                   catálogo de otra empresa.
-- Blandas (avisan, piden nota, quedan en operation_warnings): capacidad
--   'flexible', ordinario + colas en la misma 2ª pasada, % Alc. fuera de
--   rango habitual, diferencia entre volumen declarado y ledger.
