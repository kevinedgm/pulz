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
-- tomas.h → 'tomas-2026' · dueña B → 'qa-bafaca534319-prueba-b-2026' · admin → 'pulz-2026'
-- ---------------------------------------------------------------------
insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
                        raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
                        confirmation_token, recovery_token, email_change_token_new, email_change) values
  ('00000000-0000-0000-0000-000000000000', '3d7bfe2b-81f6-41b8-9896-82b07e6f7195', 'authenticated', 'authenticated', 'qa-bafaca534319-tu@pulz.mx',
   extensions.crypt('pulz-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', 'f8fb9c90-a957-445e-af14-7ae4ff6a15e6', 'authenticated', 'authenticated', 'qa-bafaca534319-benito@cuatrovientos.mx',
   extensions.crypt('benito-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '24779240-b10a-4822-bde1-42b3387abe23', 'authenticated', 'authenticated', 'qa-bafaca534319-aurelia@df32d354-6ab5-4cf4-bbc0-a58d39253d79.usuarios.pulz.mx',
   extensions.crypt('aurelia-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '493e9ff0-2712-45cf-b1ce-d7771c716a4b', 'authenticated', 'authenticated', 'qa-bafaca534319-tomas.h@df32d354-6ab5-4cf4-bbc0-a58d39253d79.usuarios.pulz.mx',
   extensions.crypt('tomas-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', 'be11da5b-35f7-470b-b6d5-9625a816d4e4', 'authenticated', 'authenticated', 'qa-bafaca534319-duena@pruebab.mx',
   extensions.crypt('qa-bafaca534319-prueba-b-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '');

insert into profiles (id, full_name) values
  ('3d7bfe2b-81f6-41b8-9896-82b07e6f7195', 'Admin PULZ'),
  ('f8fb9c90-a957-445e-af14-7ae4ff6a15e6', 'Benito Cruz'),
  ('24779240-b10a-4822-bde1-42b3387abe23', 'Aurelia Santiago'),
  ('493e9ff0-2712-45cf-b1ce-d7771c716a4b', 'Tomás Hernández'),
  ('be11da5b-35f7-470b-b6d5-9625a816d4e4', 'Dueña Prueba B');

insert into platform_admins (user_id) values ('3d7bfe2b-81f6-41b8-9896-82b07e6f7195');

-- Planes (§14, §18 #2 y #3)
-- Fixture: reutiliza plans canónica, sin modificarla.
-- Fixture: reutiliza plan_limits canónica, sin modificarla.
-- Fixture: reutiliza plan_features canónica, sin modificarla.

-- Empresas
insert into organizations (id, name, slug, state, brand_color, logo_path, welcome_message, created_by) values
  ('df32d354-6ab5-4cf4-bbc0-a58d39253d79', 'Mezcal Cuatro Vientos', 'qa-bafaca534319-cuatro-vientos', 'Oaxaca', '#7A3E1D', null, 'Registro de producción del palenque', 'f8fb9c90-a957-445e-af14-7ae4ff6a15e6'),
  ('1bb2dac7-49b5-4b4a-ae49-e5c96df3a99f', 'Palenque Prueba B', 'qa-bafaca534319-prueba-b', 'Oaxaca', '#173F87', null, 'Empresa de prueba', 'be11da5b-35f7-470b-b6d5-9625a816d4e4');
insert into organization_slug_history (slug, organization_id, retired_at, retired_by) values
  ('qa-bafaca534319-mezcal-cuatro-vientos', 'df32d354-6ab5-4cf4-bbc0-a58d39253d79', '2026-09-02 09:00:00-06', 'f8fb9c90-a957-445e-af14-7ae4ff6a15e6');
insert into organization_members (organization_id, user_id, role, status, username, must_change_password) values
  ('df32d354-6ab5-4cf4-bbc0-a58d39253d79', 'f8fb9c90-a957-445e-af14-7ae4ff6a15e6', 'admin', 'activo', null, false),
  ('df32d354-6ab5-4cf4-bbc0-a58d39253d79', '24779240-b10a-4822-bde1-42b3387abe23', 'productor', 'activo', 'aurelia', false),
  ('df32d354-6ab5-4cf4-bbc0-a58d39253d79', '493e9ff0-2712-45cf-b1ce-d7771c716a4b', 'operador', 'activo', 'tomas.h', true),
  ('1bb2dac7-49b5-4b4a-ae49-e5c96df3a99f', 'be11da5b-35f7-470b-b6d5-9625a816d4e4', 'admin', 'activo', null, false);
insert into member_invitations (id, organization_id, user_id, token_hash, expires_at, used_at, created_by) values
  ('3875dd16-a543-4cdf-8a8e-e059868a27f4', 'df32d354-6ab5-4cf4-bbc0-a58d39253d79', '493e9ff0-2712-45cf-b1ce-d7771c716a4b', 'qa-bafaca534319:SIMULADO', '2026-09-05 10:00:00-06', null, 'f8fb9c90-a957-445e-af14-7ae4ff6a15e6');
insert into login_throttle (user_id, failed_count, last_failed_at, locked_until) values
  ('493e9ff0-2712-45cf-b1ce-d7771c716a4b', 3, '2026-09-03 07:12:00-06', null);
insert into organization_settings (organization_id, record_puntas, measurement_mode, warn_mixed_second_pass, fermentation_expected_days, measurement_reminder_hour, default_folio_decision) values
  ('df32d354-6ab5-4cf4-bbc0-a58d39253d79', false, 'minimo', true, 7, 9, 'conservar'),
  ('1bb2dac7-49b5-4b4a-ae49-e5c96df3a99f', false, 'minimo', true, 7, 9, 'conservar');
insert into subscriptions (organization_id, plan_id, status, current_period_end) values
  ('df32d354-6ab5-4cf4-bbc0-a58d39253d79', 'edd15bcf-ad82-5684-a2e7-d85db401885b', 'prueba', '2026-10-15 00:00:00-06'),
  ('1bb2dac7-49b5-4b4a-ae49-e5c96df3a99f', 'ee35d6fd-b4d6-56d6-b7b4-61cb81932b21', 'gratis', null);

-- ---------------------------------------------------------------------
-- Plantillas de plataforma (§10.2.1)
-- ---------------------------------------------------------------------
-- Fixture: reutiliza catalog_item_templates canónica, sin modificarla.
-- Fixture: reutiliza movement_concept_templates canónica, sin modificarla.
-- Fixture: reutiliza species_templates canónica, sin modificarla.

select seed_organization_catalogs('df32d354-6ab5-4cf4-bbc0-a58d39253d79');
select seed_organization_catalogs('1bb2dac7-49b5-4b4a-ae49-e5c96df3a99f');

-- Lo propio de Cuatro Vientos y lo que oculta (§10.2.4)
insert into catalog_items (id, organization_id, template_id, catalog, name, sort_order, created_by) values
  ('93ded1d4-6e9d-447a-ac6f-efcd1aeb7fe9', 'df32d354-6ab5-4cf4-bbc0-a58d39253d79', null, 'tipo_alambique', 'Refrescadera de cobre', 100, 'f8fb9c90-a957-445e-af14-7ae4ff6a15e6');
insert into movement_concepts (id, organization_id, template_id, direction, name, source_lot, creates_lot, asks_result, asks_counterparty, sort_order, created_by) values
  ('621b7a7a-dbdc-4656-91fc-3e5d139171c5', 'df32d354-6ab5-4cf4-bbc0-a58d39253d79', null, 'salida', 'Regalo a cliente', 'no_aplica', false, false, true, 100, 'f8fb9c90-a957-445e-af14-7ae4ff6a15e6');
update catalog_items set active = false
 where organization_id = 'df32d354-6ab5-4cf4-bbc0-a58d39253d79'
   and template_id in ('5c985133-23d9-50fa-a252-6ff6b5b74134', 'b1fce67a-21bf-50a7-9344-fdf29eb5331e');
update movement_concepts set active = false
 where organization_id = 'df32d354-6ab5-4cf4-bbc0-a58d39253d79'
   and template_id = '8b7f6579-99ef-549e-b427-b1d4d8bea9da';

-- ---------------------------------------------------------------------
-- Ayudas de la semilla (temporales; mueren con la sesión). security definer
-- para que resuelvan ids aunque el rol activo sea 'authenticated'.
-- ---------------------------------------------------------------------
create function pg_temp.seed_a() returns uuid language sql immutable as $$ select 'df32d354-6ab5-4cf4-bbc0-a58d39253d79'::uuid $$;
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
  ('43af5f54-9519-4b20-b7bb-de328c62ad77', pg_temp.seed_a(), 'Loma del Toro', 'Santiago Matatlán', 'Familia Cruz');
insert into suppliers (id, organization_id, name, type_item_id) values
  ('c576523c-536a-4e3c-a050-5f1fd907afab', pg_temp.seed_a(), 'Magueyes Don Pedro', pg_temp.seed_cat('640b537d-bf52-5c4b-b407-a5f4fb7c5800')),
  ('8077ad3e-1899-4f96-9bf2-5718a0ca7a70', pg_temp.seed_a(), 'Destilados Hermanos Luna', pg_temp.seed_cat('bb234638-3c78-56cd-9f41-2fb38182f181'));
insert into supplies (id, organization_id, name, unit_item_id) values
  ('4e28b1b8-ed34-4f5e-94bb-abbf0d9c9d43', pg_temp.seed_a(), 'Pulque como inóculo', pg_temp.seed_cat('bc6f104d-2841-5b36-b492-76b36becb172'));
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy, liquid_class) values
  ('ffa39e66-4139-455b-9767-3aba0ff6e29d', pg_temp.seed_a(), 'horno', 'Horno 1', pg_temp.seed_cat('d53ba2da-cada-5215-804a-ff304d569f97'), 10000, 'kg', 'libre', null),
  ('ebd49fa1-44d3-4806-987a-4e7378bd7199', pg_temp.seed_a(), 'molino', 'Tahona', pg_temp.seed_cat('60285283-d000-52f0-95da-d2b2e6d70fa1'), null, 'kg', 'libre', null),
  ('7a14fd82-a2fc-4657-a922-a71cfa4c015c', pg_temp.seed_a(), 'tina', 'Tina 1', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('f0c19b85-4772-4c49-b009-63b607de2863', pg_temp.seed_a(), 'tina', 'Tina 2', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('b8ec5340-0c6c-461d-b4a8-c28a30fa9b1d', pg_temp.seed_a(), 'tina', 'Tina 3', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('e2f6ec88-1b7c-4603-ae8a-b4d92f117920', pg_temp.seed_a(), 'alambique', 'Alambique 1', pg_temp.seed_cat('af73010e-53f2-5769-b3b1-6cda154e665e'), 300, 'L', 'estricta', null),
  ('18f6d65c-c594-4d4a-a006-71d54a3fc197', pg_temp.seed_a(), 'alambique', 'Alambique 2', '93ded1d4-6e9d-447a-ac6f-efcd1aeb7fe9', 250, 'L', 'estricta', null),
  ('3a223477-3efb-4989-8bdc-c1ee29278460', pg_temp.seed_a(), 'colector', 'Colector mezcal', pg_temp.seed_cat('2cd7e70b-6246-543e-8f67-23743fefdf95'), 60, 'L', 'flexible', 'mezcal'),
  ('d6d83f3f-2022-4f23-901e-58d01dd5ec8b', pg_temp.seed_a(), 'colector', 'Colector ordinario', pg_temp.seed_cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'ordinario'),
  ('202fa09b-3d6f-401d-a8c4-510f090594fa', pg_temp.seed_a(), 'colector', 'Colector colas', pg_temp.seed_cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'colas'),
  ('7b62ec06-7aea-44d4-8026-a3591ad5af79', pg_temp.seed_a(), 'tanque', 'Tanque 1', pg_temp.seed_cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1000, 'L', 'flexible', null),
  ('db856d86-89a7-4dbc-a0a2-d009d69d257e', pg_temp.seed_a(), 'tanque', 'Tanque 2', pg_temp.seed_cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1500, 'L', 'flexible', null);

-- Palenque Prueba B: lo mínimo para probar aislamiento
insert into predios (id, organization_id, name, municipality) values
  ('87779e94-0f9f-4c00-8b8c-d71c38b3a989', '1bb2dac7-49b5-4b4a-ae49-e5c96df3a99f', 'Predio B', 'Ejutla');
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy) values
  ('634a2e47-70a0-4386-b123-e293d7fd7386', '1bb2dac7-49b5-4b4a-ae49-e5c96df3a99f', 'tina', 'Tina B1',
   (select id from catalog_items where organization_id = '1bb2dac7-49b5-4b4a-ae49-e5c96df3a99f' and template_id = 'b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1000, 'L', 'flexible');

-- =====================================================================
-- Cuatro Vientos: la producción, POR RPC, en orden cronológico
-- =====================================================================

-- 2026-09-01 · Benito: lo que ya había en el Tanque 2 (carga inicial)
select pg_temp.seed_como('f8fb9c90-a957-445e-af14-7ae4ff6a15e6');
select registrar_entrada(pg_temp.seed_a(), 'c1a79c4a-b357-43e2-a6ec-84c4ec8c2079', '2026-09-01 10:15:00-06',
  'granel', pg_temp.seed_res('Tanque 2'), 600, 44.2, 'mezcal', 'carga_inicial',
  p_concepto => pg_temp.seed_con('255e79f1-12b3-5969-8453-e40623275559'),
  p_nota => 'Lo que ya había en el tanque al empezar', p_folio => 'G-INI-01');

-- 2026-09-01 · Aurelia: la Tina 3 ya fermentaba
select pg_temp.seed_como('24779240-b10a-4822-bde1-42b3387abe23');
select registrar_entrada(pg_temp.seed_a(), 'c3a5969b-988e-448e-924a-62907e3fa6a5', '2026-09-01 10:40:00-06',
  'fermentado', pg_temp.seed_res('Tina 3'), 1300, null, null, 'carga_inicial',
  p_nota => 'Tina que ya fermentaba', p_folio => 'FER-T3-INI');

-- 2026-09-02 · Aurelia: recepción de maguey
select registrar_recepcion_maguey(pg_temp.seed_a(), 'a69cfa35-4980-41d6-88ba-9ddfa7b17c56', '2026-09-02 07:30:00-06',
  8000, pg_temp.seed_esp('67a96efd-2c72-528e-8682-d144fe1f802c'), '43af5f54-9519-4b20-b7bb-de328c62ad77',
  'c576523c-536a-4e3c-a050-5f1fd907afab', 132, 'Piñas de 8 años, buen tamaño', 'MAG-001');

-- 2026-09-02 · Horneado (la simulación lo abría Tomás; §11.1 lo reserva a
-- admin/productor, así que lo abre Aurelia — docs/DECISIONES.md)
select abrir_horneado(pg_temp.seed_a(), '18073434-2eac-4433-95b2-89245988739d', '2026-09-02 12:00:00-06',
  pg_temp.seed_res('Horno 1'), array[pg_temp.seed_lot('MAG-001')], array[8000::numeric], p_folio => 'HOR-001');
-- 2026-09-06 · Aurelia cierra: 6,200 kg de agave cocido
select cerrar_horneado(pg_temp.seed_a(), 'f6203153-c202-43ac-85cf-b4a30d8e7f92', '2026-09-06 08:00:00-06',
  pg_temp.seed_hor('HOR-001'), 6200, 'Leña de encino', p_folio => 'AC-001');

-- 2026-09-07 · Aurelia: formulación repartida a Tina 1 y Tina 2
select registrar_formulacion(pg_temp.seed_a(), 'e5fe6360-16e6-4337-aaf2-c566e0494465', '2026-09-07 09:00:00-06',
  pg_temp.seed_res('Tahona'), array[pg_temp.seed_lot('AC-001')], array[6200::numeric], 1900,
  array[pg_temp.seed_res('Tina 1'), pg_temp.seed_res('Tina 2')], array[1400::numeric, 1400::numeric],
  array['4e28b1b8-ed34-4f5e-94bb-abbf0d9c9d43'::uuid], array[20::numeric],
  'Tahona con mula', null, 'F-001', array['FER-T1-001', 'FER-T2-001']);

-- Mediciones diarias (escala de actividad 1–6, §18 #1; la simulación traía 7 y 8)
-- Tina 1
select pg_temp.seed_como('493e9ff0-2712-45cf-b1ce-d7771c716a4b');
select registrar_medicion(pg_temp.seed_a(), '521b6b95-f613-4d79-ad9b-0b4dc1d35792', '2026-09-08 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 1, 'minimo', 4,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.5,12.0]::numeric[]);
select pg_temp.seed_como('24779240-b10a-4822-bde1-42b3387abe23');
select registrar_medicion(pg_temp.seed_a(), 'e90b80f0-595f-4351-8127-90df5c2d8bd2', '2026-09-09 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.0,9.5]::numeric[]);
select pg_temp.seed_como('493e9ff0-2712-45cf-b1ce-d7771c716a4b');
select registrar_medicion(pg_temp.seed_a(), '9b0308bd-ea74-488b-a715-383914de936b', '2026-09-10 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.5,6.0]::numeric[]);
select pg_temp.seed_como('24779240-b10a-4822-bde1-42b3387abe23');
select registrar_medicion(pg_temp.seed_a(), 'c91ffa7e-d772-4b71-a9fc-c705320bde85', '2026-09-11 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 4, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.5,3.5]::numeric[]);
select pg_temp.seed_como('493e9ff0-2712-45cf-b1ce-d7771c716a4b');
select registrar_medicion(pg_temp.seed_a(), 'b10db18e-ab93-4097-bb24-7411574e4018', '2026-09-12 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 5, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.0,1.5]::numeric[]);
-- Tina 2
select registrar_medicion(pg_temp.seed_a(), '1977e08f-3e41-4b0d-a30f-0fa7f3a1e302', '2026-09-08 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 1, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.0,12.2]::numeric[]);
select registrar_medicion(pg_temp.seed_a(), '90332364-edb3-45b5-882d-a05b072c1345', '2026-09-09 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.5,10.1]::numeric[]);
select registrar_medicion(pg_temp.seed_a(), '5299200f-bc2b-4767-bcd1-ebe3959cfd38', '2026-09-10 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.0,7.4]::numeric[]);

-- 2026-09-12 · Aurelia declara lista la Tina 1
select pg_temp.seed_como('24779240-b10a-4822-bde1-42b3387abe23');
select declarar_tina_lista(pg_temp.seed_a(), 'b552c4bd-cd48-4d22-9804-f51f25fa44fa', '2026-09-12 17:00:00-06',
  pg_temp.seed_cyc('Tina 1'), 'Día 5: ya no burbujea, sabor seco');

-- 2026-09-13 · Tomás: dos corridas de 1ª pasada desde la Tina 1
select pg_temp.seed_como('493e9ff0-2712-45cf-b1ce-d7771c716a4b');
select abrir_corrida(pg_temp.seed_a(), '69779b64-b7d5-4374-a9eb-ed74d852ffab', '2026-09-13 06:00:00-06',
  pg_temp.seed_res('Alambique 1'), 'primera', array[pg_temp.seed_res('Tina 1')], array[pg_temp.seed_lot('FER-T1-001')], array[290::numeric],
  p_folio => 'DES-001');
select registrar_corte(pg_temp.seed_a(), '33bb11ba-5453-422e-ac7d-5ef1798cc941', '2026-09-13 08:00:00-06', pg_temp.seed_run('DES-001'), 'mezcal', 8, 51.0, pg_temp.seed_res('Colector mezcal'), p_folio => 'MEZ-001');
select registrar_corte(pg_temp.seed_a(), '51665859-a7e6-44e7-af41-2766c536e5cf', '2026-09-13 10:00:00-06', pg_temp.seed_run('DES-001'), 'ordinario', 40, 24.0, pg_temp.seed_res('Colector ordinario'), p_folio => 'ORD-001');
select registrar_corte(pg_temp.seed_a(), 'eca6f5e7-a7cc-4849-9c1b-bb6065e21317', '2026-09-13 12:00:00-06', pg_temp.seed_run('DES-001'), 'colas', 12, 9.0, pg_temp.seed_res('Colector colas'), p_folio => 'COL-001');
select cerrar_corrida(pg_temp.seed_a(), '3b7a9604-7c91-42a7-8d81-f2fb1cce52d7', '2026-09-13 14:00:00-06', pg_temp.seed_run('DES-001'));

select abrir_corrida(pg_temp.seed_a(), '83e2dab2-5771-4d01-8a13-fa1c8d6cb5b0', '2026-09-13 06:00:00-06',
  pg_temp.seed_res('Alambique 2'), 'primera', array[pg_temp.seed_res('Tina 1')], array[pg_temp.seed_lot('FER-T1-001')], array[240::numeric],
  p_folio => 'DES-002');
select registrar_corte(pg_temp.seed_a(), '1e45eb00-3602-4933-8a8b-d0b20d6790ee', '2026-09-13 08:00:00-06', pg_temp.seed_run('DES-002'), 'mezcal', 6, 50.0, pg_temp.seed_res('Colector mezcal'));
select registrar_corte(pg_temp.seed_a(), '81da9382-96b4-41ac-af76-517a9997d82d', '2026-09-13 10:00:00-06', pg_temp.seed_run('DES-002'), 'ordinario', 34, 23.0, pg_temp.seed_res('Colector ordinario'));
select registrar_corte(pg_temp.seed_a(), 'aeb69c89-f1e9-4c2b-8095-edbbdeb663f6', '2026-09-13 12:00:00-06', pg_temp.seed_run('DES-002'), 'colas', 10, 8.0, pg_temp.seed_res('Colector colas'));
select cerrar_corrida(pg_temp.seed_a(), '0a20270f-d660-48c3-bf97-acba92022ae4', '2026-09-13 14:00:00-06', pg_temp.seed_run('DES-002'));

-- 2026-09-15 · Tomás: 2ª pasada con ordinario y colas juntos (aviso + nota)
select abrir_corrida(pg_temp.seed_a(), '79705ed1-ab69-4e4e-965e-b1f3cf120471', '2026-09-15 06:00:00-06',
  pg_temp.seed_res('Alambique 1'), 'segunda',
  array[pg_temp.seed_res('Colector ordinario'), pg_temp.seed_res('Colector colas')],
  array[pg_temp.seed_lot('ORD-001'), pg_temp.seed_lot('COL-001')], array[74::numeric, 22::numeric],
  'Había olla libre y poca cola; se juntó con el ordinario', 'DES-003');
select registrar_corte(pg_temp.seed_a(), '727d6c7f-2a76-423b-8f30-0a6dbf146332', '2026-09-15 08:00:00-06', pg_temp.seed_run('DES-003'), 'mezcal', 26, 52.5, pg_temp.seed_res('Colector mezcal'));
select registrar_corte(pg_temp.seed_a(), '45efe2b1-1127-4a1a-81ee-126d861621a7', '2026-09-15 10:00:00-06', pg_temp.seed_run('DES-003'), 'colas', 16, 10.0, pg_temp.seed_res('Colector colas'), p_folio => 'COL-002');
select cerrar_corrida(pg_temp.seed_a(), '49e976ef-9056-475f-a7a8-268c4c527014', '2026-09-15 14:00:00-06', pg_temp.seed_run('DES-003'));

-- 2026-09-16 · Aurelia: el mezcal del colector pasa a granel con folio nuevo
select pg_temp.seed_como('24779240-b10a-4822-bde1-42b3387abe23');
select transferir(pg_temp.seed_a(), '5ff24a74-f33d-41ab-83b5-7a1ff77d9f15', '2026-09-16 09:00:00-06',
  pg_temp.seed_res('Colector mezcal'), pg_temp.seed_res('Tanque 1'), pg_temp.seed_lot('MEZ-001'), 40, 51.6, 'renombrar', 'G-2609-01');
-- Agua para bajar grado: 4 L, declara 43.8 L (contracción) y 47.0 %
select registrar_movimiento_granel(pg_temp.seed_a(), '5fbe8480-68a3-425d-b612-e85694dd60d4', '2026-09-16 11:00:00-06',
  pg_temp.seed_con('66a151e2-9a2c-58be-ad4a-b117f1ddb717'), pg_temp.seed_res('Tanque 1'), 4,
  p_lote => pg_temp.seed_lot('G-2609-01'), p_resultado_l => 43.8, p_resultado_abv => 47.0);

-- 2026-09-17 · Benito: puntas guardadas (sin lote) al Tanque 2
select pg_temp.seed_como('f8fb9c90-a957-445e-af14-7ae4ff6a15e6');
select registrar_movimiento_granel(pg_temp.seed_a(), '6d458b55-1ab2-47b9-a7d6-a435666d2858', '2026-09-17 10:00:00-06',
  pg_temp.seed_con('f21aaad8-2ef6-556b-be55-64aa94431ab6'), pg_temp.seed_res('Tanque 2'), 2,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_resultado_l => 602, p_resultado_abv => 44.6, p_abv => 68.0,
  p_nota => 'Puntas guardadas de corridas de agosto, sin lote');
-- 2026-09-18 · Benito: unión de G-2609-01 (Tanque 1) con G-INI-01 (Tanque 2), se conserva el folio mayor
select registrar_movimiento_granel(pg_temp.seed_a(), 'acb3650b-147f-4c8c-966b-221a32f9704b', '2026-09-18 09:30:00-06',
  pg_temp.seed_con('df427d88-600e-550e-a097-8ffe4f4dd556'), pg_temp.seed_res('Tanque 2'), 43.8,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_lote_origen => pg_temp.seed_lot('G-2609-01'), p_recurso_origen => pg_temp.seed_res('Tanque 1'),
  p_resultado_l => 645.8, p_resultado_abv => 44.9, p_decision => 'conservar', p_nota => 'Se conserva el folio del lote mayor');
-- 2026-09-19 · Benito: compra de granel al Tanque 1
select registrar_movimiento_granel(pg_temp.seed_a(), '3521e68b-7839-49df-a952-9b078ca9d080', '2026-09-19 12:00:00-06',
  pg_temp.seed_con('688430a9-cd2f-5bae-add2-c59bc543d911'), pg_temp.seed_res('Tanque 1'), 250,
  p_resultado_l => 250, p_resultado_abv => 46.0, p_abv => 46.0, p_folio_nuevo => 'G-COMPRA-01',
  p_contraparte => 'Destilados Hermanos Luna', p_documento => 'Remisión 0452',
  p_proveedor => '8077ad3e-1899-4f96-9bf2-5718a0ca7a70', p_especie => pg_temp.seed_esp('67a96efd-2c72-528e-8682-d144fe1f802c'),
  p_predio_declarado => 'Sola de Vega');

-- 2026-09-19 · Aurelia: muestra de laboratorio
select pg_temp.seed_como('24779240-b10a-4822-bde1-42b3387abe23');
select registrar_movimiento_granel(pg_temp.seed_a(), '4c9100a3-5a81-4093-afc5-6354c490b911', '2026-09-19 13:00:00-06',
  pg_temp.seed_con('2d62ab89-6a11-558c-8b46-5c4d30aa1607'), pg_temp.seed_res('Tanque 2'), 1,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Laboratorio ficticio de Oaxaca', p_documento => 'Análisis 2026-311');

-- 2026-09-20/22 · Benito: autoconsumo, venta, regalo
select pg_temp.seed_como('f8fb9c90-a957-445e-af14-7ae4ff6a15e6');
select registrar_movimiento_granel(pg_temp.seed_a(), 'b8683983-0786-408a-a553-e019a0412139', '2026-09-20 13:00:00-06',
  pg_temp.seed_con('fa52f92b-de19-5d0c-972c-beb899bb2ccb'), pg_temp.seed_res('Tanque 2'), 2, p_lote => pg_temp.seed_lot('G-INI-01'));
select registrar_movimiento_granel(pg_temp.seed_a(), '55225c66-df6f-4bde-915f-1fc391d47d4f', '2026-09-22 13:00:00-06',
  pg_temp.seed_con('7b0ca7ca-f8ae-5f33-93d5-f0c174664ec1'), pg_temp.seed_res('Tanque 2'), 300,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.', p_documento => 'Remisión 118');
select registrar_movimiento_granel(pg_temp.seed_a(), '754c2daf-d5d5-4123-8d0d-a7cd19c99a2f', '2026-09-22 13:00:00-06',
  '621b7a7a-dbdc-4656-91fc-3e5d139171c5', pg_temp.seed_res('Tanque 2'), 1,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.');

reset role;

-- Evidencia de la compra (los adjuntos no son RPC de §12)
insert into attachments (id, organization_id, operation_id, lot_id, kind_item_id, storage_path, caption) values
  ('2b48e70b-25f9-4c04-8e42-2981ee7f03e0', pg_temp.seed_a(),
   (select id from operations where organization_id = pg_temp.seed_a() and idempotency_key = '3521e68b-7839-49df-a952-9b078ca9d080'),
   pg_temp.seed_lot('G-COMPRA-01'), pg_temp.seed_cat('0522e23b-3b1d-58be-b50c-8a6ed0627c9f'),
   'evidencias/df32d354-6ab5-4cf4-bbc0-a58d39253d79/g-compra-01/remision-0452.jpg', 'Remisión del proveedor');


-- pgTAP · Comandos (RPC) — PULZ_MAESTRO.md §12, §16 Fase 2.
-- Se corre igual que el de aislamiento (sin Docker):
--     supabase db query --linked -f supabase/tests/rpc.test.sql
-- Todo dentro de una transacción que termina en rollback.
--
-- Parte del estado que deja seed.sql (construido por RPC): comprueba los
-- saldos de §15.1, la idempotencia, cada regla dura, los avisos blandos, la
-- regla de acumulación de colectores, transferir y la conciliación.


create function pg_temp.a() returns uuid language sql immutable as $$ select 'df32d354-6ab5-4cf4-bbc0-a58d39253d79'::uuid $$;
create function pg_temp.res(c text) returns uuid language sql stable security definer as $$
  select id from resources where organization_id = pg_temp.a() and code = c $$;
create function pg_temp.lot(f text) returns uuid language sql stable security definer as $$
  select id from lots where organization_id = pg_temp.a() and folio = f $$;
create function pg_temp.cyc(tina text) returns uuid language sql stable security definer as $$
  select c.id from fermentation_cycles c join resources r on r.id = c.tina_id
   where c.organization_id = pg_temp.a() and r.code = tina and c.status <> 'cerrado' $$;
create function pg_temp.run(f text) returns uuid language sql stable security definer as $$
  select id from distillation_runs where organization_id = pg_temp.a() and folio = f $$;
create function pg_temp.con(t uuid) returns uuid language sql stable security definer as $$
  select id from movement_concepts where organization_id = pg_temp.a() and template_id = t $$;
create function pg_temp.bal(res text, f text) returns numeric language sql stable security definer as $$
  select lot_balance(pg_temp.a(), pg_temp.res(res), pg_temp.lot(f)) $$;
create function pg_temp.como(u uuid) returns void language plpgsql as $$
begin
  execute 'set local role authenticated';
  execute format('set local request.jwt.claims = %L', json_build_object('sub', u, 'role', 'authenticated')::text);
end $$;

create function pg_temp.test_rpc() returns setof text language plpgsql as $$
declare
  benito  uuid := 'f8fb9c90-a957-445e-af14-7ae4ff6a15e6';
  aurelia uuid := '24779240-b10a-4822-bde1-42b3387abe23';
  tomas   uuid := '493e9ff0-2712-45cf-b1ce-d7771c716a4b';
  duena_b uuid := 'be11da5b-35f7-470b-b6d5-9625a816d4e4';
  n0 bigint; v uuid; v2 uuid; v_op uuid;
begin
  -- 1) La simulación construida por RPC da exactamente §15.1
  return next results_eq(
    $q$select r.code, l.folio, b.volume_l::numeric(12,3)
         from resource_lot_balances b
         join resources r on r.id = b.resource_id
         join lots l on l.id = b.lot_id
        where b.organization_id = 'df32d354-6ab5-4cf4-bbc0-a58d39253d79'
        order by r.code, l.folio$q$,
    $q$values ('Colector colas', 'COL-002',     16.000::numeric(12,3)),
              ('Tanque 1',       'G-COMPRA-01', 250.000::numeric(12,3)),
              ('Tanque 2',       'G-INI-01',    341.800::numeric(12,3)),
              ('Tina 1',         'FER-T1-001',  870.000::numeric(12,3)),
              ('Tina 2',         'FER-T2-001',  1400.000::numeric(12,3)),
              ('Tina 3',         'FER-T3-INI',  1300.000::numeric(12,3))$q$,
    'la simulación por RPC da los saldos de §15.1');

  -- 2) Idempotencia: repetir la misma llave no duplica nada
  perform pg_temp.como(benito);
  select count(*) into n0 from liquid_movements where organization_id = pg_temp.a();
  select registrar_movimiento_granel(pg_temp.a(), 'b8683983-0786-408a-a553-e019a0412139', '2026-09-20 13:00:00-06',
    pg_temp.con('fa52f92b-de19-5d0c-972c-beb899bb2ccb'), pg_temp.res('Tanque 2'), 2, p_lote => pg_temp.lot('G-INI-01'))
    into v;
  return next is(v, pg_temp.lot('G-INI-01'), 'idempotencia: la segunda llamada devuelve el mismo lote');
  return next is((select count(*) from liquid_movements where organization_id = pg_temp.a()), n0,
                 'idempotencia: la segunda llamada no agrega patas al ledger');

  -- 3) Reglas duras
  return next throws_like(
    format($q$select registrar_movimiento_granel('%s', gen_random_uuid(), now(), '%s', '%s', 10000, p_lote => '%s')$q$,
           pg_temp.a(), pg_temp.con('fa52f92b-de19-5d0c-972c-beb899bb2ccb'), pg_temp.res('Tanque 2'), pg_temp.lot('G-INI-01')),
    'SALDO_INSUFICIENTE:%', 'dura: no se puede sacar más de lo que hay');
  return next throws_like(
    format($q$select abrir_corrida('%s', gen_random_uuid(), now(), '%s', 'primera', array['%s']::uuid[], array['%s']::uuid[], array[400]::numeric[])$q$,
           pg_temp.a(), pg_temp.res('Alambique 1'), pg_temp.res('Tina 2'), pg_temp.lot('FER-T2-001')),
    'CAPACIDAD_EXCEDIDA:%', 'dura: la capacidad estricta del alambique bloquea');
  perform pg_temp.como(duena_b);
  return next throws_like(
    format($q$select registrar_medicion('%s', gen_random_uuid(), now(), '%s', 4::smallint, 'minimo', 3::smallint)$q$,
           pg_temp.a(), pg_temp.cyc('Tina 2')),
    'NO_PERMITIDO:%', 'dura: un usuario de otra empresa no ejecuta RPC de A');
  perform pg_temp.como(tomas);
  return next throws_like(
    format($q$select registrar_recepcion_maguey('%s', gen_random_uuid(), now(), 100)$q$, pg_temp.a()),
    'NO_PERMITIDO:%', 'dura: un operador no registra recepción de maguey (§11.1, §18 #4)');
  return next throws_like(
    format($q$select transferir('%s', gen_random_uuid(), now(), '%s', '%s', '%s', 1)$q$,
           pg_temp.a(), pg_temp.res('Tanque 1'), pg_temp.res('Tanque 2'), pg_temp.lot('G-COMPRA-01')),
    'NO_PERMITIDO:%', 'dura: un operador no transfiere granel');

  -- 4) Avisos blandos: sin nota fallan con REQUIERE_NOTA; con nota quedan registrados
  perform pg_temp.como(aurelia);
  return next throws_like(
    format($q$select registrar_medicion('%s', gen_random_uuid(), now(), '%s', 1::smallint, 'minimo', 3::smallint,
              array['brix']::reading_variable[], array['unica']::reading_zone[], array[1]::smallint[], array[20.0]::numeric[])$q$,
           pg_temp.a(), pg_temp.cyc('Tina 2')),
    'REQUIERE_NOTA:brix_fuera_rango', 'blanda: Brix inicial fuera de rango sin nota pide nota');
  return next lives_ok(
    format($q$select registrar_medicion('%s', '0092d1ef-48e5-4b5e-baab-a7a7dd08079b', now(), '%s', 1::smallint, 'minimo', 3::smallint,
              array['brix']::reading_variable[], array['unica']::reading_zone[], array[1]::smallint[], array[20.0]::numeric[],
              'Brix alto, agua dura')$q$,
           pg_temp.a(), pg_temp.cyc('Tina 2')),
    'blanda: con nota, la medición se registra');
  return next is((select count(*) from operation_warnings w join operations o on o.id = w.operation_id
                   where o.idempotency_key = '0092d1ef-48e5-4b5e-baab-a7a7dd08079b' and w.code = 'brix_fuera_rango'), 1::bigint,
                 'blanda: el aviso queda en operation_warnings con su nota');

  -- 5) Regla de acumulación de colectores (§4.5)
  perform pg_temp.como(tomas);
  return next lives_ok(
    format($q$select abrir_corrida('%s', gen_random_uuid(), now(), '%s', 'primera', array['%s']::uuid[], array['%s']::uuid[], array[200]::numeric[], null, 'DES-004')$q$,
           pg_temp.a(), pg_temp.res('Alambique 1'), pg_temp.res('Tina 2'), pg_temp.lot('FER-T2-001')),
    'acumulación: se abre DES-004 desde la Tina 2');
  select registrar_corte(pg_temp.a(), gen_random_uuid(), now(), pg_temp.run('DES-004'), 'mezcal', 5, 50.0, pg_temp.res('Colector mezcal')) into v;
  return next isnt(v, pg_temp.lot('MEZ-001'), 'acumulación: colector vacío → nace lote nuevo');
  return next is((select folio from lots where id = v), 'MEZ-002', 'acumulación: el folio automático salta los que ya existen');
  select registrar_corte(pg_temp.a(), gen_random_uuid(), now(), pg_temp.run('DES-004'), 'colas', 3, 9.0, pg_temp.res('Colector colas')) into v;
  return next is(v, pg_temp.lot('COL-002'), 'acumulación: se suma al lote vivo del colector (COL-002) porque no se cargó a esta corrida');
  perform cerrar_corrida(pg_temp.a(), gen_random_uuid(), now(), pg_temp.run('DES-004'));
  return next lives_ok(
    format($q$select abrir_corrida('%s', gen_random_uuid(), now(), '%s', 'segunda', array['%s']::uuid[], array['%s']::uuid[], array[19]::numeric[], null, 'DES-005')$q$,
           pg_temp.a(), pg_temp.res('Alambique 2'), pg_temp.res('Colector colas'), pg_temp.lot('COL-002')),
    'acumulación: se abre DES-005 cargando COL-002');
  select registrar_corte(pg_temp.a(), gen_random_uuid(), now(), pg_temp.run('DES-005'), 'colas', 2, 8.0, pg_temp.res('Colector colas')) into v2;
  return next isnt(v2, pg_temp.lot('COL-002'), 'acumulación: el lote vivo se cargó a la misma corrida → nace lote nuevo (evita linaje circular)');

  -- 6) Transferir conservando el folio del destino, con linaje
  perform pg_temp.como(aurelia);
  select transferir(pg_temp.a(), gen_random_uuid(), now(), pg_temp.res('Colector mezcal'), pg_temp.res('Tanque 1'),
                    pg_temp.lot('MEZ-002'), 5, 49.0, 'conservar') into v;
  return next is(v, pg_temp.lot('G-COMPRA-01'), 'transferir: conservar devuelve el lote que ya estaba en el destino');
  return next is(pg_temp.bal('Tanque 1', 'G-COMPRA-01'), 255.000::numeric, 'transferir: el destino suma los litros');
  return next ok(exists (select 1 from lot_lineage where child_lot_id = pg_temp.lot('G-COMPRA-01') and parent_lot_id = pg_temp.lot('MEZ-002')),
                 'transferir: queda el aporte del lote que se unió');

  -- 7) Conciliación de volumen declarado vs. ledger (§5.1)
  perform pg_temp.como(benito);
  select registrar_movimiento_granel(pg_temp.a(), 'b67066dd-621f-4dc7-8f43-02d4a01d4c61', now(),
    pg_temp.con('66a151e2-9a2c-58be-ad4a-b117f1ddb717'), pg_temp.res('Tanque 2'), 10,
    p_lote => pg_temp.lot('G-INI-01'), p_resultado_l => 351.0, p_resultado_abv => 43.0) into v;
  select id into v_op from operations where idempotency_key = 'b67066dd-621f-4dc7-8f43-02d4a01d4c61';
  return next is(pg_temp.bal('Tanque 2', 'G-INI-01'), 351.000::numeric, 'conciliación: el saldo queda en lo declarado');
  return next is((select volume_l from liquid_movements where operation_id = v_op and movement_type = 'conciliacion'),
                 0.800::numeric, 'conciliación: la pata registra exactamente la diferencia');
  return next is((select count(*) from operation_warnings where operation_id = v_op and code = 'diferencia_volumen'), 1::bigint,
                 'conciliación: queda el aviso diferencia_volumen');

  -- 8) Estado y nivel de historia derivados
  execute 'reset role';
  return next is((select status from lots where id = pg_temp.lot('MEZ-001')), 'agotado'::lot_status,
                 'un lote sin saldo en ningún recurso queda agotado');
  return next is((select history from lots where id = pg_temp.lot('G-INI-01')), 'parcial'::history_level,
                 'historia: carga inicial unida a producción con maguey → parcial');
  return next is((select history from lots where id = pg_temp.lot('G-COMPRA-01')), 'parcial'::history_level,
                 'historia: la compra recibió mezcal con historia → parcial');
end $$;

select * from runtests((select nspname from pg_namespace where oid = pg_my_temp_schema())::name, '^test_');


rollback;
