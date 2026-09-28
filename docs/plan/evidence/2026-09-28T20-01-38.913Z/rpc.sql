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
-- tomas.h → 'tomas-2026' · dueña B → 'qa-48eeb13039414295-prueba-b-2026' · admin → 'pulz-2026'
-- ---------------------------------------------------------------------
insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
                        raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
                        confirmation_token, recovery_token, email_change_token_new, email_change) values
  ('00000000-0000-0000-0000-000000000000', 'ff811498-7c27-4333-94e9-3bec1a5eaa72', 'authenticated', 'authenticated', 'qa-48eeb13039414295-tu@pulz.mx',
   extensions.crypt('pulz-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', 'f8fe1f62-f1ed-432d-8cb6-17f883ef067d', 'authenticated', 'authenticated', 'qa-48eeb13039414295-benito@cuatrovientos.mx',
   extensions.crypt('benito-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '23298619-f343-4d34-b9cb-a9644a0c0e68', 'authenticated', 'authenticated', 'qa-48eeb13039414295-aurelia@2f07e716-b5ba-4798-b30a-21b104d66566.usuarios.pulz.mx',
   extensions.crypt('aurelia-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '6e7d97fa-36c9-4569-b015-37ef01e3b684', 'authenticated', 'authenticated', 'qa-48eeb13039414295-tomas.h@2f07e716-b5ba-4798-b30a-21b104d66566.usuarios.pulz.mx',
   extensions.crypt('tomas-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', 'ca14e317-29b0-45c8-8a37-44893406f46a', 'authenticated', 'authenticated', 'qa-48eeb13039414295-duena@pruebab.mx',
   extensions.crypt('qa-48eeb13039414295-prueba-b-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '');

insert into profiles (id, full_name) values
  ('ff811498-7c27-4333-94e9-3bec1a5eaa72', 'Admin PULZ'),
  ('f8fe1f62-f1ed-432d-8cb6-17f883ef067d', 'Benito Cruz'),
  ('23298619-f343-4d34-b9cb-a9644a0c0e68', 'Aurelia Santiago'),
  ('6e7d97fa-36c9-4569-b015-37ef01e3b684', 'Tomás Hernández'),
  ('ca14e317-29b0-45c8-8a37-44893406f46a', 'Dueña Prueba B');

insert into platform_admins (user_id) values ('ff811498-7c27-4333-94e9-3bec1a5eaa72');

-- Planes (§14, §18 #2 y #3)
-- Fixture: reutiliza plans canónica, sin modificarla.
-- Fixture: reutiliza plan_limits canónica, sin modificarla.
-- Fixture: reutiliza plan_features canónica, sin modificarla.

-- Empresas
insert into organizations (id, name, slug, state, brand_color, logo_path, welcome_message, created_by) values
  ('2f07e716-b5ba-4798-b30a-21b104d66566', 'Mezcal Cuatro Vientos', 'qa-48eeb13039414295-cuatro-vientos', 'Oaxaca', '#7A3E1D', null, 'Registro de producción del palenque', 'f8fe1f62-f1ed-432d-8cb6-17f883ef067d'),
  ('c22d4e4a-6423-4613-bcef-866815b2d6cf', 'Palenque Prueba B', 'qa-48eeb13039414295-prueba-b', 'Oaxaca', '#173F87', null, 'Empresa de prueba', 'ca14e317-29b0-45c8-8a37-44893406f46a');
insert into organization_slug_history (slug, organization_id, retired_at, retired_by) values
  ('qa-48eeb13039414295-mezcal-cuatro-vientos', '2f07e716-b5ba-4798-b30a-21b104d66566', '2026-09-02 09:00:00-06', 'f8fe1f62-f1ed-432d-8cb6-17f883ef067d');
insert into organization_members (organization_id, user_id, role, status, username, must_change_password) values
  ('2f07e716-b5ba-4798-b30a-21b104d66566', 'f8fe1f62-f1ed-432d-8cb6-17f883ef067d', 'admin', 'activo', null, false),
  ('2f07e716-b5ba-4798-b30a-21b104d66566', '23298619-f343-4d34-b9cb-a9644a0c0e68', 'productor', 'activo', 'aurelia', false),
  ('2f07e716-b5ba-4798-b30a-21b104d66566', '6e7d97fa-36c9-4569-b015-37ef01e3b684', 'operador', 'activo', 'tomas.h', true),
  ('c22d4e4a-6423-4613-bcef-866815b2d6cf', 'ca14e317-29b0-45c8-8a37-44893406f46a', 'admin', 'activo', null, false);
insert into member_invitations (id, organization_id, user_id, token_hash, expires_at, used_at, created_by) values
  ('4c54ca44-f146-4126-ae72-cffd166a3b85', '2f07e716-b5ba-4798-b30a-21b104d66566', '6e7d97fa-36c9-4569-b015-37ef01e3b684', 'qa-48eeb13039414295:SIMULADO', '2026-09-05 10:00:00-06', null, 'f8fe1f62-f1ed-432d-8cb6-17f883ef067d');
insert into login_throttle (user_id, failed_count, last_failed_at, locked_until) values
  ('6e7d97fa-36c9-4569-b015-37ef01e3b684', 3, '2026-09-03 07:12:00-06', null);
insert into organization_settings (organization_id, record_puntas, measurement_mode, warn_mixed_second_pass, fermentation_expected_days, measurement_reminder_hour, default_folio_decision) values
  ('2f07e716-b5ba-4798-b30a-21b104d66566', false, 'minimo', true, 7, 9, 'conservar'),
  ('c22d4e4a-6423-4613-bcef-866815b2d6cf', false, 'minimo', true, 7, 9, 'conservar');
insert into subscriptions (organization_id, plan_id, status, current_period_end) values
  ('2f07e716-b5ba-4798-b30a-21b104d66566', 'edd15bcf-ad82-5684-a2e7-d85db401885b', 'prueba', '2026-10-15 00:00:00-06'),
  ('c22d4e4a-6423-4613-bcef-866815b2d6cf', 'ee35d6fd-b4d6-56d6-b7b4-61cb81932b21', 'gratis', null);

-- ---------------------------------------------------------------------
-- Plantillas de plataforma (§10.2.1)
-- ---------------------------------------------------------------------
-- Fixture: reutiliza catalog_item_templates canónica, sin modificarla.
-- Fixture: reutiliza movement_concept_templates canónica, sin modificarla.
-- Fixture: reutiliza species_templates canónica, sin modificarla.

select seed_organization_catalogs('2f07e716-b5ba-4798-b30a-21b104d66566');
select seed_organization_catalogs('c22d4e4a-6423-4613-bcef-866815b2d6cf');

-- Lo propio de Cuatro Vientos y lo que oculta (§10.2.4)
insert into catalog_items (id, organization_id, template_id, catalog, name, sort_order, created_by) values
  ('bb495e14-fecf-4d86-947d-aeaabbfb10a4', '2f07e716-b5ba-4798-b30a-21b104d66566', null, 'tipo_alambique', 'Refrescadera de cobre', 100, 'f8fe1f62-f1ed-432d-8cb6-17f883ef067d');
insert into movement_concepts (id, organization_id, template_id, direction, name, source_lot, creates_lot, asks_result, asks_counterparty, sort_order, created_by) values
  ('e72a0164-5617-4ceb-9fe8-f8e703e2e5c4', '2f07e716-b5ba-4798-b30a-21b104d66566', null, 'salida', 'Regalo a cliente', 'no_aplica', false, false, true, 100, 'f8fe1f62-f1ed-432d-8cb6-17f883ef067d');
update catalog_items set active = false
 where organization_id = '2f07e716-b5ba-4798-b30a-21b104d66566'
   and template_id in ('5c985133-23d9-50fa-a252-6ff6b5b74134', 'b1fce67a-21bf-50a7-9344-fdf29eb5331e');
update movement_concepts set active = false
 where organization_id = '2f07e716-b5ba-4798-b30a-21b104d66566'
   and template_id = '8b7f6579-99ef-549e-b427-b1d4d8bea9da';

-- ---------------------------------------------------------------------
-- Ayudas de la semilla (temporales; mueren con la sesión). security definer
-- para que resuelvan ids aunque el rol activo sea 'authenticated'.
-- ---------------------------------------------------------------------
create function pg_temp.seed_a() returns uuid language sql immutable as $$ select '2f07e716-b5ba-4798-b30a-21b104d66566'::uuid $$;
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
  ('4466f529-70db-4f3b-8edc-8a02e8ddf207', pg_temp.seed_a(), 'Loma del Toro', 'Santiago Matatlán', 'Familia Cruz');
insert into suppliers (id, organization_id, name, type_item_id) values
  ('c60b1660-cdba-4b09-a4ec-a1486fdabd1b', pg_temp.seed_a(), 'Magueyes Don Pedro', pg_temp.seed_cat('640b537d-bf52-5c4b-b407-a5f4fb7c5800')),
  ('b7540523-f36e-4007-87fe-07688d209783', pg_temp.seed_a(), 'Destilados Hermanos Luna', pg_temp.seed_cat('bb234638-3c78-56cd-9f41-2fb38182f181'));
insert into supplies (id, organization_id, name, unit_item_id) values
  ('9c3a30e7-8847-40ee-89e7-c3ae82f4f213', pg_temp.seed_a(), 'Pulque como inóculo', pg_temp.seed_cat('bc6f104d-2841-5b36-b492-76b36becb172'));
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy, liquid_class) values
  ('648d0287-1b20-4c94-97f4-47581e20e7cb', pg_temp.seed_a(), 'horno', 'Horno 1', pg_temp.seed_cat('d53ba2da-cada-5215-804a-ff304d569f97'), 10000, 'kg', 'libre', null),
  ('a75f5861-6e4d-41b3-a78b-4509554400b4', pg_temp.seed_a(), 'molino', 'Tahona', pg_temp.seed_cat('60285283-d000-52f0-95da-d2b2e6d70fa1'), null, 'kg', 'libre', null),
  ('078ba201-27cf-4f65-b6a1-7cbf7e8e8122', pg_temp.seed_a(), 'tina', 'Tina 1', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('067ef6df-b450-49f8-941d-38774bd193eb', pg_temp.seed_a(), 'tina', 'Tina 2', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('13700159-1d9e-4dca-be0f-d58e8f9b2ffd', pg_temp.seed_a(), 'tina', 'Tina 3', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('c256ea0b-e253-4499-a9a8-4859df7b1883', pg_temp.seed_a(), 'alambique', 'Alambique 1', pg_temp.seed_cat('af73010e-53f2-5769-b3b1-6cda154e665e'), 300, 'L', 'estricta', null),
  ('22914672-8c13-44bd-aaf6-ce18f380ad2f', pg_temp.seed_a(), 'alambique', 'Alambique 2', 'bb495e14-fecf-4d86-947d-aeaabbfb10a4', 250, 'L', 'estricta', null),
  ('db6e694d-3bd6-4236-a9ca-fd2a3220b3fa', pg_temp.seed_a(), 'colector', 'Colector mezcal', pg_temp.seed_cat('2cd7e70b-6246-543e-8f67-23743fefdf95'), 60, 'L', 'flexible', 'mezcal'),
  ('8ceb1b9c-1e82-4f47-beb9-ad3000f9f03e', pg_temp.seed_a(), 'colector', 'Colector ordinario', pg_temp.seed_cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'ordinario'),
  ('7183f655-0740-430b-9514-7f0e9697eef7', pg_temp.seed_a(), 'colector', 'Colector colas', pg_temp.seed_cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'colas'),
  ('a5536964-bb54-4443-80e6-b1e037a73c1e', pg_temp.seed_a(), 'tanque', 'Tanque 1', pg_temp.seed_cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1000, 'L', 'flexible', null),
  ('6df0e091-d6f8-4a5a-8897-bd9f77cd3f90', pg_temp.seed_a(), 'tanque', 'Tanque 2', pg_temp.seed_cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1500, 'L', 'flexible', null);

-- Palenque Prueba B: lo mínimo para probar aislamiento
insert into predios (id, organization_id, name, municipality) values
  ('c3616aaa-cebb-4437-b7d4-bb68f8c069ce', 'c22d4e4a-6423-4613-bcef-866815b2d6cf', 'Predio B', 'Ejutla');
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy) values
  ('de309b3a-c9d7-4126-bd18-305844f645c0', 'c22d4e4a-6423-4613-bcef-866815b2d6cf', 'tina', 'Tina B1',
   (select id from catalog_items where organization_id = 'c22d4e4a-6423-4613-bcef-866815b2d6cf' and template_id = 'b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1000, 'L', 'flexible');

-- =====================================================================
-- Cuatro Vientos: la producción, POR RPC, en orden cronológico
-- =====================================================================

-- 2026-09-01 · Benito: lo que ya había en el Tanque 2 (carga inicial)
select pg_temp.seed_como('f8fe1f62-f1ed-432d-8cb6-17f883ef067d');
select registrar_entrada(pg_temp.seed_a(), '47787ba9-61b8-40f6-b3ed-08bb3aee90eb', '2026-09-01 10:15:00-06',
  'granel', pg_temp.seed_res('Tanque 2'), 600, 44.2, 'mezcal', 'carga_inicial',
  p_concepto => pg_temp.seed_con('255e79f1-12b3-5969-8453-e40623275559'),
  p_nota => 'Lo que ya había en el tanque al empezar', p_folio => 'G-INI-01');

-- 2026-09-01 · Aurelia: la Tina 3 ya fermentaba
select pg_temp.seed_como('23298619-f343-4d34-b9cb-a9644a0c0e68');
select registrar_entrada(pg_temp.seed_a(), '53ec4fbc-c1ae-4ed8-91e5-5c80ba9d8fc2', '2026-09-01 10:40:00-06',
  'fermentado', pg_temp.seed_res('Tina 3'), 1300, null, null, 'carga_inicial',
  p_nota => 'Tina que ya fermentaba', p_folio => 'FER-T3-INI');

-- 2026-09-02 · Aurelia: recepción de maguey
select registrar_recepcion_maguey(pg_temp.seed_a(), '9bb57695-42c9-4aaa-b3f0-9c7ee7e32b60', '2026-09-02 07:30:00-06',
  8000, pg_temp.seed_esp('67a96efd-2c72-528e-8682-d144fe1f802c'), '4466f529-70db-4f3b-8edc-8a02e8ddf207',
  'c60b1660-cdba-4b09-a4ec-a1486fdabd1b', 132, 'Piñas de 8 años, buen tamaño', 'MAG-001');

-- 2026-09-02 · Horneado (la simulación lo abría Tomás; §11.1 lo reserva a
-- admin/productor, así que lo abre Aurelia — docs/DECISIONES.md)
select abrir_horneado(pg_temp.seed_a(), '726a31d0-51f2-43ad-8a46-887ae73d12df', '2026-09-02 12:00:00-06',
  pg_temp.seed_res('Horno 1'), array[pg_temp.seed_lot('MAG-001')], array[8000::numeric], p_folio => 'HOR-001');
-- 2026-09-06 · Aurelia cierra: 6,200 kg de agave cocido
select cerrar_horneado(pg_temp.seed_a(), '7422732b-d4df-4025-97f1-5ec15d1819c3', '2026-09-06 08:00:00-06',
  pg_temp.seed_hor('HOR-001'), 6200, 'Leña de encino', p_folio => 'AC-001');

-- 2026-09-07 · Aurelia: formulación repartida a Tina 1 y Tina 2
select registrar_formulacion(pg_temp.seed_a(), 'bcf6d725-ad49-48d4-b074-4dd5caea62e3', '2026-09-07 09:00:00-06',
  pg_temp.seed_res('Tahona'), array[pg_temp.seed_lot('AC-001')], array[6200::numeric], 1900,
  array[pg_temp.seed_res('Tina 1'), pg_temp.seed_res('Tina 2')], array[1400::numeric, 1400::numeric],
  array['9c3a30e7-8847-40ee-89e7-c3ae82f4f213'::uuid], array[20::numeric],
  'Tahona con mula', null, 'F-001', array['FER-T1-001', 'FER-T2-001']);

-- Mediciones diarias (escala de actividad 1–6, §18 #1; la simulación traía 7 y 8)
-- Tina 1
select pg_temp.seed_como('6e7d97fa-36c9-4569-b015-37ef01e3b684');
select registrar_medicion(pg_temp.seed_a(), 'daf8b78a-5dc2-4008-ba53-ed6d7b35df11', '2026-09-08 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 1, 'minimo', 4,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.5,12.0]::numeric[]);
select pg_temp.seed_como('23298619-f343-4d34-b9cb-a9644a0c0e68');
select registrar_medicion(pg_temp.seed_a(), '6886910c-fab6-4569-839f-ba8dd8300d49', '2026-09-09 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.0,9.5]::numeric[]);
select pg_temp.seed_como('6e7d97fa-36c9-4569-b015-37ef01e3b684');
select registrar_medicion(pg_temp.seed_a(), '32415a0f-f69d-4b35-89df-2e590d71fbcb', '2026-09-10 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.5,6.0]::numeric[]);
select pg_temp.seed_como('23298619-f343-4d34-b9cb-a9644a0c0e68');
select registrar_medicion(pg_temp.seed_a(), 'f9bc8638-d6a8-434e-b8ea-c43ca9c92023', '2026-09-11 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 4, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.5,3.5]::numeric[]);
select pg_temp.seed_como('6e7d97fa-36c9-4569-b015-37ef01e3b684');
select registrar_medicion(pg_temp.seed_a(), 'a8ec3839-dac5-4995-a196-93c38b85868f', '2026-09-12 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 5, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.0,1.5]::numeric[]);
-- Tina 2
select registrar_medicion(pg_temp.seed_a(), 'e33209c8-56de-467e-a6e6-747e27ce306e', '2026-09-08 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 1, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.0,12.2]::numeric[]);
select registrar_medicion(pg_temp.seed_a(), '5e516559-e323-4406-80cd-4b075820e8b7', '2026-09-09 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.5,10.1]::numeric[]);
select registrar_medicion(pg_temp.seed_a(), '5caa6f18-e484-4833-baeb-91c329308ff6', '2026-09-10 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.0,7.4]::numeric[]);

-- 2026-09-12 · Aurelia declara lista la Tina 1
select pg_temp.seed_como('23298619-f343-4d34-b9cb-a9644a0c0e68');
select declarar_tina_lista(pg_temp.seed_a(), '84e1b83f-1d3f-4c96-be46-78409a76e832', '2026-09-12 17:00:00-06',
  pg_temp.seed_cyc('Tina 1'), 'Día 5: ya no burbujea, sabor seco');

-- 2026-09-13 · Tomás: dos corridas de 1ª pasada desde la Tina 1
select pg_temp.seed_como('6e7d97fa-36c9-4569-b015-37ef01e3b684');
select abrir_corrida(pg_temp.seed_a(), 'eb75f55d-f0fa-4440-8626-70a726bff0aa', '2026-09-13 06:00:00-06',
  pg_temp.seed_res('Alambique 1'), 'primera', array[pg_temp.seed_res('Tina 1')], array[pg_temp.seed_lot('FER-T1-001')], array[290::numeric],
  p_folio => 'DES-001');
select registrar_corte(pg_temp.seed_a(), '7f3d1431-f172-4c7b-aa6a-ceeb7206c24b', '2026-09-13 08:00:00-06', pg_temp.seed_run('DES-001'), 'mezcal', 8, 51.0, pg_temp.seed_res('Colector mezcal'), p_folio => 'MEZ-001');
select registrar_corte(pg_temp.seed_a(), '647fda34-2fee-4b9a-be9b-1c8f392f0a22', '2026-09-13 10:00:00-06', pg_temp.seed_run('DES-001'), 'ordinario', 40, 24.0, pg_temp.seed_res('Colector ordinario'), p_folio => 'ORD-001');
select registrar_corte(pg_temp.seed_a(), 'ad6d096c-cf36-4785-979e-fb989ed0e3e5', '2026-09-13 12:00:00-06', pg_temp.seed_run('DES-001'), 'colas', 12, 9.0, pg_temp.seed_res('Colector colas'), p_folio => 'COL-001');
select cerrar_corrida(pg_temp.seed_a(), '0617da85-bbd6-4553-9f53-d07ada2a12f4', '2026-09-13 14:00:00-06', pg_temp.seed_run('DES-001'));

select abrir_corrida(pg_temp.seed_a(), '8fd66516-dcf4-45aa-b971-c44734f90ccb', '2026-09-13 06:00:00-06',
  pg_temp.seed_res('Alambique 2'), 'primera', array[pg_temp.seed_res('Tina 1')], array[pg_temp.seed_lot('FER-T1-001')], array[240::numeric],
  p_folio => 'DES-002');
select registrar_corte(pg_temp.seed_a(), 'fda3ad66-7f4c-4bc9-9cc5-c014cad180a7', '2026-09-13 08:00:00-06', pg_temp.seed_run('DES-002'), 'mezcal', 6, 50.0, pg_temp.seed_res('Colector mezcal'));
select registrar_corte(pg_temp.seed_a(), '72b6fa32-a1c4-455a-90c7-9b556003aaf5', '2026-09-13 10:00:00-06', pg_temp.seed_run('DES-002'), 'ordinario', 34, 23.0, pg_temp.seed_res('Colector ordinario'));
select registrar_corte(pg_temp.seed_a(), '51940ce7-930a-470e-bab0-3b51b514a7ba', '2026-09-13 12:00:00-06', pg_temp.seed_run('DES-002'), 'colas', 10, 8.0, pg_temp.seed_res('Colector colas'));
select cerrar_corrida(pg_temp.seed_a(), 'c733134b-849b-474c-8c68-55f396c05f9f', '2026-09-13 14:00:00-06', pg_temp.seed_run('DES-002'));

-- 2026-09-15 · Tomás: 2ª pasada con ordinario y colas juntos (aviso + nota)
select abrir_corrida(pg_temp.seed_a(), '8860add5-9a58-488f-8157-5343fdacafc6', '2026-09-15 06:00:00-06',
  pg_temp.seed_res('Alambique 1'), 'segunda',
  array[pg_temp.seed_res('Colector ordinario'), pg_temp.seed_res('Colector colas')],
  array[pg_temp.seed_lot('ORD-001'), pg_temp.seed_lot('COL-001')], array[74::numeric, 22::numeric],
  'Había olla libre y poca cola; se juntó con el ordinario', 'DES-003');
select registrar_corte(pg_temp.seed_a(), '1e1b8fce-b1f6-42f3-87c8-48df9af0e9f3', '2026-09-15 08:00:00-06', pg_temp.seed_run('DES-003'), 'mezcal', 26, 52.5, pg_temp.seed_res('Colector mezcal'));
select registrar_corte(pg_temp.seed_a(), '43450a90-1521-4186-a775-8dfe03df6fd9', '2026-09-15 10:00:00-06', pg_temp.seed_run('DES-003'), 'colas', 16, 10.0, pg_temp.seed_res('Colector colas'), p_folio => 'COL-002');
select cerrar_corrida(pg_temp.seed_a(), '525f5b0c-af45-45a5-a87b-67f3e45dfd95', '2026-09-15 14:00:00-06', pg_temp.seed_run('DES-003'));

-- 2026-09-16 · Aurelia: el mezcal del colector pasa a granel con folio nuevo
select pg_temp.seed_como('23298619-f343-4d34-b9cb-a9644a0c0e68');
select transferir(pg_temp.seed_a(), '6c8a6146-0762-4b30-a282-48da8fa21683', '2026-09-16 09:00:00-06',
  pg_temp.seed_res('Colector mezcal'), pg_temp.seed_res('Tanque 1'), pg_temp.seed_lot('MEZ-001'), 40, 51.6, 'renombrar', 'G-2609-01');
-- Agua para bajar grado: 4 L, declara 43.8 L (contracción) y 47.0 %
select registrar_movimiento_granel(pg_temp.seed_a(), 'ddd16766-792e-4bbe-b189-2ac938ab5611', '2026-09-16 11:00:00-06',
  pg_temp.seed_con('66a151e2-9a2c-58be-ad4a-b117f1ddb717'), pg_temp.seed_res('Tanque 1'), 4,
  p_lote => pg_temp.seed_lot('G-2609-01'), p_resultado_l => 43.8, p_resultado_abv => 47.0);

-- 2026-09-17 · Benito: puntas guardadas (sin lote) al Tanque 2
select pg_temp.seed_como('f8fe1f62-f1ed-432d-8cb6-17f883ef067d');
select registrar_movimiento_granel(pg_temp.seed_a(), 'b8941af1-e241-4740-a1ee-c0bada583406', '2026-09-17 10:00:00-06',
  pg_temp.seed_con('f21aaad8-2ef6-556b-be55-64aa94431ab6'), pg_temp.seed_res('Tanque 2'), 2,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_resultado_l => 602, p_resultado_abv => 44.6, p_abv => 68.0,
  p_nota => 'Puntas guardadas de corridas de agosto, sin lote');
-- 2026-09-18 · Benito: unión de G-2609-01 (Tanque 1) con G-INI-01 (Tanque 2), se conserva el folio mayor
select registrar_movimiento_granel(pg_temp.seed_a(), '82d029fa-08de-4e5e-a0d3-397da391d906', '2026-09-18 09:30:00-06',
  pg_temp.seed_con('df427d88-600e-550e-a097-8ffe4f4dd556'), pg_temp.seed_res('Tanque 2'), 43.8,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_lote_origen => pg_temp.seed_lot('G-2609-01'), p_recurso_origen => pg_temp.seed_res('Tanque 1'),
  p_resultado_l => 645.8, p_resultado_abv => 44.9, p_decision => 'conservar', p_nota => 'Se conserva el folio del lote mayor');
-- 2026-09-19 · Benito: compra de granel al Tanque 1
select registrar_movimiento_granel(pg_temp.seed_a(), 'f581cf45-ea3b-4e97-8a40-7d056ce5e209', '2026-09-19 12:00:00-06',
  pg_temp.seed_con('688430a9-cd2f-5bae-add2-c59bc543d911'), pg_temp.seed_res('Tanque 1'), 250,
  p_resultado_l => 250, p_resultado_abv => 46.0, p_abv => 46.0, p_folio_nuevo => 'G-COMPRA-01',
  p_contraparte => 'Destilados Hermanos Luna', p_documento => 'Remisión 0452',
  p_proveedor => 'b7540523-f36e-4007-87fe-07688d209783', p_especie => pg_temp.seed_esp('67a96efd-2c72-528e-8682-d144fe1f802c'),
  p_predio_declarado => 'Sola de Vega');

-- 2026-09-19 · Aurelia: muestra de laboratorio
select pg_temp.seed_como('23298619-f343-4d34-b9cb-a9644a0c0e68');
select registrar_movimiento_granel(pg_temp.seed_a(), '31b63da5-7119-4600-8bca-b77b2b70994d', '2026-09-19 13:00:00-06',
  pg_temp.seed_con('2d62ab89-6a11-558c-8b46-5c4d30aa1607'), pg_temp.seed_res('Tanque 2'), 1,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Laboratorio ficticio de Oaxaca', p_documento => 'Análisis 2026-311');

-- 2026-09-20/22 · Benito: autoconsumo, venta, regalo
select pg_temp.seed_como('f8fe1f62-f1ed-432d-8cb6-17f883ef067d');
select registrar_movimiento_granel(pg_temp.seed_a(), '7e35a2c1-7e16-4cd0-b31a-47826f6f327f', '2026-09-20 13:00:00-06',
  pg_temp.seed_con('fa52f92b-de19-5d0c-972c-beb899bb2ccb'), pg_temp.seed_res('Tanque 2'), 2, p_lote => pg_temp.seed_lot('G-INI-01'));
select registrar_movimiento_granel(pg_temp.seed_a(), '4c554093-230d-4c13-a879-db4cafda8e6b', '2026-09-22 13:00:00-06',
  pg_temp.seed_con('7b0ca7ca-f8ae-5f33-93d5-f0c174664ec1'), pg_temp.seed_res('Tanque 2'), 300,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.', p_documento => 'Remisión 118');
select registrar_movimiento_granel(pg_temp.seed_a(), '602d4b11-15ec-45f2-8a32-922bfdf818ed', '2026-09-22 13:00:00-06',
  'e72a0164-5617-4ceb-9fe8-f8e703e2e5c4', pg_temp.seed_res('Tanque 2'), 1,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.');

reset role;

-- Evidencia de la compra (los adjuntos no son RPC de §12)
insert into attachments (id, organization_id, operation_id, lot_id, kind_item_id, storage_path, caption) values
  ('cefb861a-c2ea-4580-806b-7f78af03cbed', pg_temp.seed_a(),
   (select id from operations where organization_id = pg_temp.seed_a() and idempotency_key = 'f581cf45-ea3b-4e97-8a40-7d056ce5e209'),
   pg_temp.seed_lot('G-COMPRA-01'), pg_temp.seed_cat('0522e23b-3b1d-58be-b50c-8a6ed0627c9f'),
   'evidencias/2f07e716-b5ba-4798-b30a-21b104d66566/g-compra-01/remision-0452.jpg', 'Remisión del proveedor');


-- pgTAP · Comandos (RPC) — PULZ_MAESTRO.md §12, §16 Fase 2.
-- Se corre igual que el de aislamiento (sin Docker):
--     supabase db query --linked -f supabase/tests/rpc.test.sql
-- Todo dentro de una transacción que termina en rollback.
--
-- Parte del estado que deja seed.sql (construido por RPC): comprueba los
-- saldos de §15.1, la idempotencia, cada regla dura, los avisos blandos, la
-- regla de acumulación de colectores, transferir y la conciliación.


create function pg_temp.a() returns uuid language sql immutable as $$ select '2f07e716-b5ba-4798-b30a-21b104d66566'::uuid $$;
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
  benito  uuid := 'f8fe1f62-f1ed-432d-8cb6-17f883ef067d';
  aurelia uuid := '23298619-f343-4d34-b9cb-a9644a0c0e68';
  tomas   uuid := '6e7d97fa-36c9-4569-b015-37ef01e3b684';
  duena_b uuid := 'ca14e317-29b0-45c8-8a37-44893406f46a';
  n0 bigint; v uuid; v2 uuid; v_op uuid;
begin
  -- 1) La simulación construida por RPC da exactamente §15.1
  return next results_eq(
    $q$select r.code, l.folio, b.volume_l::numeric(12,3)
         from resource_lot_balances b
         join resources r on r.id = b.resource_id
         join lots l on l.id = b.lot_id
        where b.organization_id = '2f07e716-b5ba-4798-b30a-21b104d66566'
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
  select registrar_movimiento_granel(pg_temp.a(), '7e35a2c1-7e16-4cd0-b31a-47826f6f327f', '2026-09-20 13:00:00-06',
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
    format($q$select registrar_medicion('%s', 'e55ee8f6-9250-4652-a477-39fb82e73b5d', now(), '%s', 1::smallint, 'minimo', 3::smallint,
              array['brix']::reading_variable[], array['unica']::reading_zone[], array[1]::smallint[], array[20.0]::numeric[],
              'Brix alto, agua dura')$q$,
           pg_temp.a(), pg_temp.cyc('Tina 2')),
    'blanda: con nota, la medición se registra');
  return next is((select count(*) from operation_warnings w join operations o on o.id = w.operation_id
                   where o.idempotency_key = 'e55ee8f6-9250-4652-a477-39fb82e73b5d' and w.code = 'brix_fuera_rango'), 1::bigint,
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
  select registrar_movimiento_granel(pg_temp.a(), '94bc1fdb-4ef8-42b7-8a36-894f5d23a2fd', now(),
    pg_temp.con('66a151e2-9a2c-58be-ad4a-b117f1ddb717'), pg_temp.res('Tanque 2'), 10,
    p_lote => pg_temp.lot('G-INI-01'), p_resultado_l => 351.0, p_resultado_abv => 43.0) into v;
  select id into v_op from operations where idempotency_key = '94bc1fdb-4ef8-42b7-8a36-894f5d23a2fd';
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
