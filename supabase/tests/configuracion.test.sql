-- pgTAP · Configuración (Fase 4): quién escribe qué según §11.1 y la RLS
-- real (0013); nunca se borra (active = false); el cambio de slug deja
-- historial y el viejo redirige; la carga inicial crea lote y saldo; el
-- bucket 'branding' existe con sus políticas (0024).
--     supabase db query --linked -f supabase/tests/configuracion.test.sql

begin;

create function pg_temp.como(u uuid) returns void language plpgsql as $$
begin
  execute 'set local role authenticated';
  execute format('set local request.jwt.claims = %L', json_build_object('sub', u, 'role', 'authenticated')::text);
end $$;
create function pg_temp.superuser() returns void language plpgsql as $$
begin execute 'reset role'; end $$;

create function pg_temp.test_configuracion() returns setof text language plpgsql as $$
declare
  a uuid := 'b66cf468-47f7-51ee-a8f2-994d907440b9';      -- Cuatro Vientos
  b uuid := 'b0000000-0000-4000-8000-0000000000b0';      -- Prueba B
  admin_a uuid := 'a88771d6-e323-5b36-991d-c42e5880e507';
  prod_a  uuid := '417489a3-9fa1-5914-bbc9-92d5334e9734';
  oper_a  uuid := 'e8e03baf-44a8-5af4-8d68-e0f3e04315a9';
  admin_b uuid := 'c0ffee00-0000-4000-8000-0000000000b1';
  tipo_tanque uuid; tipo_tina uuid; v_tanque uuid; v_lot uuid; n int;
