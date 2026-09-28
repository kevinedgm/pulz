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
-- tomas.h → 'tomas-2026' · dueña B → 'qa-76bbe6751695-prueba-b-2026' · admin → 'pulz-2026'
-- ---------------------------------------------------------------------
insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
                        raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
                        confirmation_token, recovery_token, email_change_token_new, email_change) values
  ('00000000-0000-0000-0000-000000000000', '9023c766-4f55-48ac-af87-88a0b96f61d1', 'authenticated', 'authenticated', 'qa-76bbe6751695-tu@pulz.mx',
   extensions.crypt('pulz-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '4ba26002-a774-4573-a098-416b842425c4', 'authenticated', 'authenticated', 'qa-76bbe6751695-benito@cuatrovientos.mx',
   extensions.crypt('benito-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', 'c46e5a21-81e7-4bd6-a8e4-a5c30056a233', 'authenticated', 'authenticated', 'qa-76bbe6751695-aurelia@b615ddaa-293c-4e09-a518-0da4610b16f2.usuarios.pulz.mx',
   extensions.crypt('aurelia-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '7facc590-20d8-4c49-8620-dcde41651ffc', 'authenticated', 'authenticated', 'qa-76bbe6751695-tomas.h@b615ddaa-293c-4e09-a518-0da4610b16f2.usuarios.pulz.mx',
   extensions.crypt('tomas-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '711abe23-8be9-4eae-834a-25bfdc5a2571', 'authenticated', 'authenticated', 'qa-76bbe6751695-duena@pruebab.mx',
   extensions.crypt('qa-76bbe6751695-prueba-b-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '');

insert into profiles (id, full_name) values
  ('9023c766-4f55-48ac-af87-88a0b96f61d1', 'Admin PULZ'),
  ('4ba26002-a774-4573-a098-416b842425c4', 'Benito Cruz'),
  ('c46e5a21-81e7-4bd6-a8e4-a5c30056a233', 'Aurelia Santiago'),
  ('7facc590-20d8-4c49-8620-dcde41651ffc', 'Tomás Hernández'),
  ('711abe23-8be9-4eae-834a-25bfdc5a2571', 'Dueña Prueba B');

insert into platform_admins (user_id) values ('9023c766-4f55-48ac-af87-88a0b96f61d1');

-- Planes (§14, §18 #2 y #3)
-- Fixture: reutiliza plans canónica, sin modificarla.
-- Fixture: reutiliza plan_limits canónica, sin modificarla.
-- Fixture: reutiliza plan_features canónica, sin modificarla.

-- Empresas
insert into organizations (id, name, slug, state, brand_color, logo_path, welcome_message, created_by) values
  ('b615ddaa-293c-4e09-a518-0da4610b16f2', 'Mezcal Cuatro Vientos', 'qa-76bbe6751695-cuatro-vientos', 'Oaxaca', '#7A3E1D', null, 'Registro de producción del palenque', '4ba26002-a774-4573-a098-416b842425c4'),
  ('2d890d64-a769-40a7-a382-1c0dbc97e69f', 'Palenque Prueba B', 'qa-76bbe6751695-prueba-b', 'Oaxaca', '#173F87', null, 'Empresa de prueba', '711abe23-8be9-4eae-834a-25bfdc5a2571');
insert into organization_slug_history (slug, organization_id, retired_at, retired_by) values
  ('qa-76bbe6751695-mezcal-cuatro-vientos', 'b615ddaa-293c-4e09-a518-0da4610b16f2', '2026-09-02 09:00:00-06', '4ba26002-a774-4573-a098-416b842425c4');
insert into organization_members (organization_id, user_id, role, status, username, must_change_password) values
  ('b615ddaa-293c-4e09-a518-0da4610b16f2', '4ba26002-a774-4573-a098-416b842425c4', 'admin', 'activo', null, false),
  ('b615ddaa-293c-4e09-a518-0da4610b16f2', 'c46e5a21-81e7-4bd6-a8e4-a5c30056a233', 'productor', 'activo', 'aurelia', false),
  ('b615ddaa-293c-4e09-a518-0da4610b16f2', '7facc590-20d8-4c49-8620-dcde41651ffc', 'operador', 'activo', 'tomas.h', true),
  ('2d890d64-a769-40a7-a382-1c0dbc97e69f', '711abe23-8be9-4eae-834a-25bfdc5a2571', 'admin', 'activo', null, false);
insert into member_invitations (id, organization_id, user_id, token_hash, expires_at, used_at, created_by) values
  ('7f97d30a-64ab-4ac8-9ab9-228dbd343f24', 'b615ddaa-293c-4e09-a518-0da4610b16f2', '7facc590-20d8-4c49-8620-dcde41651ffc', 'qa-76bbe6751695:SIMULADO', '2026-09-05 10:00:00-06', null, '4ba26002-a774-4573-a098-416b842425c4');
insert into login_throttle (user_id, failed_count, last_failed_at, locked_until) values
  ('7facc590-20d8-4c49-8620-dcde41651ffc', 3, '2026-09-03 07:12:00-06', null);
insert into organization_settings (organization_id, record_puntas, measurement_mode, warn_mixed_second_pass, fermentation_expected_days, measurement_reminder_hour, default_folio_decision) values
  ('b615ddaa-293c-4e09-a518-0da4610b16f2', false, 'minimo', true, 7, 9, 'conservar'),
  ('2d890d64-a769-40a7-a382-1c0dbc97e69f', false, 'minimo', true, 7, 9, 'conservar');
insert into subscriptions (organization_id, plan_id, status, current_period_end) values
  ('b615ddaa-293c-4e09-a518-0da4610b16f2', 'edd15bcf-ad82-5684-a2e7-d85db401885b', 'prueba', '2026-10-15 00:00:00-06'),
  ('2d890d64-a769-40a7-a382-1c0dbc97e69f', 'ee35d6fd-b4d6-56d6-b7b4-61cb81932b21', 'gratis', null);

-- ---------------------------------------------------------------------
-- Plantillas de plataforma (§10.2.1)
-- ---------------------------------------------------------------------
-- Fixture: reutiliza catalog_item_templates canónica, sin modificarla.
-- Fixture: reutiliza movement_concept_templates canónica, sin modificarla.
-- Fixture: reutiliza species_templates canónica, sin modificarla.

select seed_organization_catalogs('b615ddaa-293c-4e09-a518-0da4610b16f2');
select seed_organization_catalogs('2d890d64-a769-40a7-a382-1c0dbc97e69f');

-- Lo propio de Cuatro Vientos y lo que oculta (§10.2.4)
insert into catalog_items (id, organization_id, template_id, catalog, name, sort_order, created_by) values
  ('40843c32-0328-4a0f-8382-08f493c93afe', 'b615ddaa-293c-4e09-a518-0da4610b16f2', null, 'tipo_alambique', 'Refrescadera de cobre', 100, '4ba26002-a774-4573-a098-416b842425c4');
insert into movement_concepts (id, organization_id, template_id, direction, name, source_lot, creates_lot, asks_result, asks_counterparty, sort_order, created_by) values
  ('d5e79f09-600a-49fa-84d4-25cdc0852a64', 'b615ddaa-293c-4e09-a518-0da4610b16f2', null, 'salida', 'Regalo a cliente', 'no_aplica', false, false, true, 100, '4ba26002-a774-4573-a098-416b842425c4');
update catalog_items set active = false
 where organization_id = 'b615ddaa-293c-4e09-a518-0da4610b16f2'
   and template_id in ('5c985133-23d9-50fa-a252-6ff6b5b74134', 'b1fce67a-21bf-50a7-9344-fdf29eb5331e');
update movement_concepts set active = false
 where organization_id = 'b615ddaa-293c-4e09-a518-0da4610b16f2'
   and template_id = '8b7f6579-99ef-549e-b427-b1d4d8bea9da';

-- ---------------------------------------------------------------------
-- Ayudas de la semilla (temporales; mueren con la sesión). security definer
-- para que resuelvan ids aunque el rol activo sea 'authenticated'.
-- ---------------------------------------------------------------------
create function pg_temp.seed_a() returns uuid language sql immutable as $$ select 'b615ddaa-293c-4e09-a518-0da4610b16f2'::uuid $$;
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
  ('b526be33-8b3b-4fdc-a140-b7f3175d1a11', pg_temp.seed_a(), 'Loma del Toro', 'Santiago Matatlán', 'Familia Cruz');
insert into suppliers (id, organization_id, name, type_item_id) values
  ('50a9df6b-4d73-45f1-afdc-cc3d7ffb50bb', pg_temp.seed_a(), 'Magueyes Don Pedro', pg_temp.seed_cat('640b537d-bf52-5c4b-b407-a5f4fb7c5800')),
  ('9654d498-58df-4e9a-983c-d5e71391f3d9', pg_temp.seed_a(), 'Destilados Hermanos Luna', pg_temp.seed_cat('bb234638-3c78-56cd-9f41-2fb38182f181'));
insert into supplies (id, organization_id, name, unit_item_id) values
  ('80063a46-e0e4-462c-a00f-32f7ca19c9bd', pg_temp.seed_a(), 'Pulque como inóculo', pg_temp.seed_cat('bc6f104d-2841-5b36-b492-76b36becb172'));
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy, liquid_class) values
  ('b6555cda-9998-40ad-8c6f-c18fef225e0e', pg_temp.seed_a(), 'horno', 'Horno 1', pg_temp.seed_cat('d53ba2da-cada-5215-804a-ff304d569f97'), 10000, 'kg', 'libre', null),
  ('10fda49c-638d-4457-86a7-9d1a458a38d7', pg_temp.seed_a(), 'molino', 'Tahona', pg_temp.seed_cat('60285283-d000-52f0-95da-d2b2e6d70fa1'), null, 'kg', 'libre', null),
  ('e4ae387d-87ff-4db3-b4f6-7f7e817fd3b9', pg_temp.seed_a(), 'tina', 'Tina 1', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('d8568d4c-c868-4e23-9037-be46be98150a', pg_temp.seed_a(), 'tina', 'Tina 2', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('f9d0f449-df60-43c1-9dae-df886bb619e0', pg_temp.seed_a(), 'tina', 'Tina 3', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('2ed5f8d8-ec97-44e2-b579-115d46fa6f79', pg_temp.seed_a(), 'alambique', 'Alambique 1', pg_temp.seed_cat('af73010e-53f2-5769-b3b1-6cda154e665e'), 300, 'L', 'estricta', null),
  ('4d755c0a-9d79-4145-b486-65b1abdb2110', pg_temp.seed_a(), 'alambique', 'Alambique 2', '40843c32-0328-4a0f-8382-08f493c93afe', 250, 'L', 'estricta', null),
  ('b4b66939-444c-4218-b3b4-f2aab9a46c56', pg_temp.seed_a(), 'colector', 'Colector mezcal', pg_temp.seed_cat('2cd7e70b-6246-543e-8f67-23743fefdf95'), 60, 'L', 'flexible', 'mezcal'),
  ('0d49c54c-75e9-49db-ae84-b19a2666fe84', pg_temp.seed_a(), 'colector', 'Colector ordinario', pg_temp.seed_cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'ordinario'),
  ('9ca4c6bd-a21d-4aee-a18c-4eafe1fd22a1', pg_temp.seed_a(), 'colector', 'Colector colas', pg_temp.seed_cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'colas'),
  ('9491ac93-ddfe-492e-91a1-bc08464eb355', pg_temp.seed_a(), 'tanque', 'Tanque 1', pg_temp.seed_cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1000, 'L', 'flexible', null),
  ('a267044f-ce96-4e1e-9fcb-58557878845b', pg_temp.seed_a(), 'tanque', 'Tanque 2', pg_temp.seed_cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1500, 'L', 'flexible', null);

-- Palenque Prueba B: lo mínimo para probar aislamiento
insert into predios (id, organization_id, name, municipality) values
  ('3345d398-0b7a-4708-9b25-7ebed9263272', '2d890d64-a769-40a7-a382-1c0dbc97e69f', 'Predio B', 'Ejutla');
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy) values
  ('ef3151b7-2888-4206-8b51-5b0f8881f7f0', '2d890d64-a769-40a7-a382-1c0dbc97e69f', 'tina', 'Tina B1',
   (select id from catalog_items where organization_id = '2d890d64-a769-40a7-a382-1c0dbc97e69f' and template_id = 'b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1000, 'L', 'flexible');

-- =====================================================================
-- Cuatro Vientos: la producción, POR RPC, en orden cronológico
-- =====================================================================

-- 2026-09-01 · Benito: lo que ya había en el Tanque 2 (carga inicial)
select pg_temp.seed_como('4ba26002-a774-4573-a098-416b842425c4');
select registrar_entrada(pg_temp.seed_a(), 'f2e28a9e-ef8e-4441-bfe1-af9f9bd132d2', '2026-09-01 10:15:00-06',
  'granel', pg_temp.seed_res('Tanque 2'), 600, 44.2, 'mezcal', 'carga_inicial',
  p_concepto => pg_temp.seed_con('255e79f1-12b3-5969-8453-e40623275559'),
  p_nota => 'Lo que ya había en el tanque al empezar', p_folio => 'G-INI-01');

-- 2026-09-01 · Aurelia: la Tina 3 ya fermentaba
select pg_temp.seed_como('c46e5a21-81e7-4bd6-a8e4-a5c30056a233');
select registrar_entrada(pg_temp.seed_a(), '49f4cfcf-e5fd-4e2e-afe1-9823a05c0a3d', '2026-09-01 10:40:00-06',
  'fermentado', pg_temp.seed_res('Tina 3'), 1300, null, null, 'carga_inicial',
  p_nota => 'Tina que ya fermentaba', p_folio => 'FER-T3-INI');

-- 2026-09-02 · Aurelia: recepción de maguey
select registrar_recepcion_maguey(pg_temp.seed_a(), '1468ced2-dfd0-42ce-a3af-0ca0ff46ed61', '2026-09-02 07:30:00-06',
  8000, pg_temp.seed_esp('67a96efd-2c72-528e-8682-d144fe1f802c'), 'b526be33-8b3b-4fdc-a140-b7f3175d1a11',
  '50a9df6b-4d73-45f1-afdc-cc3d7ffb50bb', 132, 'Piñas de 8 años, buen tamaño', 'MAG-001');

-- 2026-09-02 · Horneado (la simulación lo abría Tomás; §11.1 lo reserva a
-- admin/productor, así que lo abre Aurelia — docs/DECISIONES.md)
select abrir_horneado(pg_temp.seed_a(), 'd9cbf57b-05ca-46c2-b4d8-44c22ebf4930', '2026-09-02 12:00:00-06',
  pg_temp.seed_res('Horno 1'), array[pg_temp.seed_lot('MAG-001')], array[8000::numeric], p_folio => 'HOR-001');
-- 2026-09-06 · Aurelia cierra: 6,200 kg de agave cocido
select cerrar_horneado(pg_temp.seed_a(), 'aa9415f0-636f-43c6-bc43-be44c5f9279d', '2026-09-06 08:00:00-06',
  pg_temp.seed_hor('HOR-001'), 6200, 'Leña de encino', p_folio => 'AC-001');

-- 2026-09-07 · Aurelia: formulación repartida a Tina 1 y Tina 2
select registrar_formulacion(pg_temp.seed_a(), '866790a5-47d8-4938-9b8b-dc4a4ae248e6', '2026-09-07 09:00:00-06',
  pg_temp.seed_res('Tahona'), array[pg_temp.seed_lot('AC-001')], array[6200::numeric], 1900,
  array[pg_temp.seed_res('Tina 1'), pg_temp.seed_res('Tina 2')], array[1400::numeric, 1400::numeric],
  array['80063a46-e0e4-462c-a00f-32f7ca19c9bd'::uuid], array[20::numeric],
  'Tahona con mula', null, 'F-001', array['FER-T1-001', 'FER-T2-001']);

-- Mediciones diarias (escala de actividad 1–6, §18 #1; la simulación traía 7 y 8)
-- Tina 1
select pg_temp.seed_como('7facc590-20d8-4c49-8620-dcde41651ffc');
select registrar_medicion(pg_temp.seed_a(), '4a1f3f3a-235b-48d9-a49c-99a9e02a5df5', '2026-09-08 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 1, 'minimo', 4,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.5,12.0]::numeric[]);
select pg_temp.seed_como('c46e5a21-81e7-4bd6-a8e4-a5c30056a233');
select registrar_medicion(pg_temp.seed_a(), '2e6ef1e4-9263-4c83-916b-ef9861ec08b4', '2026-09-09 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.0,9.5]::numeric[]);
select pg_temp.seed_como('7facc590-20d8-4c49-8620-dcde41651ffc');
select registrar_medicion(pg_temp.seed_a(), '32ebf40d-f8e3-4488-961e-95190e5ccc01', '2026-09-10 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.5,6.0]::numeric[]);
select pg_temp.seed_como('c46e5a21-81e7-4bd6-a8e4-a5c30056a233');
select registrar_medicion(pg_temp.seed_a(), '2901c46a-6874-4645-9353-b5343fc3d0b4', '2026-09-11 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 4, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.5,3.5]::numeric[]);
select pg_temp.seed_como('7facc590-20d8-4c49-8620-dcde41651ffc');
select registrar_medicion(pg_temp.seed_a(), 'be7698ef-6968-465c-b63f-af4fe0823034', '2026-09-12 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 5, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.0,1.5]::numeric[]);
-- Tina 2
select registrar_medicion(pg_temp.seed_a(), 'b39c9080-a4ee-40d0-9ba9-ee0b05d618da', '2026-09-08 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 1, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.0,12.2]::numeric[]);
select registrar_medicion(pg_temp.seed_a(), 'fafc1726-880a-48d1-abbb-598e9891b580', '2026-09-09 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.5,10.1]::numeric[]);
select registrar_medicion(pg_temp.seed_a(), '5962e6b3-2918-43a8-b1d2-1711ec9b2f23', '2026-09-10 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.0,7.4]::numeric[]);

-- 2026-09-12 · Aurelia declara lista la Tina 1
select pg_temp.seed_como('c46e5a21-81e7-4bd6-a8e4-a5c30056a233');
select declarar_tina_lista(pg_temp.seed_a(), '66d58459-428f-432f-9e4e-5debcbde5b62', '2026-09-12 17:00:00-06',
  pg_temp.seed_cyc('Tina 1'), 'Día 5: ya no burbujea, sabor seco');

-- 2026-09-13 · Tomás: dos corridas de 1ª pasada desde la Tina 1
select pg_temp.seed_como('7facc590-20d8-4c49-8620-dcde41651ffc');
select abrir_corrida(pg_temp.seed_a(), 'e05111cd-d67d-4ae4-88a5-b8e14c3d0a8d', '2026-09-13 06:00:00-06',
  pg_temp.seed_res('Alambique 1'), 'primera', array[pg_temp.seed_res('Tina 1')], array[pg_temp.seed_lot('FER-T1-001')], array[290::numeric],
  p_folio => 'DES-001');
select registrar_corte(pg_temp.seed_a(), 'c20fc931-2c9c-4214-8891-fb5cc7ed50f4', '2026-09-13 08:00:00-06', pg_temp.seed_run('DES-001'), 'mezcal', 8, 51.0, pg_temp.seed_res('Colector mezcal'), p_folio => 'MEZ-001');
select registrar_corte(pg_temp.seed_a(), '9150b871-1136-4e21-be2a-ec93daeb34c1', '2026-09-13 10:00:00-06', pg_temp.seed_run('DES-001'), 'ordinario', 40, 24.0, pg_temp.seed_res('Colector ordinario'), p_folio => 'ORD-001');
select registrar_corte(pg_temp.seed_a(), '84f1692b-d3a7-47ce-a588-6925bacb2570', '2026-09-13 12:00:00-06', pg_temp.seed_run('DES-001'), 'colas', 12, 9.0, pg_temp.seed_res('Colector colas'), p_folio => 'COL-001');
select cerrar_corrida(pg_temp.seed_a(), '8466199e-edf0-474d-9752-efdd9627d448', '2026-09-13 14:00:00-06', pg_temp.seed_run('DES-001'));

select abrir_corrida(pg_temp.seed_a(), '03f440ec-b2c5-4441-8a01-6cff4a84136a', '2026-09-13 06:00:00-06',
  pg_temp.seed_res('Alambique 2'), 'primera', array[pg_temp.seed_res('Tina 1')], array[pg_temp.seed_lot('FER-T1-001')], array[240::numeric],
  p_folio => 'DES-002');
select registrar_corte(pg_temp.seed_a(), '6ba6e954-456d-4853-8227-cd66e1b0c405', '2026-09-13 08:00:00-06', pg_temp.seed_run('DES-002'), 'mezcal', 6, 50.0, pg_temp.seed_res('Colector mezcal'));
select registrar_corte(pg_temp.seed_a(), '22eb9b01-4b17-46dc-a36c-d6be1cc3565b', '2026-09-13 10:00:00-06', pg_temp.seed_run('DES-002'), 'ordinario', 34, 23.0, pg_temp.seed_res('Colector ordinario'));
select registrar_corte(pg_temp.seed_a(), '6e1ae57c-b1e5-49f4-a5c7-122c09a83902', '2026-09-13 12:00:00-06', pg_temp.seed_run('DES-002'), 'colas', 10, 8.0, pg_temp.seed_res('Colector colas'));
select cerrar_corrida(pg_temp.seed_a(), '3e7ffe83-add3-4e93-adc7-dddede5e234c', '2026-09-13 14:00:00-06', pg_temp.seed_run('DES-002'));

-- 2026-09-15 · Tomás: 2ª pasada con ordinario y colas juntos (aviso + nota)
select abrir_corrida(pg_temp.seed_a(), '0459ca2b-0b99-4c1f-8409-96bad8bbed48', '2026-09-15 06:00:00-06',
  pg_temp.seed_res('Alambique 1'), 'segunda',
  array[pg_temp.seed_res('Colector ordinario'), pg_temp.seed_res('Colector colas')],
  array[pg_temp.seed_lot('ORD-001'), pg_temp.seed_lot('COL-001')], array[74::numeric, 22::numeric],
  'Había olla libre y poca cola; se juntó con el ordinario', 'DES-003');
select registrar_corte(pg_temp.seed_a(), '9c982874-5463-4987-8200-71fdfbbb2547', '2026-09-15 08:00:00-06', pg_temp.seed_run('DES-003'), 'mezcal', 26, 52.5, pg_temp.seed_res('Colector mezcal'));
select registrar_corte(pg_temp.seed_a(), '8773a437-1ad9-4438-80ff-d413435d11a6', '2026-09-15 10:00:00-06', pg_temp.seed_run('DES-003'), 'colas', 16, 10.0, pg_temp.seed_res('Colector colas'), p_folio => 'COL-002');
select cerrar_corrida(pg_temp.seed_a(), '2e32dac4-c04f-4958-8368-695ea5ac8e99', '2026-09-15 14:00:00-06', pg_temp.seed_run('DES-003'));

-- 2026-09-16 · Aurelia: el mezcal del colector pasa a granel con folio nuevo
select pg_temp.seed_como('c46e5a21-81e7-4bd6-a8e4-a5c30056a233');
select transferir(pg_temp.seed_a(), '68bb7069-c82e-4742-8344-dcc5f86e0af9', '2026-09-16 09:00:00-06',
  pg_temp.seed_res('Colector mezcal'), pg_temp.seed_res('Tanque 1'), pg_temp.seed_lot('MEZ-001'), 40, 51.6, 'renombrar', 'G-2609-01');
-- Agua para bajar grado: 4 L, declara 43.8 L (contracción) y 47.0 %
select registrar_movimiento_granel(pg_temp.seed_a(), '071568fe-6631-407f-836e-8a89a5a56637', '2026-09-16 11:00:00-06',
  pg_temp.seed_con('66a151e2-9a2c-58be-ad4a-b117f1ddb717'), pg_temp.seed_res('Tanque 1'), 4,
  p_lote => pg_temp.seed_lot('G-2609-01'), p_resultado_l => 43.8, p_resultado_abv => 47.0);

-- 2026-09-17 · Benito: puntas guardadas (sin lote) al Tanque 2
select pg_temp.seed_como('4ba26002-a774-4573-a098-416b842425c4');
select registrar_movimiento_granel(pg_temp.seed_a(), 'af867ea3-4189-4872-9c3b-7f91881150e6', '2026-09-17 10:00:00-06',
  pg_temp.seed_con('f21aaad8-2ef6-556b-be55-64aa94431ab6'), pg_temp.seed_res('Tanque 2'), 2,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_resultado_l => 602, p_resultado_abv => 44.6, p_abv => 68.0,
  p_nota => 'Puntas guardadas de corridas de agosto, sin lote');
-- 2026-09-18 · Benito: unión de G-2609-01 (Tanque 1) con G-INI-01 (Tanque 2), se conserva el folio mayor
select registrar_movimiento_granel(pg_temp.seed_a(), 'cafe3c44-d628-47e4-a14a-c4f2d2198901', '2026-09-18 09:30:00-06',
  pg_temp.seed_con('df427d88-600e-550e-a097-8ffe4f4dd556'), pg_temp.seed_res('Tanque 2'), 43.8,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_lote_origen => pg_temp.seed_lot('G-2609-01'), p_recurso_origen => pg_temp.seed_res('Tanque 1'),
  p_resultado_l => 645.8, p_resultado_abv => 44.9, p_decision => 'conservar', p_nota => 'Se conserva el folio del lote mayor');
-- 2026-09-19 · Benito: compra de granel al Tanque 1
select registrar_movimiento_granel(pg_temp.seed_a(), '792acddd-879d-499c-bfe2-547e665e5cf0', '2026-09-19 12:00:00-06',
  pg_temp.seed_con('688430a9-cd2f-5bae-add2-c59bc543d911'), pg_temp.seed_res('Tanque 1'), 250,
  p_resultado_l => 250, p_resultado_abv => 46.0, p_abv => 46.0, p_folio_nuevo => 'G-COMPRA-01',
  p_contraparte => 'Destilados Hermanos Luna', p_documento => 'Remisión 0452',
  p_proveedor => '9654d498-58df-4e9a-983c-d5e71391f3d9', p_especie => pg_temp.seed_esp('67a96efd-2c72-528e-8682-d144fe1f802c'),
  p_predio_declarado => 'Sola de Vega');

-- 2026-09-19 · Aurelia: muestra de laboratorio
select pg_temp.seed_como('c46e5a21-81e7-4bd6-a8e4-a5c30056a233');
select registrar_movimiento_granel(pg_temp.seed_a(), 'ac7df339-ac55-4d81-82e0-d041e8ec7dd5', '2026-09-19 13:00:00-06',
  pg_temp.seed_con('2d62ab89-6a11-558c-8b46-5c4d30aa1607'), pg_temp.seed_res('Tanque 2'), 1,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Laboratorio ficticio de Oaxaca', p_documento => 'Análisis 2026-311');

-- 2026-09-20/22 · Benito: autoconsumo, venta, regalo
select pg_temp.seed_como('4ba26002-a774-4573-a098-416b842425c4');
select registrar_movimiento_granel(pg_temp.seed_a(), 'b8152fbe-3e80-47ae-a84b-943ca7dd06a1', '2026-09-20 13:00:00-06',
  pg_temp.seed_con('fa52f92b-de19-5d0c-972c-beb899bb2ccb'), pg_temp.seed_res('Tanque 2'), 2, p_lote => pg_temp.seed_lot('G-INI-01'));
select registrar_movimiento_granel(pg_temp.seed_a(), 'ea1930d0-0574-40eb-8f88-869af51c00cf', '2026-09-22 13:00:00-06',
  pg_temp.seed_con('7b0ca7ca-f8ae-5f33-93d5-f0c174664ec1'), pg_temp.seed_res('Tanque 2'), 300,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.', p_documento => 'Remisión 118');
select registrar_movimiento_granel(pg_temp.seed_a(), '79365566-dd75-4c50-ad43-04f000f3b814', '2026-09-22 13:00:00-06',
  'd5e79f09-600a-49fa-84d4-25cdc0852a64', pg_temp.seed_res('Tanque 2'), 1,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.');

reset role;

-- Evidencia de la compra (los adjuntos no son RPC de §12)
insert into attachments (id, organization_id, operation_id, lot_id, kind_item_id, storage_path, caption) values
  ('75d447f4-727a-4924-8fe4-ce2ff1468599', pg_temp.seed_a(),
   (select id from operations where organization_id = pg_temp.seed_a() and idempotency_key = '792acddd-879d-499c-bfe2-547e665e5cf0'),
   pg_temp.seed_lot('G-COMPRA-01'), pg_temp.seed_cat('0522e23b-3b1d-58be-b50c-8a6ed0627c9f'),
   'evidencias/b615ddaa-293c-4e09-a518-0da4610b16f2/g-compra-01/remision-0452.jpg', 'Remisión del proveedor');


-- pgTAP · Portal por empresa (PULZ_MAESTRO.md §7.3–§7.5): lo que ve alguien
-- sin sesión. portal_branding es lo único público (anon).
--     supabase db query --linked -f supabase/tests/portal.test.sql


create function pg_temp.test_portal() returns setof text language plpgsql as $$
declare a uuid := 'b615ddaa-293c-4e09-a518-0da4610b16f2'; b uuid := '2d890d64-a769-40a7-a382-1c0dbc97e69f';
begin
  -- Como anon (sin sesión), que es como llega el navegador y la Pages Function
  execute 'set local role anon';

  return next is((select name from portal_branding('qa-76bbe6751695-cuatro-vientos')), 'Mezcal Cuatro Vientos',
                 'portal_branding devuelve la marca por slug');
  return next is((select read_only from portal_branding('qa-76bbe6751695-cuatro-vientos')), false,
                 'suscripción en prueba → abierto');
  return next is((select redirect_to from portal_branding('qa-76bbe6751695-mezcal-cuatro-vientos')), 'qa-76bbe6751695-cuatro-vientos',
                 'el slug viejo redirige al actual (historial de slugs)');
  return next is((select name from portal_branding('QA-76BBE6751695-CUATRO-VIENTOS')), 'Mezcal Cuatro Vientos',
                 'el slug no distingue mayúsculas');
  return next is((select count(*) from portal_branding('no-existe')), 0::bigint,
                 'empresa inexistente: ninguna fila');
  -- anon ni siquiera tiene GRANT sobre las tablas de negocio (0013): 42501
  return next throws_ok($q$select count(*) from catalog_items$q$, '42501',
                 null, 'anon no lee nada de negocio por PostgREST (sin grant, no solo RLS)');
  return next throws_ok($q$select is_member('b615ddaa-293c-4e09-a518-0da4610b16f2')$q$, '42501',
                 null, 'anon no puede ejecutar is_member (revocado)');

  execute 'reset role';
  -- vencida → sigue abierto pero en solo lectura; cancelada → como inexistente
  update subscriptions set status = 'vencida' where organization_id = b;
  execute 'set local role anon';
  return next is((select read_only from portal_branding('qa-76bbe6751695-prueba-b')), true, 'vencida → read_only');
  execute 'reset role';
  update subscriptions set status = 'cancelada' where organization_id = b;
  execute 'set local role anon';
  return next is((select count(*) from portal_branding('qa-76bbe6751695-prueba-b')), 0::bigint,
                 'cancelada → ninguna fila, idéntico a inexistente (§7.4)');
  execute 'reset role';

  -- has_role rechaza escrituras con suscripción vencida (§11.2)
  update subscriptions set status = 'vencida' where organization_id = a;
  execute 'set local role authenticated';
  execute $q$set local request.jwt.claims = '{"sub":"4ba26002-a774-4573-a098-416b842425c4","role":"authenticated"}'$q$;
  return next is((select has_role(a, array['admin']::member_role[])), false,
                 'vencida: has_role rechaza al admin (solo lectura)');
  return next is((select is_member(a)), true, 'vencida: is_member sigue en true (la lectura sigue)');
  execute 'reset role';
end $$;

select * from runtests((select nspname from pg_namespace where oid = pg_my_temp_schema())::name, '^test_');


rollback;
