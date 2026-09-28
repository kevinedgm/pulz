-- 0026 · Vistas de proceso (Fase 5; PULZ_MAESTRO.md §13.2 #3–#6, §8.2):
-- lo derivado que la interfaz necesita para Inicio/hoy, Fermentación,
-- Destilación y Granel, calculado aquí y no en el teléfono. Todas con
-- security_invoker: manda la RLS de las tablas (nadie ve otra empresa).
-- Fechas: se entregan tal cual (timestamptz); "qué día del ciclo es hoy" y
-- "toca medir hoy" los decide el navegador en su zona horaria (DECISIONES).

-- ---------------------------------------------------------------------
-- Tinas en uso: un ciclo no cerrado por tina, con lo que hay dentro y la
-- última medición válida (promedios al vuelo, §4.4).
-- ---------------------------------------------------------------------
create view tinas_en_uso with (security_invoker = true) as
select c.organization_id,
       c.id                as cycle_id,
       c.tina_id,
       r.code              as tina,
       r.capacity          as capacidad_l,
       r.capacity_policy,
       c.lot_id,
       l.folio,
       c.status,
       c.formulation_id,
       f.folio             as formulacion,
       o.occurred_at       as started_at,
       p.full_name         as started_by,
       coalesce(b.volume_l, 0) as litros,
       coalesce(m.total, 0)    as mediciones,
       um.occurred_at      as ultima_medicion_at,
       um.day_no           as ultima_medicion_dia,
       um.activity         as ultima_actividad,
       um.temperatura      as ultima_temperatura,
       um.brix             as ultimo_brix
  from fermentation_cycles c
  join resources r   on r.id = c.tina_id
  join lots l        on l.id = c.lot_id
  join operations o  on o.id = c.operation_id
  left join profiles p on p.id = o.recorded_by
  left join formulations f on f.id = c.formulation_id
  left join resource_lot_balances b
         on b.organization_id = c.organization_id and b.resource_id = c.tina_id and b.lot_id = c.lot_id
  left join lateral (
         select count(*) as total
           from fermentation_measurements x
          where x.cycle_id = c.id and x.voided_at is null
       ) m on true
  left join lateral (
         select o2.occurred_at, x.day_no, x.activity,
                (select round(avg(v.value), 2) from measurement_readings v
                  where v.measurement_id = x.id and v.variable = 'temperatura') as temperatura,
                (select round(avg(v.value), 2) from measurement_readings v
                  where v.measurement_id = x.id and v.variable = 'brix') as brix
           from fermentation_measurements x
           join operations o2 on o2.id = x.operation_id
          where x.cycle_id = c.id and x.voided_at is null
          order by o2.occurred_at desc
          limit 1
       ) um on true
 where c.status <> 'cerrado';

-- ---------------------------------------------------------------------
-- Mediciones de un ciclo: una fila por medición, anuladas incluidas y
-- marcadas; promedios por variable y zona (el promedio nunca se guarda).
-- ---------------------------------------------------------------------
create view mediciones_del_ciclo with (security_invoker = true) as
select m.organization_id,
       m.cycle_id,
       m.id            as measurement_id,
       m.day_no,
       m.mode,
       m.activity,
       m.notes,
       o.occurred_at,
       o.recorded_at,
       p.full_name     as recorded_by,
       m.voided_at,
       m.void_reason,
       round(avg(v.value) filter (where v.variable = 'temperatura'), 2)                          as temperatura,
       round(avg(v.value) filter (where v.variable = 'brix'), 2)                                 as brix,
       round(avg(v.value) filter (where v.variable = 'temperatura' and v.zone = 'superficie'), 2) as temperatura_superficie,
       round(avg(v.value) filter (where v.variable = 'temperatura' and v.zone = 'fondo'), 2)      as temperatura_fondo,
       round(avg(v.value) filter (where v.variable = 'brix' and v.zone = 'superficie'), 2)        as brix_superficie,
       round(avg(v.value) filter (where v.variable = 'brix' and v.zone = 'fondo'), 2)             as brix_fondo,
       max(v.value) filter (where v.variable = 'dulzor')                                          as dulzor,
       max(v.value) filter (where v.variable = 'acidez')                                          as acidez,
       count(v.value)                                                                            as lecturas
  from fermentation_measurements m
  join operations o  on o.id = m.operation_id
  left join profiles p on p.id = o.recorded_by
  left join measurement_readings v on v.measurement_id = m.id
 group by m.organization_id, m.cycle_id, m.id, m.day_no, m.mode, m.activity, m.notes,
          o.occurred_at, o.recorded_at, p.full_name, m.voided_at, m.void_reason;

-- ---------------------------------------------------------------------
-- Corridas (abiertas y cerradas): alambique, orígenes cargados y cortes por
-- clase. La interfaz filtra por status.
-- ---------------------------------------------------------------------
create view corridas with (security_invoker = true) as
select d.organization_id,
       d.id               as run_id,
       d.folio,
       d.still_id,
       r.code             as alambique,
       r.capacity         as capacidad_l,
       d.pass,
       d.status,
       o.occurred_at      as started_at,
       p.full_name        as started_by,
       oc.occurred_at     as closed_at,
       coalesce(i.litros, 0) as litros_cargados,
       coalesce(i.origenes, '[]'::jsonb) as origenes,
       coalesce(k.litros, 0) as litros_cortados,
       coalesce(k.cortes, '[]'::jsonb) as cortes
  from distillation_runs d
  join resources r  on r.id = d.still_id
  join operations o on o.id = d.operation_id
  left join profiles p on p.id = o.recorded_by
  left join operations oc on oc.id = d.closed_operation_id
  left join lateral (
         select sum(mv.volume_l) as litros,
                jsonb_agg(jsonb_build_object(
                  'resource_id', mv.source_resource_id, 'recurso', rs.code,
                  'lot_id', mv.lot_id, 'folio', l.folio, 'litros', mv.volume_l, 'abv', mv.abv)
                  order by rs.code) as origenes
           from distillation_run_inputs x
           join liquid_movements mv on mv.id = x.movement_id
           left join resources rs on rs.id = mv.source_resource_id
           join lots l on l.id = mv.lot_id
          where x.run_id = d.id
       ) i on true
  left join lateral (
         select sum(mv.volume_l) as litros,
                jsonb_agg(jsonb_build_object(
                  'movement_id', mv.id, 'clase', x.cut_class, 'litros', mv.volume_l, 'abv', mv.abv,
                  'resource_id', mv.dest_resource_id, 'destino', rd.code,
                  'lot_id', mv.lot_id, 'folio', l.folio, 'occurred_at', om.occurred_at)
                  order by om.occurred_at) as cortes
           from distillation_cuts x
           join liquid_movements mv on mv.id = x.movement_id
           join operations om on om.id = mv.operation_id
           left join resources rd on rd.id = mv.dest_resource_id
           join lots l on l.id = mv.lot_id
          where x.run_id = d.id
       ) k on true;

-- ---------------------------------------------------------------------
-- Colectores con saldo: qué clase, qué lote vivo y a qué grado declarado.
-- ---------------------------------------------------------------------
create view colectores_con_saldo with (security_invoker = true) as
select b.organization_id,
       b.resource_id,
       r.code          as colector,
       r.liquid_class,
       r.capacity      as capacidad_l,
       b.lot_id,
       l.folio,
       b.volume_l      as litros,
       a.abv,
       a.occurred_at   as abv_at,
       p.full_name     as abv_by
  from resource_lot_balances b
  join resources r on r.id = b.resource_id and r.kind = 'colector'
  join lots l      on l.id = b.lot_id
  left join lot_declared_abv a on a.organization_id = b.organization_id and a.lot_id = b.lot_id
  left join profiles p on p.id = a.recorded_by
 where b.volume_l > 0;

-- ---------------------------------------------------------------------
-- Tanques de granel (activos, con o sin saldo): litros totales y lotes
-- dentro con su grado declarado vigente, quién y cuándo (§5.1, §13.2 #6).
-- ---------------------------------------------------------------------
create view tanques with (security_invoker = true) as
select r.organization_id,
       r.id            as resource_id,
       r.code          as tanque,
       r.capacity      as capacidad_l,
       r.capacity_policy,
       r.location,
       coalesce(t.litros, 0) as litros,
       coalesce(t.lotes, '[]'::jsonb) as lotes
  from resources r
  left join lateral (
         select sum(b.volume_l) as litros,
                jsonb_agg(jsonb_build_object(
                  'lot_id', b.lot_id, 'folio', l.folio, 'litros', b.volume_l,
                  'history', l.history, 'origin', l.origin,
                  'abv', a.abv, 'abv_at', a.occurred_at, 'abv_by', p.full_name)
                  order by b.volume_l desc) as lotes
           from resource_lot_balances b
           join lots l on l.id = b.lot_id
           left join lot_declared_abv a on a.organization_id = b.organization_id and a.lot_id = b.lot_id
           left join profiles p on p.id = a.recorded_by
          where b.resource_id = r.id and b.volume_l > 0
       ) t on true
 where r.kind = 'tanque' and r.active;

revoke all on tinas_en_uso, mediciones_del_ciclo, corridas, colectores_con_saldo, tanques from public, anon;
grant select on tinas_en_uso, mediciones_del_ciclo, corridas, colectores_con_saldo, tanques to authenticated;
