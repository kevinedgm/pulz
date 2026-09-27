-- 0008 · Lotes, linaje y ledger. Volúmenes solo en el ledger; nada se borra,
-- se corrige con otro movimiento. (PULZ_MAESTRO.md §3, §6, §10.3 "Núcleo")

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
create index lots_org_material_status on lots (organization_id, material, status);

-- Referencia circular (la operación crea el lote y declara su resultado):
-- se revisa al final de la transacción (§10.4.1).
alter table operations
  add foreign key (organization_id, result_lot_id) references lots(organization_id, id)
  deferrable initially deferred;

-- Qué lote aportó cuánto a qué otro lote: lo que permite trazar hacia atrás.
create table lot_lineage (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  operation_id    uuid not null,
  child_lot_id    uuid not null,
  parent_lot_id   uuid not null,
  quantity        numeric(12,3) not null check (quantity > 0),
  unit            text not null check (unit in ('kg', 'L')),
  abv             numeric(5,2),                    -- declarado, si lo dieron
  retroactive     boolean not null default false,  -- "completar historia" (§6)
  foreign key (organization_id, operation_id)  references operations(organization_id, id),
  foreign key (organization_id, child_lot_id)  references lots(organization_id, id),
  foreign key (organization_id, parent_lot_id) references lots(organization_id, id),
  check (child_lot_id <> parent_lot_id)
  -- sin unique(child, parent): el mismo lote puede aportar dos veces (§10.4.3)
);
create index lot_lineage_org_child  on lot_lineage (organization_id, child_lot_id);
create index lot_lineage_org_parent on lot_lineage (organization_id, parent_lot_id);

-- Origen externo de un lote (compra de granel, §5.3). Nada bloquea si falta.
create table lot_external_sources (
  lot_id              uuid primary key,
  organization_id     uuid not null,
  supplier_id         uuid,
  supplier_name       text,
  certificate_folio   text,                        -- opcional, nunca bloquea (§18 #7)
  certifying_body     text,
  declared_species_id uuid,
  declared_predio     text,
  foreign key (organization_id, lot_id)              references lots(organization_id, id) on delete cascade,
  foreign key (organization_id, supplier_id)         references suppliers(organization_id, id),
  foreign key (organization_id, declared_species_id) references species(organization_id, id)
);

create table maguey_receptions (
  lot_id          uuid primary key,
  organization_id uuid not null,
  species_id      uuid,
  predio_id       uuid,
  supplier_id     uuid,
  pina_count      integer check (pina_count >= 0),
  weight_kg       numeric(12,3) not null check (weight_kg > 0),
  quality_note    text,
  foreign key (organization_id, lot_id)      references lots(organization_id, id) on delete cascade,
  foreign key (organization_id, species_id)  references species(organization_id, id),
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
create index liquid_movements_org_lot       on liquid_movements (organization_id, lot_id);
create index liquid_movements_org_source    on liquid_movements (organization_id, source_resource_id);
create index liquid_movements_org_dest      on liquid_movements (organization_id, dest_resource_id);
create index liquid_movements_org_operation on liquid_movements (organization_id, operation_id);

-- Fotos y documentos (bucket privado 'evidencias', §8.1)
create table attachments (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  operation_id    uuid not null,
  lot_id          uuid not null,
  kind_item_id    uuid not null,                   -- catálogo tipo_adjunto
  storage_path    text not null,
  caption         text,
  foreign key (organization_id, operation_id) references operations(organization_id, id),
  foreign key (organization_id, lot_id)       references lots(organization_id, id),
  foreign key (organization_id, kind_item_id) references catalog_items(organization_id, id)
);
create index attachments_org_lot on attachments (organization_id, lot_id);

create function attachments_check_kind() returns trigger
language plpgsql as $$
begin
  perform assert_catalog_item(new.organization_id, new.kind_item_id, 'tipo_adjunto');
  return new;
end $$;
create trigger attachments_check_kind before insert or update of kind_item_id, organization_id on attachments
  for each row execute function attachments_check_kind();
