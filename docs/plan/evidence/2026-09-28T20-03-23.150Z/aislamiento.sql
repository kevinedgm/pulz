begin;
create or replace view lot_declared_abv with (security_invoker = true) as
select distinct on (x.organization_id, x.lot_id)
       x.organization_id, x.lot_id, x.abv, x.occurred_at, x.recorded_by
from (
  select o.organization_id, o.result_lot_id as lot_id, o.result_abv as abv,
         o.occurred_at, o.recorded_by, o.recorded_at, o.id as operation_id, o.id as source_id
    from operations o where o.result_abv is not null and o.result_lot_id is not null
  union all
  select m.organization_id, m.lot_id, m.abv, o.occurred_at, o.recorded_by,
         o.recorded_at, o.id as operation_id, m.id as source_id
    from liquid_movements m join operations o on o.id = m.operation_id
   where m.abv is not null and m.movement_type in ('entrada', 'corte')
     -- El grado del aporte no reemplaza el resultado declarado para ese
     -- mismo lote/operación (unión: aporte 47 %, resultado 44.9 %).
     and (o.result_lot_id is distinct from m.lot_id or o.result_abv is null)
) x
order by x.organization_id, x.lot_id, x.occurred_at desc,
         x.recorded_at desc, x.operation_id desc, x.source_id desc;
set local statement_timeout = '60s';
-- PULZ · Semilla de desarrollo: dos empresas.
--   A) "Mezcal Cuatro Vientos": la simulación de docs/referencia/
--      pulz_simulacion_semilla.sql, construida LLAMANDO A LAS RPC (Fase 2),
--      no con inserts al ledger. Debe dar los saldos de PULZ_MAESTRO.md §15.1.
--   B) "Palenque Prueba B": empresa mínima para probar aislamiento (§11.3).
-- Solo la corre `supabase db reset --linked`. Todo lo que no esté aquí se
-- pierde en el siguiente reset (docs/DECISIONES.md).
--
-- Lo que es configuración (usuarios, planes, empresas, plantillas,
-- recursos) va con insert directo. Lo que es producción (lotes, ledger,
-- etapas, linaje) va por RPC, con el usuario que lo registró en la
-- simulación, salvo donde §11.1 no se lo permite (docs/DECISIONES.md).


