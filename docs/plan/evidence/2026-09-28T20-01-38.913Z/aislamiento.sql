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
-- tomas.h → 'tomas-2026' · dueña B → 'qa-3b94a7a4b8464cb8-prueba-b-2026' · admin → 'pulz-2026'
-- ---------------------------------------------------------------------
insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
                        raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
                        confirmation_token, recovery_token, email_change_token_new, email_change) values
  ('00000000-0000-0000-0000-000000000000', 'd526a292-376f-4b86-937b-0f2223ba7afd', 'authenticated', 'authenticated', 'qa-3b94a7a4b8464cb8-tu@pulz.mx',
   extensions.crypt('pulz-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', 'b4390fd1-fe87-4c67-b505-8233a13f3a39', 'authenticated', 'authenticated', 'qa-3b94a7a4b8464cb8-benito@cuatrovientos.mx',
   extensions.crypt('benito-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '9bd5648e-689a-4601-9017-73e55fd6f9b4', 'authenticated', 'authenticated', 'qa-3b94a7a4b8464cb8-aurelia@7277a529-4342-46d6-8aff-3d5ecb7ccc86.usuarios.pulz.mx',
   extensions.crypt('aurelia-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '302eecd0-765e-4ba7-b56d-63c114d971bb', 'authenticated', 'authenticated', 'qa-3b94a7a4b8464cb8-tomas.h@7277a529-4342-46d6-8aff-3d5ecb7ccc86.usuarios.pulz.mx',
   extensions.crypt('tomas-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '83a8186e-bdc5-46e3-a07a-b47c31ab7952', 'authenticated', 'authenticated', 'qa-3b94a7a4b8464cb8-duena@pruebab.mx',
   extensions.crypt('qa-3b94a7a4b8464cb8-prueba-b-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '');

insert into profiles (id, full_name) values
  ('d526a292-376f-4b86-937b-0f2223ba7afd', 'Admin PULZ'),
  ('b4390fd1-fe87-4c67-b505-8233a13f3a39', 'Benito Cruz'),
  ('9bd5648e-689a-4601-9017-73e55fd6f9b4', 'Aurelia Santiago'),
  ('302eecd0-765e-4ba7-b56d-63c114d971bb', 'Tomás Hernández'),
  ('83a8186e-bdc5-46e3-a07a-b47c31ab7952', 'Dueña Prueba B');

insert into platform_admins (user_id) values ('d526a292-376f-4b86-937b-0f2223ba7afd');

-- Planes (§14, §18 #2 y #3)
-- Fixture: reutiliza plans canónica, sin modificarla.
-- Fixture: reutiliza plan_limits canónica, sin modificarla.
-- Fixture: reutiliza plan_features canónica, sin modificarla.

-- Empresas
insert into organizations (id, name, slug, state, brand_color, logo_path, welcome_message, created_by) values
  ('7277a529-4342-46d6-8aff-3d5ecb7ccc86', 'Mezcal Cuatro Vientos', 'qa-3b94a7a4b8464cb8-cuatro-vientos', 'Oaxaca', '#7A3E1D', null, 'Registro de producción del palenque', 'b4390fd1-fe87-4c67-b505-8233a13f3a39'),
  ('97124588-60fc-476f-9d6f-f5ce010370aa', 'Palenque Prueba B', 'qa-3b94a7a4b8464cb8-prueba-b', 'Oaxaca', '#173F87', null, 'Empresa de prueba', '83a8186e-bdc5-46e3-a07a-b47c31ab7952');
insert into organization_slug_history (slug, organization_id, retired_at, retired_by) values
  ('qa-3b94a7a4b8464cb8-mezcal-cuatro-vientos', '7277a529-4342-46d6-8aff-3d5ecb7ccc86', '2026-09-02 09:00:00-06', 'b4390fd1-fe87-4c67-b505-8233a13f3a39');
insert into organization_members (organization_id, user_id, role, status, username, must_change_password) values
  ('7277a529-4342-46d6-8aff-3d5ecb7ccc86', 'b4390fd1-fe87-4c67-b505-8233a13f3a39', 'admin', 'activo', null, false),
  ('7277a529-4342-46d6-8aff-3d5ecb7ccc86', '9bd5648e-689a-4601-9017-73e55fd6f9b4', 'productor', 'activo', 'aurelia', false),
  ('7277a529-4342-46d6-8aff-3d5ecb7ccc86', '302eecd0-765e-4ba7-b56d-63c114d971bb', 'operador', 'activo', 'tomas.h', true),
  ('97124588-60fc-476f-9d6f-f5ce010370aa', '83a8186e-bdc5-46e3-a07a-b47c31ab7952', 'admin', 'activo', null, false);
insert into member_invitations (id, organization_id, user_id, token_hash, expires_at, used_at, created_by) values
  ('b3a9b741-74b2-4624-9a27-b4345534a4f2', '7277a529-4342-46d6-8aff-3d5ecb7ccc86', '302eecd0-765e-4ba7-b56d-63c114d971bb', 'qa-3b94a7a4b8464cb8:SIMULADO', '2026-09-05 10:00:00-06', null, 'b4390fd1-fe87-4c67-b505-8233a13f3a39');
insert into login_throttle (user_id, failed_count, last_failed_at, locked_until) values
  ('302eecd0-765e-4ba7-b56d-63c114d971bb', 3, '2026-09-03 07:12:00-06', null);
insert into organization_settings (organization_id, record_puntas, measurement_mode, warn_mixed_second_pass, fermentation_expected_days, measurement_reminder_hour, default_folio_decision) values
  ('7277a529-4342-46d6-8aff-3d5ecb7ccc86', false, 'minimo', true, 7, 9, 'conservar'),
  ('97124588-60fc-476f-9d6f-f5ce010370aa', false, 'minimo', true, 7, 9, 'conservar');
insert into subscriptions (organization_id, plan_id, status, current_period_end) values
  ('7277a529-4342-46d6-8aff-3d5ecb7ccc86', 'edd15bcf-ad82-5684-a2e7-d85db401885b', 'prueba', '2026-10-15 00:00:00-06'),
  ('97124588-60fc-476f-9d6f-f5ce010370aa', 'ee35d6fd-b4d6-56d6-b7b4-61cb81932b21', 'gratis', null);

-- ---------------------------------------------------------------------
-- Plantillas de plataforma (§10.2.1)
-- ---------------------------------------------------------------------
-- Fixture: reutiliza catalog_item_templates canónica, sin modificarla.
-- Fixture: reutiliza movement_concept_templates canónica, sin modificarla.
-- Fixture: reutiliza species_templates canónica, sin modificarla.

select seed_organization_catalogs('7277a529-4342-46d6-8aff-3d5ecb7ccc86');
select seed_organization_catalogs('97124588-60fc-476f-9d6f-f5ce010370aa');

-- Lo propio de Cuatro Vientos y lo que oculta (§10.2.4)
insert into catalog_items (id, organization_id, template_id, catalog, name, sort_order, created_by) values
  ('933ddf27-bd66-4a42-be2f-1e60bd1c31ce', '7277a529-4342-46d6-8aff-3d5ecb7ccc86', null, 'tipo_alambique', 'Refrescadera de cobre', 100, 'b4390fd1-fe87-4c67-b505-8233a13f3a39');
insert into movement_concepts (id, organization_id, template_id, direction, name, source_lot, creates_lot, asks_result, asks_counterparty, sort_order, created_by) values
  ('fe7e0303-27c9-4bb3-ba50-64666f8923f4', '7277a529-4342-46d6-8aff-3d5ecb7ccc86', null, 'salida', 'Regalo a cliente', 'no_aplica', false, false, true, 100, 'b4390fd1-fe87-4c67-b505-8233a13f3a39');
update catalog_items set active = false
 where organization_id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86'
   and template_id in ('5c985133-23d9-50fa-a252-6ff6b5b74134', 'b1fce67a-21bf-50a7-9344-fdf29eb5331e');
update movement_concepts set active = false
 where organization_id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86'
   and template_id = '8b7f6579-99ef-549e-b427-b1d4d8bea9da';

-- ---------------------------------------------------------------------
-- Ayudas de la semilla (temporales; mueren con la sesión). security definer
-- para que resuelvan ids aunque el rol activo sea 'authenticated'.
-- ---------------------------------------------------------------------
create function pg_temp.seed_a() returns uuid language sql immutable as $$ select '7277a529-4342-46d6-8aff-3d5ecb7ccc86'::uuid $$;
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
  ('fd1cb1e4-84be-48fd-9fbb-5debda39c8a3', pg_temp.seed_a(), 'Loma del Toro', 'Santiago Matatlán', 'Familia Cruz');
insert into suppliers (id, organization_id, name, type_item_id) values
  ('3a9160ae-e677-42ff-89e0-8d60567e5ed2', pg_temp.seed_a(), 'Magueyes Don Pedro', pg_temp.seed_cat('640b537d-bf52-5c4b-b407-a5f4fb7c5800')),
  ('cced587f-ff5b-4743-bd69-8b2e5043bfae', pg_temp.seed_a(), 'Destilados Hermanos Luna', pg_temp.seed_cat('bb234638-3c78-56cd-9f41-2fb38182f181'));
insert into supplies (id, organization_id, name, unit_item_id) values
  ('6874b38f-b75b-4660-a9fb-bcf819248424', pg_temp.seed_a(), 'Pulque como inóculo', pg_temp.seed_cat('bc6f104d-2841-5b36-b492-76b36becb172'));
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy, liquid_class) values
  ('4faf719e-3e97-4ee0-b9da-7e1c06ca625c', pg_temp.seed_a(), 'horno', 'Horno 1', pg_temp.seed_cat('d53ba2da-cada-5215-804a-ff304d569f97'), 10000, 'kg', 'libre', null),
  ('867eeef9-8ef5-414f-bacd-05f0ff146307', pg_temp.seed_a(), 'molino', 'Tahona', pg_temp.seed_cat('60285283-d000-52f0-95da-d2b2e6d70fa1'), null, 'kg', 'libre', null),
  ('8b8f48cb-8ccd-46ad-82f7-9ba53a85948b', pg_temp.seed_a(), 'tina', 'Tina 1', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('f5cc6fba-d77d-4f1e-83f8-bd640d34a9cd', pg_temp.seed_a(), 'tina', 'Tina 2', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('3edd46cd-c0b5-4728-bcf8-390664ff8e35', pg_temp.seed_a(), 'tina', 'Tina 3', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('6e544b83-3c13-4b8c-b1e6-5bf87f3fc4b5', pg_temp.seed_a(), 'alambique', 'Alambique 1', pg_temp.seed_cat('af73010e-53f2-5769-b3b1-6cda154e665e'), 300, 'L', 'estricta', null),
  ('22f17c96-7d3f-44be-881a-3d148bf9f02c', pg_temp.seed_a(), 'alambique', 'Alambique 2', '933ddf27-bd66-4a42-be2f-1e60bd1c31ce', 250, 'L', 'estricta', null),
  ('cd5513b4-f935-4eb9-b360-6e375e587d87', pg_temp.seed_a(), 'colector', 'Colector mezcal', pg_temp.seed_cat('2cd7e70b-6246-543e-8f67-23743fefdf95'), 60, 'L', 'flexible', 'mezcal'),
  ('6482256c-b41a-4fb3-8347-c11cb4038138', pg_temp.seed_a(), 'colector', 'Colector ordinario', pg_temp.seed_cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'ordinario'),
  ('af4d3600-0996-4da8-9fed-8df3b9ab6af2', pg_temp.seed_a(), 'colector', 'Colector colas', pg_temp.seed_cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'colas'),
  ('4dd59fb6-bf18-4d58-afd6-cb7d6c3ccf40', pg_temp.seed_a(), 'tanque', 'Tanque 1', pg_temp.seed_cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1000, 'L', 'flexible', null),
  ('7e75db1e-2164-497d-9b76-bbfaed4c517d', pg_temp.seed_a(), 'tanque', 'Tanque 2', pg_temp.seed_cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1500, 'L', 'flexible', null);

-- Palenque Prueba B: lo mínimo para probar aislamiento
insert into predios (id, organization_id, name, municipality) values
  ('8778608c-3379-42f1-8f07-343f4b318f8a', '97124588-60fc-476f-9d6f-f5ce010370aa', 'Predio B', 'Ejutla');
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy) values
  ('af40eb5c-448c-42dc-861f-68f6240c3b0b', '97124588-60fc-476f-9d6f-f5ce010370aa', 'tina', 'Tina B1',
   (select id from catalog_items where organization_id = '97124588-60fc-476f-9d6f-f5ce010370aa' and template_id = 'b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1000, 'L', 'flexible');

-- =====================================================================
-- Cuatro Vientos: la producción, POR RPC, en orden cronológico
-- =====================================================================

-- 2026-09-01 · Benito: lo que ya había en el Tanque 2 (carga inicial)
select pg_temp.seed_como('b4390fd1-fe87-4c67-b505-8233a13f3a39');
select registrar_entrada(pg_temp.seed_a(), '8ca111b1-e5a3-4b48-a206-812e8aa465ae', '2026-09-01 10:15:00-06',
  'granel', pg_temp.seed_res('Tanque 2'), 600, 44.2, 'mezcal', 'carga_inicial',
  p_concepto => pg_temp.seed_con('255e79f1-12b3-5969-8453-e40623275559'),
  p_nota => 'Lo que ya había en el tanque al empezar', p_folio => 'G-INI-01');

-- 2026-09-01 · Aurelia: la Tina 3 ya fermentaba
select pg_temp.seed_como('9bd5648e-689a-4601-9017-73e55fd6f9b4');
select registrar_entrada(pg_temp.seed_a(), 'a17cb12b-25b2-43c4-97be-6408d652770a', '2026-09-01 10:40:00-06',
  'fermentado', pg_temp.seed_res('Tina 3'), 1300, null, null, 'carga_inicial',
  p_nota => 'Tina que ya fermentaba', p_folio => 'FER-T3-INI');

-- 2026-09-02 · Aurelia: recepción de maguey
select registrar_recepcion_maguey(pg_temp.seed_a(), '04bd798e-1078-4c6e-b99d-0eb583d65c7f', '2026-09-02 07:30:00-06',
  8000, pg_temp.seed_esp('67a96efd-2c72-528e-8682-d144fe1f802c'), 'fd1cb1e4-84be-48fd-9fbb-5debda39c8a3',
  '3a9160ae-e677-42ff-89e0-8d60567e5ed2', 132, 'Piñas de 8 años, buen tamaño', 'MAG-001');

-- 2026-09-02 · Horneado (la simulación lo abría Tomás; §11.1 lo reserva a
-- admin/productor, así que lo abre Aurelia — docs/DECISIONES.md)
select abrir_horneado(pg_temp.seed_a(), '5f62c0a5-8386-4a0e-b4e2-3ddd38b48885', '2026-09-02 12:00:00-06',
  pg_temp.seed_res('Horno 1'), array[pg_temp.seed_lot('MAG-001')], array[8000::numeric], p_folio => 'HOR-001');
-- 2026-09-06 · Aurelia cierra: 6,200 kg de agave cocido
select cerrar_horneado(pg_temp.seed_a(), 'a18b3bb3-71f6-4f63-87af-5528ff2ac02b', '2026-09-06 08:00:00-06',
  pg_temp.seed_hor('HOR-001'), 6200, 'Leña de encino', p_folio => 'AC-001');

-- 2026-09-07 · Aurelia: formulación repartida a Tina 1 y Tina 2
select registrar_formulacion(pg_temp.seed_a(), '60c8d6e7-ab42-44cd-99c4-5dcea3e08d61', '2026-09-07 09:00:00-06',
  pg_temp.seed_res('Tahona'), array[pg_temp.seed_lot('AC-001')], array[6200::numeric], 1900,
  array[pg_temp.seed_res('Tina 1'), pg_temp.seed_res('Tina 2')], array[1400::numeric, 1400::numeric],
  array['6874b38f-b75b-4660-a9fb-bcf819248424'::uuid], array[20::numeric],
  'Tahona con mula', null, 'F-001', array['FER-T1-001', 'FER-T2-001']);

-- Mediciones diarias (escala de actividad 1–6, §18 #1; la simulación traía 7 y 8)
-- Tina 1
select pg_temp.seed_como('302eecd0-765e-4ba7-b56d-63c114d971bb');
select registrar_medicion(pg_temp.seed_a(), '128b3624-054b-4663-af82-817481e3c4f8', '2026-09-08 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 1, 'minimo', 4,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.5,12.0]::numeric[]);
select pg_temp.seed_como('9bd5648e-689a-4601-9017-73e55fd6f9b4');
select registrar_medicion(pg_temp.seed_a(), 'baa37f0c-5190-467f-9738-d2ca6fd8e6bc', '2026-09-09 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.0,9.5]::numeric[]);
select pg_temp.seed_como('302eecd0-765e-4ba7-b56d-63c114d971bb');
select registrar_medicion(pg_temp.seed_a(), '3685f7bb-6fd4-45ed-ba83-9c2a147ebdb6', '2026-09-10 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.5,6.0]::numeric[]);
select pg_temp.seed_como('9bd5648e-689a-4601-9017-73e55fd6f9b4');
select registrar_medicion(pg_temp.seed_a(), '65d34e3c-53ca-4928-ad1d-66c3ce11efa3', '2026-09-11 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 4, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.5,3.5]::numeric[]);
select pg_temp.seed_como('302eecd0-765e-4ba7-b56d-63c114d971bb');
select registrar_medicion(pg_temp.seed_a(), 'bb807f46-70c7-45c4-9165-90153096fbd1', '2026-09-12 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 5, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.0,1.5]::numeric[]);
-- Tina 2
select registrar_medicion(pg_temp.seed_a(), 'fbdafc35-2105-4570-ab38-64201b64c405', '2026-09-08 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 1, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.0,12.2]::numeric[]);
select registrar_medicion(pg_temp.seed_a(), 'df98c618-ad38-4f47-ad3d-ad5060b81c03', '2026-09-09 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.5,10.1]::numeric[]);
select registrar_medicion(pg_temp.seed_a(), '7d4a1323-e613-4a25-ae17-88ffe446e7e3', '2026-09-10 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.0,7.4]::numeric[]);

-- 2026-09-12 · Aurelia declara lista la Tina 1
select pg_temp.seed_como('9bd5648e-689a-4601-9017-73e55fd6f9b4');
select declarar_tina_lista(pg_temp.seed_a(), '0e1ba8e6-c22f-49c5-ad54-df0551fbb1fa', '2026-09-12 17:00:00-06',
  pg_temp.seed_cyc('Tina 1'), 'Día 5: ya no burbujea, sabor seco');

-- 2026-09-13 · Tomás: dos corridas de 1ª pasada desde la Tina 1
select pg_temp.seed_como('302eecd0-765e-4ba7-b56d-63c114d971bb');
select abrir_corrida(pg_temp.seed_a(), 'c90b0dbc-f554-4a52-8439-99c08bf2e192', '2026-09-13 06:00:00-06',
  pg_temp.seed_res('Alambique 1'), 'primera', array[pg_temp.seed_res('Tina 1')], array[pg_temp.seed_lot('FER-T1-001')], array[290::numeric],
  p_folio => 'DES-001');
select registrar_corte(pg_temp.seed_a(), 'dd879eaf-fe05-4adf-af80-63b86d409757', '2026-09-13 08:00:00-06', pg_temp.seed_run('DES-001'), 'mezcal', 8, 51.0, pg_temp.seed_res('Colector mezcal'), p_folio => 'MEZ-001');
select registrar_corte(pg_temp.seed_a(), 'aabae9dc-48bc-43d9-9a81-e4e45b458f19', '2026-09-13 10:00:00-06', pg_temp.seed_run('DES-001'), 'ordinario', 40, 24.0, pg_temp.seed_res('Colector ordinario'), p_folio => 'ORD-001');
select registrar_corte(pg_temp.seed_a(), '910ad6e5-88fa-4443-96d8-8b6e07ccf96b', '2026-09-13 12:00:00-06', pg_temp.seed_run('DES-001'), 'colas', 12, 9.0, pg_temp.seed_res('Colector colas'), p_folio => 'COL-001');
select cerrar_corrida(pg_temp.seed_a(), 'b3ee1179-45d7-4e34-ab4b-6fc27130ce46', '2026-09-13 14:00:00-06', pg_temp.seed_run('DES-001'));

select abrir_corrida(pg_temp.seed_a(), '62a15206-c309-42a4-8cfa-4a848b8b4dca', '2026-09-13 06:00:00-06',
  pg_temp.seed_res('Alambique 2'), 'primera', array[pg_temp.seed_res('Tina 1')], array[pg_temp.seed_lot('FER-T1-001')], array[240::numeric],
  p_folio => 'DES-002');
select registrar_corte(pg_temp.seed_a(), 'ef4e7bce-99f9-4271-b84b-d02d7eeda99b', '2026-09-13 08:00:00-06', pg_temp.seed_run('DES-002'), 'mezcal', 6, 50.0, pg_temp.seed_res('Colector mezcal'));
select registrar_corte(pg_temp.seed_a(), 'ff4fca75-e68e-4ba4-8898-e76c278ff8a0', '2026-09-13 10:00:00-06', pg_temp.seed_run('DES-002'), 'ordinario', 34, 23.0, pg_temp.seed_res('Colector ordinario'));
select registrar_corte(pg_temp.seed_a(), 'f84e1672-3fce-401f-9e2c-f1c6ea74600b', '2026-09-13 12:00:00-06', pg_temp.seed_run('DES-002'), 'colas', 10, 8.0, pg_temp.seed_res('Colector colas'));
select cerrar_corrida(pg_temp.seed_a(), '771acf44-e151-4b25-ad5b-371b16e05032', '2026-09-13 14:00:00-06', pg_temp.seed_run('DES-002'));

-- 2026-09-15 · Tomás: 2ª pasada con ordinario y colas juntos (aviso + nota)
select abrir_corrida(pg_temp.seed_a(), '382646c4-99da-4a8e-acc7-c6b9d2221866', '2026-09-15 06:00:00-06',
  pg_temp.seed_res('Alambique 1'), 'segunda',
  array[pg_temp.seed_res('Colector ordinario'), pg_temp.seed_res('Colector colas')],
  array[pg_temp.seed_lot('ORD-001'), pg_temp.seed_lot('COL-001')], array[74::numeric, 22::numeric],
  'Había olla libre y poca cola; se juntó con el ordinario', 'DES-003');
select registrar_corte(pg_temp.seed_a(), 'e7cda439-711c-4d13-9059-a6b494189027', '2026-09-15 08:00:00-06', pg_temp.seed_run('DES-003'), 'mezcal', 26, 52.5, pg_temp.seed_res('Colector mezcal'));
select registrar_corte(pg_temp.seed_a(), '0e5fb198-025f-4e25-b950-5d59a8df7a9a', '2026-09-15 10:00:00-06', pg_temp.seed_run('DES-003'), 'colas', 16, 10.0, pg_temp.seed_res('Colector colas'), p_folio => 'COL-002');
select cerrar_corrida(pg_temp.seed_a(), '6fe508f7-ae2b-4024-839f-1acee4a452c2', '2026-09-15 14:00:00-06', pg_temp.seed_run('DES-003'));

-- 2026-09-16 · Aurelia: el mezcal del colector pasa a granel con folio nuevo
select pg_temp.seed_como('9bd5648e-689a-4601-9017-73e55fd6f9b4');
select transferir(pg_temp.seed_a(), 'a1200359-92a0-44db-8461-dec0610f2d14', '2026-09-16 09:00:00-06',
  pg_temp.seed_res('Colector mezcal'), pg_temp.seed_res('Tanque 1'), pg_temp.seed_lot('MEZ-001'), 40, 51.6, 'renombrar', 'G-2609-01');
-- Agua para bajar grado: 4 L, declara 43.8 L (contracción) y 47.0 %
select registrar_movimiento_granel(pg_temp.seed_a(), 'e9617019-3417-4b60-8ff4-ee019ef23d9a', '2026-09-16 11:00:00-06',
  pg_temp.seed_con('66a151e2-9a2c-58be-ad4a-b117f1ddb717'), pg_temp.seed_res('Tanque 1'), 4,
  p_lote => pg_temp.seed_lot('G-2609-01'), p_resultado_l => 43.8, p_resultado_abv => 47.0);

-- 2026-09-17 · Benito: puntas guardadas (sin lote) al Tanque 2
select pg_temp.seed_como('b4390fd1-fe87-4c67-b505-8233a13f3a39');
select registrar_movimiento_granel(pg_temp.seed_a(), '4b5450bd-3ce0-4406-b1d6-ce0098c24cb6', '2026-09-17 10:00:00-06',
  pg_temp.seed_con('f21aaad8-2ef6-556b-be55-64aa94431ab6'), pg_temp.seed_res('Tanque 2'), 2,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_resultado_l => 602, p_resultado_abv => 44.6, p_abv => 68.0,
  p_nota => 'Puntas guardadas de corridas de agosto, sin lote');
-- 2026-09-18 · Benito: unión de G-2609-01 (Tanque 1) con G-INI-01 (Tanque 2), se conserva el folio mayor
select registrar_movimiento_granel(pg_temp.seed_a(), '3c6a1392-b679-4fbf-bd2f-43b5a7bd9061', '2026-09-18 09:30:00-06',
  pg_temp.seed_con('df427d88-600e-550e-a097-8ffe4f4dd556'), pg_temp.seed_res('Tanque 2'), 43.8,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_lote_origen => pg_temp.seed_lot('G-2609-01'), p_recurso_origen => pg_temp.seed_res('Tanque 1'),
  p_resultado_l => 645.8, p_resultado_abv => 44.9, p_decision => 'conservar', p_nota => 'Se conserva el folio del lote mayor');
-- 2026-09-19 · Benito: compra de granel al Tanque 1
select registrar_movimiento_granel(pg_temp.seed_a(), 'bdf0e6f7-aa04-4a03-886c-48eb8f62fab2', '2026-09-19 12:00:00-06',
  pg_temp.seed_con('688430a9-cd2f-5bae-add2-c59bc543d911'), pg_temp.seed_res('Tanque 1'), 250,
  p_resultado_l => 250, p_resultado_abv => 46.0, p_abv => 46.0, p_folio_nuevo => 'G-COMPRA-01',
  p_contraparte => 'Destilados Hermanos Luna', p_documento => 'Remisión 0452',
  p_proveedor => 'cced587f-ff5b-4743-bd69-8b2e5043bfae', p_especie => pg_temp.seed_esp('67a96efd-2c72-528e-8682-d144fe1f802c'),
  p_predio_declarado => 'Sola de Vega');

-- 2026-09-19 · Aurelia: muestra de laboratorio
select pg_temp.seed_como('9bd5648e-689a-4601-9017-73e55fd6f9b4');
select registrar_movimiento_granel(pg_temp.seed_a(), '15b862b9-10bd-4575-8da9-1f1d106e8699', '2026-09-19 13:00:00-06',
  pg_temp.seed_con('2d62ab89-6a11-558c-8b46-5c4d30aa1607'), pg_temp.seed_res('Tanque 2'), 1,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Laboratorio ficticio de Oaxaca', p_documento => 'Análisis 2026-311');

-- 2026-09-20/22 · Benito: autoconsumo, venta, regalo
select pg_temp.seed_como('b4390fd1-fe87-4c67-b505-8233a13f3a39');
select registrar_movimiento_granel(pg_temp.seed_a(), '0e5f61f5-92e8-4891-933c-bc5481583ea4', '2026-09-20 13:00:00-06',
  pg_temp.seed_con('fa52f92b-de19-5d0c-972c-beb899bb2ccb'), pg_temp.seed_res('Tanque 2'), 2, p_lote => pg_temp.seed_lot('G-INI-01'));
select registrar_movimiento_granel(pg_temp.seed_a(), '25382af1-6245-40df-b84d-1ae5de87836f', '2026-09-22 13:00:00-06',
  pg_temp.seed_con('7b0ca7ca-f8ae-5f33-93d5-f0c174664ec1'), pg_temp.seed_res('Tanque 2'), 300,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.', p_documento => 'Remisión 118');
select registrar_movimiento_granel(pg_temp.seed_a(), 'fd1ec43d-d0a2-4258-8e9a-126412689548', '2026-09-22 13:00:00-06',
  'fe7e0303-27c9-4bb3-ba50-64666f8923f4', pg_temp.seed_res('Tanque 2'), 1,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.');

reset role;

-- Evidencia de la compra (los adjuntos no son RPC de §12)
insert into attachments (id, organization_id, operation_id, lot_id, kind_item_id, storage_path, caption) values
  ('c54ecac4-538c-4448-9050-723e2a712ff6', pg_temp.seed_a(),
   (select id from operations where organization_id = pg_temp.seed_a() and idempotency_key = 'bdf0e6f7-aa04-4a03-886c-48eb8f62fab2'),
   pg_temp.seed_lot('G-COMPRA-01'), pg_temp.seed_cat('0522e23b-3b1d-58be-b50c-8a6ed0627c9f'),
   'evidencias/7277a529-4342-46d6-8aff-3d5ecb7ccc86/g-compra-01/remision-0452.jpg', 'Remisión del proveedor');


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
--   benito  b4390fd1-fe87-4c67-b505-8233a13f3a39  admin de Cuatro Vientos (A)
--   tomas   302eecd0-765e-4ba7-b56d-63c114d971bb  operador de A
--   dueña B 83a8186e-bdc5-46e3-a07a-b47c31ab7952  admin de Palenque Prueba B
--   nadie   928954de-49ad-4d18-9514-8fe7507d1466  sin membresía
--   A = 7277a529-4342-46d6-8aff-3d5ecb7ccc86   B = 97124588-60fc-476f-9d6f-f5ce010370aa


-- Filas de la empresa A visibles bajo la RLS del rol actual, sumadas en
-- todas las tablas de negocio y vistas. Debe ser 0 para quien no es de A.
create function pg_temp.rows_of_a() returns bigint language sql as $$
  select
    (select count(*) from catalog_items      where organization_id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86') +
    (select count(*) from movement_concepts  where organization_id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86') +
    (select count(*) from species            where organization_id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86') +
    (select count(*) from predios            where organization_id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86') +
    (select count(*) from suppliers          where organization_id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86') +
    (select count(*) from supplies           where organization_id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86') +
    (select count(*) from resources          where organization_id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86') +
    (select count(*) from operations         where organization_id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86') +
    (select count(*) from operation_warnings where organization_id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86') +
    (select count(*) from lots               where organization_id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86') +
    (select count(*) from lot_lineage        where organization_id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86') +
    (select count(*) from lot_external_sources where organization_id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86') +
    (select count(*) from maguey_receptions  where organization_id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86') +
    (select count(*) from liquid_movements   where organization_id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86') +
    (select count(*) from attachments        where organization_id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86') +
    (select count(*) from roasting_runs      where organization_id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86') +
    (select count(*) from roasting_run_inputs where organization_id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86') +
    (select count(*) from formulations       where organization_id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86') +
    (select count(*) from formulation_inputs where organization_id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86') +
    (select count(*) from formulation_supplies where organization_id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86') +
    (select count(*) from fermentation_cycles where organization_id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86') +
    (select count(*) from fermentation_measurements where organization_id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86') +
    (select count(*) from measurement_readings where organization_id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86') +
    (select count(*) from distillation_runs  where organization_id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86') +
    (select count(*) from distillation_run_inputs where organization_id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86') +
    (select count(*) from distillation_cuts  where organization_id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86') +
    (select count(*) from organization_members where organization_id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86') +
    (select count(*) from organization_settings where organization_id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86') +
    (select count(*) from subscriptions      where organization_id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86') +
    (select count(*) from resource_lot_balances where organization_id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86') +
    (select count(*) from movement_log       where organization_id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86');
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
  perform pg_temp.como('b4390fd1-fe87-4c67-b505-8233a13f3a39');
  return next is((select count(*) from organizations), 1::bigint, 'benito ve exactamente una empresa');
  return next is((select count(*) from resources), 12::bigint, 'benito ve los 12 recursos de Cuatro Vientos');
  return next is((select count(*) from resources where organization_id = '97124588-60fc-476f-9d6f-f5ce010370aa'), 0::bigint,
                 'benito no ve recursos de la empresa B');
  return next ok((select pg_temp.rows_of_a()) > 0, 'benito sí ve filas de su propia empresa');

  -- 2) dueña de B no lee, no inserta ni referencia nada de A
  perform pg_temp.como('83a8186e-bdc5-46e3-a07a-b47c31ab7952');
  return next is((select count(*) from organizations), 1::bigint, 'dueña B ve solo su empresa');
  return next is((select pg_temp.rows_of_a()), 0::bigint,
                 'dueña B no ve ninguna fila de A en ninguna tabla de negocio ni vista');
  return next throws_ok(
    $q$insert into resources (organization_id, kind, code, capacity_policy)
       values ('7277a529-4342-46d6-8aff-3d5ecb7ccc86', 'tina', 'Intrusa', 'flexible')$q$,
    '42501', null, 'dueña B no puede insertar un recurso en A (RLS)');
  return next throws_ok(
    $q$insert into resources (organization_id, kind, code, type_item_id, capacity_policy)
       values ('97124588-60fc-476f-9d6f-f5ce010370aa', 'alambique', 'Alambique B1',
               '933ddf27-bd66-4a42-be2f-1e60bd1c31ce', 'estricta')$q$,
    null, null, 'dueña B no puede referenciar un catálogo de A (FK compuesta o trigger de tipo)');
  return next lives_ok(
    $q$update organizations set name = 'Hackeada' where id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86'$q$,
    'un update sobre A desde B no revienta: la RLS simplemente filtra 0 filas');
  execute 'reset role';
  return next is((select name from organizations where id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86'),
                 'Mezcal Cuatro Vientos', 'el nombre de A sigue intacto tras el intento desde B');

  -- 3) sin membresía activa no se ve nada
  perform pg_temp.como('928954de-49ad-4d18-9514-8fe7507d1466');
  return next is((select count(*) from organizations), 0::bigint, 'un usuario sin membresía no ve empresas');
  return next is((select pg_temp.rows_of_a()), 0::bigint, 'un usuario sin membresía no ve filas de negocio');

  -- 4) el operador no ejecuta funciones de admin ni escribe infraestructura
  perform pg_temp.como('302eecd0-765e-4ba7-b56d-63c114d971bb');
  return next throws_ok(
    $q$select desbloquear_miembro('7277a529-4342-46d6-8aff-3d5ecb7ccc86', '302eecd0-765e-4ba7-b56d-63c114d971bb')$q$,
    'P0001', null, 'un operador no puede desbloquear miembros');
  return next throws_ok(
    $q$insert into resources (organization_id, kind, code, capacity_policy)
       values ('7277a529-4342-46d6-8aff-3d5ecb7ccc86', 'tina', 'Tina X', 'flexible')$q$,
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
        where b.organization_id = '7277a529-4342-46d6-8aff-3d5ecb7ccc86'
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
