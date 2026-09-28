-- RETIRADA: el cuerpo histórico usa dblink con COMMIT fuera del rollback
-- y datos de la demo. El guard evita cualquier escritura si se invoca.
-- Prueba vigente aislada: pnpm test:db:concurrency.
do $$ begin
  raise exception 'PRUEBA_REEMPLAZADA: ejecuta pnpm test:db:concurrency';
end $$;

-- pgTAP · Concurrencia (PULZ_MAESTRO.md §16 Fase 2): dos transferencias
-- simultáneas del último litro → una pasa y la otra falla con
-- SALDO_INSUFICIENTE. Sin Docker y por la Management API no hay dos
-- sesiones reales, así que se abren dos conexiones con dblink desde esta.
--
-- Si dblink no puede conectarse (pide contraseña para roles que no son
-- superusuario en Supabase), el test se marca SKIP y se documenta en
-- docs/DUDAS.md: no se finge que pasó.
--
--     supabase db query --linked -f supabase/tests/rpc_concurrencia.test.sql

begin;
create extension if not exists dblink with schema extensions;

create function pg_temp.test_concurrencia() returns setof text language plpgsql as $$
declare
  a uuid := 'b66cf468-47f7-51ee-a8f2-994d907440b9';
  t1 uuid; t2 uuid; lote uuid; v_bal numeric;
  q1 text; q2 text; r1 text; r2 text; e1 text := null; e2 text := null; ok_n int := 0; fail_n int := 0;
  v_conn boolean := false;
begin
  select id into t1 from resources where organization_id = a and code = 'Tanque 1';
  select id into t2 from resources where organization_id = a and code = 'Tanque 2';
  select id into lote from lots where organization_id = a and folio = 'G-COMPRA-01';
  v_bal := lot_balance(a, t1, lote);   -- 250 L: cada sesión intenta llevárselo completo

  begin
    perform extensions.dblink_connect('c1', 'dbname=postgres');
    perform extensions.dblink_connect('c2', 'dbname=postgres');
    v_conn := true;
  exception when others then
    return next skip('dblink no pudo abrir dos sesiones: ' || sqlerrm, 2);
    return;
  end;

  -- Cada sesión actúa como Benito (admin de A): las claims van en el mismo
  -- statement para que auth.uid() las vea.
  q1 := format($q$with s as (select set_config('request.jwt.claims', '{"sub":"a88771d6-e323-5b36-991d-c42e5880e507","role":"authenticated"}', false))
                  select transferir('%s', gen_random_uuid(), now(), '%s', '%s', '%s', %s, null, 'conservar')::text from s$q$,
               a, t1, t2, lote, v_bal);
  q2 := replace(q1, 'gen_random_uuid()', 'gen_random_uuid()');

  perform extensions.dblink_send_query('c1', q1);
  perform extensions.dblink_send_query('c2', q2);

  begin
    select x into r1 from extensions.dblink_get_result('c1') as t(x text);
  exception when others then e1 := sqlerrm; end;
  begin
    select x into r2 from extensions.dblink_get_result('c2') as t(x text);
  exception when others then e2 := sqlerrm; end;

  perform extensions.dblink_disconnect('c1');
  perform extensions.dblink_disconnect('c2');

  ok_n   := (e1 is null)::int + (e2 is null)::int;
  fail_n := (e1 like '%SALDO_INSUFICIENTE:%')::int + (e2 like '%SALDO_INSUFICIENTE:%')::int;

  return next is(ok_n, 1, 'concurrencia: exactamente una de las dos transferencias pasa');
  return next is(fail_n, 1, 'concurrencia: la otra falla con SALDO_INSUFICIENTE (' || coalesce(e1, e2, 'sin error') || ')');
end $$;

select * from runtests((select nspname from pg_namespace where oid = pg_my_temp_schema())::name, '^test_');

rollback;