-- ---------------------------------------------------------------------
-- auth.users (mínimo). Tokens como '' y no NULL (§17). Contraseñas de
-- desarrollo (bcrypt vía pgcrypto, el formato que verifica GoTrue) para
-- poder probar el acceso de la Fase 3; este proyecto se resetea, no son
-- secretos:  benito → 'benito-2026' · aurelia → 'aurelia-2026' ·
-- tomas.h → 'tomas-2026' · dueña B → 'qa-fa56ce40c260-prueba-b-2026' · admin → 'pulz-2026'
-- ---------------------------------------------------------------------
insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
                        raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
                        confirmation_token, recovery_token, email_change_token_new, email_change) values
  ('00000000-0000-0000-0000-000000000000', '48b1a7f6-6f1e-427d-89e5-b86d1d31e69b', 'authenticated', 'authenticated', 'qa-fa56ce40c260-tu@pulz.mx',
   extensions.crypt('pulz-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '17079ce3-e3e7-4f9b-8a5b-a6b7fe44e7e7', 'authenticated', 'authenticated', 'qa-fa56ce40c260-benito@cuatrovientos.mx',
   extensions.crypt('benito-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', 'a15ebe3e-3043-4e50-8ded-35ce75aba035', 'authenticated', 'authenticated', 'qa-fa56ce40c260-aurelia@1c699a8a-2163-4f62-a230-8ae3f6c68b83.usuarios.pulz.mx',
   extensions.crypt('aurelia-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '53f4d72a-798d-424d-927b-2e64609ccd66', 'authenticated', 'authenticated', 'qa-fa56ce40c260-tomas.h@1c699a8a-2163-4f62-a230-8ae3f6c68b83.usuarios.pulz.mx',
   extensions.crypt('tomas-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '9dbd576d-f71a-4a52-abf9-bcb98c9039a6', 'authenticated', 'authenticated', 'qa-fa56ce40c260-duena@pruebab.mx',
   extensions.crypt('qa-fa56ce40c260-prueba-b-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '');

insert into profiles (id, full_name) values
  ('48b1a7f6-6f1e-427d-89e5-b86d1d31e69b', 'Admin PULZ'),
  ('17079ce3-e3e7-4f9b-8a5b-a6b7fe44e7e7', 'Benito Cruz'),
  ('a15ebe3e-3043-4e50-8ded-35ce75aba035', 'Aurelia Santiago'),
  ('53f4d72a-798d-424d-927b-2e64609ccd66', 'Tomás Hernández'),
  ('9dbd576d-f71a-4a52-abf9-bcb98c9039a6', 'Dueña Prueba B');

insert into platform_admins (user_id) values ('48b1a7f6-6f1e-427d-89e5-b86d1d31e69b');

-- Planes (§14, §18 #2 y #3)
-- Fixture: reutiliza plans canónica, sin modificarla.
-- Fixture: reutiliza plan_limits canónica, sin modificarla.
-- Fixture: reutiliza plan_features canónica, sin modificarla.

-- Empresas
insert into organizations (id, name, slug, state, brand_color, logo_path, welcome_message, created_by) values
  ('1c699a8a-2163-4f62-a230-8ae3f6c68b83', 'Mezcal Cuatro Vientos', 'qa-fa56ce40c260-cuatro-vientos', 'Oaxaca', '#7A3E1D', null, 'Registro de producción del palenque', '17079ce3-e3e7-4f9b-8a5b-a6b7fe44e7e7'),
  ('01c8f7ce-1629-41d7-86d5-f7267f75f855', 'Palenque Prueba B', 'qa-fa56ce40c260-prueba-b', 'Oaxaca', '#173F87', null, 'Empresa de prueba', '9dbd576d-f71a-4a52-abf9-bcb98c9039a6');
insert into organization_slug_history (slug, organization_id, retired_at, retired_by) values
  ('qa-fa56ce40c260-mezcal-cuatro-vientos', '1c699a8a-2163-4f62-a230-8ae3f6c68b83', '2026-09-02 09:00:00-06', '17079ce3-e3e7-4f9b-8a5b-a6b7fe44e7e7');
insert into organization_members (organization_id, user_id, role, status, username, must_change_password) values
  ('1c699a8a-2163-4f62-a230-8ae3f6c68b83', '17079ce3-e3e7-4f9b-8a5b-a6b7fe44e7e7', 'admin', 'activo', null, false),
  ('1c699a8a-2163-4f62-a230-8ae3f6c68b83', 'a15ebe3e-3043-4e50-8ded-35ce75aba035', 'productor', 'activo', 'aurelia', false),
  ('1c699a8a-2163-4f62-a230-8ae3f6c68b83', '53f4d72a-798d-424d-927b-2e64609ccd66', 'operador', 'activo', 'tomas.h', true),
  ('01c8f7ce-1629-41d7-86d5-f7267f75f855', '9dbd576d-f71a-4a52-abf9-bcb98c9039a6', 'admin', 'activo', null, false);
insert into member_invitations (id, organization_id, user_id, token_hash, expires_at, used_at, created_by) values
  ('61813a2c-947c-495f-9c8b-5fb01b35c463', '1c699a8a-2163-4f62-a230-8ae3f6c68b83', '53f4d72a-798d-424d-927b-2e64609ccd66', 'qa-fa56ce40c260:SIMULADO', '2026-09-05 10:00:00-06', null, '17079ce3-e3e7-4f9b-8a5b-a6b7fe44e7e7');
insert into login_throttle (user_id, failed_count, last_failed_at, locked_until) values
  ('53f4d72a-798d-424d-927b-2e64609ccd66', 3, '2026-09-03 07:12:00-06', null);
insert into organization_settings (organization_id, record_puntas, measurement_mode, warn_mixed_second_pass, fermentation_expected_days, measurement_reminder_hour, default_folio_decision) values
  ('1c699a8a-2163-4f62-a230-8ae3f6c68b83', false, 'minimo', true, 7, 9, 'conservar'),
  ('01c8f7ce-1629-41d7-86d5-f7267f75f855', false, 'minimo', true, 7, 9, 'conservar');
insert into subscriptions (organization_id, plan_id, status, current_period_end) values
  ('1c699a8a-2163-4f62-a230-8ae3f6c68b83', 'edd15bcf-ad82-5684-a2e7-d85db401885b', 'prueba', '2026-10-15 00:00:00-06'),
  ('01c8f7ce-1629-41d7-86d5-f7267f75f855', 'ee35d6fd-b4d6-56d6-b7b4-61cb81932b21', 'gratis', null);

-- ---------------------------------------------------------------------
-- Plantillas de plataforma (§10.2.1)
-- ---------------------------------------------------------------------
-- Fixture: reutiliza catalog_item_templates canónica, sin modificarla.
-- Fixture: reutiliza movement_concept_templates canónica, sin modificarla.
-- Fixture: reutiliza species_templates canónica, sin modificarla.

select seed_organization_catalogs('1c699a8a-2163-4f62-a230-8ae3f6c68b83');
select seed_organization_catalogs('01c8f7ce-1629-41d7-86d5-f7267f75f855');

-- Lo propio de Cuatro Vientos y lo que oculta (§10.2.4)
insert into catalog_items (id, organization_id, template_id, catalog, name, sort_order, created_by) values
  ('da5b3cc3-45a0-45dc-8ea0-0b8014c69c5b', '1c699a8a-2163-4f62-a230-8ae3f6c68b83', null, 'tipo_alambique', 'Refrescadera de cobre', 100, '17079ce3-e3e7-4f9b-8a5b-a6b7fe44e7e7');
insert into movement_concepts (id, organization_id, template_id, direction, name, source_lot, creates_lot, asks_result, asks_counterparty, sort_order, created_by) values
  ('09d2c4ba-941f-4465-9857-d83777e9da21', '1c699a8a-2163-4f62-a230-8ae3f6c68b83', null, 'salida', 'Regalo a cliente', 'no_aplica', false, false, true, 100, '17079ce3-e3e7-4f9b-8a5b-a6b7fe44e7e7');
update catalog_items set active = false
 where organization_id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83'
   and template_id in ('5c985133-23d9-50fa-a252-6ff6b5b74134', 'b1fce67a-21bf-50a7-9344-fdf29eb5331e');
update movement_concepts set active = false
 where organization_id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83'
   and template_id = '8b7f6579-99ef-549e-b427-b1d4d8bea9da';

-- ---------------------------------------------------------------------
-- Ayudas de la semilla (temporales; mueren con la sesión). security definer
-- para que resuelvan ids aunque el rol activo sea 'authenticated'.
-- ---------------------------------------------------------------------
create function pg_temp.seed_a() returns uuid language sql immutable as $$ select '1c699a8a-2163-4f62-a230-8ae3f6c68b83'::uuid $$;
create function pg_temp.seed_cat(t uuid) returns uuid language sql stable security definer as $$
  select id from catalog_items where organization_id = pg_temp.seed_a() and template_id = t $$;
create function pg_temp.seed_con(t uuid) returns uuid language sql stable security definer as $$
  select id from movement_concepts where organization_id = pg_temp.seed_a() and template_id = t $$;
create function pg_temp.seed_esp(t uuid) returns uuid language sql stable security definer as $$
  select id from species where organization_id = pg_temp.seed_a() and template_id = t $$;
create function pg_temp.seed_res(c text) returns uuid language sql stable security definer as $$
  select id from resources where organization_id = pg_temp.seed_a() and code = c $$;
create function pg_temp.seed_lot(f text) returns uuid language sql stable security definer as $$
  select id from lots where organization_id = pg_temp.seed_a() and folio = f $$;
create function pg_temp.seed_cyc(tina text) returns uuid language sql stable security definer as $$
  select c.id from fermentation_cycles c join resources r on r.id = c.tina_id
   where c.organization_id = pg_temp.seed_a() and r.code = tina and c.status <> 'cerrado' $$;
create function pg_temp.seed_hor(f text) returns uuid language sql stable security definer as $$
  select id from roasting_runs where organization_id = pg_temp.seed_a() and folio = f $$;
create function pg_temp.seed_run(f text) returns uuid language sql stable security definer as $$
  select id from distillation_runs where organization_id = pg_temp.seed_a() and folio = f $$;
-- Simula la sesión de un usuario, como lo haría PostgREST
create function pg_temp.seed_como(u uuid) returns void language plpgsql as $$
begin
  execute 'set local role authenticated';
  execute format('set local request.jwt.claims = %L', json_build_object('sub', u, 'role', 'authenticated')::text);
end $$;

-- ---------------------------------------------------------------------
-- Cuatro Vientos: predios, proveedores, insumos, recursos (configuración)
-- ---------------------------------------------------------------------
insert into predios (id, organization_id, name, municipality, owner_name) values
  ('18e742b4-f32c-4c12-8318-ff833d18ddad', pg_temp.seed_a(), 'Loma del Toro', 'Santiago Matatlán', 'Familia Cruz');
insert into suppliers (id, organization_id, name, type_item_id) values
  ('f586602a-973a-4258-b612-cdf3820bb48d', pg_temp.seed_a(), 'Magueyes Don Pedro', pg_temp.seed_cat('640b537d-bf52-5c4b-b407-a5f4fb7c5800')),
  ('8d191c97-0e8a-413c-85e6-55ea8a8bc72e', pg_temp.seed_a(), 'Destilados Hermanos Luna', pg_temp.seed_cat('bb234638-3c78-56cd-9f41-2fb38182f181'));
insert into supplies (id, organization_id, name, unit_item_id) values
  ('d380ff6e-7ba3-4725-81d8-47c3b7a93f90', pg_temp.seed_a(), 'Pulque como inóculo', pg_temp.seed_cat('bc6f104d-2841-5b36-b492-76b36becb172'));
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy, liquid_class) values
  ('22cbd4a7-59da-496e-a633-01a74c927de1', pg_temp.seed_a(), 'horno', 'Horno 1', pg_temp.seed_cat('d53ba2da-cada-5215-804a-ff304d569f97'), 10000, 'kg', 'libre', null),
  ('4c72b6bb-dd73-4a98-95a3-c43286e300dd', pg_temp.seed_a(), 'molino', 'Tahona', pg_temp.seed_cat('60285283-d000-52f0-95da-d2b2e6d70fa1'), null, 'kg', 'libre', null),
  ('a7b219d4-8053-46a8-8857-a691b7153069', pg_temp.seed_a(), 'tina', 'Tina 1', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('0c57ceea-d311-4c6d-ab69-e6a1c38abd83', pg_temp.seed_a(), 'tina', 'Tina 2', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('35c34cd4-f9b1-4a5f-a360-a484e54d2a02', pg_temp.seed_a(), 'tina', 'Tina 3', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('7ac5a48e-c1d1-4c1f-93f7-32c1499be21f', pg_temp.seed_a(), 'alambique', 'Alambique 1', pg_temp.seed_cat('af73010e-53f2-5769-b3b1-6cda154e665e'), 300, 'L', 'estricta', null),
  ('1a7d9ab3-44fc-4c16-816b-69c3344258b2', pg_temp.seed_a(), 'alambique', 'Alambique 2', 'da5b3cc3-45a0-45dc-8ea0-0b8014c69c5b', 250, 'L', 'estricta', null),
  ('accbbd8d-ac02-4fa4-9faf-14fe9e57824d', pg_temp.seed_a(), 'colector', 'Colector mezcal', pg_temp.seed_cat('2cd7e70b-6246-543e-8f67-23743fefdf95'), 60, 'L', 'flexible', 'mezcal'),
  ('d354694e-f505-4504-b824-5133108de045', pg_temp.seed_a(), 'colector', 'Colector ordinario', pg_temp.seed_cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'ordinario'),
  ('9e237ba6-a11b-4247-a44a-7f40f296e25c', pg_temp.seed_a(), 'colector', 'Colector colas', pg_temp.seed_cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'colas'),
  ('ff66815a-3a7b-4caa-9cfc-6675b9b6b831', pg_temp.seed_a(), 'tanque', 'Tanque 1', pg_temp.seed_cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1000, 'L', 'flexible', null),
  ('0ec3009a-2669-47fb-b2fb-6480115dc145', pg_temp.seed_a(), 'tanque', 'Tanque 2', pg_temp.seed_cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1500, 'L', 'flexible', null);

-- Palenque Prueba B: lo mínimo para probar aislamiento
insert into predios (id, organization_id, name, municipality) values
  ('dec023e0-7a4d-4113-b14b-c39c0b62182e', '01c8f7ce-1629-41d7-86d5-f7267f75f855', 'Predio B', 'Ejutla');
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy) values
  ('b0d96bdd-920b-4885-b56f-ff52d72c236b', '01c8f7ce-1629-41d7-86d5-f7267f75f855', 'tina', 'Tina B1',
   (select id from catalog_items where organization_id = '01c8f7ce-1629-41d7-86d5-f7267f75f855' and template_id = 'b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1000, 'L', 'flexible');

-- =====================================================================
-- Cuatro Vientos: la producción, POR RPC, en orden cronológico
-- =====================================================================

-- 2026-09-01 · Benito: lo que ya había en el Tanque 2 (carga inicial)
select pg_temp.seed_como('17079ce3-e3e7-4f9b-8a5b-a6b7fe44e7e7');
select registrar_entrada(pg_temp.seed_a(), '86fcbd2f-5860-4bf5-8a24-41327717a560', '2026-09-01 10:15:00-06',
  'granel', pg_temp.seed_res('Tanque 2'), 600, 44.2, 'mezcal', 'carga_inicial',
  p_concepto => pg_temp.seed_con('255e79f1-12b3-5969-8453-e40623275559'),
  p_nota => 'Lo que ya había en el tanque al empezar', p_folio => 'G-INI-01');

-- 2026-09-01 · Aurelia: la Tina 3 ya fermentaba
select pg_temp.seed_como('a15ebe3e-3043-4e50-8ded-35ce75aba035');
select registrar_entrada(pg_temp.seed_a(), 'e7863b10-95ef-4b44-87af-aab03540557c', '2026-09-01 10:40:00-06',
  'fermentado', pg_temp.seed_res('Tina 3'), 1300, null, null, 'carga_inicial',
  p_nota => 'Tina que ya fermentaba', p_folio => 'FER-T3-INI');

-- 2026-09-02 · Aurelia: recepción de maguey
select registrar_recepcion_maguey(pg_temp.seed_a(), '67212dd4-6c9e-4bde-b756-16997b845ef8', '2026-09-02 07:30:00-06',
  8000, pg_temp.seed_esp('67a96efd-2c72-528e-8682-d144fe1f802c'), '18e742b4-f32c-4c12-8318-ff833d18ddad',
  'f586602a-973a-4258-b612-cdf3820bb48d', 132, 'Piñas de 8 años, buen tamaño', 'MAG-001');

-- 2026-09-02 · Horneado (la simulación lo abría Tomás; §11.1 lo reserva a
-- admin/productor, así que lo abre Aurelia — docs/DECISIONES.md)
select abrir_horneado(pg_temp.seed_a(), '64d65718-701f-4f02-aade-ac77899c45c2', '2026-09-02 12:00:00-06',
  pg_temp.seed_res('Horno 1'), array[pg_temp.seed_lot('MAG-001')], array[8000::numeric], p_folio => 'HOR-001');
-- 2026-09-06 · Aurelia cierra: 6,200 kg de agave cocido
select cerrar_horneado(pg_temp.seed_a(), 'fd450854-3101-4fc6-bcad-aaedc4037e2d', '2026-09-06 08:00:00-06',
  pg_temp.seed_hor('HOR-001'), 6200, 'Leña de encino', p_folio => 'AC-001');

-- 2026-09-07 · Aurelia: formulación repartida a Tina 1 y Tina 2
select registrar_formulacion(pg_temp.seed_a(), '6719a17a-6f1c-4272-a545-ff4d654ccba1', '2026-09-07 09:00:00-06',
  pg_temp.seed_res('Tahona'), array[pg_temp.seed_lot('AC-001')], array[6200::numeric], 1900,
  array[pg_temp.seed_res('Tina 1'), pg_temp.seed_res('Tina 2')], array[1400::numeric, 1400::numeric],
  array['d380ff6e-7ba3-4725-81d8-47c3b7a93f90'::uuid], array[20::numeric],
  'Tahona con mula', null, 'F-001', array['FER-T1-001', 'FER-T2-001']);

-- Mediciones diarias (escala de actividad 1–6, §18 #1; la simulación traía 7 y 8)
-- Tina 1
select pg_temp.seed_como('53f4d72a-798d-424d-927b-2e64609ccd66');
select registrar_medicion(pg_temp.seed_a(), '64c3bb00-0be7-4482-8912-b56332b87d4d', '2026-09-08 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 1, 'minimo', 4,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.5,12.0]::numeric[]);
select pg_temp.seed_como('a15ebe3e-3043-4e50-8ded-35ce75aba035');
select registrar_medicion(pg_temp.seed_a(), '5ed44ea5-8782-41eb-87f0-d32b5d418c96', '2026-09-09 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.0,9.5]::numeric[]);
select pg_temp.seed_como('53f4d72a-798d-424d-927b-2e64609ccd66');
select registrar_medicion(pg_temp.seed_a(), 'e9b227d2-06db-418d-9cc7-fd6199566db3', '2026-09-10 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.5,6.0]::numeric[]);
select pg_temp.seed_como('a15ebe3e-3043-4e50-8ded-35ce75aba035');
select registrar_medicion(pg_temp.seed_a(), '35e3a0d0-0f69-491b-b614-2e05a8af77ed', '2026-09-11 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 4, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.5,3.5]::numeric[]);
select pg_temp.seed_como('53f4d72a-798d-424d-927b-2e64609ccd66');
select registrar_medicion(pg_temp.seed_a(), '46b182bf-cad5-4ae6-a318-e4abffbfa608', '2026-09-12 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 5, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.0,1.5]::numeric[]);
-- Tina 2
select registrar_medicion(pg_temp.seed_a(), 'd7d59cd4-e7cb-4be7-93fb-29ae29524abd', '2026-09-08 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 1, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.0,12.2]::numeric[]);
select registrar_medicion(pg_temp.seed_a(), '45810cad-37db-487c-a089-1e621b839449', '2026-09-09 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.5,10.1]::numeric[]);
select registrar_medicion(pg_temp.seed_a(), 'd26dd49c-ed48-4ea3-a207-181319aea062', '2026-09-10 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.0,7.4]::numeric[]);

-- 2026-09-12 · Aurelia declara lista la Tina 1
select pg_temp.seed_como('a15ebe3e-3043-4e50-8ded-35ce75aba035');
select declarar_tina_lista(pg_temp.seed_a(), '5d6c464e-3104-47ff-af48-8e3132db8520', '2026-09-12 17:00:00-06',
  pg_temp.seed_cyc('Tina 1'), 'Día 5: ya no burbujea, sabor seco');

-- 2026-09-13 · Tomás: dos corridas de 1ª pasada desde la Tina 1
select pg_temp.seed_como('53f4d72a-798d-424d-927b-2e64609ccd66');
select abrir_corrida(pg_temp.seed_a(), '23aa9681-d1e9-491f-ae02-1d18aeb43978', '2026-09-13 06:00:00-06',
  pg_temp.seed_res('Alambique 1'), 'primera', array[pg_temp.seed_res('Tina 1')], array[pg_temp.seed_lot('FER-T1-001')], array[290::numeric],
  p_folio => 'DES-001');
select registrar_corte(pg_temp.seed_a(), 'd0d46bae-c1b4-4648-a131-20968ebcdb8b', '2026-09-13 08:00:00-06', pg_temp.seed_run('DES-001'), 'mezcal', 8, 51.0, pg_temp.seed_res('Colector mezcal'), p_folio => 'MEZ-001');
select registrar_corte(pg_temp.seed_a(), '323d5986-c546-48f9-80a5-f9ac8d1b5c3d', '2026-09-13 10:00:00-06', pg_temp.seed_run('DES-001'), 'ordinario', 40, 24.0, pg_temp.seed_res('Colector ordinario'), p_folio => 'ORD-001');
select registrar_corte(pg_temp.seed_a(), '4e16b848-a424-49c8-beaa-c01a51a935a1', '2026-09-13 12:00:00-06', pg_temp.seed_run('DES-001'), 'colas', 12, 9.0, pg_temp.seed_res('Colector colas'), p_folio => 'COL-001');
select cerrar_corrida(pg_temp.seed_a(), 'cfdc9d5e-3106-4459-837a-2b0a1b0cffa9', '2026-09-13 14:00:00-06', pg_temp.seed_run('DES-001'));

select abrir_corrida(pg_temp.seed_a(), '759ad83d-814d-4037-90f7-a94d2be985ff', '2026-09-13 06:00:00-06',
  pg_temp.seed_res('Alambique 2'), 'primera', array[pg_temp.seed_res('Tina 1')], array[pg_temp.seed_lot('FER-T1-001')], array[240::numeric],
  p_folio => 'DES-002');
select registrar_corte(pg_temp.seed_a(), '098feef8-86dd-49a0-9e35-e9f5acf24890', '2026-09-13 08:00:00-06', pg_temp.seed_run('DES-002'), 'mezcal', 6, 50.0, pg_temp.seed_res('Colector mezcal'));
select registrar_corte(pg_temp.seed_a(), '67ccd2f1-81ce-4fab-b6bd-5145acfc651d', '2026-09-13 10:00:00-06', pg_temp.seed_run('DES-002'), 'ordinario', 34, 23.0, pg_temp.seed_res('Colector ordinario'));
select registrar_corte(pg_temp.seed_a(), '1709a63f-d328-4d6c-94ef-2aeaa22b43b1', '2026-09-13 12:00:00-06', pg_temp.seed_run('DES-002'), 'colas', 10, 8.0, pg_temp.seed_res('Colector colas'));
select cerrar_corrida(pg_temp.seed_a(), '0a3f5cce-78d5-48fc-95e0-2c2f0cbf8e21', '2026-09-13 14:00:00-06', pg_temp.seed_run('DES-002'));

-- 2026-09-15 · Tomás: 2ª pasada con ordinario y colas juntos (aviso + nota)
select abrir_corrida(pg_temp.seed_a(), '3410c884-862c-4160-9e52-ef3578fb9889', '2026-09-15 06:00:00-06',
  pg_temp.seed_res('Alambique 1'), 'segunda',
  array[pg_temp.seed_res('Colector ordinario'), pg_temp.seed_res('Colector colas')],
  array[pg_temp.seed_lot('ORD-001'), pg_temp.seed_lot('COL-001')], array[74::numeric, 22::numeric],
  'Había olla libre y poca cola; se juntó con el ordinario', 'DES-003');
select registrar_corte(pg_temp.seed_a(), 'c5b4bf4d-4ddd-48b6-9dff-79211f39ed1d', '2026-09-15 08:00:00-06', pg_temp.seed_run('DES-003'), 'mezcal', 26, 52.5, pg_temp.seed_res('Colector mezcal'));
select registrar_corte(pg_temp.seed_a(), '26d14dba-0c39-4284-a7fb-26a2133397b9', '2026-09-15 10:00:00-06', pg_temp.seed_run('DES-003'), 'colas', 16, 10.0, pg_temp.seed_res('Colector colas'), p_folio => 'COL-002');
select cerrar_corrida(pg_temp.seed_a(), '43f28654-29de-49e9-9278-5e0ddb9fb4c5', '2026-09-15 14:00:00-06', pg_temp.seed_run('DES-003'));

-- 2026-09-16 · Aurelia: el mezcal del colector pasa a granel con folio nuevo
select pg_temp.seed_como('a15ebe3e-3043-4e50-8ded-35ce75aba035');
select transferir(pg_temp.seed_a(), '66cf0ca3-e32b-4074-8f43-ed811c4664c1', '2026-09-16 09:00:00-06',
  pg_temp.seed_res('Colector mezcal'), pg_temp.seed_res('Tanque 1'), pg_temp.seed_lot('MEZ-001'), 40, 51.6, 'renombrar', 'G-2609-01');
-- Agua para bajar grado: 4 L, declara 43.8 L (contracción) y 47.0 %
select registrar_movimiento_granel(pg_temp.seed_a(), '45a1ab1c-6d25-4f4a-9a45-9374e4ba7838', '2026-09-16 11:00:00-06',
  pg_temp.seed_con('66a151e2-9a2c-58be-ad4a-b117f1ddb717'), pg_temp.seed_res('Tanque 1'), 4,
  p_lote => pg_temp.seed_lot('G-2609-01'), p_resultado_l => 43.8, p_resultado_abv => 47.0);

-- 2026-09-17 · Benito: puntas guardadas (sin lote) al Tanque 2
select pg_temp.seed_como('17079ce3-e3e7-4f9b-8a5b-a6b7fe44e7e7');
select registrar_movimiento_granel(pg_temp.seed_a(), '30198920-4a00-42df-887a-9f925bc9a0da', '2026-09-17 10:00:00-06',
  pg_temp.seed_con('f21aaad8-2ef6-556b-be55-64aa94431ab6'), pg_temp.seed_res('Tanque 2'), 2,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_resultado_l => 602, p_resultado_abv => 44.6, p_abv => 68.0,
  p_nota => 'Puntas guardadas de corridas de agosto, sin lote');
-- 2026-09-18 · Benito: unión de G-2609-01 (Tanque 1) con G-INI-01 (Tanque 2), se conserva el folio mayor
select registrar_movimiento_granel(pg_temp.seed_a(), 'cbd20c7a-6eda-4f21-ae5c-39ebf9d13366', '2026-09-18 09:30:00-06',
  pg_temp.seed_con('df427d88-600e-550e-a097-8ffe4f4dd556'), pg_temp.seed_res('Tanque 2'), 43.8,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_lote_origen => pg_temp.seed_lot('G-2609-01'), p_recurso_origen => pg_temp.seed_res('Tanque 1'),
  p_resultado_l => 645.8, p_resultado_abv => 44.9, p_decision => 'conservar', p_nota => 'Se conserva el folio del lote mayor');
-- 2026-09-19 · Benito: compra de granel al Tanque 1
select registrar_movimiento_granel(pg_temp.seed_a(), 'a4761f1a-74d2-43d8-b0ba-8729c4868c5a', '2026-09-19 12:00:00-06',
  pg_temp.seed_con('688430a9-cd2f-5bae-add2-c59bc543d911'), pg_temp.seed_res('Tanque 1'), 250,
  p_resultado_l => 250, p_resultado_abv => 46.0, p_abv => 46.0, p_folio_nuevo => 'G-COMPRA-01',
  p_contraparte => 'Destilados Hermanos Luna', p_documento => 'Remisión 0452',
  p_proveedor => '8d191c97-0e8a-413c-85e6-55ea8a8bc72e', p_especie => pg_temp.seed_esp('67a96efd-2c72-528e-8682-d144fe1f802c'),
  p_predio_declarado => 'Sola de Vega');

-- 2026-09-19 · Aurelia: muestra de laboratorio
select pg_temp.seed_como('a15ebe3e-3043-4e50-8ded-35ce75aba035');
select registrar_movimiento_granel(pg_temp.seed_a(), '191ddc13-dccd-4836-b767-3697c1792a58', '2026-09-19 13:00:00-06',
  pg_temp.seed_con('2d62ab89-6a11-558c-8b46-5c4d30aa1607'), pg_temp.seed_res('Tanque 2'), 1,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Laboratorio ficticio de Oaxaca', p_documento => 'Análisis 2026-311');

-- 2026-09-20/22 · Benito: autoconsumo, venta, regalo
select pg_temp.seed_como('17079ce3-e3e7-4f9b-8a5b-a6b7fe44e7e7');
select registrar_movimiento_granel(pg_temp.seed_a(), '1e1d1dcc-1c64-459b-a3cb-36605110752e', '2026-09-20 13:00:00-06',
  pg_temp.seed_con('fa52f92b-de19-5d0c-972c-beb899bb2ccb'), pg_temp.seed_res('Tanque 2'), 2, p_lote => pg_temp.seed_lot('G-INI-01'));
select registrar_movimiento_granel(pg_temp.seed_a(), 'f887c644-5aa7-4a9f-8207-b47e787f1db5', '2026-09-22 13:00:00-06',
  pg_temp.seed_con('7b0ca7ca-f8ae-5f33-93d5-f0c174664ec1'), pg_temp.seed_res('Tanque 2'), 300,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.', p_documento => 'Remisión 118');
select registrar_movimiento_granel(pg_temp.seed_a(), 'a40a5ea8-60ef-4312-aeb9-cf2bc388f3ad', '2026-09-22 13:00:00-06',
  '09d2c4ba-941f-4465-9857-d83777e9da21', pg_temp.seed_res('Tanque 2'), 1,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.');

reset role;

-- Evidencia de la compra (los adjuntos no son RPC de §12)
insert into attachments (id, organization_id, operation_id, lot_id, kind_item_id, storage_path, caption) values
  ('52fc4a47-3814-4c7e-9733-a3df89699419', pg_temp.seed_a(),
   (select id from operations where organization_id = pg_temp.seed_a() and idempotency_key = 'a4761f1a-74d2-43d8-b0ba-8729c4868c5a'),
   pg_temp.seed_lot('G-COMPRA-01'), pg_temp.seed_cat('0522e23b-3b1d-58be-b50c-8a6ed0627c9f'),
   'evidencias/1c699a8a-2163-4f62-a230-8ae3f6c68b83/g-compra-01/remision-0452.jpg', 'Remisión del proveedor');


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
--   benito  17079ce3-e3e7-4f9b-8a5b-a6b7fe44e7e7  admin de Cuatro Vientos (A)
--   tomas   53f4d72a-798d-424d-927b-2e64609ccd66  operador de A
--   dueña B 9dbd576d-f71a-4a52-abf9-bcb98c9039a6  admin de Palenque Prueba B
--   nadie   2f69cffb-b038-41a7-a646-7d86ed2223a1  sin membresía
--   A = 1c699a8a-2163-4f62-a230-8ae3f6c68b83   B = 01c8f7ce-1629-41d7-86d5-f7267f75f855


-- Filas de la empresa A visibles bajo la RLS del rol actual, sumadas en
-- todas las tablas de negocio y vistas. Debe ser 0 para quien no es de A.
create function pg_temp.rows_of_a() returns bigint language sql as $$
  select
    (select count(*) from catalog_items      where organization_id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83') +
    (select count(*) from movement_concepts  where organization_id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83') +
    (select count(*) from species            where organization_id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83') +
    (select count(*) from predios            where organization_id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83') +
    (select count(*) from suppliers          where organization_id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83') +
    (select count(*) from supplies           where organization_id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83') +
    (select count(*) from resources          where organization_id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83') +
    (select count(*) from operations         where organization_id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83') +
    (select count(*) from operation_warnings where organization_id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83') +
    (select count(*) from lots               where organization_id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83') +
    (select count(*) from lot_lineage        where organization_id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83') +
    (select count(*) from lot_external_sources where organization_id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83') +
    (select count(*) from maguey_receptions  where organization_id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83') +
    (select count(*) from liquid_movements   where organization_id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83') +
    (select count(*) from attachments        where organization_id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83') +
    (select count(*) from roasting_runs      where organization_id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83') +
    (select count(*) from roasting_run_inputs where organization_id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83') +
    (select count(*) from formulations       where organization_id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83') +
    (select count(*) from formulation_inputs where organization_id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83') +
    (select count(*) from formulation_supplies where organization_id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83') +
    (select count(*) from fermentation_cycles where organization_id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83') +
    (select count(*) from fermentation_measurements where organization_id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83') +
    (select count(*) from measurement_readings where organization_id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83') +
    (select count(*) from distillation_runs  where organization_id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83') +
    (select count(*) from distillation_run_inputs where organization_id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83') +
    (select count(*) from distillation_cuts  where organization_id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83') +
    (select count(*) from organization_members where organization_id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83') +
    (select count(*) from organization_settings where organization_id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83') +
    (select count(*) from subscriptions      where organization_id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83') +
    (select count(*) from resource_lot_balances where organization_id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83') +
    (select count(*) from movement_log       where organization_id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83');
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
  perform pg_temp.como('17079ce3-e3e7-4f9b-8a5b-a6b7fe44e7e7');
  return next is((select count(*) from organizations), 1::bigint, 'benito ve exactamente una empresa');
  return next is((select count(*) from resources), 12::bigint, 'benito ve los 12 recursos de Cuatro Vientos');
  return next is((select count(*) from resources where organization_id = '01c8f7ce-1629-41d7-86d5-f7267f75f855'), 0::bigint,
                 'benito no ve recursos de la empresa B');
  return next ok((select pg_temp.rows_of_a()) > 0, 'benito sí ve filas de su propia empresa');

  -- 2) dueña de B no lee, no inserta ni referencia nada de A
  perform pg_temp.como('9dbd576d-f71a-4a52-abf9-bcb98c9039a6');
  return next is((select count(*) from organizations), 1::bigint, 'dueña B ve solo su empresa');
  return next is((select pg_temp.rows_of_a()), 0::bigint,
                 'dueña B no ve ninguna fila de A en ninguna tabla de negocio ni vista');
  return next throws_ok(
    $q$insert into resources (organization_id, kind, code, capacity_policy)
       values ('1c699a8a-2163-4f62-a230-8ae3f6c68b83', 'tina', 'Intrusa', 'flexible')$q$,
    '42501', null, 'dueña B no puede insertar un recurso en A (RLS)');
  return next throws_ok(
    $q$insert into resources (organization_id, kind, code, type_item_id, capacity_policy)
       values ('01c8f7ce-1629-41d7-86d5-f7267f75f855', 'alambique', 'Alambique B1',
               'da5b3cc3-45a0-45dc-8ea0-0b8014c69c5b', 'estricta')$q$,
    null, null, 'dueña B no puede referenciar un catálogo de A (FK compuesta o trigger de tipo)');
  return next lives_ok(
    $q$update organizations set name = 'Hackeada' where id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83'$q$,
    'un update sobre A desde B no revienta: la RLS simplemente filtra 0 filas');
  execute 'reset role';
  return next is((select name from organizations where id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83'),
                 'Mezcal Cuatro Vientos', 'el nombre de A sigue intacto tras el intento desde B');

  -- 3) sin membresía activa no se ve nada
  perform pg_temp.como('2f69cffb-b038-41a7-a646-7d86ed2223a1');
  return next is((select count(*) from organizations), 0::bigint, 'un usuario sin membresía no ve empresas');
  return next is((select pg_temp.rows_of_a()), 0::bigint, 'un usuario sin membresía no ve filas de negocio');

  -- 4) el operador no ejecuta funciones de admin ni escribe infraestructura
  perform pg_temp.como('53f4d72a-798d-424d-927b-2e64609ccd66');
  return next throws_ok(
    $q$select desbloquear_miembro('1c699a8a-2163-4f62-a230-8ae3f6c68b83', '53f4d72a-798d-424d-927b-2e64609ccd66')$q$,
    'P0001', null, 'un operador no puede desbloquear miembros');
  return next throws_ok(
    $q$insert into resources (organization_id, kind, code, capacity_policy)
       values ('1c699a8a-2163-4f62-a230-8ae3f6c68b83', 'tina', 'Tina X', 'flexible')$q$,
    '42501', null, 'un operador no puede crear recursos');
  execute 'reset role';

  -- 5) Estructura: criterios de aceptación de §16 Fase 1
  return next is((select count(*) from pg_policies where schemaname = 'public' and cmd = 'ALL'), 0::bigint,
                 'ninguna política for all');
  -- §16 prohíbe JSON en tablas, no en las vistas de lectura de 0026.
  -- Las agregaciones de corridas/tanques no almacenan datos desnormalizados.
  return next is((select count(*) from information_schema.columns c
                   join information_schema.tables t
                     using (table_catalog, table_schema, table_name)
                   where c.table_schema = 'public' and t.table_type = 'BASE TABLE'
                     and c.data_type in ('json', 'jsonb')), 0::bigint,
                 'ninguna columna json/jsonb en tablas de public');
  return next is((select count(*) from pg_tables where schemaname = 'public' and not rowsecurity), 0::bigint,
                 'todas las tablas de public tienen RLS activada');

  -- 6) Saldos esperados de la simulación (§15.1)
  return next results_eq(
    $q$select r.code, l.folio, b.volume_l::numeric(12,3)
         from resource_lot_balances b
         join resources r on r.id = b.resource_id
         join lots l on l.id = b.lot_id
        where b.organization_id = '1c699a8a-2163-4f62-a230-8ae3f6c68b83'
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
