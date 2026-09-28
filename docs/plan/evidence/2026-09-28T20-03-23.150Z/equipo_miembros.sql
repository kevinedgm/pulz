begin;
create or replace view lot_declared_abv with (security_invoker = true) as
select distinct on (x.organization_id, x.lot_id)
       x.organization_id, x.lot_id, x.abv, x.occurred_at, x.recorded_by
from (
  select o.organization_id, o.result_lot_id as lot_id, o.result_abv as abv,
         o.occurred_at, o.recorded_by, o.recorded_at, o.id as operation_id, o.id as source_id
    from operations o where o.result_abv is not null and o.result_lot_id is not null
  union all
  select m.organization_id, m.lot_id, m.abv, o.occurred_at, o.recorded_by,
         o.recorded_at, o.id as operation_id, m.id as source_id
    from liquid_movements m join operations o on o.id = m.operation_id
   where m.abv is not null and m.movement_type in ('entrada', 'corte')
     -- El grado del aporte no reemplaza el resultado declarado para ese
     -- mismo lote/operación (unión: aporte 47 %, resultado 44.9 %).
     and (o.result_lot_id is distinct from m.lot_id or o.result_abv is null)
) x
order by x.organization_id, x.lot_id, x.occurred_at desc,
         x.recorded_at desc, x.operation_id desc, x.source_id desc;
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
-- tomas.h → 'tomas-2026' · dueña B → 'qa-fa755923af2b-prueba-b-2026' · admin → 'pulz-2026'
-- ---------------------------------------------------------------------
insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
                        raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
                        confirmation_token, recovery_token, email_change_token_new, email_change) values
  ('00000000-0000-0000-0000-000000000000', 'db81c303-ac48-4eac-be05-fa59924c9a04', 'authenticated', 'authenticated', 'qa-fa755923af2b-tu@pulz.mx',
   extensions.crypt('pulz-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '8726690b-d18a-43a3-b9df-e1b78a83a605', 'authenticated', 'authenticated', 'qa-fa755923af2b-benito@cuatrovientos.mx',
   extensions.crypt('benito-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', 'fdf59cfc-9459-45a9-bc18-6904d269d368', 'authenticated', 'authenticated', 'qa-fa755923af2b-aurelia@34a5a0c7-39c4-4e1c-a2fa-c85d327946bb.usuarios.pulz.mx',
   extensions.crypt('aurelia-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '7a47dd26-706a-49ca-b69b-0702cb0e0680', 'authenticated', 'authenticated', 'qa-fa755923af2b-tomas.h@34a5a0c7-39c4-4e1c-a2fa-c85d327946bb.usuarios.pulz.mx',
   extensions.crypt('tomas-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '16b6523c-4f18-4ba9-ad93-0969525b36ae', 'authenticated', 'authenticated', 'qa-fa755923af2b-duena@pruebab.mx',
   extensions.crypt('qa-fa755923af2b-prueba-b-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '');

insert into profiles (id, full_name) values
  ('db81c303-ac48-4eac-be05-fa59924c9a04', 'Admin PULZ'),
  ('8726690b-d18a-43a3-b9df-e1b78a83a605', 'Benito Cruz'),
  ('fdf59cfc-9459-45a9-bc18-6904d269d368', 'Aurelia Santiago'),
  ('7a47dd26-706a-49ca-b69b-0702cb0e0680', 'Tomás Hernández'),
  ('16b6523c-4f18-4ba9-ad93-0969525b36ae', 'Dueña Prueba B');

insert into platform_admins (user_id) values ('db81c303-ac48-4eac-be05-fa59924c9a04');

-- Planes (§14, §18 #2 y #3)
-- Fixture: reutiliza plans canónica, sin modificarla.
-- Fixture: reutiliza plan_limits canónica, sin modificarla.
-- Fixture: reutiliza plan_features canónica, sin modificarla.

-- Empresas
insert into organizations (id, name, slug, state, brand_color, logo_path, welcome_message, created_by) values
  ('34a5a0c7-39c4-4e1c-a2fa-c85d327946bb', 'Mezcal Cuatro Vientos', 'qa-fa755923af2b-cuatro-vientos', 'Oaxaca', '#7A3E1D', null, 'Registro de producción del palenque', '8726690b-d18a-43a3-b9df-e1b78a83a605'),
  ('187bf353-d86f-437b-a3e8-68b0653d57de', 'Palenque Prueba B', 'qa-fa755923af2b-prueba-b', 'Oaxaca', '#173F87', null, 'Empresa de prueba', '16b6523c-4f18-4ba9-ad93-0969525b36ae');
insert into organization_slug_history (slug, organization_id, retired_at, retired_by) values
  ('qa-fa755923af2b-mezcal-cuatro-vientos', '34a5a0c7-39c4-4e1c-a2fa-c85d327946bb', '2026-09-02 09:00:00-06', '8726690b-d18a-43a3-b9df-e1b78a83a605');
insert into organization_members (organization_id, user_id, role, status, username, must_change_password) values
  ('34a5a0c7-39c4-4e1c-a2fa-c85d327946bb', '8726690b-d18a-43a3-b9df-e1b78a83a605', 'admin', 'activo', null, false),
  ('34a5a0c7-39c4-4e1c-a2fa-c85d327946bb', 'fdf59cfc-9459-45a9-bc18-6904d269d368', 'productor', 'activo', 'aurelia', false),
  ('34a5a0c7-39c4-4e1c-a2fa-c85d327946bb', '7a47dd26-706a-49ca-b69b-0702cb0e0680', 'operador', 'activo', 'tomas.h', true),
  ('187bf353-d86f-437b-a3e8-68b0653d57de', '16b6523c-4f18-4ba9-ad93-0969525b36ae', 'admin', 'activo', null, false);
insert into member_invitations (id, organization_id, user_id, token_hash, expires_at, used_at, created_by) values
  ('aabb2e0e-22c4-42f9-a3c7-822c342a8096', '34a5a0c7-39c4-4e1c-a2fa-c85d327946bb', '7a47dd26-706a-49ca-b69b-0702cb0e0680', 'qa-fa755923af2b:SIMULADO', '2026-09-05 10:00:00-06', null, '8726690b-d18a-43a3-b9df-e1b78a83a605');
insert into login_throttle (user_id, failed_count, last_failed_at, locked_until) values
  ('7a47dd26-706a-49ca-b69b-0702cb0e0680', 3, '2026-09-03 07:12:00-06', null);
insert into organization_settings (organization_id, record_puntas, measurement_mode, warn_mixed_second_pass, fermentation_expected_days, measurement_reminder_hour, default_folio_decision) values
  ('34a5a0c7-39c4-4e1c-a2fa-c85d327946bb', false, 'minimo', true, 7, 9, 'conservar'),
  ('187bf353-d86f-437b-a3e8-68b0653d57de', false, 'minimo', true, 7, 9, 'conservar');
insert into subscriptions (organization_id, plan_id, status, current_period_end) values
  ('34a5a0c7-39c4-4e1c-a2fa-c85d327946bb', 'edd15bcf-ad82-5684-a2e7-d85db401885b', 'prueba', '2026-10-15 00:00:00-06'),
  ('187bf353-d86f-437b-a3e8-68b0653d57de', 'ee35d6fd-b4d6-56d6-b7b4-61cb81932b21', 'gratis', null);

-- ---------------------------------------------------------------------
-- Plantillas de plataforma (§10.2.1)
-- ---------------------------------------------------------------------
-- Fixture: reutiliza catalog_item_templates canónica, sin modificarla.
-- Fixture: reutiliza movement_concept_templates canónica, sin modificarla.
-- Fixture: reutiliza species_templates canónica, sin modificarla.

select seed_organization_catalogs('34a5a0c7-39c4-4e1c-a2fa-c85d327946bb');
select seed_organization_catalogs('187bf353-d86f-437b-a3e8-68b0653d57de');

-- Lo propio de Cuatro Vientos y lo que oculta (§10.2.4)
insert into catalog_items (id, organization_id, template_id, catalog, name, sort_order, created_by) values
  ('df4c6a46-0d4f-428a-b50d-b7648162ff8f', '34a5a0c7-39c4-4e1c-a2fa-c85d327946bb', null, 'tipo_alambique', 'Refrescadera de cobre', 100, '8726690b-d18a-43a3-b9df-e1b78a83a605');
insert into movement_concepts (id, organization_id, template_id, direction, name, source_lot, creates_lot, asks_result, asks_counterparty, sort_order, created_by) values
  ('ab062a91-2906-4dd3-a193-c868338d3106', '34a5a0c7-39c4-4e1c-a2fa-c85d327946bb', null, 'salida', 'Regalo a cliente', 'no_aplica', false, false, true, 100, '8726690b-d18a-43a3-b9df-e1b78a83a605');
update catalog_items set active = false
 where organization_id = '34a5a0c7-39c4-4e1c-a2fa-c85d327946bb'
   and template_id in ('5c985133-23d9-50fa-a252-6ff6b5b74134', 'b1fce67a-21bf-50a7-9344-fdf29eb5331e');
update movement_concepts set active = false
 where organization_id = '34a5a0c7-39c4-4e1c-a2fa-c85d327946bb'
   and template_id = '8b7f6579-99ef-549e-b427-b1d4d8bea9da';

-- ---------------------------------------------------------------------
-- Ayudas de la semilla (temporales; mueren con la sesión). security definer
-- para que resuelvan ids aunque el rol activo sea 'authenticated'.
-- ---------------------------------------------------------------------
create function pg_temp.seed_a() returns uuid language sql immutable as $$ select '34a5a0c7-39c4-4e1c-a2fa-c85d327946bb'::uuid $$;
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
  ('047dd118-e04d-4cd1-baab-ba126a532c73', pg_temp.seed_a(), 'Loma del Toro', 'Santiago Matatlán', 'Familia Cruz');
insert into suppliers (id, organization_id, name, type_item_id) values
  ('2f940b73-c418-48a6-8af3-f7ef4a8769ff', pg_temp.seed_a(), 'Magueyes Don Pedro', pg_temp.seed_cat('640b537d-bf52-5c4b-b407-a5f4fb7c5800')),
  ('18aebac2-fd9a-4fdc-a6fd-5d5daad4b366', pg_temp.seed_a(), 'Destilados Hermanos Luna', pg_temp.seed_cat('bb234638-3c78-56cd-9f41-2fb38182f181'));
insert into supplies (id, organization_id, name, unit_item_id) values
  ('5a6cfd4b-f395-43d5-a155-ded371f0a7e8', pg_temp.seed_a(), 'Pulque como inóculo', pg_temp.seed_cat('bc6f104d-2841-5b36-b492-76b36becb172'));
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy, liquid_class) values
  ('d731fccb-2883-49f9-8b32-b85a668a1a48', pg_temp.seed_a(), 'horno', 'Horno 1', pg_temp.seed_cat('d53ba2da-cada-5215-804a-ff304d569f97'), 10000, 'kg', 'libre', null),
  ('85303e98-924b-4abf-8e36-31f91db99ef0', pg_temp.seed_a(), 'molino', 'Tahona', pg_temp.seed_cat('60285283-d000-52f0-95da-d2b2e6d70fa1'), null, 'kg', 'libre', null),
  ('abd6a67a-8ca5-4c8d-85e0-fa973556aa41', pg_temp.seed_a(), 'tina', 'Tina 1', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('4a034ba8-0f89-41eb-9dd4-b7658c73c326', pg_temp.seed_a(), 'tina', 'Tina 2', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('262cef9f-1cdd-44d1-b964-0b81c163bd53', pg_temp.seed_a(), 'tina', 'Tina 3', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('fe7a30aa-f7b8-4040-9995-1eb3d08ca0b5', pg_temp.seed_a(), 'alambique', 'Alambique 1', pg_temp.seed_cat('af73010e-53f2-5769-b3b1-6cda154e665e'), 300, 'L', 'estricta', null),
  ('d19b8c6e-7055-4f2e-990c-8662647db229', pg_temp.seed_a(), 'alambique', 'Alambique 2', 'df4c6a46-0d4f-428a-b50d-b7648162ff8f', 250, 'L', 'estricta', null),
  ('3af5f879-18d1-4077-b668-dfed0349d7d3', pg_temp.seed_a(), 'colector', 'Colector mezcal', pg_temp.seed_cat('2cd7e70b-6246-543e-8f67-23743fefdf95'), 60, 'L', 'flexible', 'mezcal'),
  ('aa04f1ff-4223-4af2-a5d7-287da8825c22', pg_temp.seed_a(), 'colector', 'Colector ordinario', pg_temp.seed_cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'ordinario'),
  ('db7d3829-c8a0-4a7c-af20-5f1f01e6dd3f', pg_temp.seed_a(), 'colector', 'Colector colas', pg_temp.seed_cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'colas'),
  ('3c4d906d-1447-452c-98b9-dbf4dae66eed', pg_temp.seed_a(), 'tanque', 'Tanque 1', pg_temp.seed_cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1000, 'L', 'flexible', null),
  ('8b1e29f1-39d4-4bd6-bdac-6b1f82d3caf6', pg_temp.seed_a(), 'tanque', 'Tanque 2', pg_temp.seed_cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1500, 'L', 'flexible', null);

-- Palenque Prueba B: lo mínimo para probar aislamiento
insert into predios (id, organization_id, name, municipality) values
  ('8f0a992e-22ac-40ae-83a6-1a41e85426c2', '187bf353-d86f-437b-a3e8-68b0653d57de', 'Predio B', 'Ejutla');
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy) values
  ('8545a474-18cf-46a6-8b64-1e1d8d9a49fc', '187bf353-d86f-437b-a3e8-68b0653d57de', 'tina', 'Tina B1',
   (select id from catalog_items where organization_id = '187bf353-d86f-437b-a3e8-68b0653d57de' and template_id = 'b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1000, 'L', 'flexible');

-- =====================================================================
-- Cuatro Vientos: la producción, POR RPC, en orden cronológico
-- =====================================================================

-- 2026-09-01 · Benito: lo que ya había en el Tanque 2 (carga inicial)
select pg_temp.seed_como('8726690b-d18a-43a3-b9df-e1b78a83a605');
select registrar_entrada(pg_temp.seed_a(), 'd4101ebf-062a-40b0-9473-7157d6e12219', '2026-09-01 10:15:00-06',
  'granel', pg_temp.seed_res('Tanque 2'), 600, 44.2, 'mezcal', 'carga_inicial',
  p_concepto => pg_temp.seed_con('255e79f1-12b3-5969-8453-e40623275559'),
  p_nota => 'Lo que ya había en el tanque al empezar', p_folio => 'G-INI-01');

-- 2026-09-01 · Aurelia: la Tina 3 ya fermentaba
select pg_temp.seed_como('fdf59cfc-9459-45a9-bc18-6904d269d368');
select registrar_entrada(pg_temp.seed_a(), '22ceba99-3964-486f-8208-471d8b12e811', '2026-09-01 10:40:00-06',
  'fermentado', pg_temp.seed_res('Tina 3'), 1300, null, null, 'carga_inicial',
  p_nota => 'Tina que ya fermentaba', p_folio => 'FER-T3-INI');

-- 2026-09-02 · Aurelia: recepción de maguey
select registrar_recepcion_maguey(pg_temp.seed_a(), '934376c4-8e4c-4f3c-990a-bfeb2f63194d', '2026-09-02 07:30:00-06',
  8000, pg_temp.seed_esp('67a96efd-2c72-528e-8682-d144fe1f802c'), '047dd118-e04d-4cd1-baab-ba126a532c73',
  '2f940b73-c418-48a6-8af3-f7ef4a8769ff', 132, 'Piñas de 8 años, buen tamaño', 'MAG-001');

-- 2026-09-02 · Horneado (la simulación lo abría Tomás; §11.1 lo reserva a
-- admin/productor, así que lo abre Aurelia — docs/DECISIONES.md)
select abrir_horneado(pg_temp.seed_a(), '823fc0b4-8d5b-4ec5-9aff-f866f047dc46', '2026-09-02 12:00:00-06',
  pg_temp.seed_res('Horno 1'), array[pg_temp.seed_lot('MAG-001')], array[8000::numeric], p_folio => 'HOR-001');
-- 2026-09-06 · Aurelia cierra: 6,200 kg de agave cocido
select cerrar_horneado(pg_temp.seed_a(), '518623b3-7255-4779-be0b-15fd90786af4', '2026-09-06 08:00:00-06',
  pg_temp.seed_hor('HOR-001'), 6200, 'Leña de encino', p_folio => 'AC-001');

-- 2026-09-07 · Aurelia: formulación repartida a Tina 1 y Tina 2
select registrar_formulacion(pg_temp.seed_a(), 'bdd80496-caf3-4c11-8ba5-96e154fd657e', '2026-09-07 09:00:00-06',
  pg_temp.seed_res('Tahona'), array[pg_temp.seed_lot('AC-001')], array[6200::numeric], 1900,
  array[pg_temp.seed_res('Tina 1'), pg_temp.seed_res('Tina 2')], array[1400::numeric, 1400::numeric],
  array['5a6cfd4b-f395-43d5-a155-ded371f0a7e8'::uuid], array[20::numeric],
  'Tahona con mula', null, 'F-001', array['FER-T1-001', 'FER-T2-001']);

-- Mediciones diarias (escala de actividad 1–6, §18 #1; la simulación traía 7 y 8)
-- Tina 1
select pg_temp.seed_como('7a47dd26-706a-49ca-b69b-0702cb0e0680');
select registrar_medicion(pg_temp.seed_a(), '166de875-cd24-4e43-9e8d-f45c614430d7', '2026-09-08 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 1, 'minimo', 4,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.5,12.0]::numeric[]);
select pg_temp.seed_como('fdf59cfc-9459-45a9-bc18-6904d269d368');
select registrar_medicion(pg_temp.seed_a(), '988eef77-d2b7-4c2d-bdff-47e26c18c7d7', '2026-09-09 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.0,9.5]::numeric[]);
select pg_temp.seed_como('7a47dd26-706a-49ca-b69b-0702cb0e0680');
select registrar_medicion(pg_temp.seed_a(), 'b6d99197-3617-400b-aa7c-0cb346f99342', '2026-09-10 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.5,6.0]::numeric[]);
select pg_temp.seed_como('fdf59cfc-9459-45a9-bc18-6904d269d368');
select registrar_medicion(pg_temp.seed_a(), 'e566a0b3-d28f-4c33-ab2a-006f477b9b09', '2026-09-11 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 4, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.5,3.5]::numeric[]);
select pg_temp.seed_como('7a47dd26-706a-49ca-b69b-0702cb0e0680');
select registrar_medicion(pg_temp.seed_a(), 'dd0fbc45-1db5-4c6c-89cb-a39aa79f620c', '2026-09-12 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 5, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.0,1.5]::numeric[]);
-- Tina 2
select registrar_medicion(pg_temp.seed_a(), 'ccbcd057-6c51-4e71-abc6-876100f44032', '2026-09-08 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 1, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.0,12.2]::numeric[]);
select registrar_medicion(pg_temp.seed_a(), '4f4c89cc-6e48-4601-b8d5-144219639071', '2026-09-09 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.5,10.1]::numeric[]);
select registrar_medicion(pg_temp.seed_a(), 'ee73dcd3-c92a-410a-8209-32067189157f', '2026-09-10 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.0,7.4]::numeric[]);

-- 2026-09-12 · Aurelia declara lista la Tina 1
select pg_temp.seed_como('fdf59cfc-9459-45a9-bc18-6904d269d368');
select declarar_tina_lista(pg_temp.seed_a(), '9576614c-f29d-4612-b372-a496b9f82442', '2026-09-12 17:00:00-06',
  pg_temp.seed_cyc('Tina 1'), 'Día 5: ya no burbujea, sabor seco');

-- 2026-09-13 · Tomás: dos corridas de 1ª pasada desde la Tina 1
select pg_temp.seed_como('7a47dd26-706a-49ca-b69b-0702cb0e0680');
select abrir_corrida(pg_temp.seed_a(), 'b40025cc-2a61-4d45-be7d-049dc1012fda', '2026-09-13 06:00:00-06',
  pg_temp.seed_res('Alambique 1'), 'primera', array[pg_temp.seed_res('Tina 1')], array[pg_temp.seed_lot('FER-T1-001')], array[290::numeric],
  p_folio => 'DES-001');
select registrar_corte(pg_temp.seed_a(), 'e20f2f6f-1af4-47b9-8996-18318bb7a029', '2026-09-13 08:00:00-06', pg_temp.seed_run('DES-001'), 'mezcal', 8, 51.0, pg_temp.seed_res('Colector mezcal'), p_folio => 'MEZ-001');
select registrar_corte(pg_temp.seed_a(), 'ada0fc11-8ccc-48c8-b079-648283716d7c', '2026-09-13 10:00:00-06', pg_temp.seed_run('DES-001'), 'ordinario', 40, 24.0, pg_temp.seed_res('Colector ordinario'), p_folio => 'ORD-001');
select registrar_corte(pg_temp.seed_a(), 'bc3dc1c0-2ae6-4ed7-a08f-cce230c00145', '2026-09-13 12:00:00-06', pg_temp.seed_run('DES-001'), 'colas', 12, 9.0, pg_temp.seed_res('Colector colas'), p_folio => 'COL-001');
select cerrar_corrida(pg_temp.seed_a(), 'a097c3cf-1264-4947-babc-0f07233c64ca', '2026-09-13 14:00:00-06', pg_temp.seed_run('DES-001'));

select abrir_corrida(pg_temp.seed_a(), 'f8be4030-a6e3-4d0f-894e-7610cb01ca67', '2026-09-13 06:00:00-06',
  pg_temp.seed_res('Alambique 2'), 'primera', array[pg_temp.seed_res('Tina 1')], array[pg_temp.seed_lot('FER-T1-001')], array[240::numeric],
  p_folio => 'DES-002');
select registrar_corte(pg_temp.seed_a(), '66ceebfe-2a4e-454a-9020-13e8e1c575b3', '2026-09-13 08:00:00-06', pg_temp.seed_run('DES-002'), 'mezcal', 6, 50.0, pg_temp.seed_res('Colector mezcal'));
select registrar_corte(pg_temp.seed_a(), '19114c64-e130-4319-8510-2b1de0c6eabc', '2026-09-13 10:00:00-06', pg_temp.seed_run('DES-002'), 'ordinario', 34, 23.0, pg_temp.seed_res('Colector ordinario'));
select registrar_corte(pg_temp.seed_a(), 'ae460862-8c8d-42e6-b141-0cd92e8ca32e', '2026-09-13 12:00:00-06', pg_temp.seed_run('DES-002'), 'colas', 10, 8.0, pg_temp.seed_res('Colector colas'));
select cerrar_corrida(pg_temp.seed_a(), '79637380-6070-45fa-a692-2728589c37b3', '2026-09-13 14:00:00-06', pg_temp.seed_run('DES-002'));

-- 2026-09-15 · Tomás: 2ª pasada con ordinario y colas juntos (aviso + nota)
select abrir_corrida(pg_temp.seed_a(), 'ae572793-7b8b-46e0-b1f9-99e5ddbca729', '2026-09-15 06:00:00-06',
  pg_temp.seed_res('Alambique 1'), 'segunda',
  array[pg_temp.seed_res('Colector ordinario'), pg_temp.seed_res('Colector colas')],
  array[pg_temp.seed_lot('ORD-001'), pg_temp.seed_lot('COL-001')], array[74::numeric, 22::numeric],
  'Había olla libre y poca cola; se juntó con el ordinario', 'DES-003');
select registrar_corte(pg_temp.seed_a(), '37c5a7cd-a5c4-4a4a-aa66-bd5d06c93b22', '2026-09-15 08:00:00-06', pg_temp.seed_run('DES-003'), 'mezcal', 26, 52.5, pg_temp.seed_res('Colector mezcal'));
select registrar_corte(pg_temp.seed_a(), 'b69aa2ae-c511-41c9-90f2-3333ef1059a3', '2026-09-15 10:00:00-06', pg_temp.seed_run('DES-003'), 'colas', 16, 10.0, pg_temp.seed_res('Colector colas'), p_folio => 'COL-002');
select cerrar_corrida(pg_temp.seed_a(), '0ed2698e-9427-4aa8-9f8a-79c14ca725a0', '2026-09-15 14:00:00-06', pg_temp.seed_run('DES-003'));

-- 2026-09-16 · Aurelia: el mezcal del colector pasa a granel con folio nuevo
select pg_temp.seed_como('fdf59cfc-9459-45a9-bc18-6904d269d368');
select transferir(pg_temp.seed_a(), 'b6a6724e-c119-404e-90b1-debb7158e227', '2026-09-16 09:00:00-06',
  pg_temp.seed_res('Colector mezcal'), pg_temp.seed_res('Tanque 1'), pg_temp.seed_lot('MEZ-001'), 40, 51.6, 'renombrar', 'G-2609-01');
-- Agua para bajar grado: 4 L, declara 43.8 L (contracción) y 47.0 %
select registrar_movimiento_granel(pg_temp.seed_a(), '1e2d23b3-dd34-487b-96ef-334143f4f8a1', '2026-09-16 11:00:00-06',
  pg_temp.seed_con('66a151e2-9a2c-58be-ad4a-b117f1ddb717'), pg_temp.seed_res('Tanque 1'), 4,
  p_lote => pg_temp.seed_lot('G-2609-01'), p_resultado_l => 43.8, p_resultado_abv => 47.0);

-- 2026-09-17 · Benito: puntas guardadas (sin lote) al Tanque 2
select pg_temp.seed_como('8726690b-d18a-43a3-b9df-e1b78a83a605');
select registrar_movimiento_granel(pg_temp.seed_a(), 'd6d44c01-5076-42b0-b965-09ae5f05c290', '2026-09-17 10:00:00-06',
  pg_temp.seed_con('f21aaad8-2ef6-556b-be55-64aa94431ab6'), pg_temp.seed_res('Tanque 2'), 2,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_resultado_l => 602, p_resultado_abv => 44.6, p_abv => 68.0,
  p_nota => 'Puntas guardadas de corridas de agosto, sin lote');
-- 2026-09-18 · Benito: unión de G-2609-01 (Tanque 1) con G-INI-01 (Tanque 2), se conserva el folio mayor
select registrar_movimiento_granel(pg_temp.seed_a(), '909dad77-2f6a-49cd-a63f-4cd76b44f62c', '2026-09-18 09:30:00-06',
  pg_temp.seed_con('df427d88-600e-550e-a097-8ffe4f4dd556'), pg_temp.seed_res('Tanque 2'), 43.8,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_lote_origen => pg_temp.seed_lot('G-2609-01'), p_recurso_origen => pg_temp.seed_res('Tanque 1'),
  p_resultado_l => 645.8, p_resultado_abv => 44.9, p_decision => 'conservar', p_nota => 'Se conserva el folio del lote mayor');
-- 2026-09-19 · Benito: compra de granel al Tanque 1
select registrar_movimiento_granel(pg_temp.seed_a(), 'b765051f-fcff-453f-8279-e5369fbbc360', '2026-09-19 12:00:00-06',
  pg_temp.seed_con('688430a9-cd2f-5bae-add2-c59bc543d911'), pg_temp.seed_res('Tanque 1'), 250,
  p_resultado_l => 250, p_resultado_abv => 46.0, p_abv => 46.0, p_folio_nuevo => 'G-COMPRA-01',
  p_contraparte => 'Destilados Hermanos Luna', p_documento => 'Remisión 0452',
  p_proveedor => '18aebac2-fd9a-4fdc-a6fd-5d5daad4b366', p_especie => pg_temp.seed_esp('67a96efd-2c72-528e-8682-d144fe1f802c'),
  p_predio_declarado => 'Sola de Vega');

-- 2026-09-19 · Aurelia: muestra de laboratorio
select pg_temp.seed_como('fdf59cfc-9459-45a9-bc18-6904d269d368');
select registrar_movimiento_granel(pg_temp.seed_a(), '5dc04810-8ae4-4841-a4fa-56930246b3a2', '2026-09-19 13:00:00-06',
  pg_temp.seed_con('2d62ab89-6a11-558c-8b46-5c4d30aa1607'), pg_temp.seed_res('Tanque 2'), 1,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Laboratorio ficticio de Oaxaca', p_documento => 'Análisis 2026-311');

-- 2026-09-20/22 · Benito: autoconsumo, venta, regalo
select pg_temp.seed_como('8726690b-d18a-43a3-b9df-e1b78a83a605');
select registrar_movimiento_granel(pg_temp.seed_a(), 'bda048b6-343a-46eb-8fcb-60ef27060a31', '2026-09-20 13:00:00-06',
  pg_temp.seed_con('fa52f92b-de19-5d0c-972c-beb899bb2ccb'), pg_temp.seed_res('Tanque 2'), 2, p_lote => pg_temp.seed_lot('G-INI-01'));
select registrar_movimiento_granel(pg_temp.seed_a(), '0c4c67b3-e2a3-4583-a211-3d5b05a16186', '2026-09-22 13:00:00-06',
  pg_temp.seed_con('7b0ca7ca-f8ae-5f33-93d5-f0c174664ec1'), pg_temp.seed_res('Tanque 2'), 300,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.', p_documento => 'Remisión 118');
select registrar_movimiento_granel(pg_temp.seed_a(), '4c2c2705-d23f-4d50-bb44-e5244471ec82', '2026-09-22 13:00:00-06',
  'ab062a91-2906-4dd3-a193-c868338d3106', pg_temp.seed_res('Tanque 2'), 1,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.');

reset role;

-- Evidencia de la compra (los adjuntos no son RPC de §12)
insert into attachments (id, organization_id, operation_id, lot_id, kind_item_id, storage_path, caption) values
  ('90e20bcf-1581-4e7c-9175-b4fbae778dae', pg_temp.seed_a(),
   (select id from operations where organization_id = pg_temp.seed_a() and idempotency_key = 'b765051f-fcff-453f-8279-e5369fbbc360'),
   pg_temp.seed_lot('G-COMPRA-01'), pg_temp.seed_cat('0522e23b-3b1d-58be-b50c-8a6ed0627c9f'),
   'evidencias/34a5a0c7-39c4-4e1c-a2fa-c85d327946bb/g-compra-01/remision-0452.jpg', 'Remisión del proveedor');


-- pgTAP · equipo_miembros (0023): solo el administrador activo de la empresa
-- ve a su gente; bloqueo y vigencia del enlace derivados, nunca el token.
--     supabase db query --linked -f supabase/tests/equipo_miembros.test.sql


create function pg_temp.como(u uuid) returns void language plpgsql as $$
begin
  execute 'set local role authenticated';
  execute format('set local request.jwt.claims = %L', json_build_object('sub', u, 'role', 'authenticated')::text);
end $$;

create function pg_temp.test_equipo_miembros() returns setof text language plpgsql as $$
declare a uuid := '34a5a0c7-39c4-4e1c-a2fa-c85d327946bb'; b uuid := '187bf353-d86f-437b-a3e8-68b0653d57de';
begin
  -- operador de A: no
  perform pg_temp.como('7a47dd26-706a-49ca-b69b-0702cb0e0680');
  return next throws_like(format($q$select * from equipo_miembros('%s')$q$, a), 'NO_PERMITIDO:%',
                          'un operador no ve el equipo');
  -- productora de A: no
  perform pg_temp.como('fdf59cfc-9459-45a9-bc18-6904d269d368');
  return next throws_like(format($q$select * from equipo_miembros('%s')$q$, a), 'NO_PERMITIDO:%',
                          'una productora no ve el equipo');
  -- admin de B pidiendo A: no
  perform pg_temp.como('16b6523c-4f18-4ba9-ad93-0969525b36ae');
  return next throws_like(format($q$select * from equipo_miembros('%s')$q$, a), 'NO_PERMITIDO:%',
                          'el admin de otra empresa no ve el equipo de A');
  return next is((select count(*) from equipo_miembros(b)), 1::bigint, 'el admin de B ve a su única persona');

  -- admin de A: sí, con bloqueo y vigencia derivados
  perform pg_temp.como('8726690b-d18a-43a3-b9df-e1b78a83a605');
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
  perform pg_temp.como('8726690b-d18a-43a3-b9df-e1b78a83a605');
  return next is((select count(*) from equipo_miembros(a)), 3::bigint, 'con suscripción vencida el admin sigue viendo el equipo');
  execute 'reset role';
end $$;

select * from runtests((select nspname from pg_namespace where oid = pg_my_temp_schema())::name, '^test_');


rollback;