begin
  select id into tipo_tanque from catalog_items where organization_id = a and template_id = '51470f4b-702a-5bd5-b38d-90d2a82f9648';
  select id into tipo_tina   from catalog_items where organization_id = a and template_id = 'b16c7c9d-baa4-59f0-abdb-cc7638918cd2';

  -- ── Recursos: solo admin ─────────────────────────────────────────────
  perform pg_temp.como(admin_a);
  insert into resources (organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy)
  values (a, 'tanque', 'Tanque nuevo', tipo_tanque, 500, 'L', 'flexible') returning id into v_tanque;
  return next ok(v_tanque is not null, 'el admin crea un tanque');
  return next throws_like(
    format($q$insert into resources (organization_id, kind, code, type_item_id) values ('%s', 'tanque', 'Mal tipo', '%s')$q$, a, tipo_tina),
    '%no es de tipo tipo_tanque%', 'el tipo del recurso debe ser del catálogo de su kind');
  return next throws_like(
    format($q$insert into resources (organization_id, kind, code, type_item_id) values ('%s', 'colector', 'Sin clase', null)$q$, a),
    '%check%', 'un colector necesita clase de líquido');

  perform pg_temp.como(prod_a);
  return next throws_like(
    format($q$insert into resources (organization_id, kind, code) values ('%s', 'tanque', 'Del productor')$q$, a),
    '%row-level security%', 'la productora no crea recursos');
  update resources set code = 'Renombrado' where id = v_tanque;
  get diagnostics n = row_count;
  return next is(n, 0, 'la productora no edita recursos (0 filas)');

  perform pg_temp.como(admin_b);
  update resources set active = false where id = v_tanque;
  get diagnostics n = row_count;
  return next is(n, 0, 'el admin de B no toca recursos de A');

  -- ── Catálogos: admin edita, nadie borra ──────────────────────────────
  perform pg_temp.como(admin_a);
  update catalog_items set active = false where organization_id = a and id = tipo_tina;
  get diagnostics n = row_count;
  return next is(n, 1, 'el admin oculta un tipo de catálogo (active = false)');
  return next throws_ok(
    format($q$delete from catalog_items where organization_id = '%s' and id = '%s'$q$, a, tipo_tina),
    '42501', null, 'nadie borra elementos de catálogo (authenticated no tiene DELETE)');
  update catalog_items set active = true where organization_id = a and id = tipo_tina;
  insert into species (organization_id, common_name) values (a, 'Tobalá silvestre');
  return next is((select count(*) from species where organization_id = a and common_name = 'Tobalá silvestre'), 1::bigint,
                 'el admin agrega una especie propia');

  perform pg_temp.como(prod_a);
  return next throws_like(
    format($q$insert into species (organization_id, common_name) values ('%s', 'Otra')$q$, a),
    '%row-level security%', 'la productora no edita catálogos');

  -- ── Predios, proveedores, insumos: admin y productor; operador no ─────
  perform pg_temp.como(prod_a);
  insert into predios (organization_id, name, municipality) values (a, 'El Llano', 'Santiago Matatlán');
  return next is((select count(*) from predios where organization_id = a and name = 'El Llano'), 1::bigint,
                 'la productora da de alta un predio');
  perform pg_temp.como(oper_a);
  return next throws_like(
    format($q$insert into predios (organization_id, name) values ('%s', 'Del operador')$q$, a),
    '%row-level security%', 'el operador no da de alta predios');

  -- ── Ajustes: solo admin ──────────────────────────────────────────────
  perform pg_temp.como(oper_a);
  update organization_settings set fermentation_expected_days = 9 where organization_id = a;
  get diagnostics n = row_count;
  return next is(n, 0, 'el operador no cambia ajustes');
  perform pg_temp.como(admin_a);
  update organization_settings set fermentation_expected_days = 9, abv_warn_min = 38 where organization_id = a;
  get diagnostics n = row_count;
  return next is(n, 1, 'el admin cambia ajustes');
  return next throws_like(
    format($q$update organization_settings set abv_warn_min = 60 where organization_id = '%s'$q$, a),
    '%check%', 'los rangos de aviso se validan (min < max)');

  -- ── Portal y marca: admin; el slug viejo redirige ────────────────────
  perform pg_temp.como(prod_a);
  update organizations set welcome_message = 'x' where id = a;
  get diagnostics n = row_count;
  return next is(n, 0, 'la productora no cambia la marca');
  perform pg_temp.como(admin_a);
  update organizations set brand_color = '#173F87', welcome_message = 'Bienvenidos', logo_path = a::text || '/logo.png' where id = a;
  get diagnostics n = row_count;
  return next is(n, 1, 'el admin cambia color, mensaje y logo');
  return next throws_like(
    format($q$update organizations set brand_color = 'rojo' where id = '%s'$q$, a),
    '%check%', 'el color debe ser #RRGGBB');
  update organizations set slug = 'cuatro-vientos-mezcal' where id = a;
  return next is((select organization_id from organization_slug_history where slug = 'cuatro-vientos'), a,
                 'el slug viejo queda en el historial');
  return next is((select redirect_to from portal_branding('cuatro-vientos')), 'cuatro-vientos-mezcal',
                 'el portal del slug viejo redirige al nuevo');
  return next is((select logo_path from portal_branding('cuatro-vientos-mezcal')), a::text || '/logo.png',
                 'el portal publica la ruta del logo');
  perform pg_temp.como(admin_b);
  return next throws_like(
    format($q$update organizations set slug = 'cuatro-vientos' where id = '%s'$q$, b),
    '%', 'nadie más puede tomar un slug retirado');

  -- ── Primer arranque: carga inicial en tanque y tina ──────────────────
  perform pg_temp.como(admin_a);
  v_lot := registrar_entrada(a, '11111111-1111-4111-8111-111111111111', now(), 'granel', v_tanque, 300, 47);
  return next is(registrar_entrada(a, '11111111-1111-4111-8111-111111111111', now(), 'granel', v_tanque, 300, 47), v_lot,
                 'reintentar con la misma idempotency_key no duplica');
  perform pg_temp.superuser();   -- resource_balance es interna (sin execute para authenticated)
  return next is(resource_balance(a, v_tanque), 300::numeric, 'la carga inicial deja 300 L en el tanque nuevo');
  return next is((select origin from lots where id = v_lot), 'carga_inicial'::lot_origin, 'el lote nace como carga inicial');
  return next is((select count(*) from lots where organization_id = a and operation_id in
                    (select id from operations where organization_id = a and idempotency_key = '11111111-1111-4111-8111-111111111111')),
                 1::bigint, 'un solo lote para esa idempotency_key');
  perform pg_temp.como(admin_a);
  return next throws_like(
    format($q$select registrar_entrada('%s', gen_random_uuid(), now(), 'fermentado', '%s', 100)$q$, a, v_tanque),
    'NO_PERMITIDO: un fermentado entra en una tina', 'un fermentado no entra en un tanque');
  perform pg_temp.como(oper_a);
  return next throws_like(
    format($q$select registrar_entrada('%s', gen_random_uuid(), now(), 'granel', '%s', 10)$q$, a, v_tanque),
    'NO_PERMITIDO:%', 'el operador no registra cargas iniciales');

  -- ── Storage: bucket y políticas (0024) ───────────────────────────────
  perform pg_temp.superuser();
  return next is((select public from storage.buckets where id = 'branding'), true, 'el bucket branding es público');
  return next is((select array_length(allowed_mime_types, 1) from storage.buckets where id = 'branding'), 3, 'solo png/jpeg/webp');
  return next is((select count(*) from pg_policies where schemaname = 'storage' and tablename = 'objects' and policyname like 'branding_%'), 4::bigint,
                 'cuatro políticas branding_* en storage.objects');
  return next is(branding_org_of(a::text || '/logo.png'), a, 'branding_org_of lee la carpeta raíz');
  return next is(branding_org_of('logo.png'), null::uuid, 'sin carpeta no hay empresa');
end $$;

select * from runtests((select nspname from pg_namespace where oid = pg_my_temp_schema())::name, '^test_');

rollback;
