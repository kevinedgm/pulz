-- 0009 · Etapas. Cada una cita la operación que la abrió y la que la cerró.
-- (PULZ_MAESTRO.md §4, §10.3 "Etapas")

-- ---------------------------------------------------------------------
-- Horneado (§4.2)
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

-- ---------------------------------------------------------------------
-- Molienda y formulación (§4.3). Sin entrada directa: una tina "que ya
-- fermentaba" entra por fermentación.
-- ---------------------------------------------------------------------
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

-- ---------------------------------------------------------------------
-- Fermentación (§4.4). Sin duración fija: dura lo que dure.
-- ---------------------------------------------------------------------
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
-- Regla dura: un solo ciclo abierto por tina (§2.1)
create unique index one_open_cycle_per_tina
  on fermentation_cycles (tina_id) where status <> 'cerrado';

-- Una medición no se borra: se anula con motivo (§4.4)
create table fermentation_measurements (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  operation_id    uuid not null unique,            -- quién midió y cuándo
  cycle_id        uuid not null,
  day_no          smallint not null check (day_no >= 0), -- día del ciclo, sin tope
  mode            measurement_mode not null,
  -- Escala 1–6 con etiquetas (§18 #1, supuesto de la rama saas). El CHECK es
  -- el único lugar donde vive el tope; cambiarlo aquí cambia el sistema.
  activity        smallint check (activity between 1 and 6),
  notes           text,
  voided_at       timestamptz,
  voided_by       uuid references auth.users(id),
  void_reason     text,
  unique (organization_id, id),
  foreign key (organization_id, operation_id) references operations(organization_id, id),
  foreign key (organization_id, cycle_id)     references fermentation_cycles(organization_id, id),
  check ((voided_at is null) = (void_reason is null))
);
create index fermentation_measurements_org_cycle on fermentation_measurements (organization_id, cycle_id, day_no);

-- Cada lectura es una fila; el promedio se calcula al vuelo, nunca se guarda.
create table measurement_readings (
  measurement_id  uuid not null,
  organization_id uuid not null,
  variable        reading_variable not null,
  zone            reading_zone not null,
  reading_no      smallint not null default 1 check (reading_no between 1 and 3),
  value           numeric(6,2) not null,
  primary key (measurement_id, variable, zone, reading_no),
  foreign key (organization_id, measurement_id)
    references fermentation_measurements(organization_id, id) on delete cascade,
  -- dulzor y acidez van en la misma escala 1–6 que activity (§18 #1)
  check (variable not in ('dulzor', 'acidez') or (value between 1 and 6))
);

-- ---------------------------------------------------------------------
-- Destilación (§4.5). Se abre cuando hay olla libre, con lo que haya.
-- ---------------------------------------------------------------------
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
