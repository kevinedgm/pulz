-- 0010 · Auditoría (sin JSON: cada cambio de columna es una fila).
-- La idempotencia vive en operations, no aquí. El trigger genérico que llena
-- estas tablas es de la Fase 8 (PULZ_MAESTRO.md §16); por ahora solo la
-- estructura, para que las llaves y grants queden fijos desde el inicio.

create table audit_events (
  id              bigint generated always as identity primary key,
  organization_id uuid references organizations(id),
  actor_id        uuid references auth.users(id),
  table_name      text not null,
  record_id       uuid not null,
  action          text not null check (action in ('insert', 'update')),
  occurred_at     timestamptz not null default now()
);
create index audit_events_org_table_record on audit_events (organization_id, table_name, record_id);

create table audit_changes (
  event_id        bigint not null references audit_events(id) on delete cascade,
  column_name     text not null,
  old_value       text,
  new_value       text,
  primary key (event_id, column_name)
);
