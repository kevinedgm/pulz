begin;
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
-- tomas.h → 'tomas-2026' · dueña B → 'qa-6638aa939f924ebd-prueba-b-2026' · admin → 'pulz-2026'
-- ---------------------------------------------------------------------
insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
                        raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
                        confirmation_token, recovery_token, email_change_token_new, email_change) values
  ('00000000-0000-0000-0000-000000000000', 'e48969b1-1367-4684-ae98-18a338666931', 'authenticated', 'authenticated', 'qa-6638aa939f924ebd-tu@pulz.mx',
   extensions.crypt('pulz-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '5d9d8aad-eeb1-4974-8eae-48261a6f9149', 'authenticated', 'authenticated', 'qa-6638aa939f924ebd-benito@cuatrovientos.mx',
   extensions.crypt('benito-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '0d13fd67-880a-4ac4-803b-7c0015e4a3cc', 'authenticated', 'authenticated', 'qa-6638aa939f924ebd-aurelia@5f6c43f1-05ff-4a29-959e-de5f6cb15372.usuarios.pulz.mx',
   extensions.crypt('aurelia-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '27691739-f4c2-47c1-a0a5-f0f71c6f0900', 'authenticated', 'authenticated', 'qa-6638aa939f924ebd-tomas.h@5f6c43f1-05ff-4a29-959e-de5f6cb15372.usuarios.pulz.mx',
   extensions.crypt('tomas-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', 'f6e4dcd3-de7d-456f-891e-7ec5a87ad014', 'authenticated', 'authenticated', 'qa-6638aa939f924ebd-duena@pruebab.mx',
   extensions.crypt('qa-6638aa939f924ebd-prueba-b-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '');

insert into profiles (id, full_name) values
  ('e48969b1-1367-4684-ae98-18a338666931', 'Admin PULZ'),
  ('5d9d8aad-eeb1-4974-8eae-48261a6f9149', 'Benito Cruz'),
  ('0d13fd67-880a-4ac4-803b-7c0015e4a3cc', 'Aurelia Santiago'),
  ('27691739-f4c2-47c1-a0a5-f0f71c6f0900', 'Tomás Hernández'),
  ('f6e4dcd3-de7d-456f-891e-7ec5a87ad014', 'Dueña Prueba B');

insert into platform_admins (user_id) values ('e48969b1-1367-4684-ae98-18a338666931');

-- Planes (§14, §18 #2 y #3)
-- Fixture: reutiliza plans canónica, sin modificarla.
-- Fixture: reutiliza plan_limits canónica, sin modificarla.
-- Fixture: reutiliza plan_features canónica, sin modificarla.

-- Empresas
insert into organizations (id, name, slug, state, brand_color, logo_path, welcome_message, created_by) values
  ('5f6c43f1-05ff-4a29-959e-de5f6cb15372', 'Mezcal Cuatro Vientos', 'qa-6638aa939f924ebd-cuatro-vientos', 'Oaxaca', '#7A3E1D', null, 'Registro de producción del palenque', '5d9d8aad-eeb1-4974-8eae-48261a6f9149'),
  ('e38e99ce-9d4a-4580-b414-877143958561', 'Palenque Prueba B', 'qa-6638aa939f924ebd-prueba-b', 'Oaxaca', '#173F87', null, 'Empresa de prueba', 'f6e4dcd3-de7d-456f-891e-7ec5a87ad014');
insert into organization_slug_history (slug, organization_id, retired_at, retired_by) values
  ('qa-6638aa939f924ebd-mezcal-cuatro-vientos', '5f6c43f1-05ff-4a29-959e-de5f6cb15372', '2026-09-02 09:00:00-06', '5d9d8aad-eeb1-4974-8eae-48261a6f9149');
insert into organization_members (organization_id, user_id, role, status, username, must_change_password) values
  ('5f6c43f1-05ff-4a29-959e-de5f6cb15372', '5d9d8aad-eeb1-4974-8eae-48261a6f9149', 'admin', 'activo', null, false),
  ('5f6c43f1-05ff-4a29-959e-de5f6cb15372', '0d13fd67-880a-4ac4-803b-7c0015e4a3cc', 'productor', 'activo', 'aurelia', false),
  ('5f6c43f1-05ff-4a29-959e-de5f6cb15372', '27691739-f4c2-47c1-a0a5-f0f71c6f0900', 'operador', 'activo', 'tomas.h', true),
  ('e38e99ce-9d4a-4580-b414-877143958561', 'f6e4dcd3-de7d-456f-891e-7ec5a87ad014', 'admin', 'activo', null, false);
insert into member_invitations (id, organization_id, user_id, token_hash, expires_at, used_at, created_by) values
  ('27efc4e7-fa8a-4344-b228-9fa1ffe51f72', '5f6c43f1-05ff-4a29-959e-de5f6cb15372', '27691739-f4c2-47c1-a0a5-f0f71c6f0900', 'qa-6638aa939f924ebd:SIMULADO', '2026-09-05 10:00:00-06', null, '5d9d8aad-eeb1-4974-8eae-48261a6f9149');
insert into login_throttle (user_id, failed_count, last_failed_at, locked_until) values
  ('27691739-f4c2-47c1-a0a5-f0f71c6f0900', 3, '2026-09-03 07:12:00-06', null);
insert into organization_settings (organization_id, record_puntas, measurement_mode, warn_mixed_second_pass, fermentation_expected_days, measurement_reminder_hour, default_folio_decision) values
  ('5f6c43f1-05ff-4a29-959e-de5f6cb15372', false, 'minimo', true, 7, 9, 'conservar'),
  ('e38e99ce-9d4a-4580-b414-877143958561', false, 'minimo', true, 7, 9, 'conservar');
insert into subscriptions (organization_id, plan_id, status, current_period_end) values
  ('5f6c43f1-05ff-4a29-959e-de5f6cb15372', 'edd15bcf-ad82-5684-a2e7-d85db401885b', 'prueba', '2026-10-15 00:00:00-06'),
  ('e38e99ce-9d4a-4580-b414-877143958561', 'ee35d6fd-b4d6-56d6-b7b4-61cb81932b21', 'gratis', null);

-- ---------------------------------------------------------------------
-- Plantillas de plataforma (§10.2.1)
-- ---------------------------------------------------------------------
-- Fixture: reutiliza catalog_item_templates canónica, sin modificarla.
-- Fixture: reutiliza movement_concept_templates canónica, sin modificarla.
-- Fixture: reutiliza species_templates canónica, sin modificarla.

select seed_organization_catalogs('5f6c43f1-05ff-4a29-959e-de5f6cb15372');
select seed_organization_catalogs('e38e99ce-9d4a-4580-b414-877143958561');

-- Lo propio de Cuatro Vientos y lo que oculta (§10.2.4)
insert into catalog_items (id, organization_id, template_id, catalog, name, sort_order, created_by) values
  ('e3d4ad6f-d007-492c-9b73-4e5e8c52bddd', '5f6c43f1-05ff-4a29-959e-de5f6cb15372', null, 'tipo_alambique', 'Refrescadera de cobre', 100, '5d9d8aad-eeb1-4974-8eae-48261a6f9149');
insert into movement_concepts (id, organization_id, template_id, direction, name, source_lot, creates_lot, asks_result, asks_counterparty, sort_order, created_by) values
  ('5ae8b045-65bf-4a12-95b5-a0d4a1db0d70', '5f6c43f1-05ff-4a29-959e-de5f6cb15372', null, 'salida', 'Regalo a cliente', 'no_aplica', false, false, true, 100, '5d9d8aad-eeb1-4974-8eae-48261a6f9149');
update catalog_items set active = false
 where organization_id = '5f6c43f1-05ff-4a29-959e-de5f6cb15372'
   and template_id in ('5c985133-23d9-50fa-a252-6ff6b5b74134', 'b1fce67a-21bf-50a7-9344-fdf29eb5331e');
update movement_concepts set active = false
 where organization_id = '5f6c43f1-05ff-4a29-959e-de5f6cb15372'
   and template_id = '8b7f6579-99ef-549e-b427-b1d4d8bea9da';

-- ---------------------------------------------------------------------
-- Ayudas de la semilla (temporales; mueren con la sesión). security definer
-- para que resuelvan ids aunque el rol activo sea 'authenticated'.
-- ---------------------------------------------------------------------
create function pg_temp.seed_a() returns uuid language sql immutable as $$ select '5f6c43f1-05ff-4a29-959e-de5f6cb15372'::uuid $$;
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
  ('515b0e71-fde1-4a01-a673-11d1ef042020', pg_temp.seed_a(), 'Loma del Toro', 'Santiago Matatlán', 'Familia Cruz');
insert into suppliers (id, organization_id, name, type_item_id) values
  ('4c8a954f-f490-4ee4-bee4-27b64ec13c70', pg_temp.seed_a(), 'Magueyes Don Pedro', pg_temp.seed_cat('640b537d-bf52-5c4b-b407-a5f4fb7c5800')),
  ('57b4f49b-182d-4d34-8d1b-dce27fd84185', pg_temp.seed_a(), 'Destilados Hermanos Luna', pg_temp.seed_cat('bb234638-3c78-56cd-9f41-2fb38182f181'));
insert into supplies (id, organization_id, name, unit_item_id) values
  ('623f522f-19b2-4138-a87e-5dedccb26e25', pg_temp.seed_a(), 'Pulque como inóculo', pg_temp.seed_cat('bc6f104d-2841-5b36-b492-76b36becb172'));
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy, liquid_class) values
  ('2ddb3189-9f59-4fcf-9d2d-88dc8235baaa', pg_temp.seed_a(), 'horno', 'Horno 1', pg_temp.seed_cat('d53ba2da-cada-5215-804a-ff304d569f97'), 10000, 'kg', 'libre', null),
  ('ef3d5fa1-c52a-436f-904b-db5f9269a736', pg_temp.seed_a(), 'molino', 'Tahona', pg_temp.seed_cat('60285283-d000-52f0-95da-d2b2e6d70fa1'), null, 'kg', 'libre', null),
  ('010c7c31-b815-4585-9751-7af236850936', pg_temp.seed_a(), 'tina', 'Tina 1', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('aed7e608-8e71-412b-b0a2-5880d328e674', pg_temp.seed_a(), 'tina', 'Tina 2', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('b753acbf-fc64-4298-bc80-ec46089c7a9a', pg_temp.seed_a(), 'tina', 'Tina 3', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('efb2b4eb-721c-44c7-bf7e-3ee435b177f3', pg_temp.seed_a(), 'alambique', 'Alambique 1', pg_temp.seed_cat('af73010e-53f2-5769-b3b1-6cda154e665e'), 300, 'L', 'estricta', null),
  ('413fd5c7-18af-4de8-9f64-9858471e7962', pg_temp.seed_a(), 'alambique', 'Alambique 2', 'e3d4ad6f-d007-492c-9b73-4e5e8c52bddd', 250, 'L', 'estricta', null),
  ('84a19ad6-6e8b-422b-9684-2b69785d3584', pg_temp.seed_a(), 'colector', 'Colector mezcal', pg_temp.seed_cat('2cd7e70b-6246-543e-8f67-23743fefdf95'), 60, 'L', 'flexible', 'mezcal'),
  ('b94abeb8-c87b-4b56-aeec-211a0cf8fca5', pg_temp.seed_a(), 'colector', 'Colector ordinario', pg_temp.seed_cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'ordinario'),
  ('545d5f4d-6f63-49ea-840b-14a35b4507bb', pg_temp.seed_a(), 'colector', 'Colector colas', pg_temp.seed_cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'colas'),
  ('810288cf-0632-4a7a-96f8-b62849645e5c', pg_temp.seed_a(), 'tanque', 'Tanque 1', pg_temp.seed_cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1000, 'L', 'flexible', null),
  ('ac3cf08a-7cbf-41ea-951b-cf84e1508223', pg_temp.seed_a(), 'tanque', 'Tanque 2', pg_temp.seed_cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1500, 'L', 'flexible', null);

-- Palenque Prueba B: lo mínimo para probar aislamiento
insert into predios (id, organization_id, name, municipality) values
  ('8d2f2d01-f617-4c0b-8e20-2dd1435dbdc5', 'e38e99ce-9d4a-4580-b414-877143958561', 'Predio B', 'Ejutla');
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy) values
  ('a112cf9d-de64-467e-8e2c-21b1aab5a3f0', 'e38e99ce-9d4a-4580-b414-877143958561', 'tina', 'Tina B1',
   (select id from catalog_items where organization_id = 'e38e99ce-9d4a-4580-b414-877143958561' and template_id = 'b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1000, 'L', 'flexible');

-- =====================================================================
-- Cuatro Vientos: la producción, POR RPC, en orden cronológico
-- =====================================================================

-- 2026-09-01 · Benito: lo que ya había en el Tanque 2 (carga inicial)
select pg_temp.seed_como('5d9d8aad-eeb1-4974-8eae-48261a6f9149');
select registrar_entrada(pg_temp.seed_a(), 'ce65ea21-8a6d-4a4b-b7a8-231263debdf4', '2026-09-01 10:15:00-06',
  'granel', pg_temp.seed_res('Tanque 2'), 600, 44.2, 'mezcal', 'carga_inicial',
  p_concepto => pg_temp.seed_con('255e79f1-12b3-5969-8453-e40623275559'),
  p_nota => 'Lo que ya había en el tanque al empezar', p_folio => 'G-INI-01');

-- 2026-09-01 · Aurelia: la Tina 3 ya fermentaba
select pg_temp.seed_como('0d13fd67-880a-4ac4-803b-7c0015e4a3cc');
select registrar_entrada(pg_temp.seed_a(), 'e53c68ab-da8c-4ff0-8037-d76b2e50e653', '2026-09-01 10:40:00-06',
  'fermentado', pg_temp.seed_res('Tina 3'), 1300, null, null, 'carga_inicial',
  p_nota => 'Tina que ya fermentaba', p_folio => 'FER-T3-INI');

-- 2026-09-02 · Aurelia: recepción de maguey
select registrar_recepcion_maguey(pg_temp.seed_a(), 'c98dc45b-55da-4a66-809d-76f91a9e262e', '2026-09-02 07:30:00-06',
  8000, pg_temp.seed_esp('67a96efd-2c72-528e-8682-d144fe1f802c'), '515b0e71-fde1-4a01-a673-11d1ef042020',
  '4c8a954f-f490-4ee4-bee4-27b64ec13c70', 132, 'Piñas de 8 años, buen tamaño', 'MAG-001');

-- 2026-09-02 · Horneado (la simulación lo abría Tomás; §11.1 lo reserva a
-- admin/productor, así que lo abre Aurelia — docs/DECISIONES.md)
select abrir_horneado(pg_temp.seed_a(), '0c3dafb0-e924-4849-95c0-325c6c688b72', '2026-09-02 12:00:00-06',
  pg_temp.seed_res('Horno 1'), array[pg_temp.seed_lot('MAG-001')], array[8000::numeric], p_folio => 'HOR-001');
-- 2026-09-06 · Aurelia cierra: 6,200 kg de agave cocido
select cerrar_horneado(pg_temp.seed_a(), '9f366354-69cf-43aa-9663-d100e5d5c7d1', '2026-09-06 08:00:00-06',
  pg_temp.seed_hor('HOR-001'), 6200, 'Leña de encino', p_folio => 'AC-001');

-- 2026-09-07 · Aurelia: formulación repartida a Tina 1 y Tina 2
select registrar_formulacion(pg_temp.seed_a(), '9f4d9310-ca41-41c2-b18e-6117311a51cd', '2026-09-07 09:00:00-06',
  pg_temp.seed_res('Tahona'), array[pg_temp.seed_lot('AC-001')], array[6200::numeric], 1900,
  array[pg_temp.seed_res('Tina 1'), pg_temp.seed_res('Tina 2')], array[1400::numeric, 1400::numeric],
  array['623f522f-19b2-4138-a87e-5dedccb26e25'::uuid], array[20::numeric],
  'Tahona con mula', null, 'F-001', array['FER-T1-001', 'FER-T2-001']);

-- Mediciones diarias (escala de actividad 1–6, §18 #1; la simulación traía 7 y 8)
-- Tina 1
select pg_temp.seed_como('27691739-f4c2-47c1-a0a5-f0f71c6f0900');
select registrar_medicion(pg_temp.seed_a(), 'faf732c4-6c76-4606-86aa-e8f2f6e4ba8e', '2026-09-08 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 1, 'minimo', 4,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.5,12.0]::numeric[]);
select pg_temp.seed_como('0d13fd67-880a-4ac4-803b-7c0015e4a3cc');
select registrar_medicion(pg_temp.seed_a(), 'c3c36667-1f1d-4d8a-b503-ac7ec2c30ceb', '2026-09-09 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.0,9.5]::numeric[]);
select pg_temp.seed_como('27691739-f4c2-47c1-a0a5-f0f71c6f0900');
select registrar_medicion(pg_temp.seed_a(), '4b376718-c247-42ac-b405-cca78c463b7c', '2026-09-10 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.5,6.0]::numeric[]);
select pg_temp.seed_como('0d13fd67-880a-4ac4-803b-7c0015e4a3cc');
select registrar_medicion(pg_temp.seed_a(), '7b348b28-b3ea-4471-aae7-34b5e2726278', '2026-09-11 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 4, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.5,3.5]::numeric[]);
select pg_temp.seed_como('27691739-f4c2-47c1-a0a5-f0f71c6f0900');
select registrar_medicion(pg_temp.seed_a(), 'fbc0a571-be93-40f1-882e-f6f41570c737', '2026-09-12 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 5, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.0,1.5]::numeric[]);
-- Tina 2
select registrar_medicion(pg_temp.seed_a(), '1e7d1139-792f-46cc-a8f8-5cd6624002ac', '2026-09-08 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 1, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.0,12.2]::numeric[]);
select registrar_medicion(pg_temp.seed_a(), 'a7b2c498-d277-48ae-b651-43d9b36d3a9c', '2026-09-09 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.5,10.1]::numeric[]);
select registrar_medicion(pg_temp.seed_a(), '9ecf1cb8-9498-4a58-b471-e86d87792c98', '2026-09-10 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.0,7.4]::numeric[]);

-- 2026-09-12 · Aurelia declara lista la Tina 1
select pg_temp.seed_como('0d13fd67-880a-4ac4-803b-7c0015e4a3cc');
select declarar_tina_lista(pg_temp.seed_a(), 'bd657855-c0b5-4a20-8ff0-8af23f16982b', '2026-09-12 17:00:00-06',
  pg_temp.seed_cyc('Tina 1'), 'Día 5: ya no burbujea, sabor seco');

-- 2026-09-13 · Tomás: dos corridas de 1ª pasada desde la Tina 1
select pg_temp.seed_como('27691739-f4c2-47c1-a0a5-f0f71c6f0900');
select abrir_corrida(pg_temp.seed_a(), 'fc55f172-7fb1-496f-9af4-ace6b45c7826', '2026-09-13 06:00:00-06',
  pg_temp.seed_res('Alambique 1'), 'primera', array[pg_temp.seed_res('Tina 1')], array[pg_temp.seed_lot('FER-T1-001')], array[290::numeric],
  p_folio => 'DES-001');
select registrar_corte(pg_temp.seed_a(), '7c854585-558a-41f6-8521-8fd77c8620b1', '2026-09-13 08:00:00-06', pg_temp.seed_run('DES-001'), 'mezcal', 8, 51.0, pg_temp.seed_res('Colector mezcal'), p_folio => 'MEZ-001');
select registrar_corte(pg_temp.seed_a(), 'cd57a957-f409-4a2b-945f-f06b8266d13e', '2026-09-13 10:00:00-06', pg_temp.seed_run('DES-001'), 'ordinario', 40, 24.0, pg_temp.seed_res('Colector ordinario'), p_folio => 'ORD-001');
select registrar_corte(pg_temp.seed_a(), '99fdd9a8-9d90-408d-ad8e-3fc6b1af88ad', '2026-09-13 12:00:00-06', pg_temp.seed_run('DES-001'), 'colas', 12, 9.0, pg_temp.seed_res('Colector colas'), p_folio => 'COL-001');
select cerrar_corrida(pg_temp.seed_a(), '6cdf79c9-17f0-4720-843d-aee6789a2571', '2026-09-13 14:00:00-06', pg_temp.seed_run('DES-001'));

select abrir_corrida(pg_temp.seed_a(), 'ae9a1746-1278-4fec-be6f-07fe663a0e1e', '2026-09-13 06:00:00-06',
  pg_temp.seed_res('Alambique 2'), 'primera', array[pg_temp.seed_res('Tina 1')], array[pg_temp.seed_lot('FER-T1-001')], array[240::numeric],
  p_folio => 'DES-002');
select registrar_corte(pg_temp.seed_a(), 'e1c823d3-6513-4e60-b56b-9a3b75ad187b', '2026-09-13 08:00:00-06', pg_temp.seed_run('DES-002'), 'mezcal', 6, 50.0, pg_temp.seed_res('Colector mezcal'));
select registrar_corte(pg_temp.seed_a(), 'ee4d38c7-9ea9-4edf-9618-402ecf347e1f', '2026-09-13 10:00:00-06', pg_temp.seed_run('DES-002'), 'ordinario', 34, 23.0, pg_temp.seed_res('Colector ordinario'));
select registrar_corte(pg_temp.seed_a(), '64be79e4-8259-40e5-a5cb-a979107ac934', '2026-09-13 12:00:00-06', pg_temp.seed_run('DES-002'), 'colas', 10, 8.0, pg_temp.seed_res('Colector colas'));
select cerrar_corrida(pg_temp.seed_a(), '62e1c885-27be-4ee1-b16f-b450f5dd0adb', '2026-09-13 14:00:00-06', pg_temp.seed_run('DES-002'));

-- 2026-09-15 · Tomás: 2ª pasada con ordinario y colas juntos (aviso + nota)
select abrir_corrida(pg_temp.seed_a(), '9f516479-82ec-496e-97ec-c7f901df474b', '2026-09-15 06:00:00-06',
  pg_temp.seed_res('Alambique 1'), 'segunda',
  array[pg_temp.seed_res('Colector ordinario'), pg_temp.seed_res('Colector colas')],
  array[pg_temp.seed_lot('ORD-001'), pg_temp.seed_lot('COL-001')], array[74::numeric, 22::numeric],
  'Había olla libre y poca cola; se juntó con el ordinario', 'DES-003');
select registrar_corte(pg_temp.seed_a(), '87aa0c5c-2083-45e1-92f4-c99cbc2b0c9f', '2026-09-15 08:00:00-06', pg_temp.seed_run('DES-003'), 'mezcal', 26, 52.5, pg_temp.seed_res('Colector mezcal'));
select registrar_corte(pg_temp.seed_a(), '7549e610-da72-4048-90e4-7bcac1ebc3a8', '2026-09-15 10:00:00-06', pg_temp.seed_run('DES-003'), 'colas', 16, 10.0, pg_temp.seed_res('Colector colas'), p_folio => 'COL-002');
select cerrar_corrida(pg_temp.seed_a(), '313087d5-4b1a-44c1-8803-77433da6b0cf', '2026-09-15 14:00:00-06', pg_temp.seed_run('DES-003'));

-- 2026-09-16 · Aurelia: el mezcal del colector pasa a granel con folio nuevo
select pg_temp.seed_como('0d13fd67-880a-4ac4-803b-7c0015e4a3cc');
select transferir(pg_temp.seed_a(), '746b7858-ec36-4526-b162-4a7dcb3e8772', '2026-09-16 09:00:00-06',
  pg_temp.seed_res('Colector mezcal'), pg_temp.seed_res('Tanque 1'), pg_temp.seed_lot('MEZ-001'), 40, 51.6, 'renombrar', 'G-2609-01');
-- Agua para bajar grado: 4 L, declara 43.8 L (contracción) y 47.0 %
select registrar_movimiento_granel(pg_temp.seed_a(), 'c3b0294b-6862-4835-8aa8-11c85681d99f', '2026-09-16 11:00:00-06',
  pg_temp.seed_con('66a151e2-9a2c-58be-ad4a-b117f1ddb717'), pg_temp.seed_res('Tanque 1'), 4,
  p_lote => pg_temp.seed_lot('G-2609-01'), p_resultado_l => 43.8, p_resultado_abv => 47.0);

-- 2026-09-17 · Benito: puntas guardadas (sin lote) al Tanque 2
select pg_temp.seed_como('5d9d8aad-eeb1-4974-8eae-48261a6f9149');
select registrar_movimiento_granel(pg_temp.seed_a(), '6eacd6ca-0bef-4e94-94b4-b9cadd001b0a', '2026-09-17 10:00:00-06',
  pg_temp.seed_con('f21aaad8-2ef6-556b-be55-64aa94431ab6'), pg_temp.seed_res('Tanque 2'), 2,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_resultado_l => 602, p_resultado_abv => 44.6, p_abv => 68.0,
  p_nota => 'Puntas guardadas de corridas de agosto, sin lote');
-- 2026-09-18 · Benito: unión de G-2609-01 (Tanque 1) con G-INI-01 (Tanque 2), se conserva el folio mayor
select registrar_movimiento_granel(pg_temp.seed_a(), '03f09633-7c37-415e-890d-3d0126aca4f0', '2026-09-18 09:30:00-06',
  pg_temp.seed_con('df427d88-600e-550e-a097-8ffe4f4dd556'), pg_temp.seed_res('Tanque 2'), 43.8,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_lote_origen => pg_temp.seed_lot('G-2609-01'), p_recurso_origen => pg_temp.seed_res('Tanque 1'),
  p_resultado_l => 645.8, p_resultado_abv => 44.9, p_decision => 'conservar', p_nota => 'Se conserva el folio del lote mayor');
-- 2026-09-19 · Benito: compra de granel al Tanque 1
select registrar_movimiento_granel(pg_temp.seed_a(), '686a2c0a-f9ad-48c9-aaf1-b4f1c20deecb', '2026-09-19 12:00:00-06',
  pg_temp.seed_con('688430a9-cd2f-5bae-add2-c59bc543d911'), pg_temp.seed_res('Tanque 1'), 250,
  p_resultado_l => 250, p_resultado_abv => 46.0, p_abv => 46.0, p_folio_nuevo => 'G-COMPRA-01',
  p_contraparte => 'Destilados Hermanos Luna', p_documento => 'Remisión 0452',
  p_proveedor => '57b4f49b-182d-4d34-8d1b-dce27fd84185', p_especie => pg_temp.seed_esp('67a96efd-2c72-528e-8682-d144fe1f802c'),
  p_predio_declarado => 'Sola de Vega');

-- 2026-09-19 · Aurelia: muestra de laboratorio
select pg_temp.seed_como('0d13fd67-880a-4ac4-803b-7c0015e4a3cc');
select registrar_movimiento_granel(pg_temp.seed_a(), '484822dc-be1c-479d-a694-fb4345102bb1', '2026-09-19 13:00:00-06',
  pg_temp.seed_con('2d62ab89-6a11-558c-8b46-5c4d30aa1607'), pg_temp.seed_res('Tanque 2'), 1,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Laboratorio ficticio de Oaxaca', p_documento => 'Análisis 2026-311');

-- 2026-09-20/22 · Benito: autoconsumo, venta, regalo
select pg_temp.seed_como('5d9d8aad-eeb1-4974-8eae-48261a6f9149');
select registrar_movimiento_granel(pg_temp.seed_a(), 'ca2b4c82-edf3-42a9-82e1-a1d549c61524', '2026-09-20 13:00:00-06',
  pg_temp.seed_con('fa52f92b-de19-5d0c-972c-beb899bb2ccb'), pg_temp.seed_res('Tanque 2'), 2, p_lote => pg_temp.seed_lot('G-INI-01'));
select registrar_movimiento_granel(pg_temp.seed_a(), 'd1115bfd-4485-427a-bdeb-07437510c557', '2026-09-22 13:00:00-06',
  pg_temp.seed_con('7b0ca7ca-f8ae-5f33-93d5-f0c174664ec1'), pg_temp.seed_res('Tanque 2'), 300,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.', p_documento => 'Remisión 118');
select registrar_movimiento_granel(pg_temp.seed_a(), '867f5e93-5db1-406e-aeb6-5a87881b5c86', '2026-09-22 13:00:00-06',
  '5ae8b045-65bf-4a12-95b5-a0d4a1db0d70', pg_temp.seed_res('Tanque 2'), 1,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.');

reset role;

-- Evidencia de la compra (los adjuntos no son RPC de §12)
insert into attachments (id, organization_id, operation_id, lot_id, kind_item_id, storage_path, caption) values
  ('12d01ccc-5036-4e40-8fd4-8fba1c1ad209', pg_temp.seed_a(),
   (select id from operations where organization_id = pg_temp.seed_a() and idempotency_key = '686a2c0a-f9ad-48c9-aaf1-b4f1c20deecb'),
   pg_temp.seed_lot('G-COMPRA-01'), pg_temp.seed_cat('0522e23b-3b1d-58be-b50c-8a6ed0627c9f'),
   'evidencias/5f6c43f1-05ff-4a29-959e-de5f6cb15372/g-compra-01/remision-0452.jpg', 'Remisión del proveedor');


-- pgTAP · Configuración (Fase 4): quién escribe qué según §11.1 y la RLS,
-- recurso_en_uso (0025)
-- real (0013); nunca se borra (active = false); el cambio de slug deja
-- historial y el viejo redirige; la carga inicial crea lote y saldo; el
-- bucket 'branding' existe con sus políticas (0024).
--     supabase db query --linked -f supabase/tests/configuracion.test.sql


create function pg_temp.como(u uuid) returns void language plpgsql as $$
begin
  execute 'set local role authenticated';
  execute format('set local request.jwt.claims = %L', json_build_object('sub', u, 'role', 'authenticated')::text);
end $$;
create function pg_temp.superuser() returns void language plpgsql as $$
begin execute 'reset role'; end $$;

create function pg_temp.test_configuracion() returns setof text language plpgsql as $$
declare
  a uuid := '5f6c43f1-05ff-4a29-959e-de5f6cb15372';      -- Cuatro Vientos
  b uuid := 'e38e99ce-9d4a-4580-b414-877143958561';      -- Prueba B
  admin_a uuid := '5d9d8aad-eeb1-4974-8eae-48261a6f9149';
  prod_a  uuid := '0d13fd67-880a-4ac4-803b-7c0015e4a3cc';
  oper_a  uuid := '27691739-f4c2-47c1-a0a5-f0f71c6f0900';
  admin_b uuid := 'f6e4dcd3-de7d-456f-891e-7ec5a87ad014';
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
  update organizations set slug = 'qa-6638aa939f924ebd-cuatro-vientos-mezcal' where id = a;
  return next is((select organization_id from organization_slug_history where slug = 'qa-6638aa939f924ebd-cuatro-vientos'), a,
                 'el slug viejo queda en el historial');
  return next is((select redirect_to from portal_branding('qa-6638aa939f924ebd-cuatro-vientos')), 'qa-6638aa939f924ebd-cuatro-vientos-mezcal',
                 'el portal del slug viejo redirige al nuevo');
  return next is((select logo_path from portal_branding('qa-6638aa939f924ebd-cuatro-vientos-mezcal')), a::text || '/logo.png',
                 'el portal publica la ruta del logo');
  perform pg_temp.como(admin_b);
  return next throws_like(
    format($q$update organizations set slug = 'qa-6638aa939f924ebd-cuatro-vientos' where id = '%s'$q$, b),
    '%', 'nadie más puede tomar un slug retirado');

  -- ── Primer arranque: carga inicial en tanque y tina ──────────────────
  perform pg_temp.como(admin_a);
  v_lot := registrar_entrada(a, '68707066-fdc8-4203-b713-87d4d6ba6f9d', now(), 'granel', v_tanque, 300, 47);
  return next is(registrar_entrada(a, '68707066-fdc8-4203-b713-87d4d6ba6f9d', now(), 'granel', v_tanque, 300, 47), v_lot,
                 'reintentar con la misma idempotency_key no duplica');
  perform pg_temp.superuser();   -- resource_balance es interna (sin execute para authenticated)
  return next is(resource_balance(a, v_tanque), 300::numeric, 'la carga inicial deja 300 L en el tanque nuevo');
  return next is((select origin from lots where id = v_lot), 'carga_inicial'::lot_origin, 'el lote nace como carga inicial');
  return next is((select count(*) from lots where organization_id = a and operation_id in
                    (select id from operations where organization_id = a and idempotency_key = '68707066-fdc8-4203-b713-87d4d6ba6f9d')),
                 1::bigint, 'un solo lote para esa idempotency_key');
  perform pg_temp.como(admin_a);
  return next throws_like(
    format($q$select registrar_entrada('%s', gen_random_uuid(), now(), 'fermentado', '%s', 100)$q$, a, v_tanque),
    'NO_PERMITIDO: un fermentado entra en una tina', 'un fermentado no entra en un tanque');
  perform pg_temp.como(oper_a);
  return next throws_like(
    format($q$select registrar_entrada('%s', gen_random_uuid(), now(), 'granel', '%s', 10)$q$, a, v_tanque),
    'NO_PERMITIDO:%', 'el operador no registra cargas iniciales');

  -- ── recurso_en_uso (0025): saldo y ciclos abiertos por recurso ───────
  perform pg_temp.como(prod_a);
  return next ok((select saldo_l from recurso_en_uso(a) where resource_id = v_tanque) = 300,
                 'la productora ve 300 L en el tanque nuevo (recurso_en_uso)');
  return next ok((select ciclos_abiertos from recurso_en_uso(a)
                   where resource_id = (select id from resources where organization_id = a and code = 'Tina 1')) >= 0,
                 'recurso_en_uso devuelve ciclos abiertos de una tina');
  return next is((select count(*) from recurso_en_uso(a)), (select count(*) from resources where organization_id = a),
                 'una fila por recurso de la empresa');
  perform pg_temp.como(admin_b);
  return next is((select count(*) from recurso_en_uso(a)), 0::bigint, 'el admin de B no ve los recursos de A');

  -- ── Storage: bucket y políticas (0024) ───────────────────────────────
  perform pg_temp.superuser();
  return next is((select public from storage.buckets where id = 'branding'), true, 'el bucket branding es público');
  return next is((select array_length(allowed_mime_types, 1) from storage.buckets where id = 'branding'), 3, 'solo png/jpeg/webp');
  return next is((select count(*) from pg_policies where schemaname = 'storage' and tablename = 'objects' and policyname like 'branding_%'), 4::bigint,
                 'cuatro políticas branding_* en storage.objects');
  return next is(storage_org_of(a::text || '/logo.png'), a, 'storage_org_of lee la carpeta raíz');
  return next is(storage_org_of('logo.png'), null::uuid, 'sin carpeta no hay empresa');
end $$;

select * from runtests((select nspname from pg_namespace where oid = pg_my_temp_schema())::name, '^test_');


rollback;
