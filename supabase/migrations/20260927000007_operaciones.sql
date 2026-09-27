-- 0007 · Operaciones: quién, cuándo (en campo) y cuándo se sincronizó, una
-- sola vez. Movimientos, lotes, linaje y etapas la citan.
-- (PULZ_MAESTRO.md §3 "Operación", §8.3 idempotencia, §10.3 "Núcleo")

create table operations (
  id                 uuid primary key default gen_random_uuid(),
  organization_id    uuid not null references organizations(id) on delete cascade,
  kind               operation_kind not null,
  concept_id         uuid,                         -- solo movimiento_granel / entrada_directa
  occurred_at        timestamptz not null,         -- cuándo pasó en el palenque
  recorded_at        timestamptz not null default now(), -- cuándo llegó al servidor
  recorded_by        uuid not null references auth.users(id),
  idempotency_key    uuid not null,                -- lo genera el teléfono (offline)
  -- Lo que el usuario DECLARA que quedó (el sistema no calcula grado, §5.1)
  result_resource_id uuid,
  result_lot_id      uuid,                         -- FK diferida en 0008 (referencia circular)
  result_volume_l    numeric(12,3) check (result_volume_l >= 0),
  result_abv         numeric(5,2) check (result_abv between 0 and 100),
  folio_decision     folio_decision,               -- al juntar lotes
  counterparty       text,                         -- cliente, laboratorio, proveedor
  document_ref       text,                         -- factura, remisión, folio de análisis
  correction_of_id   uuid references operations(id),
  note               text,
  unique (organization_id, id),
  unique (organization_id, idempotency_key),
  foreign key (organization_id, concept_id)        references movement_concepts(organization_id, id),
  foreign key (organization_id, result_resource_id) references resources(organization_id, id)
);
create index operations_org_occurred on operations (organization_id, occurred_at desc);
create index operations_org_recorded_by on operations (organization_id, recorded_by);

-- Reglas blandas que el usuario decidió saltarse, con su nota (§2.1)
create table operation_warnings (
  operation_id    uuid not null,
  organization_id uuid not null,
  code            text not null,                   -- 'mezcla_clases_2a', 'excede_capacidad'...
  note            text not null,
  primary key (operation_id, code),
  foreign key (organization_id, operation_id) references operations(organization_id, id)
);
