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
-- tomas.h → 'tomas-2026' · dueña B → 'qa-cd0e326743ee4ec0-prueba-b-2026' · admin → 'pulz-2026'
-- ---------------------------------------------------------------------
insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
                        raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
                        confirmation_token, recovery_token, email_change_token_new, email_change) values
  ('00000000-0000-0000-0000-000000000000', 'c35251ca-dcd8-4e4c-9bbc-b65b5f7c8a13', 'authenticated', 'authenticated', 'qa-cd0e326743ee4ec0-tu@pulz.mx',
   extensions.crypt('pulz-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '7e2c67b0-cb82-445d-8296-40057162a654', 'authenticated', 'authenticated', 'qa-cd0e326743ee4ec0-benito@cuatrovientos.mx',
   extensions.crypt('benito-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '961b524e-0364-4939-a766-f54d790f21c0', 'authenticated', 'authenticated', 'qa-cd0e326743ee4ec0-aurelia@f7562921-80a4-46ab-8a72-c5f85b716be8.usuarios.pulz.mx',
   extensions.crypt('aurelia-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '9a8b7395-91d0-4145-a8f9-25bffd84d1d8', 'authenticated', 'authenticated', 'qa-cd0e326743ee4ec0-tomas.h@f7562921-80a4-46ab-8a72-c5f85b716be8.usuarios.pulz.mx',
   extensions.crypt('tomas-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', 'a8948bbc-13f8-48fb-99ad-b5d18b4fbcc1', 'authenticated', 'authenticated', 'qa-cd0e326743ee4ec0-duena@pruebab.mx',
   extensions.crypt('qa-cd0e326743ee4ec0-prueba-b-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '');

insert into profiles (id, full_name) values
  ('c35251ca-dcd8-4e4c-9bbc-b65b5f7c8a13', 'Admin PULZ'),
  ('7e2c67b0-cb82-445d-8296-40057162a654', 'Benito Cruz'),
  ('961b524e-0364-4939-a766-f54d790f21c0', 'Aurelia Santiago'),
  ('9a8b7395-91d0-4145-a8f9-25bffd84d1d8', 'Tomás Hernández'),
  ('a8948bbc-13f8-48fb-99ad-b5d18b4fbcc1', 'Dueña Prueba B');

insert into platform_admins (user_id) values ('c35251ca-dcd8-4e4c-9bbc-b65b5f7c8a13');

-- Planes (§14, §18 #2 y #3)
-- Fixture: reutiliza plans canónica, sin modificarla.
-- Fixture: reutiliza plan_limits canónica, sin modificarla.
-- Fixture: reutiliza plan_features canónica, sin modificarla.

-- Empresas
insert into organizations (id, name, slug, state, brand_color, logo_path, welcome_message, created_by) values
  ('f7562921-80a4-46ab-8a72-c5f85b716be8', 'Mezcal Cuatro Vientos', 'qa-cd0e326743ee4ec0-cuatro-vientos', 'Oaxaca', '#7A3E1D', null, 'Registro de producción del palenque', '7e2c67b0-cb82-445d-8296-40057162a654'),
  ('276ee1c6-4faa-4ba6-be09-b9b6db6f0471', 'Palenque Prueba B', 'qa-cd0e326743ee4ec0-prueba-b', 'Oaxaca', '#173F87', null, 'Empresa de prueba', 'a8948bbc-13f8-48fb-99ad-b5d18b4fbcc1');
insert into organization_slug_history (slug, organization_id, retired_at, retired_by) values
  ('qa-cd0e326743ee4ec0-mezcal-cuatro-vientos', 'f7562921-80a4-46ab-8a72-c5f85b716be8', '2026-09-02 09:00:00-06', '7e2c67b0-cb82-445d-8296-40057162a654');
insert into organization_members (organization_id, user_id, role, status, username, must_change_password) values
  ('f7562921-80a4-46ab-8a72-c5f85b716be8', '7e2c67b0-cb82-445d-8296-40057162a654', 'admin', 'activo', null, false),
  ('f7562921-80a4-46ab-8a72-c5f85b716be8', '961b524e-0364-4939-a766-f54d790f21c0', 'productor', 'activo', 'aurelia', false),
  ('f7562921-80a4-46ab-8a72-c5f85b716be8', '9a8b7395-91d0-4145-a8f9-25bffd84d1d8', 'operador', 'activo', 'tomas.h', true),
  ('276ee1c6-4faa-4ba6-be09-b9b6db6f0471', 'a8948bbc-13f8-48fb-99ad-b5d18b4fbcc1', 'admin', 'activo', null, false);
insert into member_invitations (id, organization_id, user_id, token_hash, expires_at, used_at, created_by) values
  ('41202d76-028f-4976-9770-75f9ae385e91', 'f7562921-80a4-46ab-8a72-c5f85b716be8', '9a8b7395-91d0-4145-a8f9-25bffd84d1d8', 'qa-cd0e326743ee4ec0:SIMULADO', '2026-09-05 10:00:00-06', null, '7e2c67b0-cb82-445d-8296-40057162a654');
insert into login_throttle (user_id, failed_count, last_failed_at, locked_until) values
  ('9a8b7395-91d0-4145-a8f9-25bffd84d1d8', 3, '2026-09-03 07:12:00-06', null);
insert into organization_settings (organization_id, record_puntas, measurement_mode, warn_mixed_second_pass, fermentation_expected_days, measurement_reminder_hour, default_folio_decision) values
  ('f7562921-80a4-46ab-8a72-c5f85b716be8', false, 'minimo', true, 7, 9, 'conservar'),
  ('276ee1c6-4faa-4ba6-be09-b9b6db6f0471', false, 'minimo', true, 7, 9, 'conservar');
insert into subscriptions (organization_id, plan_id, status, current_period_end) values
  ('f7562921-80a4-46ab-8a72-c5f85b716be8', 'edd15bcf-ad82-5684-a2e7-d85db401885b', 'prueba', '2026-10-15 00:00:00-06'),
  ('276ee1c6-4faa-4ba6-be09-b9b6db6f0471', 'ee35d6fd-b4d6-56d6-b7b4-61cb81932b21', 'gratis', null);

-- ---------------------------------------------------------------------
-- Plantillas de plataforma (§10.2.1)
-- ---------------------------------------------------------------------
-- Fixture: reutiliza catalog_item_templates canónica, sin modificarla.
-- Fixture: reutiliza movement_concept_templates canónica, sin modificarla.
-- Fixture: reutiliza species_templates canónica, sin modificarla.

select seed_organization_catalogs('f7562921-80a4-46ab-8a72-c5f85b716be8');
select seed_organization_catalogs('276ee1c6-4faa-4ba6-be09-b9b6db6f0471');

-- Lo propio de Cuatro Vientos y lo que oculta (§10.2.4)
insert into catalog_items (id, organization_id, template_id, catalog, name, sort_order, created_by) values
  ('a26f6c8b-e97c-463f-b421-4db0b4ef5ff5', 'f7562921-80a4-46ab-8a72-c5f85b716be8', null, 'tipo_alambique', 'Refrescadera de cobre', 100, '7e2c67b0-cb82-445d-8296-40057162a654');
insert into movement_concepts (id, organization_id, template_id, direction, name, source_lot, creates_lot, asks_result, asks_counterparty, sort_order, created_by) values
  ('6e6d19aa-ed25-40b1-a177-b3bc025a7db1', 'f7562921-80a4-46ab-8a72-c5f85b716be8', null, 'salida', 'Regalo a cliente', 'no_aplica', false, false, true, 100, '7e2c67b0-cb82-445d-8296-40057162a654');
update catalog_items set active = false
 where organization_id = 'f7562921-80a4-46ab-8a72-c5f85b716be8'
   and template_id in ('5c985133-23d9-50fa-a252-6ff6b5b74134', 'b1fce67a-21bf-50a7-9344-fdf29eb5331e');
update movement_concepts set active = false
 where organization_id = 'f7562921-80a4-46ab-8a72-c5f85b716be8'
   and template_id = '8b7f6579-99ef-549e-b427-b1d4d8bea9da';

-- ---------------------------------------------------------------------
-- Ayudas de la semilla (temporales; mueren con la sesión). security definer
-- para que resuelvan ids aunque el rol activo sea 'authenticated'.
-- ---------------------------------------------------------------------
create function pg_temp.seed_a() returns uuid language sql immutable as $$ select 'f7562921-80a4-46ab-8a72-c5f85b716be8'::uuid $$;
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
  ('a92ef1be-4050-4bf9-9b68-0157da975428', pg_temp.seed_a(), 'Loma del Toro', 'Santiago Matatlán', 'Familia Cruz');
insert into suppliers (id, organization_id, name, type_item_id) values
  ('137d7834-e3f4-4578-875b-d09d084ad48c', pg_temp.seed_a(), 'Magueyes Don Pedro', pg_temp.seed_cat('640b537d-bf52-5c4b-b407-a5f4fb7c5800')),
  ('4616bdac-a129-4486-8237-b2ed03721931', pg_temp.seed_a(), 'Destilados Hermanos Luna', pg_temp.seed_cat('bb234638-3c78-56cd-9f41-2fb38182f181'));
insert into supplies (id, organization_id, name, unit_item_id) values
  ('910b2a77-cc67-459a-99fe-8a20e33d188a', pg_temp.seed_a(), 'Pulque como inóculo', pg_temp.seed_cat('bc6f104d-2841-5b36-b492-76b36becb172'));
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy, liquid_class) values
  ('d3fa59e8-3dbe-481b-8775-97547686f3a9', pg_temp.seed_a(), 'horno', 'Horno 1', pg_temp.seed_cat('d53ba2da-cada-5215-804a-ff304d569f97'), 10000, 'kg', 'libre', null),
  ('beb3c1c0-40e1-4366-9e1f-f3476ed05ed2', pg_temp.seed_a(), 'molino', 'Tahona', pg_temp.seed_cat('60285283-d000-52f0-95da-d2b2e6d70fa1'), null, 'kg', 'libre', null),
  ('3bff6e06-79cc-40e7-a22e-e9314b8a22af', pg_temp.seed_a(), 'tina', 'Tina 1', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('23347a60-5e44-4e1a-84f6-1b8f73bddb30', pg_temp.seed_a(), 'tina', 'Tina 2', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('b678b22d-4847-42b4-baa4-dee8ca7e5123', pg_temp.seed_a(), 'tina', 'Tina 3', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('c38768c2-e53c-4416-8ea2-2de17adcd494', pg_temp.seed_a(), 'alambique', 'Alambique 1', pg_temp.seed_cat('af73010e-53f2-5769-b3b1-6cda154e665e'), 300, 'L', 'estricta', null),
  ('3c4032df-1c42-4f28-bfc5-9cde436cc2c6', pg_temp.seed_a(), 'alambique', 'Alambique 2', 'a26f6c8b-e97c-463f-b421-4db0b4ef5ff5', 250, 'L', 'estricta', null),
  ('da56234f-c55d-49e1-a8d5-b3b017682ec7', pg_temp.seed_a(), 'colector', 'Colector mezcal', pg_temp.seed_cat('2cd7e70b-6246-543e-8f67-23743fefdf95'), 60, 'L', 'flexible', 'mezcal'),
  ('2d015822-81b7-4367-a5aa-76ea414a7221', pg_temp.seed_a(), 'colector', 'Colector ordinario', pg_temp.seed_cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'ordinario'),
  ('7b90adfe-f3ba-4273-8745-5441fe475ff4', pg_temp.seed_a(), 'colector', 'Colector colas', pg_temp.seed_cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'colas'),
  ('89b71a40-3bce-4b50-bac5-940c35dc7bc0', pg_temp.seed_a(), 'tanque', 'Tanque 1', pg_temp.seed_cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1000, 'L', 'flexible', null),
  ('36c2bf93-ca53-407c-b695-83becc9c9513', pg_temp.seed_a(), 'tanque', 'Tanque 2', pg_temp.seed_cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1500, 'L', 'flexible', null);

-- Palenque Prueba B: lo mínimo para probar aislamiento
insert into predios (id, organization_id, name, municipality) values
  ('72b62f49-5a89-4665-ad37-52b0b94bcbdf', '276ee1c6-4faa-4ba6-be09-b9b6db6f0471', 'Predio B', 'Ejutla');
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy) values
  ('c77b0f4f-2a5e-4327-ac01-2643aa6ca826', '276ee1c6-4faa-4ba6-be09-b9b6db6f0471', 'tina', 'Tina B1',
   (select id from catalog_items where organization_id = '276ee1c6-4faa-4ba6-be09-b9b6db6f0471' and template_id = 'b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1000, 'L', 'flexible');

-- =====================================================================
-- Cuatro Vientos: la producción, POR RPC, en orden cronológico
-- =====================================================================

-- 2026-09-01 · Benito: lo que ya había en el Tanque 2 (carga inicial)
select pg_temp.seed_como('7e2c67b0-cb82-445d-8296-40057162a654');
select registrar_entrada(pg_temp.seed_a(), '5eeb0796-89ef-4360-9678-98fe3159b218', '2026-09-01 10:15:00-06',
  'granel', pg_temp.seed_res('Tanque 2'), 600, 44.2, 'mezcal', 'carga_inicial',
  p_concepto => pg_temp.seed_con('255e79f1-12b3-5969-8453-e40623275559'),
  p_nota => 'Lo que ya había en el tanque al empezar', p_folio => 'G-INI-01');

-- 2026-09-01 · Aurelia: la Tina 3 ya fermentaba
select pg_temp.seed_como('961b524e-0364-4939-a766-f54d790f21c0');
select registrar_entrada(pg_temp.seed_a(), '501475d3-4c2b-4d92-a392-5d0de2aa911e', '2026-09-01 10:40:00-06',
  'fermentado', pg_temp.seed_res('Tina 3'), 1300, null, null, 'carga_inicial',
  p_nota => 'Tina que ya fermentaba', p_folio => 'FER-T3-INI');

-- 2026-09-02 · Aurelia: recepción de maguey
select registrar_recepcion_maguey(pg_temp.seed_a(), '3be19749-dc0c-4ae9-80d2-c274677af6c7', '2026-09-02 07:30:00-06',
  8000, pg_temp.seed_esp('67a96efd-2c72-528e-8682-d144fe1f802c'), 'a92ef1be-4050-4bf9-9b68-0157da975428',
  '137d7834-e3f4-4578-875b-d09d084ad48c', 132, 'Piñas de 8 años, buen tamaño', 'MAG-001');

-- 2026-09-02 · Horneado (la simulación lo abría Tomás; §11.1 lo reserva a
-- admin/productor, así que lo abre Aurelia — docs/DECISIONES.md)
select abrir_horneado(pg_temp.seed_a(), '8a8531e1-d0be-4785-8acd-4290d60cc0e6', '2026-09-02 12:00:00-06',
  pg_temp.seed_res('Horno 1'), array[pg_temp.seed_lot('MAG-001')], array[8000::numeric], p_folio => 'HOR-001');
-- 2026-09-06 · Aurelia cierra: 6,200 kg de agave cocido
select cerrar_horneado(pg_temp.seed_a(), '971d1333-1502-400c-b616-ca2878f2ed0a', '2026-09-06 08:00:00-06',
  pg_temp.seed_hor('HOR-001'), 6200, 'Leña de encino', p_folio => 'AC-001');

-- 2026-09-07 · Aurelia: formulación repartida a Tina 1 y Tina 2
select registrar_formulacion(pg_temp.seed_a(), '296ed2fb-f0a5-4762-9f39-0faa1b50eb55', '2026-09-07 09:00:00-06',
  pg_temp.seed_res('Tahona'), array[pg_temp.seed_lot('AC-001')], array[6200::numeric], 1900,
  array[pg_temp.seed_res('Tina 1'), pg_temp.seed_res('Tina 2')], array[1400::numeric, 1400::numeric],
  array['910b2a77-cc67-459a-99fe-8a20e33d188a'::uuid], array[20::numeric],
  'Tahona con mula', null, 'F-001', array['FER-T1-001', 'FER-T2-001']);

-- Mediciones diarias (escala de actividad 1–6, §18 #1; la simulación traía 7 y 8)
-- Tina 1
select pg_temp.seed_como('9a8b7395-91d0-4145-a8f9-25bffd84d1d8');
select registrar_medicion(pg_temp.seed_a(), '7152f1c5-ff94-411b-9cca-d9ebce1c7cc3', '2026-09-08 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 1, 'minimo', 4,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.5,12.0]::numeric[]);
select pg_temp.seed_como('961b524e-0364-4939-a766-f54d790f21c0');
select registrar_medicion(pg_temp.seed_a(), '6c3bd535-2954-49d5-bc29-544e8d8ffa7f', '2026-09-09 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.0,9.5]::numeric[]);
select pg_temp.seed_como('9a8b7395-91d0-4145-a8f9-25bffd84d1d8');
select registrar_medicion(pg_temp.seed_a(), 'e1958014-0d51-437e-a858-9c8bec7a5ee5', '2026-09-10 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.5,6.0]::numeric[]);
select pg_temp.seed_como('961b524e-0364-4939-a766-f54d790f21c0');
select registrar_medicion(pg_temp.seed_a(), 'c95f4d28-04c1-4659-8fd1-9df80f2ece3d', '2026-09-11 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 4, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.5,3.5]::numeric[]);
select pg_temp.seed_como('9a8b7395-91d0-4145-a8f9-25bffd84d1d8');
select registrar_medicion(pg_temp.seed_a(), '4c5e07bf-706c-4063-85b2-013b6bf596ea', '2026-09-12 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 5, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.0,1.5]::numeric[]);
-- Tina 2
select registrar_medicion(pg_temp.seed_a(), 'c9d17e9e-451f-41b4-93da-18ccab811050', '2026-09-08 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 1, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.0,12.2]::numeric[]);
select registrar_medicion(pg_temp.seed_a(), '49c6e6dd-49c4-4e61-80b5-9b7996f14153', '2026-09-09 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.5,10.1]::numeric[]);
select registrar_medicion(pg_temp.seed_a(), '1f9c6583-510a-48e4-ad13-9b5bec6e00de', '2026-09-10 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.0,7.4]::numeric[]);

-- 2026-09-12 · Aurelia declara lista la Tina 1
select pg_temp.seed_como('961b524e-0364-4939-a766-f54d790f21c0');
select declarar_tina_lista(pg_temp.seed_a(), '3c335ad3-8eb6-44f7-bce2-591e7f99ad75', '2026-09-12 17:00:00-06',
  pg_temp.seed_cyc('Tina 1'), 'Día 5: ya no burbujea, sabor seco');

-- 2026-09-13 · Tomás: dos corridas de 1ª pasada desde la Tina 1
select pg_temp.seed_como('9a8b7395-91d0-4145-a8f9-25bffd84d1d8');
select abrir_corrida(pg_temp.seed_a(), '71f9179f-f50a-4fea-93a3-34f52c339795', '2026-09-13 06:00:00-06',
  pg_temp.seed_res('Alambique 1'), 'primera', array[pg_temp.seed_res('Tina 1')], array[pg_temp.seed_lot('FER-T1-001')], array[290::numeric],
  p_folio => 'DES-001');
select registrar_corte(pg_temp.seed_a(), 'c1584baf-678a-4514-9c30-a4413c83764d', '2026-09-13 08:00:00-06', pg_temp.seed_run('DES-001'), 'mezcal', 8, 51.0, pg_temp.seed_res('Colector mezcal'), p_folio => 'MEZ-001');
select registrar_corte(pg_temp.seed_a(), 'af1ed5a6-71ac-44f6-bd2e-eae90fa62433', '2026-09-13 10:00:00-06', pg_temp.seed_run('DES-001'), 'ordinario', 40, 24.0, pg_temp.seed_res('Colector ordinario'), p_folio => 'ORD-001');
select registrar_corte(pg_temp.seed_a(), '7211629b-9a15-4269-b86e-8f2a2283b91b', '2026-09-13 12:00:00-06', pg_temp.seed_run('DES-001'), 'colas', 12, 9.0, pg_temp.seed_res('Colector colas'), p_folio => 'COL-001');
select cerrar_corrida(pg_temp.seed_a(), 'c3f29b58-4ed6-4830-83a5-c4769b715611', '2026-09-13 14:00:00-06', pg_temp.seed_run('DES-001'));

select abrir_corrida(pg_temp.seed_a(), '7ed4b9c4-fc74-48dc-8da2-f0c12483e152', '2026-09-13 06:00:00-06',
  pg_temp.seed_res('Alambique 2'), 'primera', array[pg_temp.seed_res('Tina 1')], array[pg_temp.seed_lot('FER-T1-001')], array[240::numeric],
  p_folio => 'DES-002');
select registrar_corte(pg_temp.seed_a(), '21129346-6bd2-4b54-8e45-fdbd4328baee', '2026-09-13 08:00:00-06', pg_temp.seed_run('DES-002'), 'mezcal', 6, 50.0, pg_temp.seed_res('Colector mezcal'));
select registrar_corte(pg_temp.seed_a(), '2fd5bc15-d5cf-4df6-82cf-2a650c355eab', '2026-09-13 10:00:00-06', pg_temp.seed_run('DES-002'), 'ordinario', 34, 23.0, pg_temp.seed_res('Colector ordinario'));
select registrar_corte(pg_temp.seed_a(), 'bd219569-ee79-4e86-bef9-edd578a1d430', '2026-09-13 12:00:00-06', pg_temp.seed_run('DES-002'), 'colas', 10, 8.0, pg_temp.seed_res('Colector colas'));
select cerrar_corrida(pg_temp.seed_a(), '984e3acb-ee4e-4cc3-bae6-dfc3d4676700', '2026-09-13 14:00:00-06', pg_temp.seed_run('DES-002'));

-- 2026-09-15 · Tomás: 2ª pasada con ordinario y colas juntos (aviso + nota)
select abrir_corrida(pg_temp.seed_a(), '5525704f-4a5b-42af-9513-fd80fbc2cd7f', '2026-09-15 06:00:00-06',
  pg_temp.seed_res('Alambique 1'), 'segunda',
  array[pg_temp.seed_res('Colector ordinario'), pg_temp.seed_res('Colector colas')],
  array[pg_temp.seed_lot('ORD-001'), pg_temp.seed_lot('COL-001')], array[74::numeric, 22::numeric],
  'Había olla libre y poca cola; se juntó con el ordinario', 'DES-003');
select registrar_corte(pg_temp.seed_a(), '0de5f4eb-28f0-4759-bbdb-5a7e07eb248d', '2026-09-15 08:00:00-06', pg_temp.seed_run('DES-003'), 'mezcal', 26, 52.5, pg_temp.seed_res('Colector mezcal'));
select registrar_corte(pg_temp.seed_a(), 'c17c300d-122a-46be-9d63-1dcf1f4f9f77', '2026-09-15 10:00:00-06', pg_temp.seed_run('DES-003'), 'colas', 16, 10.0, pg_temp.seed_res('Colector colas'), p_folio => 'COL-002');
select cerrar_corrida(pg_temp.seed_a(), '0ceade81-c95c-49af-b527-4f4b934b140c', '2026-09-15 14:00:00-06', pg_temp.seed_run('DES-003'));

-- 2026-09-16 · Aurelia: el mezcal del colector pasa a granel con folio nuevo
select pg_temp.seed_como('961b524e-0364-4939-a766-f54d790f21c0');
select transferir(pg_temp.seed_a(), '7d62562c-03bb-4c0e-92f0-b68344caa1db', '2026-09-16 09:00:00-06',
  pg_temp.seed_res('Colector mezcal'), pg_temp.seed_res('Tanque 1'), pg_temp.seed_lot('MEZ-001'), 40, 51.6, 'renombrar', 'G-2609-01');
-- Agua para bajar grado: 4 L, declara 43.8 L (contracción) y 47.0 %
select registrar_movimiento_granel(pg_temp.seed_a(), '1118d97d-4dcf-42d4-9d70-d8a8c9149a03', '2026-09-16 11:00:00-06',
  pg_temp.seed_con('66a151e2-9a2c-58be-ad4a-b117f1ddb717'), pg_temp.seed_res('Tanque 1'), 4,
  p_lote => pg_temp.seed_lot('G-2609-01'), p_resultado_l => 43.8, p_resultado_abv => 47.0);

-- 2026-09-17 · Benito: puntas guardadas (sin lote) al Tanque 2
select pg_temp.seed_como('7e2c67b0-cb82-445d-8296-40057162a654');
select registrar_movimiento_granel(pg_temp.seed_a(), 'd9cabe0d-dd77-4b24-b08d-6344030c6d73', '2026-09-17 10:00:00-06',
  pg_temp.seed_con('f21aaad8-2ef6-556b-be55-64aa94431ab6'), pg_temp.seed_res('Tanque 2'), 2,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_resultado_l => 602, p_resultado_abv => 44.6, p_abv => 68.0,
  p_nota => 'Puntas guardadas de corridas de agosto, sin lote');
-- 2026-09-18 · Benito: unión de G-2609-01 (Tanque 1) con G-INI-01 (Tanque 2), se conserva el folio mayor
select registrar_movimiento_granel(pg_temp.seed_a(), '0740a0a5-14b1-4301-b59e-aae11319d5d8', '2026-09-18 09:30:00-06',
  pg_temp.seed_con('df427d88-600e-550e-a097-8ffe4f4dd556'), pg_temp.seed_res('Tanque 2'), 43.8,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_lote_origen => pg_temp.seed_lot('G-2609-01'), p_recurso_origen => pg_temp.seed_res('Tanque 1'),
  p_resultado_l => 645.8, p_resultado_abv => 44.9, p_decision => 'conservar', p_nota => 'Se conserva el folio del lote mayor');
-- 2026-09-19 · Benito: compra de granel al Tanque 1
select registrar_movimiento_granel(pg_temp.seed_a(), '7c5f1acb-244c-4e07-9e6d-b036035b5069', '2026-09-19 12:00:00-06',
  pg_temp.seed_con('688430a9-cd2f-5bae-add2-c59bc543d911'), pg_temp.seed_res('Tanque 1'), 250,
  p_resultado_l => 250, p_resultado_abv => 46.0, p_abv => 46.0, p_folio_nuevo => 'G-COMPRA-01',
  p_contraparte => 'Destilados Hermanos Luna', p_documento => 'Remisión 0452',
  p_proveedor => '4616bdac-a129-4486-8237-b2ed03721931', p_especie => pg_temp.seed_esp('67a96efd-2c72-528e-8682-d144fe1f802c'),
  p_predio_declarado => 'Sola de Vega');

-- 2026-09-19 · Aurelia: muestra de laboratorio
select pg_temp.seed_como('961b524e-0364-4939-a766-f54d790f21c0');
select registrar_movimiento_granel(pg_temp.seed_a(), 'd5ab3450-cc64-4e40-94c6-380c5e50e7cb', '2026-09-19 13:00:00-06',
  pg_temp.seed_con('2d62ab89-6a11-558c-8b46-5c4d30aa1607'), pg_temp.seed_res('Tanque 2'), 1,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Laboratorio ficticio de Oaxaca', p_documento => 'Análisis 2026-311');

-- 2026-09-20/22 · Benito: autoconsumo, venta, regalo
select pg_temp.seed_como('7e2c67b0-cb82-445d-8296-40057162a654');
select registrar_movimiento_granel(pg_temp.seed_a(), 'f862d017-14b3-4714-b890-58beb614029e', '2026-09-20 13:00:00-06',
  pg_temp.seed_con('fa52f92b-de19-5d0c-972c-beb899bb2ccb'), pg_temp.seed_res('Tanque 2'), 2, p_lote => pg_temp.seed_lot('G-INI-01'));
select registrar_movimiento_granel(pg_temp.seed_a(), 'c9076e6f-414d-432f-aa9e-e3bdca7094b2', '2026-09-22 13:00:00-06',
  pg_temp.seed_con('7b0ca7ca-f8ae-5f33-93d5-f0c174664ec1'), pg_temp.seed_res('Tanque 2'), 300,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.', p_documento => 'Remisión 118');
select registrar_movimiento_granel(pg_temp.seed_a(), 'cff6b2f2-7b5d-4dc4-8ff1-d82cd3e6d9b0', '2026-09-22 13:00:00-06',
  '6e6d19aa-ed25-40b1-a177-b3bc025a7db1', pg_temp.seed_res('Tanque 2'), 1,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.');

reset role;

-- Evidencia de la compra (los adjuntos no son RPC de §12)
insert into attachments (id, organization_id, operation_id, lot_id, kind_item_id, storage_path, caption) values
  ('0b2d0172-f43c-4043-90af-885c0edf0774', pg_temp.seed_a(),
   (select id from operations where organization_id = pg_temp.seed_a() and idempotency_key = '7c5f1acb-244c-4e07-9e6d-b036035b5069'),
   pg_temp.seed_lot('G-COMPRA-01'), pg_temp.seed_cat('0522e23b-3b1d-58be-b50c-8a6ed0627c9f'),
   'evidencias/f7562921-80a4-46ab-8a72-c5f85b716be8/g-compra-01/remision-0452.jpg', 'Remisión del proveedor');


-- pgTAP · equipo_miembros (0023): solo el administrador activo de la empresa
-- ve a su gente; bloqueo y vigencia del enlace derivados, nunca el token.
--     supabase db query --linked -f supabase/tests/equipo_miembros.test.sql


create function pg_temp.como(u uuid) returns void language plpgsql as $$
begin
  execute 'set local role authenticated';
  execute format('set local request.jwt.claims = %L', json_build_object('sub', u, 'role', 'authenticated')::text);
end $$;

create function pg_temp.test_equipo_miembros() returns setof text language plpgsql as $$
declare a uuid := 'f7562921-80a4-46ab-8a72-c5f85b716be8'; b uuid := '276ee1c6-4faa-4ba6-be09-b9b6db6f0471';
begin
  -- operador de A: no
  perform pg_temp.como('9a8b7395-91d0-4145-a8f9-25bffd84d1d8');
  return next throws_like(format($q$select * from equipo_miembros('%s')$q$, a), 'NO_PERMITIDO:%',
                          'un operador no ve el equipo');
  -- productora de A: no
  perform pg_temp.como('961b524e-0364-4939-a766-f54d790f21c0');
  return next throws_like(format($q$select * from equipo_miembros('%s')$q$, a), 'NO_PERMITIDO:%',
                          'una productora no ve el equipo');
  -- admin de B pidiendo A: no
  perform pg_temp.como('a8948bbc-13f8-48fb-99ad-b5d18b4fbcc1');
  return next throws_like(format($q$select * from equipo_miembros('%s')$q$, a), 'NO_PERMITIDO:%',
                          'el admin de otra empresa no ve el equipo de A');
  return next is((select count(*) from equipo_miembros(b)), 1::bigint, 'el admin de B ve a su única persona');

  -- admin de A: sí, con bloqueo y vigencia derivados
  perform pg_temp.como('7e2c67b0-cb82-445d-8296-40057162a654');
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
  perform pg_temp.como('7e2c67b0-cb82-445d-8296-40057162a654');
  return next is((select count(*) from equipo_miembros(a)), 3::bigint, 'con suscripción vencida el admin sigue viendo el equipo');
  execute 'reset role';
end $$;

select * from runtests((select nspname from pg_namespace where oid = pg_my_temp_schema())::name, '^test_');


rollback;
