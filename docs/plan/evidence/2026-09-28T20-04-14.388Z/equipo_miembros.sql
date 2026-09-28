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
-- tomas.h → 'tomas-2026' · dueña B → 'qa-1ed22ebb066c-prueba-b-2026' · admin → 'pulz-2026'
-- ---------------------------------------------------------------------
insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
                        raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
                        confirmation_token, recovery_token, email_change_token_new, email_change) values
  ('00000000-0000-0000-0000-000000000000', '70537a7f-89dd-4887-8aa2-8de131ac6a65', 'authenticated', 'authenticated', 'qa-1ed22ebb066c-tu@pulz.mx',
   extensions.crypt('pulz-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '0076c2c3-f515-45fa-af62-5709e788e259', 'authenticated', 'authenticated', 'qa-1ed22ebb066c-benito@cuatrovientos.mx',
   extensions.crypt('benito-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', 'd8022133-4d7f-4616-8e51-0220fa27f412', 'authenticated', 'authenticated', 'qa-1ed22ebb066c-aurelia@1dd58da3-a2ef-4844-82cf-ec478971b224.usuarios.pulz.mx',
   extensions.crypt('aurelia-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '4794ab6d-f5d3-4b38-9c38-256025640de3', 'authenticated', 'authenticated', 'qa-1ed22ebb066c-tomas.h@1dd58da3-a2ef-4844-82cf-ec478971b224.usuarios.pulz.mx',
   extensions.crypt('tomas-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '5069f675-eadc-4d2f-9e74-81cbabc73088', 'authenticated', 'authenticated', 'qa-1ed22ebb066c-duena@pruebab.mx',
   extensions.crypt('qa-1ed22ebb066c-prueba-b-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '');

insert into profiles (id, full_name) values
  ('70537a7f-89dd-4887-8aa2-8de131ac6a65', 'Admin PULZ'),
  ('0076c2c3-f515-45fa-af62-5709e788e259', 'Benito Cruz'),
  ('d8022133-4d7f-4616-8e51-0220fa27f412', 'Aurelia Santiago'),
  ('4794ab6d-f5d3-4b38-9c38-256025640de3', 'Tomás Hernández'),
  ('5069f675-eadc-4d2f-9e74-81cbabc73088', 'Dueña Prueba B');

insert into platform_admins (user_id) values ('70537a7f-89dd-4887-8aa2-8de131ac6a65');

-- Planes (§14, §18 #2 y #3)
-- Fixture: reutiliza plans canónica, sin modificarla.
-- Fixture: reutiliza plan_limits canónica, sin modificarla.
-- Fixture: reutiliza plan_features canónica, sin modificarla.

-- Empresas
insert into organizations (id, name, slug, state, brand_color, logo_path, welcome_message, created_by) values
  ('1dd58da3-a2ef-4844-82cf-ec478971b224', 'Mezcal Cuatro Vientos', 'qa-1ed22ebb066c-cuatro-vientos', 'Oaxaca', '#7A3E1D', null, 'Registro de producción del palenque', '0076c2c3-f515-45fa-af62-5709e788e259'),
  ('d2a4356e-608b-4d61-9a40-e993607581bf', 'Palenque Prueba B', 'qa-1ed22ebb066c-prueba-b', 'Oaxaca', '#173F87', null, 'Empresa de prueba', '5069f675-eadc-4d2f-9e74-81cbabc73088');
insert into organization_slug_history (slug, organization_id, retired_at, retired_by) values
  ('qa-1ed22ebb066c-mezcal-cuatro-vientos', '1dd58da3-a2ef-4844-82cf-ec478971b224', '2026-09-02 09:00:00-06', '0076c2c3-f515-45fa-af62-5709e788e259');
insert into organization_members (organization_id, user_id, role, status, username, must_change_password) values
  ('1dd58da3-a2ef-4844-82cf-ec478971b224', '0076c2c3-f515-45fa-af62-5709e788e259', 'admin', 'activo', null, false),
  ('1dd58da3-a2ef-4844-82cf-ec478971b224', 'd8022133-4d7f-4616-8e51-0220fa27f412', 'productor', 'activo', 'aurelia', false),
  ('1dd58da3-a2ef-4844-82cf-ec478971b224', '4794ab6d-f5d3-4b38-9c38-256025640de3', 'operador', 'activo', 'tomas.h', true),
  ('d2a4356e-608b-4d61-9a40-e993607581bf', '5069f675-eadc-4d2f-9e74-81cbabc73088', 'admin', 'activo', null, false);
insert into member_invitations (id, organization_id, user_id, token_hash, expires_at, used_at, created_by) values
  ('e921c79f-53aa-4858-a326-5f0d84e909b2', '1dd58da3-a2ef-4844-82cf-ec478971b224', '4794ab6d-f5d3-4b38-9c38-256025640de3', 'qa-1ed22ebb066c:SIMULADO', '2026-09-05 10:00:00-06', null, '0076c2c3-f515-45fa-af62-5709e788e259');
insert into login_throttle (user_id, failed_count, last_failed_at, locked_until) values
  ('4794ab6d-f5d3-4b38-9c38-256025640de3', 3, '2026-09-03 07:12:00-06', null);
insert into organization_settings (organization_id, record_puntas, measurement_mode, warn_mixed_second_pass, fermentation_expected_days, measurement_reminder_hour, default_folio_decision) values
  ('1dd58da3-a2ef-4844-82cf-ec478971b224', false, 'minimo', true, 7, 9, 'conservar'),
  ('d2a4356e-608b-4d61-9a40-e993607581bf', false, 'minimo', true, 7, 9, 'conservar');
insert into subscriptions (organization_id, plan_id, status, current_period_end) values
  ('1dd58da3-a2ef-4844-82cf-ec478971b224', 'edd15bcf-ad82-5684-a2e7-d85db401885b', 'prueba', '2026-10-15 00:00:00-06'),
  ('d2a4356e-608b-4d61-9a40-e993607581bf', 'ee35d6fd-b4d6-56d6-b7b4-61cb81932b21', 'gratis', null);

-- ---------------------------------------------------------------------
-- Plantillas de plataforma (§10.2.1)
-- ---------------------------------------------------------------------
-- Fixture: reutiliza catalog_item_templates canónica, sin modificarla.
-- Fixture: reutiliza movement_concept_templates canónica, sin modificarla.
-- Fixture: reutiliza species_templates canónica, sin modificarla.

select seed_organization_catalogs('1dd58da3-a2ef-4844-82cf-ec478971b224');
select seed_organization_catalogs('d2a4356e-608b-4d61-9a40-e993607581bf');

-- Lo propio de Cuatro Vientos y lo que oculta (§10.2.4)
insert into catalog_items (id, organization_id, template_id, catalog, name, sort_order, created_by) values
  ('8d75560d-070e-4a51-b9d1-cf5e1f28ee77', '1dd58da3-a2ef-4844-82cf-ec478971b224', null, 'tipo_alambique', 'Refrescadera de cobre', 100, '0076c2c3-f515-45fa-af62-5709e788e259');
insert into movement_concepts (id, organization_id, template_id, direction, name, source_lot, creates_lot, asks_result, asks_counterparty, sort_order, created_by) values
  ('816d7c68-2691-437d-af69-adff60f78570', '1dd58da3-a2ef-4844-82cf-ec478971b224', null, 'salida', 'Regalo a cliente', 'no_aplica', false, false, true, 100, '0076c2c3-f515-45fa-af62-5709e788e259');
update catalog_items set active = false
 where organization_id = '1dd58da3-a2ef-4844-82cf-ec478971b224'
   and template_id in ('5c985133-23d9-50fa-a252-6ff6b5b74134', 'b1fce67a-21bf-50a7-9344-fdf29eb5331e');
update movement_concepts set active = false
 where organization_id = '1dd58da3-a2ef-4844-82cf-ec478971b224'
   and template_id = '8b7f6579-99ef-549e-b427-b1d4d8bea9da';

-- ---------------------------------------------------------------------
-- Ayudas de la semilla (temporales; mueren con la sesión). security definer
-- para que resuelvan ids aunque el rol activo sea 'authenticated'.
-- ---------------------------------------------------------------------
create function pg_temp.seed_a() returns uuid language sql immutable as $$ select '1dd58da3-a2ef-4844-82cf-ec478971b224'::uuid $$;
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
  ('7f62dacb-26f7-4e88-a4df-c02662989507', pg_temp.seed_a(), 'Loma del Toro', 'Santiago Matatlán', 'Familia Cruz');
insert into suppliers (id, organization_id, name, type_item_id) values
  ('219f3975-b2ed-42c5-bf16-c532c78b6357', pg_temp.seed_a(), 'Magueyes Don Pedro', pg_temp.seed_cat('640b537d-bf52-5c4b-b407-a5f4fb7c5800')),
  ('215d499a-a2f3-4ece-9a83-47c94d046996', pg_temp.seed_a(), 'Destilados Hermanos Luna', pg_temp.seed_cat('bb234638-3c78-56cd-9f41-2fb38182f181'));
insert into supplies (id, organization_id, name, unit_item_id) values
  ('cdd1d9af-a8da-421d-aa66-e7afffe1d9d5', pg_temp.seed_a(), 'Pulque como inóculo', pg_temp.seed_cat('bc6f104d-2841-5b36-b492-76b36becb172'));
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy, liquid_class) values
  ('5fc4a0ca-1e3a-4cab-ad95-1b26cda424ab', pg_temp.seed_a(), 'horno', 'Horno 1', pg_temp.seed_cat('d53ba2da-cada-5215-804a-ff304d569f97'), 10000, 'kg', 'libre', null),
  ('36473bfe-a5e9-467b-855d-8a94e198c519', pg_temp.seed_a(), 'molino', 'Tahona', pg_temp.seed_cat('60285283-d000-52f0-95da-d2b2e6d70fa1'), null, 'kg', 'libre', null),
  ('cbce864e-80d1-4a88-bb07-9cc1f9aa88b1', pg_temp.seed_a(), 'tina', 'Tina 1', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('64d32aab-965f-44a7-86ce-bf90c68462df', pg_temp.seed_a(), 'tina', 'Tina 2', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('18a512f6-e3de-413d-84cf-44228b3b04fd', pg_temp.seed_a(), 'tina', 'Tina 3', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('32c130a8-e53e-4d62-bfc6-0ff144a90dec', pg_temp.seed_a(), 'alambique', 'Alambique 1', pg_temp.seed_cat('af73010e-53f2-5769-b3b1-6cda154e665e'), 300, 'L', 'estricta', null),
  ('20f71f96-3163-4d88-8142-1787d879283d', pg_temp.seed_a(), 'alambique', 'Alambique 2', '8d75560d-070e-4a51-b9d1-cf5e1f28ee77', 250, 'L', 'estricta', null),
  ('06e71a5e-ec4b-4062-b00d-523585847846', pg_temp.seed_a(), 'colector', 'Colector mezcal', pg_temp.seed_cat('2cd7e70b-6246-543e-8f67-23743fefdf95'), 60, 'L', 'flexible', 'mezcal'),
  ('114c5b2b-6ae7-48a0-9ce9-1afa9df16491', pg_temp.seed_a(), 'colector', 'Colector ordinario', pg_temp.seed_cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'ordinario'),
  ('f10e9613-2f4b-45e3-9b97-68233a72be27', pg_temp.seed_a(), 'colector', 'Colector colas', pg_temp.seed_cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'colas'),
  ('15f0bd58-b1f4-44aa-bdf9-95c8fb66d10f', pg_temp.seed_a(), 'tanque', 'Tanque 1', pg_temp.seed_cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1000, 'L', 'flexible', null),
  ('1f027f11-5e5e-4d1d-8787-eeb68197178f', pg_temp.seed_a(), 'tanque', 'Tanque 2', pg_temp.seed_cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1500, 'L', 'flexible', null);

-- Palenque Prueba B: lo mínimo para probar aislamiento
insert into predios (id, organization_id, name, municipality) values
  ('6164f1c2-c6bc-4d22-8850-a28561c487f1', 'd2a4356e-608b-4d61-9a40-e993607581bf', 'Predio B', 'Ejutla');
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy) values
  ('008801ae-bbc6-4143-8fd6-0eee020dbd45', 'd2a4356e-608b-4d61-9a40-e993607581bf', 'tina', 'Tina B1',
   (select id from catalog_items where organization_id = 'd2a4356e-608b-4d61-9a40-e993607581bf' and template_id = 'b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1000, 'L', 'flexible');

-- =====================================================================
-- Cuatro Vientos: la producción, POR RPC, en orden cronológico
-- =====================================================================

-- 2026-09-01 · Benito: lo que ya había en el Tanque 2 (carga inicial)
select pg_temp.seed_como('0076c2c3-f515-45fa-af62-5709e788e259');
select registrar_entrada(pg_temp.seed_a(), '4849769e-5d64-46b0-b982-66e145b0bf2d', '2026-09-01 10:15:00-06',
  'granel', pg_temp.seed_res('Tanque 2'), 600, 44.2, 'mezcal', 'carga_inicial',
  p_concepto => pg_temp.seed_con('255e79f1-12b3-5969-8453-e40623275559'),
  p_nota => 'Lo que ya había en el tanque al empezar', p_folio => 'G-INI-01');

-- 2026-09-01 · Aurelia: la Tina 3 ya fermentaba
select pg_temp.seed_como('d8022133-4d7f-4616-8e51-0220fa27f412');
select registrar_entrada(pg_temp.seed_a(), 'a016f6c5-d72f-4d21-8d1a-43d2862dc74c', '2026-09-01 10:40:00-06',
  'fermentado', pg_temp.seed_res('Tina 3'), 1300, null, null, 'carga_inicial',
  p_nota => 'Tina que ya fermentaba', p_folio => 'FER-T3-INI');

-- 2026-09-02 · Aurelia: recepción de maguey
select registrar_recepcion_maguey(pg_temp.seed_a(), '5854f923-7e5a-4d59-87f6-e8af3fce7ad4', '2026-09-02 07:30:00-06',
  8000, pg_temp.seed_esp('67a96efd-2c72-528e-8682-d144fe1f802c'), '7f62dacb-26f7-4e88-a4df-c02662989507',
  '219f3975-b2ed-42c5-bf16-c532c78b6357', 132, 'Piñas de 8 años, buen tamaño', 'MAG-001');

-- 2026-09-02 · Horneado (la simulación lo abría Tomás; §11.1 lo reserva a
-- admin/productor, así que lo abre Aurelia — docs/DECISIONES.md)
select abrir_horneado(pg_temp.seed_a(), 'd3839f48-f15e-42e4-b7fc-4d8f52baf5f0', '2026-09-02 12:00:00-06',
  pg_temp.seed_res('Horno 1'), array[pg_temp.seed_lot('MAG-001')], array[8000::numeric], p_folio => 'HOR-001');
-- 2026-09-06 · Aurelia cierra: 6,200 kg de agave cocido
select cerrar_horneado(pg_temp.seed_a(), '106ae34b-8b8b-42f6-bbaf-58a59725440e', '2026-09-06 08:00:00-06',
  pg_temp.seed_hor('HOR-001'), 6200, 'Leña de encino', p_folio => 'AC-001');

-- 2026-09-07 · Aurelia: formulación repartida a Tina 1 y Tina 2
select registrar_formulacion(pg_temp.seed_a(), '1ee9949d-0e43-41f5-9f17-b81ac85d3293', '2026-09-07 09:00:00-06',
  pg_temp.seed_res('Tahona'), array[pg_temp.seed_lot('AC-001')], array[6200::numeric], 1900,
  array[pg_temp.seed_res('Tina 1'), pg_temp.seed_res('Tina 2')], array[1400::numeric, 1400::numeric],
  array['cdd1d9af-a8da-421d-aa66-e7afffe1d9d5'::uuid], array[20::numeric],
  'Tahona con mula', null, 'F-001', array['FER-T1-001', 'FER-T2-001']);

-- Mediciones diarias (escala de actividad 1–6, §18 #1; la simulación traía 7 y 8)
-- Tina 1
select pg_temp.seed_como('4794ab6d-f5d3-4b38-9c38-256025640de3');
select registrar_medicion(pg_temp.seed_a(), '39b9ada0-3c71-442b-ae86-6ca0806ccf41', '2026-09-08 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 1, 'minimo', 4,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.5,12.0]::numeric[]);
select pg_temp.seed_como('d8022133-4d7f-4616-8e51-0220fa27f412');
select registrar_medicion(pg_temp.seed_a(), '524b5728-0071-41d0-a5ff-898bd76b4abf', '2026-09-09 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.0,9.5]::numeric[]);
select pg_temp.seed_como('4794ab6d-f5d3-4b38-9c38-256025640de3');
select registrar_medicion(pg_temp.seed_a(), '5db9d0e8-2e86-4e0c-92fe-a03a538e26d3', '2026-09-10 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.5,6.0]::numeric[]);
select pg_temp.seed_como('d8022133-4d7f-4616-8e51-0220fa27f412');
select registrar_medicion(pg_temp.seed_a(), '57b8cb9c-2f19-4fcb-b78e-4f89d72a9983', '2026-09-11 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 4, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.5,3.5]::numeric[]);
select pg_temp.seed_como('4794ab6d-f5d3-4b38-9c38-256025640de3');
select registrar_medicion(pg_temp.seed_a(), 'cdcbc012-4655-45f4-b25f-a4cd5b94b57e', '2026-09-12 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 5, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.0,1.5]::numeric[]);
-- Tina 2
select registrar_medicion(pg_temp.seed_a(), '64a041ca-4129-41f9-a066-25756855330b', '2026-09-08 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 1, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.0,12.2]::numeric[]);
select registrar_medicion(pg_temp.seed_a(), '3cc34713-c5e8-4649-ac57-8eb04eb3e79d', '2026-09-09 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.5,10.1]::numeric[]);
select registrar_medicion(pg_temp.seed_a(), '32b5e119-7e30-4589-ba20-fbf44541f56f', '2026-09-10 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.0,7.4]::numeric[]);

-- 2026-09-12 · Aurelia declara lista la Tina 1
select pg_temp.seed_como('d8022133-4d7f-4616-8e51-0220fa27f412');
select declarar_tina_lista(pg_temp.seed_a(), '200d0903-12ee-41f3-819f-30e66e7f7cd4', '2026-09-12 17:00:00-06',
  pg_temp.seed_cyc('Tina 1'), 'Día 5: ya no burbujea, sabor seco');

-- 2026-09-13 · Tomás: dos corridas de 1ª pasada desde la Tina 1
select pg_temp.seed_como('4794ab6d-f5d3-4b38-9c38-256025640de3');
select abrir_corrida(pg_temp.seed_a(), 'bf52a65b-3b1e-438e-bbd1-3c0a4a103d59', '2026-09-13 06:00:00-06',
  pg_temp.seed_res('Alambique 1'), 'primera', array[pg_temp.seed_res('Tina 1')], array[pg_temp.seed_lot('FER-T1-001')], array[290::numeric],
  p_folio => 'DES-001');
select registrar_corte(pg_temp.seed_a(), '160fe17b-e41e-4cb0-8d64-163892ae01de', '2026-09-13 08:00:00-06', pg_temp.seed_run('DES-001'), 'mezcal', 8, 51.0, pg_temp.seed_res('Colector mezcal'), p_folio => 'MEZ-001');
select registrar_corte(pg_temp.seed_a(), '01050605-8b3d-4265-86e6-22d524b38302', '2026-09-13 10:00:00-06', pg_temp.seed_run('DES-001'), 'ordinario', 40, 24.0, pg_temp.seed_res('Colector ordinario'), p_folio => 'ORD-001');
select registrar_corte(pg_temp.seed_a(), '6b7ac228-f60b-44c7-995b-701db049bdfe', '2026-09-13 12:00:00-06', pg_temp.seed_run('DES-001'), 'colas', 12, 9.0, pg_temp.seed_res('Colector colas'), p_folio => 'COL-001');
select cerrar_corrida(pg_temp.seed_a(), '304b8a3e-568e-45c5-b4a0-6c1f845ef516', '2026-09-13 14:00:00-06', pg_temp.seed_run('DES-001'));

select abrir_corrida(pg_temp.seed_a(), '2a34c6ef-b47f-46f7-83ab-90a0fece764f', '2026-09-13 06:00:00-06',
  pg_temp.seed_res('Alambique 2'), 'primera', array[pg_temp.seed_res('Tina 1')], array[pg_temp.seed_lot('FER-T1-001')], array[240::numeric],
  p_folio => 'DES-002');
select registrar_corte(pg_temp.seed_a(), 'd46b9c2b-5d0b-4df6-8f0f-7385cf121fbd', '2026-09-13 08:00:00-06', pg_temp.seed_run('DES-002'), 'mezcal', 6, 50.0, pg_temp.seed_res('Colector mezcal'));
select registrar_corte(pg_temp.seed_a(), '7d221ccd-fd01-4e06-a9bb-3275814c93f0', '2026-09-13 10:00:00-06', pg_temp.seed_run('DES-002'), 'ordinario', 34, 23.0, pg_temp.seed_res('Colector ordinario'));
select registrar_corte(pg_temp.seed_a(), 'fe5cf3b5-0439-40be-ab94-0c4f0b84a365', '2026-09-13 12:00:00-06', pg_temp.seed_run('DES-002'), 'colas', 10, 8.0, pg_temp.seed_res('Colector colas'));
select cerrar_corrida(pg_temp.seed_a(), 'c12b224b-19e0-4b6c-bcd3-b40aa6798be6', '2026-09-13 14:00:00-06', pg_temp.seed_run('DES-002'));

-- 2026-09-15 · Tomás: 2ª pasada con ordinario y colas juntos (aviso + nota)
select abrir_corrida(pg_temp.seed_a(), 'b9e40c66-dafb-4756-8f28-4cc27d166de3', '2026-09-15 06:00:00-06',
  pg_temp.seed_res('Alambique 1'), 'segunda',
  array[pg_temp.seed_res('Colector ordinario'), pg_temp.seed_res('Colector colas')],
  array[pg_temp.seed_lot('ORD-001'), pg_temp.seed_lot('COL-001')], array[74::numeric, 22::numeric],
  'Había olla libre y poca cola; se juntó con el ordinario', 'DES-003');
select registrar_corte(pg_temp.seed_a(), '14e74706-5785-4dac-93a8-b8e6b4273801', '2026-09-15 08:00:00-06', pg_temp.seed_run('DES-003'), 'mezcal', 26, 52.5, pg_temp.seed_res('Colector mezcal'));
select registrar_corte(pg_temp.seed_a(), 'e2b6dc98-6849-4b4a-864b-2bddcab53158', '2026-09-15 10:00:00-06', pg_temp.seed_run('DES-003'), 'colas', 16, 10.0, pg_temp.seed_res('Colector colas'), p_folio => 'COL-002');
select cerrar_corrida(pg_temp.seed_a(), '1995b7e5-0eac-47d1-afed-1525420ebe9b', '2026-09-15 14:00:00-06', pg_temp.seed_run('DES-003'));

-- 2026-09-16 · Aurelia: el mezcal del colector pasa a granel con folio nuevo
select pg_temp.seed_como('d8022133-4d7f-4616-8e51-0220fa27f412');
select transferir(pg_temp.seed_a(), '368c59fc-027b-4205-a652-93cb2a3d1603', '2026-09-16 09:00:00-06',
  pg_temp.seed_res('Colector mezcal'), pg_temp.seed_res('Tanque 1'), pg_temp.seed_lot('MEZ-001'), 40, 51.6, 'renombrar', 'G-2609-01');
-- Agua para bajar grado: 4 L, declara 43.8 L (contracción) y 47.0 %
select registrar_movimiento_granel(pg_temp.seed_a(), '51519522-0314-40cd-aba3-275a81b9c2ce', '2026-09-16 11:00:00-06',
  pg_temp.seed_con('66a151e2-9a2c-58be-ad4a-b117f1ddb717'), pg_temp.seed_res('Tanque 1'), 4,
  p_lote => pg_temp.seed_lot('G-2609-01'), p_resultado_l => 43.8, p_resultado_abv => 47.0);

-- 2026-09-17 · Benito: puntas guardadas (sin lote) al Tanque 2
select pg_temp.seed_como('0076c2c3-f515-45fa-af62-5709e788e259');
select registrar_movimiento_granel(pg_temp.seed_a(), '48a8acf9-bfd4-44ac-a43f-bf624b4a4966', '2026-09-17 10:00:00-06',
  pg_temp.seed_con('f21aaad8-2ef6-556b-be55-64aa94431ab6'), pg_temp.seed_res('Tanque 2'), 2,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_resultado_l => 602, p_resultado_abv => 44.6, p_abv => 68.0,
  p_nota => 'Puntas guardadas de corridas de agosto, sin lote');
-- 2026-09-18 · Benito: unión de G-2609-01 (Tanque 1) con G-INI-01 (Tanque 2), se conserva el folio mayor
select registrar_movimiento_granel(pg_temp.seed_a(), 'ffd41c45-f91a-4c62-b6ef-33066ec83fcd', '2026-09-18 09:30:00-06',
  pg_temp.seed_con('df427d88-600e-550e-a097-8ffe4f4dd556'), pg_temp.seed_res('Tanque 2'), 43.8,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_lote_origen => pg_temp.seed_lot('G-2609-01'), p_recurso_origen => pg_temp.seed_res('Tanque 1'),
  p_resultado_l => 645.8, p_resultado_abv => 44.9, p_decision => 'conservar', p_nota => 'Se conserva el folio del lote mayor');
-- 2026-09-19 · Benito: compra de granel al Tanque 1
select registrar_movimiento_granel(pg_temp.seed_a(), '9e2698ad-f424-436a-a096-ba34d6ffa236', '2026-09-19 12:00:00-06',
  pg_temp.seed_con('688430a9-cd2f-5bae-add2-c59bc543d911'), pg_temp.seed_res('Tanque 1'), 250,
  p_resultado_l => 250, p_resultado_abv => 46.0, p_abv => 46.0, p_folio_nuevo => 'G-COMPRA-01',
  p_contraparte => 'Destilados Hermanos Luna', p_documento => 'Remisión 0452',
  p_proveedor => '215d499a-a2f3-4ece-9a83-47c94d046996', p_especie => pg_temp.seed_esp('67a96efd-2c72-528e-8682-d144fe1f802c'),
  p_predio_declarado => 'Sola de Vega');

-- 2026-09-19 · Aurelia: muestra de laboratorio
select pg_temp.seed_como('d8022133-4d7f-4616-8e51-0220fa27f412');
select registrar_movimiento_granel(pg_temp.seed_a(), '5c65ab2f-a70e-43e5-9e44-d5dc46ce4691', '2026-09-19 13:00:00-06',
  pg_temp.seed_con('2d62ab89-6a11-558c-8b46-5c4d30aa1607'), pg_temp.seed_res('Tanque 2'), 1,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Laboratorio ficticio de Oaxaca', p_documento => 'Análisis 2026-311');

-- 2026-09-20/22 · Benito: autoconsumo, venta, regalo
select pg_temp.seed_como('0076c2c3-f515-45fa-af62-5709e788e259');
select registrar_movimiento_granel(pg_temp.seed_a(), 'e455ccd8-7410-4b2e-95f0-eef538d184f6', '2026-09-20 13:00:00-06',
  pg_temp.seed_con('fa52f92b-de19-5d0c-972c-beb899bb2ccb'), pg_temp.seed_res('Tanque 2'), 2, p_lote => pg_temp.seed_lot('G-INI-01'));
select registrar_movimiento_granel(pg_temp.seed_a(), '6aa46530-6406-445d-818a-0f9f9853c354', '2026-09-22 13:00:00-06',
  pg_temp.seed_con('7b0ca7ca-f8ae-5f33-93d5-f0c174664ec1'), pg_temp.seed_res('Tanque 2'), 300,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.', p_documento => 'Remisión 118');
select registrar_movimiento_granel(pg_temp.seed_a(), 'e597d8f5-1c28-4f52-80e7-308cb13e9a9e', '2026-09-22 13:00:00-06',
  '816d7c68-2691-437d-af69-adff60f78570', pg_temp.seed_res('Tanque 2'), 1,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.');

reset role;

-- Evidencia de la compra (los adjuntos no son RPC de §12)
insert into attachments (id, organization_id, operation_id, lot_id, kind_item_id, storage_path, caption) values
  ('d5328590-b26d-442f-b78e-3a28a21d0626', pg_temp.seed_a(),
   (select id from operations where organization_id = pg_temp.seed_a() and idempotency_key = '9e2698ad-f424-436a-a096-ba34d6ffa236'),
   pg_temp.seed_lot('G-COMPRA-01'), pg_temp.seed_cat('0522e23b-3b1d-58be-b50c-8a6ed0627c9f'),
   'evidencias/1dd58da3-a2ef-4844-82cf-ec478971b224/g-compra-01/remision-0452.jpg', 'Remisión del proveedor');


-- pgTAP · equipo_miembros (0023): solo el administrador activo de la empresa
-- ve a su gente; bloqueo y vigencia del enlace derivados, nunca el token.
--     supabase db query --linked -f supabase/tests/equipo_miembros.test.sql


create function pg_temp.como(u uuid) returns void language plpgsql as $$
begin
  execute 'set local role authenticated';
  execute format('set local request.jwt.claims = %L', json_build_object('sub', u, 'role', 'authenticated')::text);
end $$;

create function pg_temp.test_equipo_miembros() returns setof text language plpgsql as $$
declare a uuid := '1dd58da3-a2ef-4844-82cf-ec478971b224'; b uuid := 'd2a4356e-608b-4d61-9a40-e993607581bf';
begin
  -- operador de A: no
  perform pg_temp.como('4794ab6d-f5d3-4b38-9c38-256025640de3');
  return next throws_like(format($q$select * from equipo_miembros('%s')$q$, a), 'NO_PERMITIDO:%',
                          'un operador no ve el equipo');
  -- productora de A: no
  perform pg_temp.como('d8022133-4d7f-4616-8e51-0220fa27f412');
  return next throws_like(format($q$select * from equipo_miembros('%s')$q$, a), 'NO_PERMITIDO:%',
                          'una productora no ve el equipo');
  -- admin de B pidiendo A: no
  perform pg_temp.como('5069f675-eadc-4d2f-9e74-81cbabc73088');
  return next throws_like(format($q$select * from equipo_miembros('%s')$q$, a), 'NO_PERMITIDO:%',
                          'el admin de otra empresa no ve el equipo de A');
  return next is((select count(*) from equipo_miembros(b)), 1::bigint, 'el admin de B ve a su única persona');

  -- admin de A: sí, con bloqueo y vigencia derivados
  perform pg_temp.como('0076c2c3-f515-45fa-af62-5709e788e259');
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
  perform pg_temp.como('0076c2c3-f515-45fa-af62-5709e788e259');
  return next is((select count(*) from equipo_miembros(a)), 3::bigint, 'con suscripción vencida el admin sigue viendo el equipo');
  execute 'reset role';
end $$;

select * from runtests((select nspname from pg_namespace where oid = pg_my_temp_schema())::name, '^test_');


rollback;
