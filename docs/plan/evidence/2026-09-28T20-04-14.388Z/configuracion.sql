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
-- tomas.h → 'tomas-2026' · dueña B → 'qa-e17042f4f1bd-prueba-b-2026' · admin → 'pulz-2026'
-- ---------------------------------------------------------------------
insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
                        raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
                        confirmation_token, recovery_token, email_change_token_new, email_change) values
  ('00000000-0000-0000-0000-000000000000', 'fda121af-c8d4-47ff-8655-90e44f256bae', 'authenticated', 'authenticated', 'qa-e17042f4f1bd-tu@pulz.mx',
   extensions.crypt('pulz-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '1cd1ed69-372c-45dd-a8b3-677d2b83d1d1', 'authenticated', 'authenticated', 'qa-e17042f4f1bd-benito@cuatrovientos.mx',
   extensions.crypt('benito-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '2e636fed-5c84-4775-969f-84d2823fbb0c', 'authenticated', 'authenticated', 'qa-e17042f4f1bd-aurelia@5a84f223-81a5-473c-ae36-bf2404abcd35.usuarios.pulz.mx',
   extensions.crypt('aurelia-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '6ae8e54a-1da4-47e1-a94c-ef77f9f03e6e', 'authenticated', 'authenticated', 'qa-e17042f4f1bd-tomas.h@5a84f223-81a5-473c-ae36-bf2404abcd35.usuarios.pulz.mx',
   extensions.crypt('tomas-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', 'e6be5a73-c721-4c3f-b38e-bff2ac9d3117', 'authenticated', 'authenticated', 'qa-e17042f4f1bd-duena@pruebab.mx',
   extensions.crypt('qa-e17042f4f1bd-prueba-b-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '');

insert into profiles (id, full_name) values
  ('fda121af-c8d4-47ff-8655-90e44f256bae', 'Admin PULZ'),
  ('1cd1ed69-372c-45dd-a8b3-677d2b83d1d1', 'Benito Cruz'),
  ('2e636fed-5c84-4775-969f-84d2823fbb0c', 'Aurelia Santiago'),
  ('6ae8e54a-1da4-47e1-a94c-ef77f9f03e6e', 'Tomás Hernández'),
  ('e6be5a73-c721-4c3f-b38e-bff2ac9d3117', 'Dueña Prueba B');

insert into platform_admins (user_id) values ('fda121af-c8d4-47ff-8655-90e44f256bae');

-- Planes (§14, §18 #2 y #3)
-- Fixture: reutiliza plans canónica, sin modificarla.
-- Fixture: reutiliza plan_limits canónica, sin modificarla.
-- Fixture: reutiliza plan_features canónica, sin modificarla.

-- Empresas
insert into organizations (id, name, slug, state, brand_color, logo_path, welcome_message, created_by) values
  ('5a84f223-81a5-473c-ae36-bf2404abcd35', 'Mezcal Cuatro Vientos', 'qa-e17042f4f1bd-cuatro-vientos', 'Oaxaca', '#7A3E1D', null, 'Registro de producción del palenque', '1cd1ed69-372c-45dd-a8b3-677d2b83d1d1'),
  ('9335fe2f-4473-451d-9319-d2a9cc350e37', 'Palenque Prueba B', 'qa-e17042f4f1bd-prueba-b', 'Oaxaca', '#173F87', null, 'Empresa de prueba', 'e6be5a73-c721-4c3f-b38e-bff2ac9d3117');
insert into organization_slug_history (slug, organization_id, retired_at, retired_by) values
  ('qa-e17042f4f1bd-mezcal-cuatro-vientos', '5a84f223-81a5-473c-ae36-bf2404abcd35', '2026-09-02 09:00:00-06', '1cd1ed69-372c-45dd-a8b3-677d2b83d1d1');
insert into organization_members (organization_id, user_id, role, status, username, must_change_password) values
  ('5a84f223-81a5-473c-ae36-bf2404abcd35', '1cd1ed69-372c-45dd-a8b3-677d2b83d1d1', 'admin', 'activo', null, false),
  ('5a84f223-81a5-473c-ae36-bf2404abcd35', '2e636fed-5c84-4775-969f-84d2823fbb0c', 'productor', 'activo', 'aurelia', false),
  ('5a84f223-81a5-473c-ae36-bf2404abcd35', '6ae8e54a-1da4-47e1-a94c-ef77f9f03e6e', 'operador', 'activo', 'tomas.h', true),
  ('9335fe2f-4473-451d-9319-d2a9cc350e37', 'e6be5a73-c721-4c3f-b38e-bff2ac9d3117', 'admin', 'activo', null, false);
insert into member_invitations (id, organization_id, user_id, token_hash, expires_at, used_at, created_by) values
  ('9aac1e7a-dba4-4c25-bb2a-b1dcdff864d8', '5a84f223-81a5-473c-ae36-bf2404abcd35', '6ae8e54a-1da4-47e1-a94c-ef77f9f03e6e', 'qa-e17042f4f1bd:SIMULADO', '2026-09-05 10:00:00-06', null, '1cd1ed69-372c-45dd-a8b3-677d2b83d1d1');
insert into login_throttle (user_id, failed_count, last_failed_at, locked_until) values
  ('6ae8e54a-1da4-47e1-a94c-ef77f9f03e6e', 3, '2026-09-03 07:12:00-06', null);
insert into organization_settings (organization_id, record_puntas, measurement_mode, warn_mixed_second_pass, fermentation_expected_days, measurement_reminder_hour, default_folio_decision) values
  ('5a84f223-81a5-473c-ae36-bf2404abcd35', false, 'minimo', true, 7, 9, 'conservar'),
  ('9335fe2f-4473-451d-9319-d2a9cc350e37', false, 'minimo', true, 7, 9, 'conservar');
insert into subscriptions (organization_id, plan_id, status, current_period_end) values
  ('5a84f223-81a5-473c-ae36-bf2404abcd35', 'edd15bcf-ad82-5684-a2e7-d85db401885b', 'prueba', '2026-10-15 00:00:00-06'),
  ('9335fe2f-4473-451d-9319-d2a9cc350e37', 'ee35d6fd-b4d6-56d6-b7b4-61cb81932b21', 'gratis', null);

-- ---------------------------------------------------------------------
-- Plantillas de plataforma (§10.2.1)
-- ---------------------------------------------------------------------
-- Fixture: reutiliza catalog_item_templates canónica, sin modificarla.
-- Fixture: reutiliza movement_concept_templates canónica, sin modificarla.
-- Fixture: reutiliza species_templates canónica, sin modificarla.

select seed_organization_catalogs('5a84f223-81a5-473c-ae36-bf2404abcd35');
select seed_organization_catalogs('9335fe2f-4473-451d-9319-d2a9cc350e37');

-- Lo propio de Cuatro Vientos y lo que oculta (§10.2.4)
insert into catalog_items (id, organization_id, template_id, catalog, name, sort_order, created_by) values
  ('9ca61775-ad0b-4305-ad50-efb918f862d7', '5a84f223-81a5-473c-ae36-bf2404abcd35', null, 'tipo_alambique', 'Refrescadera de cobre', 100, '1cd1ed69-372c-45dd-a8b3-677d2b83d1d1');
insert into movement_concepts (id, organization_id, template_id, direction, name, source_lot, creates_lot, asks_result, asks_counterparty, sort_order, created_by) values
  ('ee077b46-10cf-47ec-834f-c3ac2a0c3b98', '5a84f223-81a5-473c-ae36-bf2404abcd35', null, 'salida', 'Regalo a cliente', 'no_aplica', false, false, true, 100, '1cd1ed69-372c-45dd-a8b3-677d2b83d1d1');
update catalog_items set active = false
 where organization_id = '5a84f223-81a5-473c-ae36-bf2404abcd35'
   and template_id in ('5c985133-23d9-50fa-a252-6ff6b5b74134', 'b1fce67a-21bf-50a7-9344-fdf29eb5331e');
update movement_concepts set active = false
 where organization_id = '5a84f223-81a5-473c-ae36-bf2404abcd35'
   and template_id = '8b7f6579-99ef-549e-b427-b1d4d8bea9da';

-- ---------------------------------------------------------------------
-- Ayudas de la semilla (temporales; mueren con la sesión). security definer
-- para que resuelvan ids aunque el rol activo sea 'authenticated'.
-- ---------------------------------------------------------------------
create function pg_temp.seed_a() returns uuid language sql immutable as $$ select '5a84f223-81a5-473c-ae36-bf2404abcd35'::uuid $$;
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
  ('7b88f02d-a364-4126-801f-58bce5e08b08', pg_temp.seed_a(), 'Loma del Toro', 'Santiago Matatlán', 'Familia Cruz');
insert into suppliers (id, organization_id, name, type_item_id) values
  ('a48fe9e7-635d-42a9-b9c9-643d9eff18c5', pg_temp.seed_a(), 'Magueyes Don Pedro', pg_temp.seed_cat('640b537d-bf52-5c4b-b407-a5f4fb7c5800')),
  ('bba40de6-bb20-464b-99af-55b20c7be41f', pg_temp.seed_a(), 'Destilados Hermanos Luna', pg_temp.seed_cat('bb234638-3c78-56cd-9f41-2fb38182f181'));
insert into supplies (id, organization_id, name, unit_item_id) values
  ('b39bb1c6-54a3-4b35-a48c-5cdd1537ba2b', pg_temp.seed_a(), 'Pulque como inóculo', pg_temp.seed_cat('bc6f104d-2841-5b36-b492-76b36becb172'));
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy, liquid_class) values
  ('09a413dc-dfc7-4ef2-8afb-83ed0a7b2f9a', pg_temp.seed_a(), 'horno', 'Horno 1', pg_temp.seed_cat('d53ba2da-cada-5215-804a-ff304d569f97'), 10000, 'kg', 'libre', null),
  ('5af1c85c-cba3-472f-b33d-2c27190f5489', pg_temp.seed_a(), 'molino', 'Tahona', pg_temp.seed_cat('60285283-d000-52f0-95da-d2b2e6d70fa1'), null, 'kg', 'libre', null),
  ('704fa35a-2d38-4294-8a78-7b857ffd4754', pg_temp.seed_a(), 'tina', 'Tina 1', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('80938d57-b3a7-4e5b-99af-a5e737c3c04d', pg_temp.seed_a(), 'tina', 'Tina 2', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('26e2bbbb-2726-4eb2-b0fc-c7cad1d469d4', pg_temp.seed_a(), 'tina', 'Tina 3', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('aa31e85d-3db6-4389-a899-f307ab591dc1', pg_temp.seed_a(), 'alambique', 'Alambique 1', pg_temp.seed_cat('af73010e-53f2-5769-b3b1-6cda154e665e'), 300, 'L', 'estricta', null),
  ('82f4cacc-a05c-4fbd-8731-27f94e8d5ad8', pg_temp.seed_a(), 'alambique', 'Alambique 2', '9ca61775-ad0b-4305-ad50-efb918f862d7', 250, 'L', 'estricta', null),
  ('89790951-cd05-44cf-8b2f-a72850640561', pg_temp.seed_a(), 'colector', 'Colector mezcal', pg_temp.seed_cat('2cd7e70b-6246-543e-8f67-23743fefdf95'), 60, 'L', 'flexible', 'mezcal'),
  ('0ed269b8-08cb-474c-9c1e-fafead1f533b', pg_temp.seed_a(), 'colector', 'Colector ordinario', pg_temp.seed_cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'ordinario'),
  ('92090652-0ab6-4aa8-98f5-b7045464a321', pg_temp.seed_a(), 'colector', 'Colector colas', pg_temp.seed_cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'colas'),
  ('8d41633b-b5e2-4101-9a54-b1e46459b6a4', pg_temp.seed_a(), 'tanque', 'Tanque 1', pg_temp.seed_cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1000, 'L', 'flexible', null),
  ('f5fb07d9-a1b3-459a-a383-16c01160ba73', pg_temp.seed_a(), 'tanque', 'Tanque 2', pg_temp.seed_cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1500, 'L', 'flexible', null);

-- Palenque Prueba B: lo mínimo para probar aislamiento
insert into predios (id, organization_id, name, municipality) values
  ('0c4ec32b-38b2-4e68-a990-cf73329eb0ff', '9335fe2f-4473-451d-9319-d2a9cc350e37', 'Predio B', 'Ejutla');
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy) values
  ('a742c60c-2746-49be-a3dd-0bfb09f44001', '9335fe2f-4473-451d-9319-d2a9cc350e37', 'tina', 'Tina B1',
   (select id from catalog_items where organization_id = '9335fe2f-4473-451d-9319-d2a9cc350e37' and template_id = 'b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1000, 'L', 'flexible');

-- =====================================================================
-- Cuatro Vientos: la producción, POR RPC, en orden cronológico
-- =====================================================================

-- 2026-09-01 · Benito: lo que ya había en el Tanque 2 (carga inicial)
select pg_temp.seed_como('1cd1ed69-372c-45dd-a8b3-677d2b83d1d1');
select registrar_entrada(pg_temp.seed_a(), 'f72bc0cd-53a8-4ed8-a409-a82be4ce4581', '2026-09-01 10:15:00-06',
  'granel', pg_temp.seed_res('Tanque 2'), 600, 44.2, 'mezcal', 'carga_inicial',
  p_concepto => pg_temp.seed_con('255e79f1-12b3-5969-8453-e40623275559'),
  p_nota => 'Lo que ya había en el tanque al empezar', p_folio => 'G-INI-01');

-- 2026-09-01 · Aurelia: la Tina 3 ya fermentaba
select pg_temp.seed_como('2e636fed-5c84-4775-969f-84d2823fbb0c');
select registrar_entrada(pg_temp.seed_a(), 'c04b7e77-9786-4cb7-b395-559c5b9c788d', '2026-09-01 10:40:00-06',
  'fermentado', pg_temp.seed_res('Tina 3'), 1300, null, null, 'carga_inicial',
  p_nota => 'Tina que ya fermentaba', p_folio => 'FER-T3-INI');

-- 2026-09-02 · Aurelia: recepción de maguey
select registrar_recepcion_maguey(pg_temp.seed_a(), '6bad8fcf-28eb-4e5d-846f-f758f6293aca', '2026-09-02 07:30:00-06',
  8000, pg_temp.seed_esp('67a96efd-2c72-528e-8682-d144fe1f802c'), '7b88f02d-a364-4126-801f-58bce5e08b08',
  'a48fe9e7-635d-42a9-b9c9-643d9eff18c5', 132, 'Piñas de 8 años, buen tamaño', 'MAG-001');

-- 2026-09-02 · Horneado (la simulación lo abría Tomás; §11.1 lo reserva a
-- admin/productor, así que lo abre Aurelia — docs/DECISIONES.md)
select abrir_horneado(pg_temp.seed_a(), '13ca90f3-be2f-4636-b40b-ada2afd31ebf', '2026-09-02 12:00:00-06',
  pg_temp.seed_res('Horno 1'), array[pg_temp.seed_lot('MAG-001')], array[8000::numeric], p_folio => 'HOR-001');
-- 2026-09-06 · Aurelia cierra: 6,200 kg de agave cocido
select cerrar_horneado(pg_temp.seed_a(), '64a54dda-a39f-476b-8b66-d909997449a2', '2026-09-06 08:00:00-06',
  pg_temp.seed_hor('HOR-001'), 6200, 'Leña de encino', p_folio => 'AC-001');

-- 2026-09-07 · Aurelia: formulación repartida a Tina 1 y Tina 2
select registrar_formulacion(pg_temp.seed_a(), 'a21d819d-a7b6-4741-9e98-8ee91e2b3a01', '2026-09-07 09:00:00-06',
  pg_temp.seed_res('Tahona'), array[pg_temp.seed_lot('AC-001')], array[6200::numeric], 1900,
  array[pg_temp.seed_res('Tina 1'), pg_temp.seed_res('Tina 2')], array[1400::numeric, 1400::numeric],
  array['b39bb1c6-54a3-4b35-a48c-5cdd1537ba2b'::uuid], array[20::numeric],
  'Tahona con mula', null, 'F-001', array['FER-T1-001', 'FER-T2-001']);

-- Mediciones diarias (escala de actividad 1–6, §18 #1; la simulación traía 7 y 8)
-- Tina 1
select pg_temp.seed_como('6ae8e54a-1da4-47e1-a94c-ef77f9f03e6e');
select registrar_medicion(pg_temp.seed_a(), 'f10b33c1-401c-4633-8c70-ea655a0ca248', '2026-09-08 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 1, 'minimo', 4,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.5,12.0]::numeric[]);
select pg_temp.seed_como('2e636fed-5c84-4775-969f-84d2823fbb0c');
select registrar_medicion(pg_temp.seed_a(), 'ad060d73-bef8-4746-a28c-1a98b4ff1786', '2026-09-09 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.0,9.5]::numeric[]);
select pg_temp.seed_como('6ae8e54a-1da4-47e1-a94c-ef77f9f03e6e');
select registrar_medicion(pg_temp.seed_a(), '5019d630-aa95-4b21-ac81-104d40385b07', '2026-09-10 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.5,6.0]::numeric[]);
select pg_temp.seed_como('2e636fed-5c84-4775-969f-84d2823fbb0c');
select registrar_medicion(pg_temp.seed_a(), '688933d1-2ccd-4059-8bfc-da304fa231e3', '2026-09-11 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 4, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.5,3.5]::numeric[]);
select pg_temp.seed_como('6ae8e54a-1da4-47e1-a94c-ef77f9f03e6e');
select registrar_medicion(pg_temp.seed_a(), '36ecce2d-0e69-4cd9-87b7-55792640a959', '2026-09-12 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 5, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.0,1.5]::numeric[]);
-- Tina 2
select registrar_medicion(pg_temp.seed_a(), '1f8610ce-69fa-43b9-b771-7cef53b6a603', '2026-09-08 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 1, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.0,12.2]::numeric[]);
select registrar_medicion(pg_temp.seed_a(), '07198c36-959c-40e9-9583-b2b7e93a3d56', '2026-09-09 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.5,10.1]::numeric[]);
select registrar_medicion(pg_temp.seed_a(), '144779e1-969c-4f58-ab6d-0141d0da14d8', '2026-09-10 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.0,7.4]::numeric[]);

-- 2026-09-12 · Aurelia declara lista la Tina 1
select pg_temp.seed_como('2e636fed-5c84-4775-969f-84d2823fbb0c');
select declarar_tina_lista(pg_temp.seed_a(), '5bc2dfd7-551d-4933-ae8a-cd566a2535d1', '2026-09-12 17:00:00-06',
  pg_temp.seed_cyc('Tina 1'), 'Día 5: ya no burbujea, sabor seco');

-- 2026-09-13 · Tomás: dos corridas de 1ª pasada desde la Tina 1
select pg_temp.seed_como('6ae8e54a-1da4-47e1-a94c-ef77f9f03e6e');
select abrir_corrida(pg_temp.seed_a(), 'bbc6d24d-bc9d-414c-af24-2832c0dd41c4', '2026-09-13 06:00:00-06',
  pg_temp.seed_res('Alambique 1'), 'primera', array[pg_temp.seed_res('Tina 1')], array[pg_temp.seed_lot('FER-T1-001')], array[290::numeric],
  p_folio => 'DES-001');
select registrar_corte(pg_temp.seed_a(), '7ebbc666-1b40-4966-97c5-6719fd76a059', '2026-09-13 08:00:00-06', pg_temp.seed_run('DES-001'), 'mezcal', 8, 51.0, pg_temp.seed_res('Colector mezcal'), p_folio => 'MEZ-001');
select registrar_corte(pg_temp.seed_a(), 'bfea40f9-7238-444b-9682-5a62c19c5412', '2026-09-13 10:00:00-06', pg_temp.seed_run('DES-001'), 'ordinario', 40, 24.0, pg_temp.seed_res('Colector ordinario'), p_folio => 'ORD-001');
select registrar_corte(pg_temp.seed_a(), 'd9eef19b-55e1-4c4a-802d-91e68d587446', '2026-09-13 12:00:00-06', pg_temp.seed_run('DES-001'), 'colas', 12, 9.0, pg_temp.seed_res('Colector colas'), p_folio => 'COL-001');
select cerrar_corrida(pg_temp.seed_a(), '75782f3a-568b-4228-81a3-134017e08e9b', '2026-09-13 14:00:00-06', pg_temp.seed_run('DES-001'));

select abrir_corrida(pg_temp.seed_a(), '32a55e63-0a9d-4f36-87c2-be0988fb4e62', '2026-09-13 06:00:00-06',
  pg_temp.seed_res('Alambique 2'), 'primera', array[pg_temp.seed_res('Tina 1')], array[pg_temp.seed_lot('FER-T1-001')], array[240::numeric],
  p_folio => 'DES-002');
select registrar_corte(pg_temp.seed_a(), 'c7d63cee-59e0-45b1-8e91-1d3f415a219f', '2026-09-13 08:00:00-06', pg_temp.seed_run('DES-002'), 'mezcal', 6, 50.0, pg_temp.seed_res('Colector mezcal'));
select registrar_corte(pg_temp.seed_a(), '7a22fd1b-b518-4ac0-abf5-d2b13d157f54', '2026-09-13 10:00:00-06', pg_temp.seed_run('DES-002'), 'ordinario', 34, 23.0, pg_temp.seed_res('Colector ordinario'));
select registrar_corte(pg_temp.seed_a(), '16e523cd-5edd-4d19-a6a2-cb3319e6a978', '2026-09-13 12:00:00-06', pg_temp.seed_run('DES-002'), 'colas', 10, 8.0, pg_temp.seed_res('Colector colas'));
select cerrar_corrida(pg_temp.seed_a(), '08ed02b4-8fd9-44f6-b113-8253d910a407', '2026-09-13 14:00:00-06', pg_temp.seed_run('DES-002'));

-- 2026-09-15 · Tomás: 2ª pasada con ordinario y colas juntos (aviso + nota)
select abrir_corrida(pg_temp.seed_a(), 'beca90af-67f1-45ad-aa5b-f22332b84862', '2026-09-15 06:00:00-06',
  pg_temp.seed_res('Alambique 1'), 'segunda',
  array[pg_temp.seed_res('Colector ordinario'), pg_temp.seed_res('Colector colas')],
  array[pg_temp.seed_lot('ORD-001'), pg_temp.seed_lot('COL-001')], array[74::numeric, 22::numeric],
  'Había olla libre y poca cola; se juntó con el ordinario', 'DES-003');
select registrar_corte(pg_temp.seed_a(), '84d336d5-3866-4f9e-aebe-2faad5979127', '2026-09-15 08:00:00-06', pg_temp.seed_run('DES-003'), 'mezcal', 26, 52.5, pg_temp.seed_res('Colector mezcal'));
select registrar_corte(pg_temp.seed_a(), '4dd66d0c-eecc-41aa-b6df-1ff4cf029046', '2026-09-15 10:00:00-06', pg_temp.seed_run('DES-003'), 'colas', 16, 10.0, pg_temp.seed_res('Colector colas'), p_folio => 'COL-002');
select cerrar_corrida(pg_temp.seed_a(), '9f34983f-81ed-4fac-b05f-88000ba8c193', '2026-09-15 14:00:00-06', pg_temp.seed_run('DES-003'));

-- 2026-09-16 · Aurelia: el mezcal del colector pasa a granel con folio nuevo
select pg_temp.seed_como('2e636fed-5c84-4775-969f-84d2823fbb0c');
select transferir(pg_temp.seed_a(), '60db90af-45d2-4ca6-a64e-9bc0a7c262fa', '2026-09-16 09:00:00-06',
  pg_temp.seed_res('Colector mezcal'), pg_temp.seed_res('Tanque 1'), pg_temp.seed_lot('MEZ-001'), 40, 51.6, 'renombrar', 'G-2609-01');
-- Agua para bajar grado: 4 L, declara 43.8 L (contracción) y 47.0 %
select registrar_movimiento_granel(pg_temp.seed_a(), '305bcf05-e010-48ce-bf48-07e9bd934414', '2026-09-16 11:00:00-06',
  pg_temp.seed_con('66a151e2-9a2c-58be-ad4a-b117f1ddb717'), pg_temp.seed_res('Tanque 1'), 4,
  p_lote => pg_temp.seed_lot('G-2609-01'), p_resultado_l => 43.8, p_resultado_abv => 47.0);

-- 2026-09-17 · Benito: puntas guardadas (sin lote) al Tanque 2
select pg_temp.seed_como('1cd1ed69-372c-45dd-a8b3-677d2b83d1d1');
select registrar_movimiento_granel(pg_temp.seed_a(), '9708675f-9b8c-4e64-8154-1b961ed151c1', '2026-09-17 10:00:00-06',
  pg_temp.seed_con('f21aaad8-2ef6-556b-be55-64aa94431ab6'), pg_temp.seed_res('Tanque 2'), 2,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_resultado_l => 602, p_resultado_abv => 44.6, p_abv => 68.0,
  p_nota => 'Puntas guardadas de corridas de agosto, sin lote');
-- 2026-09-18 · Benito: unión de G-2609-01 (Tanque 1) con G-INI-01 (Tanque 2), se conserva el folio mayor
select registrar_movimiento_granel(pg_temp.seed_a(), '6317a53c-e040-4437-ad33-8dd9514e4bdc', '2026-09-18 09:30:00-06',
  pg_temp.seed_con('df427d88-600e-550e-a097-8ffe4f4dd556'), pg_temp.seed_res('Tanque 2'), 43.8,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_lote_origen => pg_temp.seed_lot('G-2609-01'), p_recurso_origen => pg_temp.seed_res('Tanque 1'),
  p_resultado_l => 645.8, p_resultado_abv => 44.9, p_decision => 'conservar', p_nota => 'Se conserva el folio del lote mayor');
-- 2026-09-19 · Benito: compra de granel al Tanque 1
select registrar_movimiento_granel(pg_temp.seed_a(), '691c6c66-a8ad-4fc1-b1d8-e5f97803d445', '2026-09-19 12:00:00-06',
  pg_temp.seed_con('688430a9-cd2f-5bae-add2-c59bc543d911'), pg_temp.seed_res('Tanque 1'), 250,
  p_resultado_l => 250, p_resultado_abv => 46.0, p_abv => 46.0, p_folio_nuevo => 'G-COMPRA-01',
  p_contraparte => 'Destilados Hermanos Luna', p_documento => 'Remisión 0452',
  p_proveedor => 'bba40de6-bb20-464b-99af-55b20c7be41f', p_especie => pg_temp.seed_esp('67a96efd-2c72-528e-8682-d144fe1f802c'),
  p_predio_declarado => 'Sola de Vega');

-- 2026-09-19 · Aurelia: muestra de laboratorio
select pg_temp.seed_como('2e636fed-5c84-4775-969f-84d2823fbb0c');
select registrar_movimiento_granel(pg_temp.seed_a(), 'eac655a8-9c4f-4183-a440-faaeb8195843', '2026-09-19 13:00:00-06',
  pg_temp.seed_con('2d62ab89-6a11-558c-8b46-5c4d30aa1607'), pg_temp.seed_res('Tanque 2'), 1,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Laboratorio ficticio de Oaxaca', p_documento => 'Análisis 2026-311');

-- 2026-09-20/22 · Benito: autoconsumo, venta, regalo
select pg_temp.seed_como('1cd1ed69-372c-45dd-a8b3-677d2b83d1d1');
select registrar_movimiento_granel(pg_temp.seed_a(), 'c8a7aabc-f9e9-473f-91ad-7a181a4d4df1', '2026-09-20 13:00:00-06',
  pg_temp.seed_con('fa52f92b-de19-5d0c-972c-beb899bb2ccb'), pg_temp.seed_res('Tanque 2'), 2, p_lote => pg_temp.seed_lot('G-INI-01'));
select registrar_movimiento_granel(pg_temp.seed_a(), '3a2a4c31-7978-4751-8707-69f0c4396f72', '2026-09-22 13:00:00-06',
  pg_temp.seed_con('7b0ca7ca-f8ae-5f33-93d5-f0c174664ec1'), pg_temp.seed_res('Tanque 2'), 300,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.', p_documento => 'Remisión 118');
select registrar_movimiento_granel(pg_temp.seed_a(), '544a86c6-9222-4efb-9925-6421bc88b1c7', '2026-09-22 13:00:00-06',
  'ee077b46-10cf-47ec-834f-c3ac2a0c3b98', pg_temp.seed_res('Tanque 2'), 1,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.');

reset role;

-- Evidencia de la compra (los adjuntos no son RPC de §12)
insert into attachments (id, organization_id, operation_id, lot_id, kind_item_id, storage_path, caption) values
  ('a213ed25-bd19-443f-88c8-5008db599a31', pg_temp.seed_a(),
   (select id from operations where organization_id = pg_temp.seed_a() and idempotency_key = '691c6c66-a8ad-4fc1-b1d8-e5f97803d445'),
   pg_temp.seed_lot('G-COMPRA-01'), pg_temp.seed_cat('0522e23b-3b1d-58be-b50c-8a6ed0627c9f'),
   'evidencias/5a84f223-81a5-473c-ae36-bf2404abcd35/g-compra-01/remision-0452.jpg', 'Remisión del proveedor');


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
  a uuid := '5a84f223-81a5-473c-ae36-bf2404abcd35';      -- Cuatro Vientos
  b uuid := '9335fe2f-4473-451d-9319-d2a9cc350e37';      -- Prueba B
  admin_a uuid := '1cd1ed69-372c-45dd-a8b3-677d2b83d1d1';
  prod_a  uuid := '2e636fed-5c84-4775-969f-84d2823fbb0c';
  oper_a  uuid := '6ae8e54a-1da4-47e1-a94c-ef77f9f03e6e';
  admin_b uuid := 'e6be5a73-c721-4c3f-b38e-bff2ac9d3117';
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
  update organizations set slug = 'qa-e17042f4f1bd-cuatro-vientos-mezcal' where id = a;
  return next is((select organization_id from organization_slug_history where slug = 'qa-e17042f4f1bd-cuatro-vientos'), a,
                 'el slug viejo queda en el historial');
  return next is((select redirect_to from portal_branding('qa-e17042f4f1bd-cuatro-vientos')), 'qa-e17042f4f1bd-cuatro-vientos-mezcal',
                 'el portal del slug viejo redirige al nuevo');
  return next is((select logo_path from portal_branding('qa-e17042f4f1bd-cuatro-vientos-mezcal')), a::text || '/logo.png',
                 'el portal publica la ruta del logo');
  perform pg_temp.como(admin_b);
  return next throws_like(
    format($q$update organizations set slug = 'qa-e17042f4f1bd-cuatro-vientos' where id = '%s'$q$, b),
    '%', 'nadie más puede tomar un slug retirado');

  -- ── Primer arranque: carga inicial en tanque y tina ──────────────────
  perform pg_temp.como(admin_a);
  v_lot := registrar_entrada(a, '52e5b38a-9198-4d3c-b2c8-a296c32c5e61', now(), 'granel', v_tanque, 300, 47);
  return next is(registrar_entrada(a, '52e5b38a-9198-4d3c-b2c8-a296c32c5e61', now(), 'granel', v_tanque, 300, 47), v_lot,
                 'reintentar con la misma idempotency_key no duplica');
  perform pg_temp.superuser();   -- resource_balance es interna (sin execute para authenticated)
  return next is(resource_balance(a, v_tanque), 300::numeric, 'la carga inicial deja 300 L en el tanque nuevo');
  return next is((select origin from lots where id = v_lot), 'carga_inicial'::lot_origin, 'el lote nace como carga inicial');
  return next is((select count(*) from lots where organization_id = a and operation_id in
                    (select id from operations where organization_id = a and idempotency_key = '52e5b38a-9198-4d3c-b2c8-a296c32c5e61')),
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
