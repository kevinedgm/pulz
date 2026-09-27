-- 0011 · Vistas de lectura. Los saldos se derivan del ledger; nunca se guarda
-- un contador. security_invoker = true: la RLS de las tablas base aplica.
-- (PULZ_MAESTRO.md §3 "Ledger", §10.3 "Vistas")

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

-- Grado vigente: el último que el usuario declaró. No se calcula (§5.1).
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

-- Bitácora legible: cada pata con quién y cuándo (§6)
create view movement_log with (security_invoker = true) as
select m.organization_id, m.id as movement_id, o.id as operation_id, o.kind,
       mc.name as concept, m.movement_type, l.folio, m.volume_l, m.abv,
       rs.code as source, rd.code as destination,
       o.occurred_at, o.recorded_at, o.recorded_by as recorded_by_id,
       p.full_name as recorded_by, o.note
  from liquid_movements m
  join operations o  on o.id = m.operation_id
  join lots l        on l.id = m.lot_id
  left join movement_concepts mc on mc.id = o.concept_id
  left join resources rs on rs.id = m.source_resource_id
  left join resources rd on rd.id = m.dest_resource_id
  left join profiles p   on p.id = o.recorded_by;

-- Saldo de sólidos (maguey, agave cocido): lo inicial menos lo consumido
create view solid_lot_balances with (security_invoker = true) as
select l.organization_id, l.id as lot_id, l.folio, l.material,
       l.initial_quantity
       - coalesce((select sum(quantity_kg) from roasting_run_inputs r where r.lot_id = l.id), 0)
       - coalesce((select sum(quantity_kg) from formulation_inputs f where f.lot_id = l.id), 0)
         as remaining_kg
from lots l
where l.material in ('maguey', 'agave_cocido');
