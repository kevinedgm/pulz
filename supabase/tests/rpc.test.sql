-- pgTAP · Comandos (RPC) — PULZ_MAESTRO.md §12, §16 Fase 2.
-- Se corre igual que el de aislamiento (sin Docker):
--     supabase db query --linked -f supabase/tests/rpc.test.sql
-- Todo dentro de una transacción que termina en rollback.
--
-- Parte del estado que deja seed.sql (construido por RPC): comprueba los
-- saldos de §15.1, la idempotencia, cada regla dura, los avisos blandos, la
-- regla de acumulación de colectores, transferir y la conciliación.

begin;

create function pg_temp.a() returns uuid language sql immutable as $$ select 'b66cf468-47f7-51ee-a8f2-994d907440b9'::uuid $$;
create function pg_temp.res(c text) returns uuid language sql stable security definer as $$
  select id from resources where organization_id = pg_temp.a() and code = c $$;
create function pg_temp.lot(f text) returns uuid language sql stable security definer as $$
  select id from lots where organization_id = pg_temp.a() and folio = f $$;
create function pg_temp.cyc(tina text) returns uuid language sql stable security definer as $$
  select c.id from fermentation_cycles c join resources r on r.id = c.tina_id
   where c.organization_id = pg_temp.a() and r.code = tina and c.status <> 'cerrado' $$;
create function pg_temp.run(f text) returns uuid language sql stable security definer as $$
  select id from distillation_runs where organization_id = pg_temp.a() and folio = f $$;
create function pg_temp.con(t uuid) returns uuid language sql stable security definer as $$
  select id from movement_concepts where organization_id = pg_temp.a() and template_id = t $$;
create function pg_temp.bal(res text, f text) returns numeric language sql stable security definer as $$
  select lot_balance(pg_temp.a(), pg_temp.res(res), pg_temp.lot(f)) $$;
create function pg_temp.como(u uuid) returns void language plpgsql as $$
begin
  execute 'set local role authenticated';
  execute format('set local request.jwt.claims = %L', json_build_object('sub', u, 'role', 'authenticated')::text);
end $$;

create function pg_temp.test_rpc() returns setof text language plpgsql as $$
declare
  benito  uuid := 'a88771d6-e323-5b36-991d-c42e5880e507';
  aurelia uuid := '417489a3-9fa1-5914-bbc9-92d5334e9734';
  tomas   uuid := 'e8e03baf-44a8-5af4-8d68-e0f3e04315a9';
  duena_b uuid := 'c0ffee00-0000-4000-8000-0000000000b1';
  n0 bigint; v uuid; v2 uuid; v_op uuid;
