-- pgTAP · Portal por empresa (PULZ_MAESTRO.md §7.3–§7.5): lo que ve alguien
-- sin sesión. portal_branding es lo único público (anon).
--     supabase db query --linked -f supabase/tests/portal.test.sql

begin;

create function pg_temp.test_portal() returns setof text language plpgsql as $$
declare a uuid := 'b66cf468-47f7-51ee-a8f2-994d907440b9'; b uuid := 'b0000000-0000-4000-8000-0000000000b0';
begin
  -- Como anon (sin sesión), que es como llega el navegador y la Pages Function
  execute 'set local role anon';

  return next is((select name from portal_branding('cuatro-vientos')), 'Mezcal Cuatro Vientos',
                 'portal_branding devuelve la marca por slug');
  return next is((select read_only from portal_branding('cuatro-vientos')), false,
                 'suscripción en prueba → abierto');
  return next is((select redirect_to from portal_branding('mezcal-cuatro-vientos')), 'cuatro-vientos',
                 'el slug viejo redirige al actual (historial de slugs)');
  return next is((select name from portal_branding('CUATRO-VIENTOS')), 'Mezcal Cuatro Vientos',
                 'el slug no distingue mayúsculas');
  return next is((select count(*) from portal_branding('no-existe')), 0::bigint,
                 'empresa inexistente: ninguna fila');
  -- anon ni siquiera tiene GRANT sobre las tablas de negocio (0013): 42501
  return next throws_ok($q$select count(*) from catalog_items$q$, '42501',
                 null, 'anon no lee nada de negocio por PostgREST (sin grant, no solo RLS)');
  return next throws_ok($q$select is_member('b66cf468-47f7-51ee-a8f2-994d907440b9')$q$, '42501',
                 null, 'anon no puede ejecutar is_member (revocado)');

  execute 'reset role';
  -- vencida → sigue abierto pero en solo lectura; cancelada → como inexistente
  update subscriptions set status = 'vencida' where organization_id = b;
  execute 'set local role anon';
  return next is((select read_only from portal_branding('prueba-b')), true, 'vencida → read_only');
  execute 'reset role';
  update subscriptions set status = 'cancelada' where organization_id = b;
  execute 'set local role anon';
  return next is((select count(*) from portal_branding('prueba-b')), 0::bigint,
                 'cancelada → ninguna fila, idéntico a inexistente (§7.4)');
  execute 'reset role';

  -- has_role rechaza escrituras con suscripción vencida (§11.2)
  update subscriptions set status = 'vencida' where organization_id = a;
  execute 'set local role authenticated';
  execute $q$set local request.jwt.claims = '{"sub":"a88771d6-e323-5b36-991d-c42e5880e507","role":"authenticated"}'$q$;
  return next is((select has_role(a, array['admin']::member_role[])), false,
                 'vencida: has_role rechaza al admin (solo lectura)');
  return next is((select is_member(a)), true, 'vencida: is_member sigue en true (la lectura sigue)');
  execute 'reset role';
end $$;

select * from runtests((select nspname from pg_namespace where oid = pg_my_temp_schema())::name, '^test_');

rollback;
