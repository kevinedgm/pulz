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
-- tomas.h → 'tomas-2026' · dueña B → 'qa-5a4feb7d12bb4aae-prueba-b-2026' · admin → 'pulz-2026'
-- ---------------------------------------------------------------------
insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
                        raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
                        confirmation_token, recovery_token, email_change_token_new, email_change) values
  ('00000000-0000-0000-0000-000000000000', '74f5ca48-56b7-4364-9ae6-94079c521783', 'authenticated', 'authenticated', 'qa-5a4feb7d12bb4aae-tu@pulz.mx',
   extensions.crypt('pulz-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '091f0c17-2883-4127-8087-fe133ab13c62', 'authenticated', 'authenticated', 'qa-5a4feb7d12bb4aae-benito@cuatrovientos.mx',
   extensions.crypt('benito-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', 'e9d5e2f3-49ca-4a12-8c9f-cfeaee9e8f33', 'authenticated', 'authenticated', 'qa-5a4feb7d12bb4aae-aurelia@d0325d36-d707-4172-8b7b-3b3de3d63f37.usuarios.pulz.mx',
   extensions.crypt('aurelia-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', 'b1bafbd1-ef96-4c49-a3d0-c1b4325ce53c', 'authenticated', 'authenticated', 'qa-5a4feb7d12bb4aae-tomas.h@d0325d36-d707-4172-8b7b-3b3de3d63f37.usuarios.pulz.mx',
   extensions.crypt('tomas-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', 'f2130c91-1f59-4650-9a3d-57277da16fe1', 'authenticated', 'authenticated', 'qa-5a4feb7d12bb4aae-duena@pruebab.mx',
   extensions.crypt('qa-5a4feb7d12bb4aae-prueba-b-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '');

insert into profiles (id, full_name) values
  ('74f5ca48-56b7-4364-9ae6-94079c521783', 'Admin PULZ'),
  ('091f0c17-2883-4127-8087-fe133ab13c62', 'Benito Cruz'),
  ('e9d5e2f3-49ca-4a12-8c9f-cfeaee9e8f33', 'Aurelia Santiago'),
  ('b1bafbd1-ef96-4c49-a3d0-c1b4325ce53c', 'Tomás Hernández'),
  ('f2130c91-1f59-4650-9a3d-57277da16fe1', 'Dueña Prueba B');

insert into platform_admins (user_id) values ('74f5ca48-56b7-4364-9ae6-94079c521783');

-- Planes (§14, §18 #2 y #3)
-- Fixture: reutiliza plans canónica, sin modificarla.
-- Fixture: reutiliza plan_limits canónica, sin modificarla.
-- Fixture: reutiliza plan_features canónica, sin modificarla.

-- Empresas
insert into organizations (id, name, slug, state, brand_color, logo_path, welcome_message, created_by) values
  ('d0325d36-d707-4172-8b7b-3b3de3d63f37', 'Mezcal Cuatro Vientos', 'qa-5a4feb7d12bb4aae-cuatro-vientos', 'Oaxaca', '#7A3E1D', null, 'Registro de producción del palenque', '091f0c17-2883-4127-8087-fe133ab13c62'),
  ('af4268cd-2195-4d32-b1c4-82f19337f346', 'Palenque Prueba B', 'qa-5a4feb7d12bb4aae-prueba-b', 'Oaxaca', '#173F87', null, 'Empresa de prueba', 'f2130c91-1f59-4650-9a3d-57277da16fe1');
insert into organization_slug_history (slug, organization_id, retired_at, retired_by) values
  ('qa-5a4feb7d12bb4aae-mezcal-cuatro-vientos', 'd0325d36-d707-4172-8b7b-3b3de3d63f37', '2026-09-02 09:00:00-06', '091f0c17-2883-4127-8087-fe133ab13c62');
insert into organization_members (organization_id, user_id, role, status, username, must_change_password) values
  ('d0325d36-d707-4172-8b7b-3b3de3d63f37', '091f0c17-2883-4127-8087-fe133ab13c62', 'admin', 'activo', null, false),
  ('d0325d36-d707-4172-8b7b-3b3de3d63f37', 'e9d5e2f3-49ca-4a12-8c9f-cfeaee9e8f33', 'productor', 'activo', 'aurelia', false),
  ('d0325d36-d707-4172-8b7b-3b3de3d63f37', 'b1bafbd1-ef96-4c49-a3d0-c1b4325ce53c', 'operador', 'activo', 'tomas.h', true),
  ('af4268cd-2195-4d32-b1c4-82f19337f346', 'f2130c91-1f59-4650-9a3d-57277da16fe1', 'admin', 'activo', null, false);
insert into member_invitations (id, organization_id, user_id, token_hash, expires_at, used_at, created_by) values
  ('e9ffc1dd-3db8-4b4b-8eb6-d3bab9d05bdd', 'd0325d36-d707-4172-8b7b-3b3de3d63f37', 'b1bafbd1-ef96-4c49-a3d0-c1b4325ce53c', 'qa-5a4feb7d12bb4aae:SIMULADO', '2026-09-05 10:00:00-06', null, '091f0c17-2883-4127-8087-fe133ab13c62');
insert into login_throttle (user_id, failed_count, last_failed_at, locked_until) values
  ('b1bafbd1-ef96-4c49-a3d0-c1b4325ce53c', 3, '2026-09-03 07:12:00-06', null);
insert into organization_settings (organization_id, record_puntas, measurement_mode, warn_mixed_second_pass, fermentation_expected_days, measurement_reminder_hour, default_folio_decision) values
  ('d0325d36-d707-4172-8b7b-3b3de3d63f37', false, 'minimo', true, 7, 9, 'conservar'),
  ('af4268cd-2195-4d32-b1c4-82f19337f346', false, 'minimo', true, 7, 9, 'conservar');
insert into subscriptions (organization_id, plan_id, status, current_period_end) values
  ('d0325d36-d707-4172-8b7b-3b3de3d63f37', 'edd15bcf-ad82-5684-a2e7-d85db401885b', 'prueba', '2026-10-15 00:00:00-06'),
  ('af4268cd-2195-4d32-b1c4-82f19337f346', 'ee35d6fd-b4d6-56d6-b7b4-61cb81932b21', 'gratis', null);

-- ---------------------------------------------------------------------
-- Plantillas de plataforma (§10.2.1)
-- ---------------------------------------------------------------------
-- Fixture: reutiliza catalog_item_templates canónica, sin modificarla.
-- Fixture: reutiliza movement_concept_templates canónica, sin modificarla.
-- Fixture: reutiliza species_templates canónica, sin modificarla.

select seed_organization_catalogs('d0325d36-d707-4172-8b7b-3b3de3d63f37');
select seed_organization_catalogs('af4268cd-2195-4d32-b1c4-82f19337f346');

-- Lo propio de Cuatro Vientos y lo que oculta (§10.2.4)
insert into catalog_items (id, organization_id, template_id, catalog, name, sort_order, created_by) values
  ('3789315b-ce99-4850-8e07-f7b658638cf0', 'd0325d36-d707-4172-8b7b-3b3de3d63f37', null, 'tipo_alambique', 'Refrescadera de cobre', 100, '091f0c17-2883-4127-8087-fe133ab13c62');
insert into movement_concepts (id, organization_id, template_id, direction, name, source_lot, creates_lot, asks_result, asks_counterparty, sort_order, created_by) values
  ('79cbf8a9-1d63-4adf-8a2e-5d9689c9a9bc', 'd0325d36-d707-4172-8b7b-3b3de3d63f37', null, 'salida', 'Regalo a cliente', 'no_aplica', false, false, true, 100, '091f0c17-2883-4127-8087-fe133ab13c62');
update catalog_items set active = false
 where organization_id = 'd0325d36-d707-4172-8b7b-3b3de3d63f37'
   and template_id in ('5c985133-23d9-50fa-a252-6ff6b5b74134', 'b1fce67a-21bf-50a7-9344-fdf29eb5331e');
update movement_concepts set active = false
 where organization_id = 'd0325d36-d707-4172-8b7b-3b3de3d63f37'
   and template_id = '8b7f6579-99ef-549e-b427-b1d4d8bea9da';

-- ---------------------------------------------------------------------
-- Ayudas de la semilla (temporales; mueren con la sesión). security definer
-- para que resuelvan ids aunque el rol activo sea 'authenticated'.
-- ---------------------------------------------------------------------
create function pg_temp.seed_a() returns uuid language sql immutable as $$ select 'd0325d36-d707-4172-8b7b-3b3de3d63f37'::uuid $$;
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
  ('8bae1699-6f61-42ee-a14e-29c7448d6246', pg_temp.seed_a(), 'Loma del Toro', 'Santiago Matatlán', 'Familia Cruz');
insert into suppliers (id, organization_id, name, type_item_id) values
  ('7c0cab72-1d8a-424d-bf42-d7097b5564e6', pg_temp.seed_a(), 'Magueyes Don Pedro', pg_temp.seed_cat('640b537d-bf52-5c4b-b407-a5f4fb7c5800')),
  ('68a2f1d1-024b-458c-87e0-56278b54fb3a', pg_temp.seed_a(), 'Destilados Hermanos Luna', pg_temp.seed_cat('bb234638-3c78-56cd-9f41-2fb38182f181'));
insert into supplies (id, organization_id, name, unit_item_id) values
  ('0948901c-debc-4efc-88d8-6ea4f43c589f', pg_temp.seed_a(), 'Pulque como inóculo', pg_temp.seed_cat('bc6f104d-2841-5b36-b492-76b36becb172'));
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy, liquid_class) values
  ('f781b9b6-8f06-4811-9a67-2df028bff986', pg_temp.seed_a(), 'horno', 'Horno 1', pg_temp.seed_cat('d53ba2da-cada-5215-804a-ff304d569f97'), 10000, 'kg', 'libre', null),
  ('78e315f8-770f-4794-bc3e-0ecf0446b6e1', pg_temp.seed_a(), 'molino', 'Tahona', pg_temp.seed_cat('60285283-d000-52f0-95da-d2b2e6d70fa1'), null, 'kg', 'libre', null),
  ('c228891f-ba3b-4696-8637-c3a084ca9ac7', pg_temp.seed_a(), 'tina', 'Tina 1', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('3865dd0b-3f5a-4f92-84f0-a8ce7add9033', pg_temp.seed_a(), 'tina', 'Tina 2', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('2d2d0f98-216b-4c80-9a82-fbae699d20e9', pg_temp.seed_a(), 'tina', 'Tina 3', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('f7e519cd-af4e-431f-b96b-2448ad468193', pg_temp.seed_a(), 'alambique', 'Alambique 1', pg_temp.seed_cat('af73010e-53f2-5769-b3b1-6cda154e665e'), 300, 'L', 'estricta', null),
  ('e60ed2f1-4d10-469f-965d-adf6f1e5eb74', pg_temp.seed_a(), 'alambique', 'Alambique 2', '3789315b-ce99-4850-8e07-f7b658638cf0', 250, 'L', 'estricta', null),
  ('81827b3f-c08c-4c7a-b492-0190e03a7933', pg_temp.seed_a(), 'colector', 'Colector mezcal', pg_temp.seed_cat('2cd7e70b-6246-543e-8f67-23743fefdf95'), 60, 'L', 'flexible', 'mezcal'),
  ('f76daccd-8f87-4f12-951b-613a36282387', pg_temp.seed_a(), 'colector', 'Colector ordinario', pg_temp.seed_cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'ordinario'),
  ('3d5a379b-3db7-4cb6-a4b6-fa9c2ed7b948', pg_temp.seed_a(), 'colector', 'Colector colas', pg_temp.seed_cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'colas'),
  ('6da2a521-c8e3-4973-b1ff-11ab812ce4ad', pg_temp.seed_a(), 'tanque', 'Tanque 1', pg_temp.seed_cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1000, 'L', 'flexible', null),
  ('958d9964-5db8-4e5e-b5a7-094df7b9b09d', pg_temp.seed_a(), 'tanque', 'Tanque 2', pg_temp.seed_cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1500, 'L', 'flexible', null);

-- Palenque Prueba B: lo mínimo para probar aislamiento
insert into predios (id, organization_id, name, municipality) values
  ('a55a898f-105f-4fb7-8563-06298aedba62', 'af4268cd-2195-4d32-b1c4-82f19337f346', 'Predio B', 'Ejutla');
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy) values
  ('bbd5c94f-72bd-4dac-882c-05c124833301', 'af4268cd-2195-4d32-b1c4-82f19337f346', 'tina', 'Tina B1',
   (select id from catalog_items where organization_id = 'af4268cd-2195-4d32-b1c4-82f19337f346' and template_id = 'b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1000, 'L', 'flexible');

-- =====================================================================
-- Cuatro Vientos: la producción, POR RPC, en orden cronológico
-- =====================================================================

-- 2026-09-01 · Benito: lo que ya había en el Tanque 2 (carga inicial)
select pg_temp.seed_como('091f0c17-2883-4127-8087-fe133ab13c62');
select registrar_entrada(pg_temp.seed_a(), '2853df08-2735-4fb4-8ee9-7c77330d806e', '2026-09-01 10:15:00-06',
  'granel', pg_temp.seed_res('Tanque 2'), 600, 44.2, 'mezcal', 'carga_inicial',
  p_concepto => pg_temp.seed_con('255e79f1-12b3-5969-8453-e40623275559'),
  p_nota => 'Lo que ya había en el tanque al empezar', p_folio => 'G-INI-01');

-- 2026-09-01 · Aurelia: la Tina 3 ya fermentaba
select pg_temp.seed_como('e9d5e2f3-49ca-4a12-8c9f-cfeaee9e8f33');
select registrar_entrada(pg_temp.seed_a(), 'e008d9e6-a4b3-4d85-9f39-2180a048c730', '2026-09-01 10:40:00-06',
  'fermentado', pg_temp.seed_res('Tina 3'), 1300, null, null, 'carga_inicial',
  p_nota => 'Tina que ya fermentaba', p_folio => 'FER-T3-INI');

-- 2026-09-02 · Aurelia: recepción de maguey
select registrar_recepcion_maguey(pg_temp.seed_a(), '6907a6b7-9f64-4bc4-9085-debb3a7997ce', '2026-09-02 07:30:00-06',
  8000, pg_temp.seed_esp('67a96efd-2c72-528e-8682-d144fe1f802c'), '8bae1699-6f61-42ee-a14e-29c7448d6246',
  '7c0cab72-1d8a-424d-bf42-d7097b5564e6', 132, 'Piñas de 8 años, buen tamaño', 'MAG-001');

-- 2026-09-02 · Horneado (la simulación lo abría Tomás; §11.1 lo reserva a
-- admin/productor, así que lo abre Aurelia — docs/DECISIONES.md)
select abrir_horneado(pg_temp.seed_a(), '4b6365e2-3d5d-473d-972b-fb49d7dba9b6', '2026-09-02 12:00:00-06',
  pg_temp.seed_res('Horno 1'), array[pg_temp.seed_lot('MAG-001')], array[8000::numeric], p_folio => 'HOR-001');
-- 2026-09-06 · Aurelia cierra: 6,200 kg de agave cocido
select cerrar_horneado(pg_temp.seed_a(), 'b969d239-38c5-4363-850c-4c8cae9c63a2', '2026-09-06 08:00:00-06',
  pg_temp.seed_hor('HOR-001'), 6200, 'Leña de encino', p_folio => 'AC-001');

-- 2026-09-07 · Aurelia: formulación repartida a Tina 1 y Tina 2
select registrar_formulacion(pg_temp.seed_a(), '250f24de-a36e-4ae4-a706-c0a21f3c43a5', '2026-09-07 09:00:00-06',
  pg_temp.seed_res('Tahona'), array[pg_temp.seed_lot('AC-001')], array[6200::numeric], 1900,
  array[pg_temp.seed_res('Tina 1'), pg_temp.seed_res('Tina 2')], array[1400::numeric, 1400::numeric],
  array['0948901c-debc-4efc-88d8-6ea4f43c589f'::uuid], array[20::numeric],
  'Tahona con mula', null, 'F-001', array['FER-T1-001', 'FER-T2-001']);

-- Mediciones diarias (escala de actividad 1–6, §18 #1; la simulación traía 7 y 8)
-- Tina 1
select pg_temp.seed_como('b1bafbd1-ef96-4c49-a3d0-c1b4325ce53c');
select registrar_medicion(pg_temp.seed_a(), 'd439cb2b-d4b5-41e8-9dee-f5afc1dad794', '2026-09-08 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 1, 'minimo', 4,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.5,12.0]::numeric[]);
select pg_temp.seed_como('e9d5e2f3-49ca-4a12-8c9f-cfeaee9e8f33');
select registrar_medicion(pg_temp.seed_a(), 'cfae9fe2-e862-47ba-9124-214d50f5c2ab', '2026-09-09 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.0,9.5]::numeric[]);
select pg_temp.seed_como('b1bafbd1-ef96-4c49-a3d0-c1b4325ce53c');
select registrar_medicion(pg_temp.seed_a(), '42b7b78d-1609-43e5-b335-1d2ccc1fdfce', '2026-09-10 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.5,6.0]::numeric[]);
select pg_temp.seed_como('e9d5e2f3-49ca-4a12-8c9f-cfeaee9e8f33');
select registrar_medicion(pg_temp.seed_a(), '2e6c58e2-4728-4f55-a689-03b268adc788', '2026-09-11 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 4, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.5,3.5]::numeric[]);
select pg_temp.seed_como('b1bafbd1-ef96-4c49-a3d0-c1b4325ce53c');
select registrar_medicion(pg_temp.seed_a(), '782ac8f9-682c-4dbd-aba2-8a94f5fc018a', '2026-09-12 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 5, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.0,1.5]::numeric[]);
-- Tina 2
select registrar_medicion(pg_temp.seed_a(), 'd38cdff4-66d0-4a24-90b1-f24669d40b7f', '2026-09-08 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 1, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.0,12.2]::numeric[]);
select registrar_medicion(pg_temp.seed_a(), 'c1b8b5d5-ed4d-44c7-83c4-dde074696cde', '2026-09-09 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.5,10.1]::numeric[]);
select registrar_medicion(pg_temp.seed_a(), '7131afed-50b0-4364-bf4b-d4f3177ad887', '2026-09-10 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.0,7.4]::numeric[]);

-- 2026-09-12 · Aurelia declara lista la Tina 1
select pg_temp.seed_como('e9d5e2f3-49ca-4a12-8c9f-cfeaee9e8f33');
select declarar_tina_lista(pg_temp.seed_a(), '87c77ec3-d6d3-450c-aded-cfd9e5806990', '2026-09-12 17:00:00-06',
  pg_temp.seed_cyc('Tina 1'), 'Día 5: ya no burbujea, sabor seco');

-- 2026-09-13 · Tomás: dos corridas de 1ª pasada desde la Tina 1
select pg_temp.seed_como('b1bafbd1-ef96-4c49-a3d0-c1b4325ce53c');
select abrir_corrida(pg_temp.seed_a(), '375e8481-a89e-457f-8e50-2f647f3ce85a', '2026-09-13 06:00:00-06',
  pg_temp.seed_res('Alambique 1'), 'primera', array[pg_temp.seed_res('Tina 1')], array[pg_temp.seed_lot('FER-T1-001')], array[290::numeric],
  p_folio => 'DES-001');
select registrar_corte(pg_temp.seed_a(), '3a252b49-7c38-4cb5-b0f4-8301b392cc59', '2026-09-13 08:00:00-06', pg_temp.seed_run('DES-001'), 'mezcal', 8, 51.0, pg_temp.seed_res('Colector mezcal'), p_folio => 'MEZ-001');
select registrar_corte(pg_temp.seed_a(), 'e758512f-5ec0-4bb4-b2d5-7c8a49dfb36e', '2026-09-13 10:00:00-06', pg_temp.seed_run('DES-001'), 'ordinario', 40, 24.0, pg_temp.seed_res('Colector ordinario'), p_folio => 'ORD-001');
select registrar_corte(pg_temp.seed_a(), '74b88c05-53db-4c0e-9cb1-8fd1f8ccc2ae', '2026-09-13 12:00:00-06', pg_temp.seed_run('DES-001'), 'colas', 12, 9.0, pg_temp.seed_res('Colector colas'), p_folio => 'COL-001');
select cerrar_corrida(pg_temp.seed_a(), '28ec9558-c2ba-492a-a6da-712e447e811d', '2026-09-13 14:00:00-06', pg_temp.seed_run('DES-001'));

select abrir_corrida(pg_temp.seed_a(), '2551ad30-592a-4b19-aff8-a112c0379c14', '2026-09-13 06:00:00-06',
  pg_temp.seed_res('Alambique 2'), 'primera', array[pg_temp.seed_res('Tina 1')], array[pg_temp.seed_lot('FER-T1-001')], array[240::numeric],
  p_folio => 'DES-002');
select registrar_corte(pg_temp.seed_a(), '415ce2a5-d61e-4f7d-8531-8935e6ea8661', '2026-09-13 08:00:00-06', pg_temp.seed_run('DES-002'), 'mezcal', 6, 50.0, pg_temp.seed_res('Colector mezcal'));
select registrar_corte(pg_temp.seed_a(), '8884de43-8bbf-4212-ac54-6c31bf9a5d93', '2026-09-13 10:00:00-06', pg_temp.seed_run('DES-002'), 'ordinario', 34, 23.0, pg_temp.seed_res('Colector ordinario'));
select registrar_corte(pg_temp.seed_a(), 'e526a3e8-f122-4269-a911-62183884aa7c', '2026-09-13 12:00:00-06', pg_temp.seed_run('DES-002'), 'colas', 10, 8.0, pg_temp.seed_res('Colector colas'));
select cerrar_corrida(pg_temp.seed_a(), 'ea77e8b2-d19f-497f-9fd3-6d0774e8392a', '2026-09-13 14:00:00-06', pg_temp.seed_run('DES-002'));

-- 2026-09-15 · Tomás: 2ª pasada con ordinario y colas juntos (aviso + nota)
select abrir_corrida(pg_temp.seed_a(), 'c6537fa9-6646-4f85-a3ca-418b64318555', '2026-09-15 06:00:00-06',
  pg_temp.seed_res('Alambique 1'), 'segunda',
  array[pg_temp.seed_res('Colector ordinario'), pg_temp.seed_res('Colector colas')],
  array[pg_temp.seed_lot('ORD-001'), pg_temp.seed_lot('COL-001')], array[74::numeric, 22::numeric],
  'Había olla libre y poca cola; se juntó con el ordinario', 'DES-003');
select registrar_corte(pg_temp.seed_a(), '80d81869-469f-451f-b0ff-0fce797f9539', '2026-09-15 08:00:00-06', pg_temp.seed_run('DES-003'), 'mezcal', 26, 52.5, pg_temp.seed_res('Colector mezcal'));
select registrar_corte(pg_temp.seed_a(), '77b4c005-b0fc-4bb5-a08c-e56dc7375b86', '2026-09-15 10:00:00-06', pg_temp.seed_run('DES-003'), 'colas', 16, 10.0, pg_temp.seed_res('Colector colas'), p_folio => 'COL-002');
select cerrar_corrida(pg_temp.seed_a(), '8964a9b7-91af-49b1-a48c-284ae2ec5e22', '2026-09-15 14:00:00-06', pg_temp.seed_run('DES-003'));

-- 2026-09-16 · Aurelia: el mezcal del colector pasa a granel con folio nuevo
select pg_temp.seed_como('e9d5e2f3-49ca-4a12-8c9f-cfeaee9e8f33');
select transferir(pg_temp.seed_a(), '05baa055-29f7-4935-8e50-2670f037152c', '2026-09-16 09:00:00-06',
  pg_temp.seed_res('Colector mezcal'), pg_temp.seed_res('Tanque 1'), pg_temp.seed_lot('MEZ-001'), 40, 51.6, 'renombrar', 'G-2609-01');
-- Agua para bajar grado: 4 L, declara 43.8 L (contracción) y 47.0 %
select registrar_movimiento_granel(pg_temp.seed_a(), 'de546f49-3999-4938-be97-467745c730b2', '2026-09-16 11:00:00-06',
  pg_temp.seed_con('66a151e2-9a2c-58be-ad4a-b117f1ddb717'), pg_temp.seed_res('Tanque 1'), 4,
  p_lote => pg_temp.seed_lot('G-2609-01'), p_resultado_l => 43.8, p_resultado_abv => 47.0);

-- 2026-09-17 · Benito: puntas guardadas (sin lote) al Tanque 2
select pg_temp.seed_como('091f0c17-2883-4127-8087-fe133ab13c62');
select registrar_movimiento_granel(pg_temp.seed_a(), '88981784-e424-4d30-9927-63d1bd6020c6', '2026-09-17 10:00:00-06',
  pg_temp.seed_con('f21aaad8-2ef6-556b-be55-64aa94431ab6'), pg_temp.seed_res('Tanque 2'), 2,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_resultado_l => 602, p_resultado_abv => 44.6, p_abv => 68.0,
  p_nota => 'Puntas guardadas de corridas de agosto, sin lote');
-- 2026-09-18 · Benito: unión de G-2609-01 (Tanque 1) con G-INI-01 (Tanque 2), se conserva el folio mayor
select registrar_movimiento_granel(pg_temp.seed_a(), '3921d326-5d92-4502-8a7a-95e4116f54c5', '2026-09-18 09:30:00-06',
  pg_temp.seed_con('df427d88-600e-550e-a097-8ffe4f4dd556'), pg_temp.seed_res('Tanque 2'), 43.8,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_lote_origen => pg_temp.seed_lot('G-2609-01'), p_recurso_origen => pg_temp.seed_res('Tanque 1'),
  p_resultado_l => 645.8, p_resultado_abv => 44.9, p_decision => 'conservar', p_nota => 'Se conserva el folio del lote mayor');
-- 2026-09-19 · Benito: compra de granel al Tanque 1
select registrar_movimiento_granel(pg_temp.seed_a(), '1bbb36c3-6db6-44af-9e45-e40a06cf357e', '2026-09-19 12:00:00-06',
  pg_temp.seed_con('688430a9-cd2f-5bae-add2-c59bc543d911'), pg_temp.seed_res('Tanque 1'), 250,
  p_resultado_l => 250, p_resultado_abv => 46.0, p_abv => 46.0, p_folio_nuevo => 'G-COMPRA-01',
  p_contraparte => 'Destilados Hermanos Luna', p_documento => 'Remisión 0452',
  p_proveedor => '68a2f1d1-024b-458c-87e0-56278b54fb3a', p_especie => pg_temp.seed_esp('67a96efd-2c72-528e-8682-d144fe1f802c'),
  p_predio_declarado => 'Sola de Vega');

-- 2026-09-19 · Aurelia: muestra de laboratorio
select pg_temp.seed_como('e9d5e2f3-49ca-4a12-8c9f-cfeaee9e8f33');
select registrar_movimiento_granel(pg_temp.seed_a(), 'f4db0670-3046-4572-8995-03b53cbedfc5', '2026-09-19 13:00:00-06',
  pg_temp.seed_con('2d62ab89-6a11-558c-8b46-5c4d30aa1607'), pg_temp.seed_res('Tanque 2'), 1,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Laboratorio ficticio de Oaxaca', p_documento => 'Análisis 2026-311');

-- 2026-09-20/22 · Benito: autoconsumo, venta, regalo
select pg_temp.seed_como('091f0c17-2883-4127-8087-fe133ab13c62');
select registrar_movimiento_granel(pg_temp.seed_a(), 'e98d7717-699c-47bf-9362-7751e6948cc1', '2026-09-20 13:00:00-06',
  pg_temp.seed_con('fa52f92b-de19-5d0c-972c-beb899bb2ccb'), pg_temp.seed_res('Tanque 2'), 2, p_lote => pg_temp.seed_lot('G-INI-01'));
select registrar_movimiento_granel(pg_temp.seed_a(), 'ddb61ca5-ce97-4cb8-90a9-74a77b27e930', '2026-09-22 13:00:00-06',
  pg_temp.seed_con('7b0ca7ca-f8ae-5f33-93d5-f0c174664ec1'), pg_temp.seed_res('Tanque 2'), 300,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.', p_documento => 'Remisión 118');
select registrar_movimiento_granel(pg_temp.seed_a(), 'e6e2ffdd-5322-40cc-ac0c-64eb85b071d2', '2026-09-22 13:00:00-06',
  '79cbf8a9-1d63-4adf-8a2e-5d9689c9a9bc', pg_temp.seed_res('Tanque 2'), 1,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.');

reset role;

-- Evidencia de la compra (los adjuntos no son RPC de §12)
insert into attachments (id, organization_id, operation_id, lot_id, kind_item_id, storage_path, caption) values
  ('9d472796-8504-495b-8955-185de1a7554c', pg_temp.seed_a(),
   (select id from operations where organization_id = pg_temp.seed_a() and idempotency_key = '1bbb36c3-6db6-44af-9e45-e40a06cf357e'),
   pg_temp.seed_lot('G-COMPRA-01'), pg_temp.seed_cat('0522e23b-3b1d-58be-b50c-8a6ed0627c9f'),
   'evidencias/d0325d36-d707-4172-8b7b-3b3de3d63f37/g-compra-01/remision-0452.jpg', 'Remisión del proveedor');


-- pgTAP · Portal por empresa (PULZ_MAESTRO.md §7.3–§7.5): lo que ve alguien
-- sin sesión. portal_branding es lo único público (anon).
--     supabase db query --linked -f supabase/tests/portal.test.sql


create function pg_temp.test_portal() returns setof text language plpgsql as $$
declare a uuid := 'd0325d36-d707-4172-8b7b-3b3de3d63f37'; b uuid := 'af4268cd-2195-4d32-b1c4-82f19337f346';
begin
  -- Como anon (sin sesión), que es como llega el navegador y la Pages Function
  execute 'set local role anon';

  return next is((select name from portal_branding('qa-5a4feb7d12bb4aae-cuatro-vientos')), 'Mezcal Cuatro Vientos',
                 'portal_branding devuelve la marca por slug');
  return next is((select read_only from portal_branding('qa-5a4feb7d12bb4aae-cuatro-vientos')), false,
                 'suscripción en prueba → abierto');
  return next is((select redirect_to from portal_branding('qa-5a4feb7d12bb4aae-mezcal-cuatro-vientos')), 'qa-5a4feb7d12bb4aae-cuatro-vientos',
                 'el slug viejo redirige al actual (historial de slugs)');
  return next is((select name from portal_branding('qa-5a4feb7d12bb4aae-cuatro-vientos')), 'Mezcal Cuatro Vientos',
                 'el slug no distingue mayúsculas');
  return next is((select count(*) from portal_branding('no-existe')), 0::bigint,
                 'empresa inexistente: ninguna fila');
  -- anon ni siquiera tiene GRANT sobre las tablas de negocio (0013): 42501
  return next throws_ok($q$select count(*) from catalog_items$q$, '42501',
                 null, 'anon no lee nada de negocio por PostgREST (sin grant, no solo RLS)');
  return next throws_ok($q$select is_member('d0325d36-d707-4172-8b7b-3b3de3d63f37')$q$, '42501',
                 null, 'anon no puede ejecutar is_member (revocado)');

  execute 'reset role';
  -- vencida → sigue abierto pero en solo lectura; cancelada → como inexistente
  update subscriptions set status = 'vencida' where organization_id = b;
  execute 'set local role anon';
  return next is((select read_only from portal_branding('qa-5a4feb7d12bb4aae-prueba-b')), true, 'vencida → read_only');
  execute 'reset role';
  update subscriptions set status = 'cancelada' where organization_id = b;
  execute 'set local role anon';
  return next is((select count(*) from portal_branding('qa-5a4feb7d12bb4aae-prueba-b')), 0::bigint,
                 'cancelada → ninguna fila, idéntico a inexistente (§7.4)');
  execute 'reset role';

  -- has_role rechaza escrituras con suscripción vencida (§11.2)
  update subscriptions set status = 'vencida' where organization_id = a;
  execute 'set local role authenticated';
  execute $q$set local request.jwt.claims = '{"sub":"091f0c17-2883-4127-8087-fe133ab13c62","role":"authenticated"}'$q$;
  return next is((select has_role(a, array['admin']::member_role[])), false,
                 'vencida: has_role rechaza al admin (solo lectura)');
  return next is((select is_member(a)), true, 'vencida: is_member sigue en true (la lectura sigue)');
  execute 'reset role';
end $$;

select * from runtests((select nspname from pg_namespace where oid = pg_my_temp_schema())::name, '^test_');


rollback;
