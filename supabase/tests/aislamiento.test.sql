-- pgTAP · Aislamiento entre empresas (PULZ_MAESTRO.md §11.3) y criterios de
-- aceptación de la Fase 1 (§16).
--
-- Cómo se corre (sin Docker): `supabase test db --linked` conecta al proyecto
-- alojado pero levanta pg_prove en un contenedor local, y Docker está
-- descartado (CLAUDE.md §1). Por eso el test es una función pgTAP y se
-- ejecuta con el runner de la Management API, que solo devuelve el último
-- resultado — y ese es justo `runtests()`, con todas las líneas TAP:
--
--     supabase db query --linked -f supabase/tests/aislamiento.test.sql
--
-- Todo va dentro de una transacción que termina en rollback: no deja rastro.
--
-- Usuarios de la semilla:
--   benito  a88771d6-e323-5b36-991d-c42e5880e507  admin de Cuatro Vientos (A)
--   tomas   e8e03baf-44a8-5af4-8d68-e0f3e04315a9  operador de A
--   dueña B c0ffee00-0000-4000-8000-0000000000b1  admin de Palenque Prueba B
--   nadie   deadbeef-0000-4000-8000-000000000000  sin membresía
--   A = b66cf468-47f7-51ee-a8f2-994d907440b9   B = b0000000-0000-4000-8000-0000000000b0

begin;

-- Filas de la empresa A visibles bajo la RLS del rol actual, sumadas en
-- todas las tablas de negocio y vistas. Debe ser 0 para quien no es de A.
create function pg_temp.rows_of_a() returns bigint language sql as $$
  select
    (select count(*) from catalog_items      where organization_id = 'b66cf468-47f7-51ee-a8f2-994d907440b9') +
    (select count(*) from movement_concepts  where organization_id = 'b66cf468-47f7-51ee-a8f2-994d907440b9') +
    (select count(*) from species            where organization_id = 'b66cf468-47f7-51ee-a8f2-994d907440b9') +
    (select count(*) from predios            where organization_id = 'b66cf468-47f7-51ee-a8f2-994d907440b9') +
    (select count(*) from suppliers          where organization_id = 'b66cf468-47f7-51ee-a8f2-994d907440b9') +
    (select count(*) from supplies           where organization_id = 'b66cf468-47f7-51ee-a8f2-994d907440b9') +
    (select count(*) from resources          where organization_id = 'b66cf468-47f7-51ee-a8f2-994d907440b9') +
    (select count(*) from operations         where organization_id = 'b66cf468-47f7-51ee-a8f2-994d907440b9') +
    (select count(*) from operation_warnings where organization_id = 'b66cf468-47f7-51ee-a8f2-994d907440b9') +
    (select count(*) from lots               where organization_id = 'b66cf468-47f7-51ee-a8f2-994d907440b9') +
    (select count(*) from lot_lineage        where organization_id = 'b66cf468-47f7-51ee-a8f2-994d907440b9') +
    (select count(*) from lot_external_sources where organization_id = 'b66cf468-47f7-51ee-a8f2-994d907440b9') +
    (select count(*) from maguey_receptions  where organization_id = 'b66cf468-47f7-51ee-a8f2-994d907440b9') +
    (select count(*) from liquid_movements   where organization_id = 'b66cf468-47f7-51ee-a8f2-994d907440b9') +
    (select count(*) from attachments        where organization_id = 'b66cf468-47f7-51ee-a8f2-994d907440b9') +
    (select count(*) from roasting_runs      where organization_id = 'b66cf468-47f7-51ee-a8f2-994d907440b9') +
    (select count(*) from roasting_run_inputs where organization_id = 'b66cf468-47f7-51ee-a8f2-994d907440b9') +
    (select count(*) from formulations       where organization_id = 'b66cf468-47f7-51ee-a8f2-994d907440b9') +
    (select count(*) from formulation_inputs where organization_id = 'b66cf468-47f7-51ee-a8f2-994d907440b9') +
    (select count(*) from formulation_supplies where organization_id = 'b66cf468-47f7-51ee-a8f2-994d907440b9') +
    (select count(*) from fermentation_cycles where organization_id = 'b66cf468-47f7-51ee-a8f2-994d907440b9') +
    (select count(*) from fermentation_measurements where organization_id = 'b66cf468-47f7-51ee-a8f2-994d907440b9') +
    (select count(*) from measurement_readings where organization_id = 'b66cf468-47f7-51ee-a8f2-994d907440b9') +
    (select count(*) from distillation_runs  where organization_id = 'b66cf468-47f7-51ee-a8f2-994d907440b9') +
    (select count(*) from distillation_run_inputs where organization_id = 'b66cf468-47f7-51ee-a8f2-994d907440b9') +
    (select count(*) from distillation_cuts  where organization_id = 'b66cf468-47f7-51ee-a8f2-994d907440b9') +
    (select count(*) from organization_members where organization_id = 'b66cf468-47f7-51ee-a8f2-994d907440b9') +
    (select count(*) from organization_settings where organization_id = 'b66cf468-47f7-51ee-a8f2-994d907440b9') +
    (select count(*) from subscriptions      where organization_id = 'b66cf468-47f7-51ee-a8f2-994d907440b9') +
    (select count(*) from resource_lot_balances where organization_id = 'b66cf468-47f7-51ee-a8f2-994d907440b9') +
    (select count(*) from movement_log       where organization_id = 'b66cf468-47f7-51ee-a8f2-994d907440b9');
