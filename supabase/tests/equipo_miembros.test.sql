-- pgTAP · equipo_miembros (0023): solo el administrador activo de la empresa
-- ve a su gente; bloqueo y vigencia del enlace derivados, nunca el token.
--     supabase db query --linked -f supabase/tests/equipo_miembros.test.sql

begin;

create function pg_temp.como(u uuid) returns void language plpgsql as $$
begin
  execute 'set local role authenticated';
  execute format('set local request.jwt.claims = %L', json_build_object('sub', u, 'role', 'authenticated')::text);
end $$;

create function pg_temp.test_equipo_miembros() returns setof text language plpgsql as $$
declare a uuid := 'b66cf468-47f7-51ee-a8f2-994d907440b9'; b uuid := 'b0000000-0000-4000-8000-0000000000b0';
begin
  -- operador de A: no
  perform pg_temp.como('e8e03baf-44a8-5af4-8d68-e0f3e04315a9');
  return next throws_like(format($q$select * from equipo_miembros('%s')$q$, a), 'NO_PERMITIDO:%',
                          'un operador no ve el equipo');
  -- productora de A: no
  perform pg_temp.como('417489a3-9fa1-5914-bbc9-92d5334e9734');
  return next throws_like(format($q$select * from equipo_miembros('%s')$q$, a), 'NO_PERMITIDO:%',
                          'una productora no ve el equipo');
  -- admin de B pidiendo A: no
  perform pg_temp.como('c0ffee00-0000-4000-8000-0000000000b1');
  return next throws_like(format($q$select * from equipo_miembros('%s')$q$, a), 'NO_PERMITIDO:%',
                          'el admin de otra empresa no ve el equipo de A');
  return next is((select count(*) from equipo_miembros(b)), 1::bigint, 'el admin de B ve a su única persona');

  -- admin de A: sí, con bloqueo y vigencia derivados
  perform pg_temp.como('a88771d6-e323-5b36-991d-c42e5880e507');
  return next is((select count(*) from equipo_miembros(a)), 3::bigint, 'Benito ve a las 3 personas de Cuatro Vientos');
  return next is((select full_name from equipo_miembros(a) limit 1), 'Benito Cruz', 'el titular (admin) va primero');
  return next is((select must_change_password from equipo_miembros(a) where username = 'tomas.h'), true,
                 'Tomás debe cambiar la contraseña dictada');
  return next is((select locked_until from equipo_miembros(a) where username = 'tomas.h'), null::timestamptz,
                 'Tomás no está bloqueado (3 fallos, sin locked_until)');
  return next is((select invitation_used from equipo_miembros(a) where username = 'tomas.h'), false,
                 'la invitación de Tomás no se ha usado');
  return next ok((select invitation_expires_at from equipo_miembros(a) where username = 'tomas.h') is not null,
                 'la vigencia de la invitación se expone (el token nunca)');
  return next is((select username from equipo_miembros(a) where role = 'admin'), null::text,
                 'el titular no tiene usuario simple');

  -- vencida: el admin sigue viendo (solo lectura, §7.4)
  execute 'reset role';
  update subscriptions set status = 'vencida' where organization_id = a;
  perform pg_temp.como('a88771d6-e323-5b36-991d-c42e5880e507');
  return next is((select count(*) from equipo_miembros(a)), 3::bigint, 'con suscripción vencida el admin sigue viendo el equipo');
  execute 'reset role';
end $$;

select * from runtests((select nspname from pg_namespace where oid = pg_my_temp_schema())::name, '^test_');

rollback;
