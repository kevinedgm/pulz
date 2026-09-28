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
-- tomas.h → 'tomas-2026' · dueña B → 'qa-60898440ca3f4d39-prueba-b-2026' · admin → 'pulz-2026'
-- ---------------------------------------------------------------------
insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
                        raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
                        confirmation_token, recovery_token, email_change_token_new, email_change) values
  ('00000000-0000-0000-0000-000000000000', '44fd2a1e-e209-4467-8b9e-05b5c1c76156', 'authenticated', 'authenticated', 'qa-60898440ca3f4d39-tu@pulz.mx',
   extensions.crypt('pulz-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', 'fc213641-abee-4720-a73b-7fa74656e93f', 'authenticated', 'authenticated', 'qa-60898440ca3f4d39-benito@cuatrovientos.mx',
   extensions.crypt('benito-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '86688284-4a5f-41b9-bc98-59bbed83ae40', 'authenticated', 'authenticated', 'qa-60898440ca3f4d39-aurelia@616d4e2f-5330-4ea0-af9e-7ff497c67906.usuarios.pulz.mx',
   extensions.crypt('aurelia-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '0fc578bc-3480-44f1-995a-854be7f7402a', 'authenticated', 'authenticated', 'qa-60898440ca3f4d39-tomas.h@616d4e2f-5330-4ea0-af9e-7ff497c67906.usuarios.pulz.mx',
   extensions.crypt('tomas-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', 'ee9bda4d-a97f-43ec-870d-56124d11cb0b', 'authenticated', 'authenticated', 'qa-60898440ca3f4d39-duena@pruebab.mx',
   extensions.crypt('qa-60898440ca3f4d39-prueba-b-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '');

insert into profiles (id, full_name) values
  ('44fd2a1e-e209-4467-8b9e-05b5c1c76156', 'Admin PULZ'),
  ('fc213641-abee-4720-a73b-7fa74656e93f', 'Benito Cruz'),
  ('86688284-4a5f-41b9-bc98-59bbed83ae40', 'Aurelia Santiago'),
  ('0fc578bc-3480-44f1-995a-854be7f7402a', 'Tomás Hernández'),
  ('ee9bda4d-a97f-43ec-870d-56124d11cb0b', 'Dueña Prueba B');

insert into platform_admins (user_id) values ('44fd2a1e-e209-4467-8b9e-05b5c1c76156');

-- Planes (§14, §18 #2 y #3)
-- Fixture: reutiliza plans canónica, sin modificarla.
-- Fixture: reutiliza plan_limits canónica, sin modificarla.
-- Fixture: reutiliza plan_features canónica, sin modificarla.

-- Empresas
insert into organizations (id, name, slug, state, brand_color, logo_path, welcome_message, created_by) values
  ('616d4e2f-5330-4ea0-af9e-7ff497c67906', 'Mezcal Cuatro Vientos', 'qa-60898440ca3f4d39-cuatro-vientos', 'Oaxaca', '#7A3E1D', null, 'Registro de producción del palenque', 'fc213641-abee-4720-a73b-7fa74656e93f'),
  ('3b0b0fad-b88b-4ac9-aa6f-01e286ebe28a', 'Palenque Prueba B', 'qa-60898440ca3f4d39-prueba-b', 'Oaxaca', '#173F87', null, 'Empresa de prueba', 'ee9bda4d-a97f-43ec-870d-56124d11cb0b');
insert into organization_slug_history (slug, organization_id, retired_at, retired_by) values
  ('qa-60898440ca3f4d39-mezcal-cuatro-vientos', '616d4e2f-5330-4ea0-af9e-7ff497c67906', '2026-09-02 09:00:00-06', 'fc213641-abee-4720-a73b-7fa74656e93f');
insert into organization_members (organization_id, user_id, role, status, username, must_change_password) values
  ('616d4e2f-5330-4ea0-af9e-7ff497c67906', 'fc213641-abee-4720-a73b-7fa74656e93f', 'admin', 'activo', null, false),
  ('616d4e2f-5330-4ea0-af9e-7ff497c67906', '86688284-4a5f-41b9-bc98-59bbed83ae40', 'productor', 'activo', 'aurelia', false),
  ('616d4e2f-5330-4ea0-af9e-7ff497c67906', '0fc578bc-3480-44f1-995a-854be7f7402a', 'operador', 'activo', 'tomas.h', true),
  ('3b0b0fad-b88b-4ac9-aa6f-01e286ebe28a', 'ee9bda4d-a97f-43ec-870d-56124d11cb0b', 'admin', 'activo', null, false);
insert into member_invitations (id, organization_id, user_id, token_hash, expires_at, used_at, created_by) values
  ('779a2286-c1a7-468d-aac8-da349cdbdd27', '616d4e2f-5330-4ea0-af9e-7ff497c67906', '0fc578bc-3480-44f1-995a-854be7f7402a', 'qa-60898440ca3f4d39:SIMULADO', '2026-09-05 10:00:00-06', null, 'fc213641-abee-4720-a73b-7fa74656e93f');
insert into login_throttle (user_id, failed_count, last_failed_at, locked_until) values
  ('0fc578bc-3480-44f1-995a-854be7f7402a', 3, '2026-09-03 07:12:00-06', null);
insert into organization_settings (organization_id, record_puntas, measurement_mode, warn_mixed_second_pass, fermentation_expected_days, measurement_reminder_hour, default_folio_decision) values
  ('616d4e2f-5330-4ea0-af9e-7ff497c67906', false, 'minimo', true, 7, 9, 'conservar'),
  ('3b0b0fad-b88b-4ac9-aa6f-01e286ebe28a', false, 'minimo', true, 7, 9, 'conservar');
insert into subscriptions (organization_id, plan_id, status, current_period_end) values
  ('616d4e2f-5330-4ea0-af9e-7ff497c67906', 'edd15bcf-ad82-5684-a2e7-d85db401885b', 'prueba', '2026-10-15 00:00:00-06'),
  ('3b0b0fad-b88b-4ac9-aa6f-01e286ebe28a', 'ee35d6fd-b4d6-56d6-b7b4-61cb81932b21', 'gratis', null);

-- ---------------------------------------------------------------------
-- Plantillas de plataforma (§10.2.1)
-- ---------------------------------------------------------------------
-- Fixture: reutiliza catalog_item_templates canónica, sin modificarla.
-- Fixture: reutiliza movement_concept_templates canónica, sin modificarla.
-- Fixture: reutiliza species_templates canónica, sin modificarla.

select seed_organization_catalogs('616d4e2f-5330-4ea0-af9e-7ff497c67906');
select seed_organization_catalogs('3b0b0fad-b88b-4ac9-aa6f-01e286ebe28a');

-- Lo propio de Cuatro Vientos y lo que oculta (§10.2.4)
insert into catalog_items (id, organization_id, template_id, catalog, name, sort_order, created_by) values
  ('8fbe2adb-10b1-4c59-a71c-eaf0e019d1f3', '616d4e2f-5330-4ea0-af9e-7ff497c67906', null, 'tipo_alambique', 'Refrescadera de cobre', 100, 'fc213641-abee-4720-a73b-7fa74656e93f');
insert into movement_concepts (id, organization_id, template_id, direction, name, source_lot, creates_lot, asks_result, asks_counterparty, sort_order, created_by) values
  ('f7635d33-3267-4738-a2ec-56c2b0f237dc', '616d4e2f-5330-4ea0-af9e-7ff497c67906', null, 'salida', 'Regalo a cliente', 'no_aplica', false, false, true, 100, 'fc213641-abee-4720-a73b-7fa74656e93f');
update catalog_items set active = false
 where organization_id = '616d4e2f-5330-4ea0-af9e-7ff497c67906'
   and template_id in ('5c985133-23d9-50fa-a252-6ff6b5b74134', 'b1fce67a-21bf-50a7-9344-fdf29eb5331e');
update movement_concepts set active = false
 where organization_id = '616d4e2f-5330-4ea0-af9e-7ff497c67906'
   and template_id = '8b7f6579-99ef-549e-b427-b1d4d8bea9da';

-- ---------------------------------------------------------------------
-- Ayudas de la semilla (temporales; mueren con la sesión). security definer
-- para que resuelvan ids aunque el rol activo sea 'authenticated'.
-- ---------------------------------------------------------------------
create function pg_temp.seed_a() returns uuid language sql immutable as $$ select '616d4e2f-5330-4ea0-af9e-7ff497c67906'::uuid $$;
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
  ('49a8b077-b56b-4d46-8c5e-560d2df36214', pg_temp.seed_a(), 'Loma del Toro', 'Santiago Matatlán', 'Familia Cruz');
insert into suppliers (id, organization_id, name, type_item_id) values
  ('d2211c4c-a075-42db-8295-77b5062a4cb7', pg_temp.seed_a(), 'Magueyes Don Pedro', pg_temp.seed_cat('640b537d-bf52-5c4b-b407-a5f4fb7c5800')),
  ('6126b5ee-5021-4d93-bb41-041af1a5bf42', pg_temp.seed_a(), 'Destilados Hermanos Luna', pg_temp.seed_cat('bb234638-3c78-56cd-9f41-2fb38182f181'));
insert into supplies (id, organization_id, name, unit_item_id) values
  ('c2cb6401-57fe-48ae-94cb-d8257939d78c', pg_temp.seed_a(), 'Pulque como inóculo', pg_temp.seed_cat('bc6f104d-2841-5b36-b492-76b36becb172'));
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy, liquid_class) values
  ('847cd439-532a-483d-86d3-9bcc06a65824', pg_temp.seed_a(), 'horno', 'Horno 1', pg_temp.seed_cat('d53ba2da-cada-5215-804a-ff304d569f97'), 10000, 'kg', 'libre', null),
  ('12d337fb-61b3-4fd1-a2e8-805778b05ba7', pg_temp.seed_a(), 'molino', 'Tahona', pg_temp.seed_cat('60285283-d000-52f0-95da-d2b2e6d70fa1'), null, 'kg', 'libre', null),
  ('c0dee860-6d38-4b95-a5ae-8796ea79cdbb', pg_temp.seed_a(), 'tina', 'Tina 1', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('2a72dfee-00bd-4736-a96e-af643b6e6566', pg_temp.seed_a(), 'tina', 'Tina 2', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('3b32a6da-eace-4c3d-b0c8-671cd1d7a9bd', pg_temp.seed_a(), 'tina', 'Tina 3', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('965175ad-236a-439b-a5df-34a540de876b', pg_temp.seed_a(), 'alambique', 'Alambique 1', pg_temp.seed_cat('af73010e-53f2-5769-b3b1-6cda154e665e'), 300, 'L', 'estricta', null),
  ('95aca3c3-aff2-4ae3-8eaf-050bfca4696b', pg_temp.seed_a(), 'alambique', 'Alambique 2', '8fbe2adb-10b1-4c59-a71c-eaf0e019d1f3', 250, 'L', 'estricta', null),
  ('64c40533-0de0-42bc-9fae-e28a6e6bb1e2', pg_temp.seed_a(), 'colector', 'Colector mezcal', pg_temp.seed_cat('2cd7e70b-6246-543e-8f67-23743fefdf95'), 60, 'L', 'flexible', 'mezcal'),
  ('bf95f69e-a29c-4d41-a793-ac15c45b30ca', pg_temp.seed_a(), 'colector', 'Colector ordinario', pg_temp.seed_cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'ordinario'),
  ('b59058c0-26e9-41d7-a29e-70294e0dc68f', pg_temp.seed_a(), 'colector', 'Colector colas', pg_temp.seed_cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'colas'),
  ('4693460b-49a9-4aee-914b-68b78b28d54f', pg_temp.seed_a(), 'tanque', 'Tanque 1', pg_temp.seed_cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1000, 'L', 'flexible', null),
  ('582b0711-1743-4c29-a1fd-4b78a7b9048c', pg_temp.seed_a(), 'tanque', 'Tanque 2', pg_temp.seed_cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1500, 'L', 'flexible', null);

-- Palenque Prueba B: lo mínimo para probar aislamiento
insert into predios (id, organization_id, name, municipality) values
  ('3fb48893-66b1-4f7a-97af-e4d8a40d63e2', '3b0b0fad-b88b-4ac9-aa6f-01e286ebe28a', 'Predio B', 'Ejutla');
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy) values
  ('2d50930c-235d-4e68-9e5a-d22e42912d7b', '3b0b0fad-b88b-4ac9-aa6f-01e286ebe28a', 'tina', 'Tina B1',
   (select id from catalog_items where organization_id = '3b0b0fad-b88b-4ac9-aa6f-01e286ebe28a' and template_id = 'b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1000, 'L', 'flexible');

-- =====================================================================
-- Cuatro Vientos: la producción, POR RPC, en orden cronológico
-- =====================================================================

-- 2026-09-01 · Benito: lo que ya había en el Tanque 2 (carga inicial)
select pg_temp.seed_como('fc213641-abee-4720-a73b-7fa74656e93f');
select registrar_entrada(pg_temp.seed_a(), 'd2eec40f-1227-4637-9227-d1371cbea771', '2026-09-01 10:15:00-06',
  'granel', pg_temp.seed_res('Tanque 2'), 600, 44.2, 'mezcal', 'carga_inicial',
  p_concepto => pg_temp.seed_con('255e79f1-12b3-5969-8453-e40623275559'),
  p_nota => 'Lo que ya había en el tanque al empezar', p_folio => 'G-INI-01');

-- 2026-09-01 · Aurelia: la Tina 3 ya fermentaba
select pg_temp.seed_como('86688284-4a5f-41b9-bc98-59bbed83ae40');
select registrar_entrada(pg_temp.seed_a(), '5a0244d7-3523-4752-a0e8-42d61accfe6d', '2026-09-01 10:40:00-06',
  'fermentado', pg_temp.seed_res('Tina 3'), 1300, null, null, 'carga_inicial',
  p_nota => 'Tina que ya fermentaba', p_folio => 'FER-T3-INI');

-- 2026-09-02 · Aurelia: recepción de maguey
select registrar_recepcion_maguey(pg_temp.seed_a(), '92c66624-a1d1-46ce-a67e-e0eba6067e32', '2026-09-02 07:30:00-06',
  8000, pg_temp.seed_esp('67a96efd-2c72-528e-8682-d144fe1f802c'), '49a8b077-b56b-4d46-8c5e-560d2df36214',
  'd2211c4c-a075-42db-8295-77b5062a4cb7', 132, 'Piñas de 8 años, buen tamaño', 'MAG-001');

-- 2026-09-02 · Horneado (la simulación lo abría Tomás; §11.1 lo reserva a
-- admin/productor, así que lo abre Aurelia — docs/DECISIONES.md)
select abrir_horneado(pg_temp.seed_a(), '601f021b-8d30-4f29-abd2-746c5711f975', '2026-09-02 12:00:00-06',
  pg_temp.seed_res('Horno 1'), array[pg_temp.seed_lot('MAG-001')], array[8000::numeric], p_folio => 'HOR-001');
-- 2026-09-06 · Aurelia cierra: 6,200 kg de agave cocido
select cerrar_horneado(pg_temp.seed_a(), 'b3ebee83-dc54-4b20-946f-36f30574d1a5', '2026-09-06 08:00:00-06',
  pg_temp.seed_hor('HOR-001'), 6200, 'Leña de encino', p_folio => 'AC-001');

-- 2026-09-07 · Aurelia: formulación repartida a Tina 1 y Tina 2
select registrar_formulacion(pg_temp.seed_a(), '1a08dee3-115d-4f7f-b23b-151b4d3f0774', '2026-09-07 09:00:00-06',
  pg_temp.seed_res('Tahona'), array[pg_temp.seed_lot('AC-001')], array[6200::numeric], 1900,
  array[pg_temp.seed_res('Tina 1'), pg_temp.seed_res('Tina 2')], array[1400::numeric, 1400::numeric],
  array['c2cb6401-57fe-48ae-94cb-d8257939d78c'::uuid], array[20::numeric],
  'Tahona con mula', null, 'F-001', array['FER-T1-001', 'FER-T2-001']);

-- Mediciones diarias (escala de actividad 1–6, §18 #1; la simulación traía 7 y 8)
-- Tina 1
select pg_temp.seed_como('0fc578bc-3480-44f1-995a-854be7f7402a');
select registrar_medicion(pg_temp.seed_a(), 'f359b20f-cf7c-428a-83f4-cddaff780aa4', '2026-09-08 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 1, 'minimo', 4,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.5,12.0]::numeric[]);
select pg_temp.seed_como('86688284-4a5f-41b9-bc98-59bbed83ae40');
select registrar_medicion(pg_temp.seed_a(), 'fcf636ec-56aa-478c-b3b7-de194b170620', '2026-09-09 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.0,9.5]::numeric[]);
select pg_temp.seed_como('0fc578bc-3480-44f1-995a-854be7f7402a');
select registrar_medicion(pg_temp.seed_a(), 'b06cf426-ca9a-40c0-b5c4-d5c35826ff58', '2026-09-10 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.5,6.0]::numeric[]);
select pg_temp.seed_como('86688284-4a5f-41b9-bc98-59bbed83ae40');
select registrar_medicion(pg_temp.seed_a(), 'e939cfdb-bbf0-4c4a-bef8-ae723e4976ef', '2026-09-11 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 4, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.5,3.5]::numeric[]);
select pg_temp.seed_como('0fc578bc-3480-44f1-995a-854be7f7402a');
select registrar_medicion(pg_temp.seed_a(), '181a5d2f-4645-404a-8c21-7c80f065d5f3', '2026-09-12 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 5, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.0,1.5]::numeric[]);
-- Tina 2
select registrar_medicion(pg_temp.seed_a(), '6fe136b0-36af-471b-b416-c24cfa572d32', '2026-09-08 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 1, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.0,12.2]::numeric[]);
select registrar_medicion(pg_temp.seed_a(), '35f417d0-5d73-4420-b6ba-06388182932e', '2026-09-09 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.5,10.1]::numeric[]);
select registrar_medicion(pg_temp.seed_a(), '244e8918-bf64-4c45-a02e-00aac51b2174', '2026-09-10 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.0,7.4]::numeric[]);

-- 2026-09-12 · Aurelia declara lista la Tina 1
select pg_temp.seed_como('86688284-4a5f-41b9-bc98-59bbed83ae40');
select declarar_tina_lista(pg_temp.seed_a(), 'b185cd8e-6b07-4842-b58a-8a789940318b', '2026-09-12 17:00:00-06',
  pg_temp.seed_cyc('Tina 1'), 'Día 5: ya no burbujea, sabor seco');

-- 2026-09-13 · Tomás: dos corridas de 1ª pasada desde la Tina 1
select pg_temp.seed_como('0fc578bc-3480-44f1-995a-854be7f7402a');
select abrir_corrida(pg_temp.seed_a(), 'd4b741d4-0a1b-4e31-b14a-3038a242f370', '2026-09-13 06:00:00-06',
  pg_temp.seed_res('Alambique 1'), 'primera', array[pg_temp.seed_res('Tina 1')], array[pg_temp.seed_lot('FER-T1-001')], array[290::numeric],
  p_folio => 'DES-001');
select registrar_corte(pg_temp.seed_a(), '729e3af8-ca40-4167-97e3-17dbf0760329', '2026-09-13 08:00:00-06', pg_temp.seed_run('DES-001'), 'mezcal', 8, 51.0, pg_temp.seed_res('Colector mezcal'), p_folio => 'MEZ-001');
select registrar_corte(pg_temp.seed_a(), '0eaf84ca-0636-491e-a54a-9b62539a9098', '2026-09-13 10:00:00-06', pg_temp.seed_run('DES-001'), 'ordinario', 40, 24.0, pg_temp.seed_res('Colector ordinario'), p_folio => 'ORD-001');
select registrar_corte(pg_temp.seed_a(), '00ef397f-6312-406c-8bd6-0216909cd1a2', '2026-09-13 12:00:00-06', pg_temp.seed_run('DES-001'), 'colas', 12, 9.0, pg_temp.seed_res('Colector colas'), p_folio => 'COL-001');
select cerrar_corrida(pg_temp.seed_a(), 'b52d3a39-ea1b-4d7e-8ea2-e362aa96f6ec', '2026-09-13 14:00:00-06', pg_temp.seed_run('DES-001'));

select abrir_corrida(pg_temp.seed_a(), '39b8e58f-8282-43ff-8a29-f3f98f3b7af7', '2026-09-13 06:00:00-06',
  pg_temp.seed_res('Alambique 2'), 'primera', array[pg_temp.seed_res('Tina 1')], array[pg_temp.seed_lot('FER-T1-001')], array[240::numeric],
  p_folio => 'DES-002');
select registrar_corte(pg_temp.seed_a(), '8a71eeac-4d2b-4af5-91cb-cf0c2dc3f6ef', '2026-09-13 08:00:00-06', pg_temp.seed_run('DES-002'), 'mezcal', 6, 50.0, pg_temp.seed_res('Colector mezcal'));
select registrar_corte(pg_temp.seed_a(), '3721b98b-63df-470a-b02c-0933c5736fc2', '2026-09-13 10:00:00-06', pg_temp.seed_run('DES-002'), 'ordinario', 34, 23.0, pg_temp.seed_res('Colector ordinario'));
select registrar_corte(pg_temp.seed_a(), 'fdc58d16-84b3-465a-b277-7e7436efff26', '2026-09-13 12:00:00-06', pg_temp.seed_run('DES-002'), 'colas', 10, 8.0, pg_temp.seed_res('Colector colas'));
select cerrar_corrida(pg_temp.seed_a(), 'db7df68a-a300-48f8-8886-85346b4dfcd5', '2026-09-13 14:00:00-06', pg_temp.seed_run('DES-002'));

-- 2026-09-15 · Tomás: 2ª pasada con ordinario y colas juntos (aviso + nota)
select abrir_corrida(pg_temp.seed_a(), '174951f2-f8cf-4bfc-9376-48e71f711973', '2026-09-15 06:00:00-06',
  pg_temp.seed_res('Alambique 1'), 'segunda',
  array[pg_temp.seed_res('Colector ordinario'), pg_temp.seed_res('Colector colas')],
  array[pg_temp.seed_lot('ORD-001'), pg_temp.seed_lot('COL-001')], array[74::numeric, 22::numeric],
  'Había olla libre y poca cola; se juntó con el ordinario', 'DES-003');
select registrar_corte(pg_temp.seed_a(), '0aacef3d-1802-429d-9260-86f952cea768', '2026-09-15 08:00:00-06', pg_temp.seed_run('DES-003'), 'mezcal', 26, 52.5, pg_temp.seed_res('Colector mezcal'));
select registrar_corte(pg_temp.seed_a(), '6b484338-6e99-4217-83f4-31769c780796', '2026-09-15 10:00:00-06', pg_temp.seed_run('DES-003'), 'colas', 16, 10.0, pg_temp.seed_res('Colector colas'), p_folio => 'COL-002');
select cerrar_corrida(pg_temp.seed_a(), 'bc75dd3c-5601-4761-8dbd-dfb840a8b093', '2026-09-15 14:00:00-06', pg_temp.seed_run('DES-003'));

-- 2026-09-16 · Aurelia: el mezcal del colector pasa a granel con folio nuevo
select pg_temp.seed_como('86688284-4a5f-41b9-bc98-59bbed83ae40');
select transferir(pg_temp.seed_a(), '582d1cca-c94d-41e1-9c36-162dbfb12350', '2026-09-16 09:00:00-06',
  pg_temp.seed_res('Colector mezcal'), pg_temp.seed_res('Tanque 1'), pg_temp.seed_lot('MEZ-001'), 40, 51.6, 'renombrar', 'G-2609-01');
-- Agua para bajar grado: 4 L, declara 43.8 L (contracción) y 47.0 %
select registrar_movimiento_granel(pg_temp.seed_a(), '483bd296-3831-4616-b83f-fc6398ee5108', '2026-09-16 11:00:00-06',
  pg_temp.seed_con('66a151e2-9a2c-58be-ad4a-b117f1ddb717'), pg_temp.seed_res('Tanque 1'), 4,
  p_lote => pg_temp.seed_lot('G-2609-01'), p_resultado_l => 43.8, p_resultado_abv => 47.0);

-- 2026-09-17 · Benito: puntas guardadas (sin lote) al Tanque 2
select pg_temp.seed_como('fc213641-abee-4720-a73b-7fa74656e93f');
select registrar_movimiento_granel(pg_temp.seed_a(), '7d62f0c4-6b9b-4956-a686-7b0d5d397eb1', '2026-09-17 10:00:00-06',
  pg_temp.seed_con('f21aaad8-2ef6-556b-be55-64aa94431ab6'), pg_temp.seed_res('Tanque 2'), 2,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_resultado_l => 602, p_resultado_abv => 44.6, p_abv => 68.0,
  p_nota => 'Puntas guardadas de corridas de agosto, sin lote');
-- 2026-09-18 · Benito: unión de G-2609-01 (Tanque 1) con G-INI-01 (Tanque 2), se conserva el folio mayor
select registrar_movimiento_granel(pg_temp.seed_a(), '107d0957-22fd-4f98-afae-c8e961a90ff3', '2026-09-18 09:30:00-06',
  pg_temp.seed_con('df427d88-600e-550e-a097-8ffe4f4dd556'), pg_temp.seed_res('Tanque 2'), 43.8,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_lote_origen => pg_temp.seed_lot('G-2609-01'), p_recurso_origen => pg_temp.seed_res('Tanque 1'),
  p_resultado_l => 645.8, p_resultado_abv => 44.9, p_decision => 'conservar', p_nota => 'Se conserva el folio del lote mayor');
-- 2026-09-19 · Benito: compra de granel al Tanque 1
select registrar_movimiento_granel(pg_temp.seed_a(), '9860b95c-de9f-451b-848d-ec33d74b4213', '2026-09-19 12:00:00-06',
  pg_temp.seed_con('688430a9-cd2f-5bae-add2-c59bc543d911'), pg_temp.seed_res('Tanque 1'), 250,
  p_resultado_l => 250, p_resultado_abv => 46.0, p_abv => 46.0, p_folio_nuevo => 'G-COMPRA-01',
  p_contraparte => 'Destilados Hermanos Luna', p_documento => 'Remisión 0452',
  p_proveedor => '6126b5ee-5021-4d93-bb41-041af1a5bf42', p_especie => pg_temp.seed_esp('67a96efd-2c72-528e-8682-d144fe1f802c'),
  p_predio_declarado => 'Sola de Vega');

-- 2026-09-19 · Aurelia: muestra de laboratorio
select pg_temp.seed_como('86688284-4a5f-41b9-bc98-59bbed83ae40');
select registrar_movimiento_granel(pg_temp.seed_a(), 'de55060b-5643-4290-ac8e-aa814a92fc34', '2026-09-19 13:00:00-06',
  pg_temp.seed_con('2d62ab89-6a11-558c-8b46-5c4d30aa1607'), pg_temp.seed_res('Tanque 2'), 1,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Laboratorio ficticio de Oaxaca', p_documento => 'Análisis 2026-311');

-- 2026-09-20/22 · Benito: autoconsumo, venta, regalo
select pg_temp.seed_como('fc213641-abee-4720-a73b-7fa74656e93f');
select registrar_movimiento_granel(pg_temp.seed_a(), '7ef37eb7-bd31-4b69-b06a-c4f4d599715d', '2026-09-20 13:00:00-06',
  pg_temp.seed_con('fa52f92b-de19-5d0c-972c-beb899bb2ccb'), pg_temp.seed_res('Tanque 2'), 2, p_lote => pg_temp.seed_lot('G-INI-01'));
select registrar_movimiento_granel(pg_temp.seed_a(), '2c765bb9-44e2-4d79-b7a3-29849378c983', '2026-09-22 13:00:00-06',
  pg_temp.seed_con('7b0ca7ca-f8ae-5f33-93d5-f0c174664ec1'), pg_temp.seed_res('Tanque 2'), 300,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.', p_documento => 'Remisión 118');
select registrar_movimiento_granel(pg_temp.seed_a(), '6a45a005-33a5-43e3-9baa-cb80e3130dff', '2026-09-22 13:00:00-06',
  'f7635d33-3267-4738-a2ec-56c2b0f237dc', pg_temp.seed_res('Tanque 2'), 1,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.');

reset role;

-- Evidencia de la compra (los adjuntos no son RPC de §12)
insert into attachments (id, organization_id, operation_id, lot_id, kind_item_id, storage_path, caption) values
  ('9f4d9fc0-f1f7-4de7-8498-d12ffc15117e', pg_temp.seed_a(),
   (select id from operations where organization_id = pg_temp.seed_a() and idempotency_key = '9860b95c-de9f-451b-848d-ec33d74b4213'),
   pg_temp.seed_lot('G-COMPRA-01'), pg_temp.seed_cat('0522e23b-3b1d-58be-b50c-8a6ed0627c9f'),
   'evidencias/616d4e2f-5330-4ea0-af9e-7ff497c67906/g-compra-01/remision-0452.jpg', 'Remisión del proveedor');


-- pgTAP · Proceso (Fase 5): las vistas de 0026 contra la simulación de
-- Cuatro Vientos (deben coincidir con PULZ_MAESTRO.md §15.1 y con la
-- semilla), aislamiento (Prueba B ve vacío) y el bucket 'evidencias' con
-- sus políticas y la fila de attachments (0027).
--     supabase db query --linked -f supabase/tests/proceso.test.sql


create function pg_temp.como(u uuid) returns void language plpgsql as $$
begin
  execute 'set local role authenticated';
  execute format('set local request.jwt.claims = %L', json_build_object('sub', u, 'role', 'authenticated')::text);
end $$;

create function pg_temp.test_proceso() returns setof text language plpgsql as $$
declare
  a uuid := '616d4e2f-5330-4ea0-af9e-7ff497c67906';      -- Cuatro Vientos
  b uuid := '3b0b0fad-b88b-4ac9-aa6f-01e286ebe28a';      -- Prueba B
  admin_a uuid := 'fc213641-abee-4720-a73b-7fa74656e93f'; -- Benito
  oper_a  uuid := '0fc578bc-3480-44f1-995a-854be7f7402a'; -- Tomás
  admin_b uuid := 'ee9bda4d-a97f-43ec-870d-56124d11cb0b';
  t record; n int; v_att uuid; v_op uuid; v_lot uuid; v_foto uuid; v_tanq uuid;
begin
  -- ── Tinas en uso (como operador: lee todo lo de su empresa) ──────────
  perform pg_temp.como(oper_a);
  select count(*) into n from tinas_en_uso where organization_id = a;
  return next is(n, 3, 'tres tinas en uso (Tina 1 en vaciado, Tina 2 y Tina 3 fermentando)');

  select * into t from tinas_en_uso where organization_id = a and tina = 'Tina 1';
  return next is(t.status::text, 'en_vaciado', 'Tina 1 quedó en vaciado al cargarse al alambique');
  return next is(t.litros, 870::numeric, 'Tina 1: 870 L (§15.1)');
  return next is(t.mediciones, 5::bigint, 'Tina 1: 5 mediciones válidas');
  return next is(t.ultima_medicion_dia, 5::smallint, 'Tina 1: la última medición es del día 5');
  return next is(t.ultima_actividad, 3::smallint, 'Tina 1: actividad 3 en la última medición');
  return next ok(t.ultima_temperatura is not null and t.ultimo_brix is not null, 'Tina 1: promedios de temperatura y Brix al vuelo');
  return next is(t.folio, 'FER-T1-001', 'Tina 1: lote FER-T1-001');
  return next ok(t.formulacion is not null, 'Tina 1 viene de una formulación');

  select * into t from tinas_en_uso where organization_id = a and tina = 'Tina 2';
  return next is(t.status::text, 'fermentando', 'Tina 2 fermentando');
  return next is(t.litros, 1400::numeric, 'Tina 2: 1,400 L (§15.1)');
  return next is(t.mediciones, 3::bigint, 'Tina 2: 3 mediciones');

  select * into t from tinas_en_uso where organization_id = a and tina = 'Tina 3';
  return next is(t.litros, 1300::numeric, 'Tina 3: 1,300 L (§15.1)');
  return next ok(t.formulation_id is null and t.formulacion is null, 'Tina 3 ya fermentaba: sin formulación (DUDAS #7)');
  return next is(t.mediciones, 0::bigint, 'Tina 3: sin mediciones');
  return next ok(t.ultima_medicion_at is null, 'Tina 3: última medición nula, no un error');

  -- ── Mediciones del ciclo ─────────────────────────────────────────────
  select count(*) into n from mediciones_del_ciclo m
   where m.organization_id = a and m.cycle_id = (select cycle_id from tinas_en_uso where organization_id = a and tina = 'Tina 1');
  return next is(n, 5, 'mediciones_del_ciclo: 5 filas para Tina 1');
  select * into t from mediciones_del_ciclo m
   where m.organization_id = a and m.cycle_id = (select cycle_id from tinas_en_uso where organization_id = a and tina = 'Tina 1')
     and m.day_no = 1;
  return next is(t.mode::text, 'minimo', 'día 1 en modo mínimo');
  return next ok(t.temperatura is not null and t.brix is not null, 'día 1: temperatura y Brix promediados');
  return next ok(t.dulzor is null and t.acidez is null, 'modo mínimo: sin dulzor ni acidez');
  return next ok(t.recorded_by is not null, 'quién midió, con nombre');

  -- ── Corridas ─────────────────────────────────────────────────────────
  select count(*) into n from corridas where organization_id = a;
  return next is(n, 3, 'tres corridas en la simulación');
  select count(*) into n from corridas where organization_id = a and status = 'abierta';
  return next is(n, 0, 'ninguna abierta al final');
  select * into t from corridas where organization_id = a and folio = 'DES-001';
  return next is(t.litros_cargados, 290::numeric, 'DES-001 cargó 290 L de la Tina 1');
  return next is(t.litros_cortados, 60::numeric, 'DES-001 cortó 8 + 40 + 12 = 60 L');
  return next is(jsonb_array_length(t.cortes), 3, 'DES-001: tres cortes');
  return next is(t.origenes->0->>'recurso', 'Tina 1', 'DES-001: el origen es la Tina 1');
  select * into t from corridas where organization_id = a and folio = 'DES-003';
  return next is(t.pass::text, 'segunda', 'DES-003 es de 2ª pasada');
  return next is(jsonb_array_length(t.origenes), 2, 'DES-003: ordinario y colas juntos (aviso con nota)');
  return next is(t.litros_cargados, 96::numeric, 'DES-003 cargó 74 + 22 = 96 L');

  -- ── Colectores y tanques (§15.1) ─────────────────────────────────────
  select count(*) into n from colectores_con_saldo where organization_id = a;
  return next is(n, 1, 'solo el colector de colas tiene saldo');
  select * into t from colectores_con_saldo where organization_id = a;
  return next is(t.colector, 'Colector colas', 'es el Colector colas');
  return next is(t.folio, 'COL-002', 'con el lote COL-002 (nació aparte por la regla de acumulación)');
  return next is(t.litros, 16::numeric, 'Colector colas: 16 L');
  return next is(t.abv, 10.0::numeric, 'grado declarado del corte: 10 %');

  select count(*) into n from tanques where organization_id = a;
  return next is(n, 2, 'dos tanques activos');
  select * into t from tanques where organization_id = a and tanque = 'Tanque 1';
  return next is(t.litros, 250::numeric, 'Tanque 1: 250 L (G-COMPRA-01)');
  return next is(t.lotes->0->>'folio', 'G-COMPRA-01', 'Tanque 1: lote G-COMPRA-01');
  return next is((t.lotes->0->>'abv')::numeric, 46.0::numeric, 'Tanque 1: 46 % declarado en la compra');
  return next is(t.lotes->0->>'history', 'declarada', 'la compra tiene historia declarada');
  select * into t from tanques where organization_id = a and tanque = 'Tanque 2';
  return next is(t.litros, 341.8::numeric, 'Tanque 2: 341.8 L (G-INI-01)');
  return next is((t.lotes->0->>'abv')::numeric, 44.9::numeric, 'Tanque 2: el grado vigente es el de la unión (44.9)');
  return next is(t.lotes->0->>'abv_by', 'Benito Cruz', 'quién declaró el grado vigente');

  -- ── Aislamiento: Prueba B ve solo lo suyo ────────────────────────────
  perform pg_temp.como(admin_b);
  select count(*) into n from tinas_en_uso;
  return next is(n, 0, 'Prueba B: sin tinas en uso');
  select count(*) into n from corridas;
  return next is(n, 0, 'Prueba B: sin corridas');
  select count(*) into n from tanques;
  return next is(n, 0, 'Prueba B: sin tanques (solo tiene Tina B1)');
  select count(*) into n from colectores_con_saldo;
  return next is(n, 0, 'Prueba B: sin colectores');
  select count(*) into n from attachments;
  return next is(n, 0, 'Prueba B no ve los adjuntos de A');

  -- ── Evidencias: bucket privado y políticas (0027) ────────────────────
  execute 'reset role';
  return next is((select public from storage.buckets where id = 'evidencias'), false, 'el bucket evidencias es privado');
  return next is((select file_size_limit from storage.buckets where id = 'evidencias'), 10485760::bigint, 'límite 10 MB');
  return next ok((select 'application/pdf' = any(allowed_mime_types) from storage.buckets where id = 'evidencias'), 'acepta PDF');
  select count(*) into n from pg_policies where schemaname = 'storage' and tablename = 'objects' and policyname like 'evidencias_%';
  return next is(n, 2, 'dos políticas: leer y subir (nadie borra)');
  return next is(storage_org_of(a::text || '/foto.jpg'), a, 'storage_org_of saca la empresa de la carpeta raíz');

  -- Ids resueltos como superusuario para que las pruebas de RLS no fallen
  -- por un null (la RLS ya esconde las filas de A a quien no es de A).
  select id into v_op   from operations where organization_id = a and idempotency_key = 'f359b20f-cf7c-428a-83f4-cddaff780aa4';
  select id into v_lot  from lots where organization_id = a and folio = 'FER-T1-001';
  select id into v_foto from catalog_items where organization_id = a and template_id = 'e4966301-96da-5221-8658-fecbb86b2319';
  select id into v_tanq from catalog_items where organization_id = a and template_id = '51470f4b-702a-5bd5-b38d-90d2a82f9648';

  -- El operador crea la fila del adjunto de su empresa
  perform pg_temp.como(oper_a);
  insert into attachments (organization_id, operation_id, lot_id, kind_item_id, storage_path, caption)
  values (a, v_op, v_lot, v_foto, a::text || '/fer-t1-001/dia-1.jpg', 'Tina 1, día 1')
  returning id into v_att;
  return next ok(v_att is not null, 'el operador registra la foto de su medición');
  return next throws_like(
    format($q$insert into attachments (organization_id, operation_id, lot_id, kind_item_id, storage_path)
           values ('%s', '%s', '%s', '%s', '%s/x.jpg')$q$, a, v_op, v_lot, v_tanq, a),
    '%tipo_adjunto%', 'el tipo del adjunto debe ser del catálogo tipo_adjunto');
  return next throws_like(
    format($q$update attachments set caption = 'otra' where id = '%s'$q$, v_att),
    '%permission denied%', 'nadie edita una evidencia (ni siquiera hay GRANT de update)');

  perform pg_temp.como(admin_b);
  return next throws_like(
    format($q$insert into attachments (organization_id, operation_id, lot_id, kind_item_id, storage_path)
           values ('%s', '%s', '%s', '%s', '%s/x.jpg')$q$, a, v_op, v_lot, v_foto, a),
    '%tipo_adjunto%', 'el admin de B no adjunta nada a A (el trigger ya no le encuentra ni el catálogo de A: la RLS lo esconde antes de llegar a la política)');
end $$;

select * from runtests((select nspname from pg_namespace where oid = pg_my_temp_schema())::name, '^test_');


rollback;
