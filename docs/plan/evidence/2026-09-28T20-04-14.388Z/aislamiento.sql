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
-- tomas.h → 'tomas-2026' · dueña B → 'qa-c70288cb6e9f-prueba-b-2026' · admin → 'pulz-2026'
-- ---------------------------------------------------------------------
insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
                        raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
                        confirmation_token, recovery_token, email_change_token_new, email_change) values
  ('00000000-0000-0000-0000-000000000000', '05110bc8-8e1e-4fde-9982-bd796263c31b', 'authenticated', 'authenticated', 'qa-c70288cb6e9f-tu@pulz.mx',
   extensions.crypt('pulz-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '9a7386b2-f5fb-4a44-81ab-104f81e47a0a', 'authenticated', 'authenticated', 'qa-c70288cb6e9f-benito@cuatrovientos.mx',
   extensions.crypt('benito-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', 'd54f424b-842b-46e6-861c-2288c0830869', 'authenticated', 'authenticated', 'qa-c70288cb6e9f-aurelia@eebd520d-5b6a-49f4-9130-6b3cc96962c7.usuarios.pulz.mx',
   extensions.crypt('aurelia-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '45efa42c-ef9f-4b05-b048-c4e4025dcca4', 'authenticated', 'authenticated', 'qa-c70288cb6e9f-tomas.h@eebd520d-5b6a-49f4-9130-6b3cc96962c7.usuarios.pulz.mx',
   extensions.crypt('tomas-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '9d040584-1da0-4086-863c-3ffde9bd23a4', 'authenticated', 'authenticated', 'qa-c70288cb6e9f-duena@pruebab.mx',
   extensions.crypt('qa-c70288cb6e9f-prueba-b-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '');

insert into profiles (id, full_name) values
  ('05110bc8-8e1e-4fde-9982-bd796263c31b', 'Admin PULZ'),
  ('9a7386b2-f5fb-4a44-81ab-104f81e47a0a', 'Benito Cruz'),
  ('d54f424b-842b-46e6-861c-2288c0830869', 'Aurelia Santiago'),
  ('45efa42c-ef9f-4b05-b048-c4e4025dcca4', 'Tomás Hernández'),
  ('9d040584-1da0-4086-863c-3ffde9bd23a4', 'Dueña Prueba B');

insert into platform_admins (user_id) values ('05110bc8-8e1e-4fde-9982-bd796263c31b');

-- Planes (§14, §18 #2 y #3)
-- Fixture: reutiliza plans canónica, sin modificarla.
-- Fixture: reutiliza plan_limits canónica, sin modificarla.
-- Fixture: reutiliza plan_features canónica, sin modificarla.

-- Empresas
insert into organizations (id, name, slug, state, brand_color, logo_path, welcome_message, created_by) values
  ('eebd520d-5b6a-49f4-9130-6b3cc96962c7', 'Mezcal Cuatro Vientos', 'qa-c70288cb6e9f-cuatro-vientos', 'Oaxaca', '#7A3E1D', null, 'Registro de producción del palenque', '9a7386b2-f5fb-4a44-81ab-104f81e47a0a'),
  ('95d75927-77ce-4013-a34c-317853149090', 'Palenque Prueba B', 'qa-c70288cb6e9f-prueba-b', 'Oaxaca', '#173F87', null, 'Empresa de prueba', '9d040584-1da0-4086-863c-3ffde9bd23a4');
insert into organization_slug_history (slug, organization_id, retired_at, retired_by) values
  ('qa-c70288cb6e9f-mezcal-cuatro-vientos', 'eebd520d-5b6a-49f4-9130-6b3cc96962c7', '2026-09-02 09:00:00-06', '9a7386b2-f5fb-4a44-81ab-104f81e47a0a');
insert into organization_members (organization_id, user_id, role, status, username, must_change_password) values
  ('eebd520d-5b6a-49f4-9130-6b3cc96962c7', '9a7386b2-f5fb-4a44-81ab-104f81e47a0a', 'admin', 'activo', null, false),
  ('eebd520d-5b6a-49f4-9130-6b3cc96962c7', 'd54f424b-842b-46e6-861c-2288c0830869', 'productor', 'activo', 'aurelia', false),
  ('eebd520d-5b6a-49f4-9130-6b3cc96962c7', '45efa42c-ef9f-4b05-b048-c4e4025dcca4', 'operador', 'activo', 'tomas.h', true),
  ('95d75927-77ce-4013-a34c-317853149090', '9d040584-1da0-4086-863c-3ffde9bd23a4', 'admin', 'activo', null, false);
insert into member_invitations (id, organization_id, user_id, token_hash, expires_at, used_at, created_by) values
  ('1ea5f3ce-fe69-4922-b1f9-68dd4c31de8c', 'eebd520d-5b6a-49f4-9130-6b3cc96962c7', '45efa42c-ef9f-4b05-b048-c4e4025dcca4', 'qa-c70288cb6e9f:SIMULADO', '2026-09-05 10:00:00-06', null, '9a7386b2-f5fb-4a44-81ab-104f81e47a0a');
insert into login_throttle (user_id, failed_count, last_failed_at, locked_until) values
  ('45efa42c-ef9f-4b05-b048-c4e4025dcca4', 3, '2026-09-03 07:12:00-06', null);
insert into organization_settings (organization_id, record_puntas, measurement_mode, warn_mixed_second_pass, fermentation_expected_days, measurement_reminder_hour, default_folio_decision) values
  ('eebd520d-5b6a-49f4-9130-6b3cc96962c7', false, 'minimo', true, 7, 9, 'conservar'),
  ('95d75927-77ce-4013-a34c-317853149090', false, 'minimo', true, 7, 9, 'conservar');
insert into subscriptions (organization_id, plan_id, status, current_period_end) values
  ('eebd520d-5b6a-49f4-9130-6b3cc96962c7', 'edd15bcf-ad82-5684-a2e7-d85db401885b', 'prueba', '2026-10-15 00:00:00-06'),
  ('95d75927-77ce-4013-a34c-317853149090', 'ee35d6fd-b4d6-56d6-b7b4-61cb81932b21', 'gratis', null);

-- ---------------------------------------------------------------------
-- Plantillas de plataforma (§10.2.1)
-- ---------------------------------------------------------------------
-- Fixture: reutiliza catalog_item_templates canónica, sin modificarla.
-- Fixture: reutiliza movement_concept_templates canónica, sin modificarla.
-- Fixture: reutiliza species_templates canónica, sin modificarla.

select seed_organization_catalogs('eebd520d-5b6a-49f4-9130-6b3cc96962c7');
select seed_organization_catalogs('95d75927-77ce-4013-a34c-317853149090');

-- Lo propio de Cuatro Vientos y lo que oculta (§10.2.4)
insert into catalog_items (id, organization_id, template_id, catalog, name, sort_order, created_by) values
  ('4860fafb-a063-4bd1-ab8e-2baab84a9e76', 'eebd520d-5b6a-49f4-9130-6b3cc96962c7', null, 'tipo_alambique', 'Refrescadera de cobre', 100, '9a7386b2-f5fb-4a44-81ab-104f81e47a0a');
insert into movement_concepts (id, organization_id, template_id, direction, name, source_lot, creates_lot, asks_result, asks_counterparty, sort_order, created_by) values
  ('93cd0a21-8637-498a-9d68-20b371e79f13', 'eebd520d-5b6a-49f4-9130-6b3cc96962c7', null, 'salida', 'Regalo a cliente', 'no_aplica', false, false, true, 100, '9a7386b2-f5fb-4a44-81ab-104f81e47a0a');
update catalog_items set active = false
 where organization_id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7'
   and template_id in ('5c985133-23d9-50fa-a252-6ff6b5b74134', 'b1fce67a-21bf-50a7-9344-fdf29eb5331e');
update movement_concepts set active = false
 where organization_id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7'
   and template_id = '8b7f6579-99ef-549e-b427-b1d4d8bea9da';

-- ---------------------------------------------------------------------
-- Ayudas de la semilla (temporales; mueren con la sesión). security definer
-- para que resuelvan ids aunque el rol activo sea 'authenticated'.
-- ---------------------------------------------------------------------
create function pg_temp.seed_a() returns uuid language sql immutable as $$ select 'eebd520d-5b6a-49f4-9130-6b3cc96962c7'::uuid $$;
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
  ('8aedaea7-bce5-4828-8eb8-7f641264f2cd', pg_temp.seed_a(), 'Loma del Toro', 'Santiago Matatlán', 'Familia Cruz');
insert into suppliers (id, organization_id, name, type_item_id) values
  ('afeae7c8-8e5b-4b0b-9e80-aa8933a0ea55', pg_temp.seed_a(), 'Magueyes Don Pedro', pg_temp.seed_cat('640b537d-bf52-5c4b-b407-a5f4fb7c5800')),
  ('0b01b96c-3243-4ae7-a319-9dffeb29f738', pg_temp.seed_a(), 'Destilados Hermanos Luna', pg_temp.seed_cat('bb234638-3c78-56cd-9f41-2fb38182f181'));
insert into supplies (id, organization_id, name, unit_item_id) values
  ('c1967115-f7d1-484e-8619-2acde5fcb82a', pg_temp.seed_a(), 'Pulque como inóculo', pg_temp.seed_cat('bc6f104d-2841-5b36-b492-76b36becb172'));
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy, liquid_class) values
  ('132cb9c2-04c2-4134-8c81-7c4bdcd61fe9', pg_temp.seed_a(), 'horno', 'Horno 1', pg_temp.seed_cat('d53ba2da-cada-5215-804a-ff304d569f97'), 10000, 'kg', 'libre', null),
  ('a6bf1986-9ad0-4fa8-9b15-c521af7f23a7', pg_temp.seed_a(), 'molino', 'Tahona', pg_temp.seed_cat('60285283-d000-52f0-95da-d2b2e6d70fa1'), null, 'kg', 'libre', null),
  ('276b3698-49fd-420a-af92-149853dd1d9b', pg_temp.seed_a(), 'tina', 'Tina 1', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('596dcf86-8099-41e0-b918-879c43c04998', pg_temp.seed_a(), 'tina', 'Tina 2', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('890e9e66-edad-4d54-a04e-e8a4de13c00a', pg_temp.seed_a(), 'tina', 'Tina 3', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('b7380ec7-090e-4f86-a385-55f096a8719b', pg_temp.seed_a(), 'alambique', 'Alambique 1', pg_temp.seed_cat('af73010e-53f2-5769-b3b1-6cda154e665e'), 300, 'L', 'estricta', null),
  ('dfd73958-5708-465d-8d38-b92086f3448e', pg_temp.seed_a(), 'alambique', 'Alambique 2', '4860fafb-a063-4bd1-ab8e-2baab84a9e76', 250, 'L', 'estricta', null),
  ('dfdfb15d-fe72-4e23-8e04-e02024f76a4d', pg_temp.seed_a(), 'colector', 'Colector mezcal', pg_temp.seed_cat('2cd7e70b-6246-543e-8f67-23743fefdf95'), 60, 'L', 'flexible', 'mezcal'),
  ('19280026-6bfd-4e5d-a729-160056b15a18', pg_temp.seed_a(), 'colector', 'Colector ordinario', pg_temp.seed_cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'ordinario'),
  ('891c473a-fa44-4474-b1dd-e7cfe767add4', pg_temp.seed_a(), 'colector', 'Colector colas', pg_temp.seed_cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'colas'),
  ('b05e03cd-e1d7-45d7-b63c-ec5d72b747e2', pg_temp.seed_a(), 'tanque', 'Tanque 1', pg_temp.seed_cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1000, 'L', 'flexible', null),
  ('3aa74e02-75f0-4ac7-98c9-0b3ee72fa4d9', pg_temp.seed_a(), 'tanque', 'Tanque 2', pg_temp.seed_cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1500, 'L', 'flexible', null);

-- Palenque Prueba B: lo mínimo para probar aislamiento
insert into predios (id, organization_id, name, municipality) values
  ('6e0a9769-6782-47c2-821b-c549327743c3', '95d75927-77ce-4013-a34c-317853149090', 'Predio B', 'Ejutla');
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy) values
  ('92c6b0ee-1467-4e97-b0c2-e825bfd1f320', '95d75927-77ce-4013-a34c-317853149090', 'tina', 'Tina B1',
   (select id from catalog_items where organization_id = '95d75927-77ce-4013-a34c-317853149090' and template_id = 'b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1000, 'L', 'flexible');

-- =====================================================================
-- Cuatro Vientos: la producción, POR RPC, en orden cronológico
-- =====================================================================

-- 2026-09-01 · Benito: lo que ya había en el Tanque 2 (carga inicial)
select pg_temp.seed_como('9a7386b2-f5fb-4a44-81ab-104f81e47a0a');
select registrar_entrada(pg_temp.seed_a(), '30ce66cc-2ac2-46c1-977f-daf0db65a940', '2026-09-01 10:15:00-06',
  'granel', pg_temp.seed_res('Tanque 2'), 600, 44.2, 'mezcal', 'carga_inicial',
  p_concepto => pg_temp.seed_con('255e79f1-12b3-5969-8453-e40623275559'),
  p_nota => 'Lo que ya había en el tanque al empezar', p_folio => 'G-INI-01');

-- 2026-09-01 · Aurelia: la Tina 3 ya fermentaba
select pg_temp.seed_como('d54f424b-842b-46e6-861c-2288c0830869');
select registrar_entrada(pg_temp.seed_a(), '93549cf5-9f61-48f7-8aae-a38e641f2838', '2026-09-01 10:40:00-06',
  'fermentado', pg_temp.seed_res('Tina 3'), 1300, null, null, 'carga_inicial',
  p_nota => 'Tina que ya fermentaba', p_folio => 'FER-T3-INI');

-- 2026-09-02 · Aurelia: recepción de maguey
select registrar_recepcion_maguey(pg_temp.seed_a(), '909e6afb-9c88-49d2-a207-0959320f1ee1', '2026-09-02 07:30:00-06',
  8000, pg_temp.seed_esp('67a96efd-2c72-528e-8682-d144fe1f802c'), '8aedaea7-bce5-4828-8eb8-7f641264f2cd',
  'afeae7c8-8e5b-4b0b-9e80-aa8933a0ea55', 132, 'Piñas de 8 años, buen tamaño', 'MAG-001');

-- 2026-09-02 · Horneado (la simulación lo abría Tomás; §11.1 lo reserva a
-- admin/productor, así que lo abre Aurelia — docs/DECISIONES.md)
select abrir_horneado(pg_temp.seed_a(), 'd7156216-9fa2-4347-b145-e575b2844a1d', '2026-09-02 12:00:00-06',
  pg_temp.seed_res('Horno 1'), array[pg_temp.seed_lot('MAG-001')], array[8000::numeric], p_folio => 'HOR-001');
-- 2026-09-06 · Aurelia cierra: 6,200 kg de agave cocido
select cerrar_horneado(pg_temp.seed_a(), 'a138a73a-2449-4a89-9ae0-7654d9b83d92', '2026-09-06 08:00:00-06',
  pg_temp.seed_hor('HOR-001'), 6200, 'Leña de encino', p_folio => 'AC-001');

-- 2026-09-07 · Aurelia: formulación repartida a Tina 1 y Tina 2
select registrar_formulacion(pg_temp.seed_a(), '30dc2551-1fa8-4917-99c4-c85fac395e39', '2026-09-07 09:00:00-06',
  pg_temp.seed_res('Tahona'), array[pg_temp.seed_lot('AC-001')], array[6200::numeric], 1900,
  array[pg_temp.seed_res('Tina 1'), pg_temp.seed_res('Tina 2')], array[1400::numeric, 1400::numeric],
  array['c1967115-f7d1-484e-8619-2acde5fcb82a'::uuid], array[20::numeric],
  'Tahona con mula', null, 'F-001', array['FER-T1-001', 'FER-T2-001']);

-- Mediciones diarias (escala de actividad 1–6, §18 #1; la simulación traía 7 y 8)
-- Tina 1
select pg_temp.seed_como('45efa42c-ef9f-4b05-b048-c4e4025dcca4');
select registrar_medicion(pg_temp.seed_a(), '2b48e343-6a08-4e6b-8be3-d8ab05ac19c7', '2026-09-08 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 1, 'minimo', 4,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.5,12.0]::numeric[]);
select pg_temp.seed_como('d54f424b-842b-46e6-861c-2288c0830869');
select registrar_medicion(pg_temp.seed_a(), '838176ea-62b4-41ca-aed5-d487ec403e57', '2026-09-09 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.0,9.5]::numeric[]);
select pg_temp.seed_como('45efa42c-ef9f-4b05-b048-c4e4025dcca4');
select registrar_medicion(pg_temp.seed_a(), '08a6a03a-4ab4-4498-bb0c-b319ce1b3e8e', '2026-09-10 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.5,6.0]::numeric[]);
select pg_temp.seed_como('d54f424b-842b-46e6-861c-2288c0830869');
select registrar_medicion(pg_temp.seed_a(), '8bcf3bde-9f5c-4b3f-a056-d9c664a8d2f6', '2026-09-11 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 4, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.5,3.5]::numeric[]);
select pg_temp.seed_como('45efa42c-ef9f-4b05-b048-c4e4025dcca4');
select registrar_medicion(pg_temp.seed_a(), 'ea127f95-47ed-484e-a602-41ecc7e2deff', '2026-09-12 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 5, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.0,1.5]::numeric[]);
-- Tina 2
select registrar_medicion(pg_temp.seed_a(), '34643187-e2fc-47d9-b79a-cfa8d290dc9a', '2026-09-08 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 1, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.0,12.2]::numeric[]);
select registrar_medicion(pg_temp.seed_a(), 'd7924f65-cdb6-4696-85ff-beb579453765', '2026-09-09 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.5,10.1]::numeric[]);
select registrar_medicion(pg_temp.seed_a(), '8a06aa00-3eb3-4114-a835-71ab8173464c', '2026-09-10 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.0,7.4]::numeric[]);

-- 2026-09-12 · Aurelia declara lista la Tina 1
select pg_temp.seed_como('d54f424b-842b-46e6-861c-2288c0830869');
select declarar_tina_lista(pg_temp.seed_a(), 'bf0f04e5-adbc-4d63-96b1-93397feeac6c', '2026-09-12 17:00:00-06',
  pg_temp.seed_cyc('Tina 1'), 'Día 5: ya no burbujea, sabor seco');

-- 2026-09-13 · Tomás: dos corridas de 1ª pasada desde la Tina 1
select pg_temp.seed_como('45efa42c-ef9f-4b05-b048-c4e4025dcca4');
select abrir_corrida(pg_temp.seed_a(), '4d976582-a52b-4234-842d-08a148fc4da9', '2026-09-13 06:00:00-06',
  pg_temp.seed_res('Alambique 1'), 'primera', array[pg_temp.seed_res('Tina 1')], array[pg_temp.seed_lot('FER-T1-001')], array[290::numeric],
  p_folio => 'DES-001');
select registrar_corte(pg_temp.seed_a(), '935f607d-71f4-4492-8ed1-a20c6ec5a49f', '2026-09-13 08:00:00-06', pg_temp.seed_run('DES-001'), 'mezcal', 8, 51.0, pg_temp.seed_res('Colector mezcal'), p_folio => 'MEZ-001');
select registrar_corte(pg_temp.seed_a(), 'ceae336a-b144-457c-b85c-4cbd63f86421', '2026-09-13 10:00:00-06', pg_temp.seed_run('DES-001'), 'ordinario', 40, 24.0, pg_temp.seed_res('Colector ordinario'), p_folio => 'ORD-001');
select registrar_corte(pg_temp.seed_a(), '8a8f7bbd-3346-4e85-b143-f442801c60f1', '2026-09-13 12:00:00-06', pg_temp.seed_run('DES-001'), 'colas', 12, 9.0, pg_temp.seed_res('Colector colas'), p_folio => 'COL-001');
select cerrar_corrida(pg_temp.seed_a(), 'bdbf732f-6514-4f07-afd8-7b44c2c25a0b', '2026-09-13 14:00:00-06', pg_temp.seed_run('DES-001'));

select abrir_corrida(pg_temp.seed_a(), 'dda5a8b7-01d4-487c-a2bb-8fd00e869695', '2026-09-13 06:00:00-06',
  pg_temp.seed_res('Alambique 2'), 'primera', array[pg_temp.seed_res('Tina 1')], array[pg_temp.seed_lot('FER-T1-001')], array[240::numeric],
  p_folio => 'DES-002');
select registrar_corte(pg_temp.seed_a(), '851bedbe-3714-447c-b4b6-d356bc459450', '2026-09-13 08:00:00-06', pg_temp.seed_run('DES-002'), 'mezcal', 6, 50.0, pg_temp.seed_res('Colector mezcal'));
select registrar_corte(pg_temp.seed_a(), '378e8db3-140f-4b41-8755-834da4d12f95', '2026-09-13 10:00:00-06', pg_temp.seed_run('DES-002'), 'ordinario', 34, 23.0, pg_temp.seed_res('Colector ordinario'));
select registrar_corte(pg_temp.seed_a(), '6e24bdf2-1799-4224-b008-4ab0b47332c8', '2026-09-13 12:00:00-06', pg_temp.seed_run('DES-002'), 'colas', 10, 8.0, pg_temp.seed_res('Colector colas'));
select cerrar_corrida(pg_temp.seed_a(), '369e4271-ef41-406e-9cee-e13343e57835', '2026-09-13 14:00:00-06', pg_temp.seed_run('DES-002'));

-- 2026-09-15 · Tomás: 2ª pasada con ordinario y colas juntos (aviso + nota)
select abrir_corrida(pg_temp.seed_a(), 'df829ec0-a166-44da-9c35-ff4af88ab2aa', '2026-09-15 06:00:00-06',
  pg_temp.seed_res('Alambique 1'), 'segunda',
  array[pg_temp.seed_res('Colector ordinario'), pg_temp.seed_res('Colector colas')],
  array[pg_temp.seed_lot('ORD-001'), pg_temp.seed_lot('COL-001')], array[74::numeric, 22::numeric],
  'Había olla libre y poca cola; se juntó con el ordinario', 'DES-003');
select registrar_corte(pg_temp.seed_a(), 'fa0a7c34-cee1-4387-9437-7023ecb12294', '2026-09-15 08:00:00-06', pg_temp.seed_run('DES-003'), 'mezcal', 26, 52.5, pg_temp.seed_res('Colector mezcal'));
select registrar_corte(pg_temp.seed_a(), 'f850e402-4402-4556-912f-c4c1785f0586', '2026-09-15 10:00:00-06', pg_temp.seed_run('DES-003'), 'colas', 16, 10.0, pg_temp.seed_res('Colector colas'), p_folio => 'COL-002');
select cerrar_corrida(pg_temp.seed_a(), 'c25f7f13-d9f7-4001-a72c-2d28efcd03c2', '2026-09-15 14:00:00-06', pg_temp.seed_run('DES-003'));

-- 2026-09-16 · Aurelia: el mezcal del colector pasa a granel con folio nuevo
select pg_temp.seed_como('d54f424b-842b-46e6-861c-2288c0830869');
select transferir(pg_temp.seed_a(), '7a6db54d-713a-4627-abb1-f35040cc2077', '2026-09-16 09:00:00-06',
  pg_temp.seed_res('Colector mezcal'), pg_temp.seed_res('Tanque 1'), pg_temp.seed_lot('MEZ-001'), 40, 51.6, 'renombrar', 'G-2609-01');
-- Agua para bajar grado: 4 L, declara 43.8 L (contracción) y 47.0 %
select registrar_movimiento_granel(pg_temp.seed_a(), '6f49663c-e06a-4b71-af39-a4ba78354ed6', '2026-09-16 11:00:00-06',
  pg_temp.seed_con('66a151e2-9a2c-58be-ad4a-b117f1ddb717'), pg_temp.seed_res('Tanque 1'), 4,
  p_lote => pg_temp.seed_lot('G-2609-01'), p_resultado_l => 43.8, p_resultado_abv => 47.0);

-- 2026-09-17 · Benito: puntas guardadas (sin lote) al Tanque 2
select pg_temp.seed_como('9a7386b2-f5fb-4a44-81ab-104f81e47a0a');
select registrar_movimiento_granel(pg_temp.seed_a(), '06b36051-ca94-47f2-9760-443f20d7de6f', '2026-09-17 10:00:00-06',
  pg_temp.seed_con('f21aaad8-2ef6-556b-be55-64aa94431ab6'), pg_temp.seed_res('Tanque 2'), 2,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_resultado_l => 602, p_resultado_abv => 44.6, p_abv => 68.0,
  p_nota => 'Puntas guardadas de corridas de agosto, sin lote');
-- 2026-09-18 · Benito: unión de G-2609-01 (Tanque 1) con G-INI-01 (Tanque 2), se conserva el folio mayor
select registrar_movimiento_granel(pg_temp.seed_a(), 'd2bcd96e-4946-498f-965e-e0ab5882f19f', '2026-09-18 09:30:00-06',
  pg_temp.seed_con('df427d88-600e-550e-a097-8ffe4f4dd556'), pg_temp.seed_res('Tanque 2'), 43.8,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_lote_origen => pg_temp.seed_lot('G-2609-01'), p_recurso_origen => pg_temp.seed_res('Tanque 1'),
  p_resultado_l => 645.8, p_resultado_abv => 44.9, p_decision => 'conservar', p_nota => 'Se conserva el folio del lote mayor');
-- 2026-09-19 · Benito: compra de granel al Tanque 1
select registrar_movimiento_granel(pg_temp.seed_a(), '080f50ec-0172-4f01-a3e7-02679667244c', '2026-09-19 12:00:00-06',
  pg_temp.seed_con('688430a9-cd2f-5bae-add2-c59bc543d911'), pg_temp.seed_res('Tanque 1'), 250,
  p_resultado_l => 250, p_resultado_abv => 46.0, p_abv => 46.0, p_folio_nuevo => 'G-COMPRA-01',
  p_contraparte => 'Destilados Hermanos Luna', p_documento => 'Remisión 0452',
  p_proveedor => '0b01b96c-3243-4ae7-a319-9dffeb29f738', p_especie => pg_temp.seed_esp('67a96efd-2c72-528e-8682-d144fe1f802c'),
  p_predio_declarado => 'Sola de Vega');

-- 2026-09-19 · Aurelia: muestra de laboratorio
select pg_temp.seed_como('d54f424b-842b-46e6-861c-2288c0830869');
select registrar_movimiento_granel(pg_temp.seed_a(), 'd2b3ac11-eb3f-4dc0-9ff9-83e07d641a26', '2026-09-19 13:00:00-06',
  pg_temp.seed_con('2d62ab89-6a11-558c-8b46-5c4d30aa1607'), pg_temp.seed_res('Tanque 2'), 1,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Laboratorio ficticio de Oaxaca', p_documento => 'Análisis 2026-311');

-- 2026-09-20/22 · Benito: autoconsumo, venta, regalo
select pg_temp.seed_como('9a7386b2-f5fb-4a44-81ab-104f81e47a0a');
select registrar_movimiento_granel(pg_temp.seed_a(), '10846a05-2231-4fca-bbc7-f8cd37b266f0', '2026-09-20 13:00:00-06',
  pg_temp.seed_con('fa52f92b-de19-5d0c-972c-beb899bb2ccb'), pg_temp.seed_res('Tanque 2'), 2, p_lote => pg_temp.seed_lot('G-INI-01'));
select registrar_movimiento_granel(pg_temp.seed_a(), '8b187e93-291d-4757-a8a6-06196e3c28bf', '2026-09-22 13:00:00-06',
  pg_temp.seed_con('7b0ca7ca-f8ae-5f33-93d5-f0c174664ec1'), pg_temp.seed_res('Tanque 2'), 300,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.', p_documento => 'Remisión 118');
select registrar_movimiento_granel(pg_temp.seed_a(), '5cf2d43a-0477-490b-b487-c269e33fccb4', '2026-09-22 13:00:00-06',
  '93cd0a21-8637-498a-9d68-20b371e79f13', pg_temp.seed_res('Tanque 2'), 1,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.');

reset role;

-- Evidencia de la compra (los adjuntos no son RPC de §12)
insert into attachments (id, organization_id, operation_id, lot_id, kind_item_id, storage_path, caption) values
  ('11012c5e-ca5b-4f9e-ad14-f6b707aad15b', pg_temp.seed_a(),
   (select id from operations where organization_id = pg_temp.seed_a() and idempotency_key = '080f50ec-0172-4f01-a3e7-02679667244c'),
   pg_temp.seed_lot('G-COMPRA-01'), pg_temp.seed_cat('0522e23b-3b1d-58be-b50c-8a6ed0627c9f'),
   'evidencias/eebd520d-5b6a-49f4-9130-6b3cc96962c7/g-compra-01/remision-0452.jpg', 'Remisión del proveedor');


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
--   benito  9a7386b2-f5fb-4a44-81ab-104f81e47a0a  admin de Cuatro Vientos (A)
--   tomas   45efa42c-ef9f-4b05-b048-c4e4025dcca4  operador de A
--   dueña B 9d040584-1da0-4086-863c-3ffde9bd23a4  admin de Palenque Prueba B
--   nadie   5412d813-6714-48e6-bcd3-8a9359412eba  sin membresía
--   A = eebd520d-5b6a-49f4-9130-6b3cc96962c7   B = 95d75927-77ce-4013-a34c-317853149090


-- Filas de la empresa A visibles bajo la RLS del rol actual, sumadas en
-- todas las tablas de negocio y vistas. Debe ser 0 para quien no es de A.
create function pg_temp.rows_of_a() returns bigint language sql as $$
  select
    (select count(*) from catalog_items      where organization_id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7') +
    (select count(*) from movement_concepts  where organization_id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7') +
    (select count(*) from species            where organization_id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7') +
    (select count(*) from predios            where organization_id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7') +
    (select count(*) from suppliers          where organization_id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7') +
    (select count(*) from supplies           where organization_id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7') +
    (select count(*) from resources          where organization_id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7') +
    (select count(*) from operations         where organization_id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7') +
    (select count(*) from operation_warnings where organization_id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7') +
    (select count(*) from lots               where organization_id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7') +
    (select count(*) from lot_lineage        where organization_id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7') +
    (select count(*) from lot_external_sources where organization_id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7') +
    (select count(*) from maguey_receptions  where organization_id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7') +
    (select count(*) from liquid_movements   where organization_id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7') +
    (select count(*) from attachments        where organization_id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7') +
    (select count(*) from roasting_runs      where organization_id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7') +
    (select count(*) from roasting_run_inputs where organization_id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7') +
    (select count(*) from formulations       where organization_id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7') +
    (select count(*) from formulation_inputs where organization_id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7') +
    (select count(*) from formulation_supplies where organization_id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7') +
    (select count(*) from fermentation_cycles where organization_id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7') +
    (select count(*) from fermentation_measurements where organization_id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7') +
    (select count(*) from measurement_readings where organization_id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7') +
    (select count(*) from distillation_runs  where organization_id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7') +
    (select count(*) from distillation_run_inputs where organization_id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7') +
    (select count(*) from distillation_cuts  where organization_id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7') +
    (select count(*) from organization_members where organization_id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7') +
    (select count(*) from organization_settings where organization_id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7') +
    (select count(*) from subscriptions      where organization_id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7') +
    (select count(*) from resource_lot_balances where organization_id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7') +
    (select count(*) from movement_log       where organization_id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7');
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
  perform pg_temp.como('9a7386b2-f5fb-4a44-81ab-104f81e47a0a');
  return next is((select count(*) from organizations), 1::bigint, 'benito ve exactamente una empresa');
  return next is((select count(*) from resources), 12::bigint, 'benito ve los 12 recursos de Cuatro Vientos');
  return next is((select count(*) from resources where organization_id = '95d75927-77ce-4013-a34c-317853149090'), 0::bigint,
                 'benito no ve recursos de la empresa B');
  return next ok((select pg_temp.rows_of_a()) > 0, 'benito sí ve filas de su propia empresa');

  -- 2) dueña de B no lee, no inserta ni referencia nada de A
  perform pg_temp.como('9d040584-1da0-4086-863c-3ffde9bd23a4');
  return next is((select count(*) from organizations), 1::bigint, 'dueña B ve solo su empresa');
  return next is((select pg_temp.rows_of_a()), 0::bigint,
                 'dueña B no ve ninguna fila de A en ninguna tabla de negocio ni vista');
  return next throws_ok(
    $q$insert into resources (organization_id, kind, code, capacity_policy)
       values ('eebd520d-5b6a-49f4-9130-6b3cc96962c7', 'tina', 'Intrusa', 'flexible')$q$,
    '42501', null, 'dueña B no puede insertar un recurso en A (RLS)');
  return next throws_ok(
    $q$insert into resources (organization_id, kind, code, type_item_id, capacity_policy)
       values ('95d75927-77ce-4013-a34c-317853149090', 'alambique', 'Alambique B1',
               '4860fafb-a063-4bd1-ab8e-2baab84a9e76', 'estricta')$q$,
    null, null, 'dueña B no puede referenciar un catálogo de A (FK compuesta o trigger de tipo)');
  return next lives_ok(
    $q$update organizations set name = 'Hackeada' where id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7'$q$,
    'un update sobre A desde B no revienta: la RLS simplemente filtra 0 filas');
  execute 'reset role';
  return next is((select name from organizations where id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7'),
                 'Mezcal Cuatro Vientos', 'el nombre de A sigue intacto tras el intento desde B');

  -- 3) sin membresía activa no se ve nada
  perform pg_temp.como('5412d813-6714-48e6-bcd3-8a9359412eba');
  return next is((select count(*) from organizations), 0::bigint, 'un usuario sin membresía no ve empresas');
  return next is((select pg_temp.rows_of_a()), 0::bigint, 'un usuario sin membresía no ve filas de negocio');

  -- 4) el operador no ejecuta funciones de admin ni escribe infraestructura
  perform pg_temp.como('45efa42c-ef9f-4b05-b048-c4e4025dcca4');
  return next throws_ok(
    $q$select desbloquear_miembro('eebd520d-5b6a-49f4-9130-6b3cc96962c7', '45efa42c-ef9f-4b05-b048-c4e4025dcca4')$q$,
    'P0001', null, 'un operador no puede desbloquear miembros');
  return next throws_ok(
    $q$insert into resources (organization_id, kind, code, capacity_policy)
       values ('eebd520d-5b6a-49f4-9130-6b3cc96962c7', 'tina', 'Tina X', 'flexible')$q$,
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
        where b.organization_id = 'eebd520d-5b6a-49f4-9130-6b3cc96962c7'
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