begin
  -- 1) La simulación construida por RPC da exactamente §15.1
  return next results_eq(
    $q$select r.code, l.folio, b.volume_l::numeric(12,3)
         from resource_lot_balances b
         join resources r on r.id = b.resource_id
         join lots l on l.id = b.lot_id
        where b.organization_id = 'b66cf468-47f7-51ee-a8f2-994d907440b9'
        order by r.code, l.folio$q$,
    $q$values ('Colector colas', 'COL-002',     16.000::numeric(12,3)),
              ('Tanque 1',       'G-COMPRA-01', 250.000::numeric(12,3)),
              ('Tanque 2',       'G-INI-01',    341.800::numeric(12,3)),
              ('Tina 1',         'FER-T1-001',  870.000::numeric(12,3)),
              ('Tina 2',         'FER-T2-001',  1400.000::numeric(12,3)),
              ('Tina 3',         'FER-T3-INI',  1300.000::numeric(12,3))$q$,
    'la simulación por RPC da los saldos de §15.1');

  -- 2) Idempotencia: repetir la misma llave no duplica nada
  perform pg_temp.como(benito);
  select count(*) into n0 from liquid_movements where organization_id = pg_temp.a();
  select registrar_movimiento_granel(pg_temp.a(), 'fac42efe-57e6-532d-8156-ff649279a923', '2026-09-20 13:00:00-06',
    pg_temp.con('fa52f92b-de19-5d0c-972c-beb899bb2ccb'), pg_temp.res('Tanque 2'), 2, p_lote => pg_temp.lot('G-INI-01'))
    into v;
  return next is(v, pg_temp.lot('G-INI-01'), 'idempotencia: la segunda llamada devuelve el mismo lote');
  return next is((select count(*) from liquid_movements where organization_id = pg_temp.a()), n0,
                 'idempotencia: la segunda llamada no agrega patas al ledger');

  -- 3) Reglas duras
  return next throws_like(
    format($q$select registrar_movimiento_granel('%s', gen_random_uuid(), now(), '%s', '%s', 10000, p_lote => '%s')$q$,
           pg_temp.a(), pg_temp.con('fa52f92b-de19-5d0c-972c-beb899bb2ccb'), pg_temp.res('Tanque 2'), pg_temp.lot('G-INI-01')),
    'SALDO_INSUFICIENTE:%', 'dura: no se puede sacar más de lo que hay');
  return next throws_like(
    format($q$select abrir_corrida('%s', gen_random_uuid(), now(), '%s', 'primera', array['%s']::uuid[], array['%s']::uuid[], array[400]::numeric[])$q$,
           pg_temp.a(), pg_temp.res('Alambique 1'), pg_temp.res('Tina 2'), pg_temp.lot('FER-T2-001')),
    'CAPACIDAD_EXCEDIDA:%', 'dura: la capacidad estricta del alambique bloquea');
  perform pg_temp.como(duena_b);
  return next throws_like(
    format($q$select registrar_medicion('%s', gen_random_uuid(), now(), '%s', 4::smallint, 'minimo', 3::smallint)$q$,
           pg_temp.a(), pg_temp.cyc('Tina 2')),
    'NO_PERMITIDO:%', 'dura: un usuario de otra empresa no ejecuta RPC de A');
  perform pg_temp.como(tomas);
  return next throws_like(
    format($q$select registrar_recepcion_maguey('%s', gen_random_uuid(), now(), 100)$q$, pg_temp.a()),
    'NO_PERMITIDO:%', 'dura: un operador no registra recepción de maguey (§11.1, §18 #4)');
  return next throws_like(
    format($q$select transferir('%s', gen_random_uuid(), now(), '%s', '%s', '%s', 1)$q$,
           pg_temp.a(), pg_temp.res('Tanque 1'), pg_temp.res('Tanque 2'), pg_temp.lot('G-COMPRA-01')),
    'NO_PERMITIDO:%', 'dura: un operador no transfiere granel');

  -- 4) Avisos blandos: sin nota fallan con REQUIERE_NOTA; con nota quedan registrados
  perform pg_temp.como(aurelia);
  return next throws_like(
    format($q$select registrar_medicion('%s', gen_random_uuid(), now(), '%s', 1::smallint, 'minimo', 3::smallint,
              array['brix']::reading_variable[], array['unica']::reading_zone[], array[1]::smallint[], array[20.0]::numeric[])$q$,
           pg_temp.a(), pg_temp.cyc('Tina 2')),
    'REQUIERE_NOTA:brix_fuera_rango', 'blanda: Brix inicial fuera de rango sin nota pide nota');
  return next lives_ok(
    format($q$select registrar_medicion('%s', '11111111-1111-4111-8111-111111111111', now(), '%s', 1::smallint, 'minimo', 3::smallint,
              array['brix']::reading_variable[], array['unica']::reading_zone[], array[1]::smallint[], array[20.0]::numeric[],
              'Brix alto, agua dura')$q$,
           pg_temp.a(), pg_temp.cyc('Tina 2')),
    'blanda: con nota, la medición se registra');
  return next is((select count(*) from operation_warnings w join operations o on o.id = w.operation_id
                   where o.idempotency_key = '11111111-1111-4111-8111-111111111111' and w.code = 'brix_fuera_rango'), 1::bigint,
                 'blanda: el aviso queda en operation_warnings con su nota');

  -- 5) Regla de acumulación de colectores (§4.5)
  perform pg_temp.como(tomas);
  return next lives_ok(
    format($q$select abrir_corrida('%s', gen_random_uuid(), now(), '%s', 'primera', array['%s']::uuid[], array['%s']::uuid[], array[200]::numeric[], null, 'DES-004')$q$,
           pg_temp.a(), pg_temp.res('Alambique 1'), pg_temp.res('Tina 2'), pg_temp.lot('FER-T2-001')),
    'acumulación: se abre DES-004 desde la Tina 2');
  select registrar_corte(pg_temp.a(), gen_random_uuid(), now(), pg_temp.run('DES-004'), 'mezcal', 5, 50.0, pg_temp.res('Colector mezcal')) into v;
  return next isnt(v, pg_temp.lot('MEZ-001'), 'acumulación: colector vacío → nace lote nuevo');
  return next is((select folio from lots where id = v), 'MEZ-002', 'acumulación: el folio automático salta los que ya existen');
  select registrar_corte(pg_temp.a(), gen_random_uuid(), now(), pg_temp.run('DES-004'), 'colas', 3, 9.0, pg_temp.res('Colector colas')) into v;
  return next is(v, pg_temp.lot('COL-002'), 'acumulación: se suma al lote vivo del colector (COL-002) porque no se cargó a esta corrida');
  perform cerrar_corrida(pg_temp.a(), gen_random_uuid(), now(), pg_temp.run('DES-004'));
  return next lives_ok(
    format($q$select abrir_corrida('%s', gen_random_uuid(), now(), '%s', 'segunda', array['%s']::uuid[], array['%s']::uuid[], array[19]::numeric[], null, 'DES-005')$q$,
           pg_temp.a(), pg_temp.res('Alambique 2'), pg_temp.res('Colector colas'), pg_temp.lot('COL-002')),
    'acumulación: se abre DES-005 cargando COL-002');
  select registrar_corte(pg_temp.a(), gen_random_uuid(), now(), pg_temp.run('DES-005'), 'colas', 2, 8.0, pg_temp.res('Colector colas')) into v2;
  return next isnt(v2, pg_temp.lot('COL-002'), 'acumulación: el lote vivo se cargó a la misma corrida → nace lote nuevo (evita linaje circular)');

  -- 6) Transferir conservando el folio del destino, con linaje
  perform pg_temp.como(aurelia);
  select transferir(pg_temp.a(), gen_random_uuid(), now(), pg_temp.res('Colector mezcal'), pg_temp.res('Tanque 1'),
                    pg_temp.lot('MEZ-002'), 5, 49.0, 'conservar') into v;
  return next is(v, pg_temp.lot('G-COMPRA-01'), 'transferir: conservar devuelve el lote que ya estaba en el destino');
  return next is(pg_temp.bal('Tanque 1', 'G-COMPRA-01'), 255.000::numeric, 'transferir: el destino suma los litros');
  return next ok(exists (select 1 from lot_lineage where child_lot_id = pg_temp.lot('G-COMPRA-01') and parent_lot_id = pg_temp.lot('MEZ-002')),
                 'transferir: queda el aporte del lote que se unió');

  -- 7) Conciliación de volumen declarado vs. ledger (§5.1)
  perform pg_temp.como(benito);
  select registrar_movimiento_granel(pg_temp.a(), '22222222-2222-4222-8222-222222222222', now(),
    pg_temp.con('66a151e2-9a2c-58be-ad4a-b117f1ddb717'), pg_temp.res('Tanque 2'), 10,
    p_lote => pg_temp.lot('G-INI-01'), p_resultado_l => 351.0, p_resultado_abv => 43.0) into v;
  select id into v_op from operations where idempotency_key = '22222222-2222-4222-8222-222222222222';
  return next is(pg_temp.bal('Tanque 2', 'G-INI-01'), 351.000::numeric, 'conciliación: el saldo queda en lo declarado');
  return next is((select volume_l from liquid_movements where operation_id = v_op and movement_type = 'conciliacion'),
                 0.800::numeric, 'conciliación: la pata registra exactamente la diferencia');
  return next is((select count(*) from operation_warnings where operation_id = v_op and code = 'diferencia_volumen'), 1::bigint,
                 'conciliación: queda el aviso diferencia_volumen');

  -- 8) Estado y nivel de historia derivados
  execute 'reset role';
  return next is((select status from lots where id = pg_temp.lot('MEZ-001')), 'agotado'::lot_status,
                 'un lote sin saldo en ningún recurso queda agotado');
  return next is((select history from lots where id = pg_temp.lot('G-INI-01')), 'parcial'::history_level,
                 'historia: carga inicial unida a producción con maguey → parcial');
  return next is((select history from lots where id = pg_temp.lot('G-COMPRA-01')), 'parcial'::history_level,
                 'historia: la compra recibió mezcal con historia → parcial');
end $$;

select * from runtests((select nspname from pg_namespace where oid = pg_my_temp_schema())::name, '^test_');

rollback;