$$;

-- Simula a un usuario con sesión, como lo haría PostgREST
create function pg_temp.como(p_user uuid) returns void language plpgsql as $$
begin
  execute 'set local role authenticated';
  execute format('set local request.jwt.claims = %L',
                 json_build_object('sub', p_user, 'role', 'authenticated')::text);
end $$;

create function pg_temp.test_aislamiento() returns setof text language plpgsql as $$
begin
  -- 1) benito (admin de A) ve lo suyo y nada de B
  perform pg_temp.como('a88771d6-e323-5b36-991d-c42e5880e507');
  return next is((select count(*) from organizations), 1::bigint, 'benito ve exactamente una empresa');
  return next is((select count(*) from resources), 12::bigint, 'benito ve los 12 recursos de Cuatro Vientos');
  return next is((select count(*) from resources where organization_id = 'b0000000-0000-4000-8000-0000000000b0'), 0::bigint,
                 'benito no ve recursos de la empresa B');
  return next ok((select pg_temp.rows_of_a()) > 0, 'benito sí ve filas de su propia empresa');

  -- 2) dueña de B no lee, no inserta ni referencia nada de A
  perform pg_temp.como('c0ffee00-0000-4000-8000-0000000000b1');
  return next is((select count(*) from organizations), 1::bigint, 'dueña B ve solo su empresa');
  return next is((select pg_temp.rows_of_a()), 0::bigint,
                 'dueña B no ve ninguna fila de A en ninguna tabla de negocio ni vista');
  return next throws_ok(
    $q$insert into resources (organization_id, kind, code, capacity_policy)
       values ('b66cf468-47f7-51ee-a8f2-994d907440b9', 'tina', 'Intrusa', 'flexible')$q$,
    '42501', null, 'dueña B no puede insertar un recurso en A (RLS)');
  return next throws_ok(
    $q$insert into resources (organization_id, kind, code, type_item_id, capacity_policy)
       values ('b0000000-0000-4000-8000-0000000000b0', 'alambique', 'Alambique B1',
               '29da31b1-2580-5943-873c-afc18495a601', 'estricta')$q$,
    null, null, 'dueña B no puede referenciar un catálogo de A (FK compuesta o trigger de tipo)');
  return next lives_ok(
    $q$update organizations set name = 'Hackeada' where id = 'b66cf468-47f7-51ee-a8f2-994d907440b9'$q$,
    'un update sobre A desde B no revienta: la RLS simplemente filtra 0 filas');
  execute 'reset role';
  return next is((select name from organizations where id = 'b66cf468-47f7-51ee-a8f2-994d907440b9'),
                 'Mezcal Cuatro Vientos', 'el nombre de A sigue intacto tras el intento desde B');

  -- 3) sin membresía activa no se ve nada
  perform pg_temp.como('deadbeef-0000-4000-8000-000000000000');
  return next is((select count(*) from organizations), 0::bigint, 'un usuario sin membresía no ve empresas');
  return next is((select pg_temp.rows_of_a()), 0::bigint, 'un usuario sin membresía no ve filas de negocio');

  -- 4) el operador no ejecuta funciones de admin ni escribe infraestructura
  perform pg_temp.como('e8e03baf-44a8-5af4-8d68-e0f3e04315a9');
  return next throws_ok(
    $q$select desbloquear_miembro('b66cf468-47f7-51ee-a8f2-994d907440b9', 'e8e03baf-44a8-5af4-8d68-e0f3e04315a9')$q$,
    'P0001', null, 'un operador no puede desbloquear miembros');
  return next throws_ok(
    $q$insert into resources (organization_id, kind, code, capacity_policy)
       values ('b66cf468-47f7-51ee-a8f2-994d907440b9', 'tina', 'Tina X', 'flexible')$q$,
    '42501', null, 'un operador no puede crear recursos');
  execute 'reset role';

  -- 5) Estructura: criterios de aceptación de §16 Fase 1
  return next is((select count(*) from pg_policies where schemaname = 'public' and cmd = 'ALL'), 0::bigint,
                 'ninguna política for all');
  return next is((select count(*) from information_schema.columns
                   where table_schema = 'public' and data_type in ('json', 'jsonb')), 0::bigint,
                 'ninguna columna json/jsonb en public');
  return next is((select count(*) from pg_tables where schemaname = 'public' and not rowsecurity), 0::bigint,
                 'todas las tablas de public tienen RLS activada');

  -- 6) Saldos esperados de la simulación (§15.1)
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
    'los saldos de resource_lot_balances coinciden con §15.1');
end $$;

-- pg_temp no es un nombre de esquema real para runtests: se resuelve el
-- esquema temporal de esta sesión (pg_temp_NN).
select * from runtests((select nspname from pg_namespace where oid = pg_my_temp_schema())::name, '^test_');

rollback;
