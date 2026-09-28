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
-- tomas.h → 'tomas-2026' · dueña B → 'qa-2a405c188267-prueba-b-2026' · admin → 'pulz-2026'
-- ---------------------------------------------------------------------
insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
                        raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
                        confirmation_token, recovery_token, email_change_token_new, email_change) values
  ('00000000-0000-0000-0000-000000000000', '3c950240-4392-43e3-b20c-1639e1bb0de8', 'authenticated', 'authenticated', 'qa-2a405c188267-tu@pulz.mx',
   extensions.crypt('pulz-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '2f6e2305-b5a5-4cda-bc25-f74f9145ca72', 'authenticated', 'authenticated', 'qa-2a405c188267-benito@cuatrovientos.mx',
   extensions.crypt('benito-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', 'd0477962-ae6d-40f1-9528-336cb2ddda85', 'authenticated', 'authenticated', 'qa-2a405c188267-aurelia@ab657e37-17a7-4b03-8c0f-2260aed400a5.usuarios.pulz.mx',
   extensions.crypt('aurelia-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '4f16c8c6-e2c0-4e78-8c79-0cf3901c8c2f', 'authenticated', 'authenticated', 'qa-2a405c188267-tomas.h@ab657e37-17a7-4b03-8c0f-2260aed400a5.usuarios.pulz.mx',
   extensions.crypt('tomas-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '0fbd45fd-a72c-4d53-b60c-e3fe76fa4812', 'authenticated', 'authenticated', 'qa-2a405c188267-duena@pruebab.mx',
   extensions.crypt('qa-2a405c188267-prueba-b-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '');

insert into profiles (id, full_name) values
  ('3c950240-4392-43e3-b20c-1639e1bb0de8', 'Admin PULZ'),
  ('2f6e2305-b5a5-4cda-bc25-f74f9145ca72', 'Benito Cruz'),
  ('d0477962-ae6d-40f1-9528-336cb2ddda85', 'Aurelia Santiago'),
  ('4f16c8c6-e2c0-4e78-8c79-0cf3901c8c2f', 'Tomás Hernández'),
  ('0fbd45fd-a72c-4d53-b60c-e3fe76fa4812', 'Dueña Prueba B');

insert into platform_admins (user_id) values ('3c950240-4392-43e3-b20c-1639e1bb0de8');

-- Planes (§14, §18 #2 y #3)
-- Fixture: reutiliza plans canónica, sin modificarla.
-- Fixture: reutiliza plan_limits canónica, sin modificarla.
-- Fixture: reutiliza plan_features canónica, sin modificarla.

-- Empresas
insert into organizations (id, name, slug, state, brand_color, logo_path, welcome_message, created_by) values
  ('ab657e37-17a7-4b03-8c0f-2260aed400a5', 'Mezcal Cuatro Vientos', 'qa-2a405c188267-cuatro-vientos', 'Oaxaca', '#7A3E1D', null, 'Registro de producción del palenque', '2f6e2305-b5a5-4cda-bc25-f74f9145ca72'),
  ('86145cbd-63d1-4c31-afc5-2a647c5723e2', 'Palenque Prueba B', 'qa-2a405c188267-prueba-b', 'Oaxaca', '#173F87', null, 'Empresa de prueba', '0fbd45fd-a72c-4d53-b60c-e3fe76fa4812');
insert into organization_slug_history (slug, organization_id, retired_at, retired_by) values
  ('qa-2a405c188267-mezcal-cuatro-vientos', 'ab657e37-17a7-4b03-8c0f-2260aed400a5', '2026-09-02 09:00:00-06', '2f6e2305-b5a5-4cda-bc25-f74f9145ca72');
insert into organization_members (organization_id, user_id, role, status, username, must_change_password) values
  ('ab657e37-17a7-4b03-8c0f-2260aed400a5', '2f6e2305-b5a5-4cda-bc25-f74f9145ca72', 'admin', 'activo', null, false),
  ('ab657e37-17a7-4b03-8c0f-2260aed400a5', 'd0477962-ae6d-40f1-9528-336cb2ddda85', 'productor', 'activo', 'aurelia', false),
  ('ab657e37-17a7-4b03-8c0f-2260aed400a5', '4f16c8c6-e2c0-4e78-8c79-0cf3901c8c2f', 'operador', 'activo', 'tomas.h', true),
  ('86145cbd-63d1-4c31-afc5-2a647c5723e2', '0fbd45fd-a72c-4d53-b60c-e3fe76fa4812', 'admin', 'activo', null, false);
insert into member_invitations (id, organization_id, user_id, token_hash, expires_at, used_at, created_by) values
  ('68ef8e15-6c46-41f9-b9e6-aa3dbbbca3bb', 'ab657e37-17a7-4b03-8c0f-2260aed400a5', '4f16c8c6-e2c0-4e78-8c79-0cf3901c8c2f', 'qa-2a405c188267:SIMULADO', '2026-09-05 10:00:00-06', null, '2f6e2305-b5a5-4cda-bc25-f74f9145ca72');
insert into login_throttle (user_id, failed_count, last_failed_at, locked_until) values
  ('4f16c8c6-e2c0-4e78-8c79-0cf3901c8c2f', 3, '2026-09-03 07:12:00-06', null);
insert into organization_settings (organization_id, record_puntas, measurement_mode, warn_mixed_second_pass, fermentation_expected_days, measurement_reminder_hour, default_folio_decision) values
  ('ab657e37-17a7-4b03-8c0f-2260aed400a5', false, 'minimo', true, 7, 9, 'conservar'),
  ('86145cbd-63d1-4c31-afc5-2a647c5723e2', false, 'minimo', true, 7, 9, 'conservar');
insert into subscriptions (organization_id, plan_id, status, current_period_end) values
  ('ab657e37-17a7-4b03-8c0f-2260aed400a5', 'edd15bcf-ad82-5684-a2e7-d85db401885b', 'prueba', '2026-10-15 00:00:00-06'),
  ('86145cbd-63d1-4c31-afc5-2a647c5723e2', 'ee35d6fd-b4d6-56d6-b7b4-61cb81932b21', 'gratis', null);

-- ---------------------------------------------------------------------
-- Plantillas de plataforma (§10.2.1)
-- ---------------------------------------------------------------------
-- Fixture: reutiliza catalog_item_templates canónica, sin modificarla.
-- Fixture: reutiliza movement_concept_templates canónica, sin modificarla.
-- Fixture: reutiliza species_templates canónica, sin modificarla.

select seed_organization_catalogs('ab657e37-17a7-4b03-8c0f-2260aed400a5');
select seed_organization_catalogs('86145cbd-63d1-4c31-afc5-2a647c5723e2');

-- Lo propio de Cuatro Vientos y lo que oculta (§10.2.4)
insert into catalog_items (id, organization_id, template_id, catalog, name, sort_order, created_by) values
  ('fe81f5bd-d01c-4a8d-a724-25b4adcce775', 'ab657e37-17a7-4b03-8c0f-2260aed400a5', null, 'tipo_alambique', 'Refrescadera de cobre', 100, '2f6e2305-b5a5-4cda-bc25-f74f9145ca72');
insert into movement_concepts (id, organization_id, template_id, direction, name, source_lot, creates_lot, asks_result, asks_counterparty, sort_order, created_by) values
  ('98d96d62-b121-4d17-b30b-afdbf021124d', 'ab657e37-17a7-4b03-8c0f-2260aed400a5', null, 'salida', 'Regalo a cliente', 'no_aplica', false, false, true, 100, '2f6e2305-b5a5-4cda-bc25-f74f9145ca72');
update catalog_items set active = false
 where organization_id = 'ab657e37-17a7-4b03-8c0f-2260aed400a5'
   and template_id in ('5c985133-23d9-50fa-a252-6ff6b5b74134', 'b1fce67a-21bf-50a7-9344-fdf29eb5331e');
update movement_concepts set active = false
 where organization_id = 'ab657e37-17a7-4b03-8c0f-2260aed400a5'
   and template_id = '8b7f6579-99ef-549e-b427-b1d4d8bea9da';

-- ---------------------------------------------------------------------
-- Ayudas de la semilla (temporales; mueren con la sesión). security definer
-- para que resuelvan ids aunque el rol activo sea 'authenticated'.
-- ---------------------------------------------------------------------
create function pg_temp.seed_a() returns uuid language sql immutable as $$ select 'ab657e37-17a7-4b03-8c0f-2260aed400a5'::uuid $$;
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
  ('d77f2aa8-7a69-4170-868d-8441d6ecceb2', pg_temp.seed_a(), 'Loma del Toro', 'Santiago Matatlán', 'Familia Cruz');
insert into suppliers (id, organization_id, name, type_item_id) values
  ('2e9402c9-2415-4132-a8c8-c102f6fadbdd', pg_temp.seed_a(), 'Magueyes Don Pedro', pg_temp.seed_cat('640b537d-bf52-5c4b-b407-a5f4fb7c5800')),
  ('8e5697a1-0e79-4b89-adc5-02989a728d0a', pg_temp.seed_a(), 'Destilados Hermanos Luna', pg_temp.seed_cat('bb234638-3c78-56cd-9f41-2fb38182f181'));
insert into supplies (id, organization_id, name, unit_item_id) values
  ('7212370c-ed7e-4c95-b751-53cb06f653af', pg_temp.seed_a(), 'Pulque como inóculo', pg_temp.seed_cat('bc6f104d-2841-5b36-b492-76b36becb172'));
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy, liquid_class) values
  ('fc270600-e9a5-49b5-859e-a50c79352749', pg_temp.seed_a(), 'horno', 'Horno 1', pg_temp.seed_cat('d53ba2da-cada-5215-804a-ff304d569f97'), 10000, 'kg', 'libre', null),
  ('d273a8f8-4aa9-4854-a4d0-31628866ea2e', pg_temp.seed_a(), 'molino', 'Tahona', pg_temp.seed_cat('60285283-d000-52f0-95da-d2b2e6d70fa1'), null, 'kg', 'libre', null),
  ('e6493a90-3799-4ed7-b132-97134ff277cd', pg_temp.seed_a(), 'tina', 'Tina 1', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('dc2ff77f-2a4c-4c5a-adc8-dda4e10442a3', pg_temp.seed_a(), 'tina', 'Tina 2', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('aa590ff6-043b-43f6-9686-027e81cc38fe', pg_temp.seed_a(), 'tina', 'Tina 3', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('5c0efb8d-6c24-4d3a-b5b0-abaeed6a8a84', pg_temp.seed_a(), 'alambique', 'Alambique 1', pg_temp.seed_cat('af73010e-53f2-5769-b3b1-6cda154e665e'), 300, 'L', 'estricta', null),
  ('1ed684a8-abdf-4914-840d-9ad638e239b0', pg_temp.seed_a(), 'alambique', 'Alambique 2', 'fe81f5bd-d01c-4a8d-a724-25b4adcce775', 250, 'L', 'estricta', null),
  ('54e55e84-f743-40dd-b4c5-899c577a30e6', pg_temp.seed_a(), 'colector', 'Colector mezcal', pg_temp.seed_cat('2cd7e70b-6246-543e-8f67-23743fefdf95'), 60, 'L', 'flexible', 'mezcal'),
  ('0f22280b-90f6-4022-850e-f04f7375950d', pg_temp.seed_a(), 'colector', 'Colector ordinario', pg_temp.seed_cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'ordinario'),
  ('07fb4025-83ac-4726-b55d-cd55a9691948', pg_temp.seed_a(), 'colector', 'Colector colas', pg_temp.seed_cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'colas'),
  ('52814010-3ca9-491c-9ab9-4aa3b2269975', pg_temp.seed_a(), 'tanque', 'Tanque 1', pg_temp.seed_cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1000, 'L', 'flexible', null),
  ('6765aec1-ed2d-49e9-a0dd-39c7382d374d', pg_temp.seed_a(), 'tanque', 'Tanque 2', pg_temp.seed_cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1500, 'L', 'flexible', null);

-- Palenque Prueba B: lo mínimo para probar aislamiento
insert into predios (id, organization_id, name, municipality) values
  ('0ccffc87-8de5-4ed9-af4b-751508e80ea3', '86145cbd-63d1-4c31-afc5-2a647c5723e2', 'Predio B', 'Ejutla');
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy) values
  ('79e69dfd-42cd-44b9-ba37-92126059041d', '86145cbd-63d1-4c31-afc5-2a647c5723e2', 'tina', 'Tina B1',
   (select id from catalog_items where organization_id = '86145cbd-63d1-4c31-afc5-2a647c5723e2' and template_id = 'b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1000, 'L', 'flexible');

-- =====================================================================
-- Cuatro Vientos: la producción, POR RPC, en orden cronológico
-- =====================================================================

-- 2026-09-01 · Benito: lo que ya había en el Tanque 2 (carga inicial)
select pg_temp.seed_como('2f6e2305-b5a5-4cda-bc25-f74f9145ca72');
select registrar_entrada(pg_temp.seed_a(), 'f9aea4ad-aeb3-4180-9797-51c22f755b83', '2026-09-01 10:15:00-06',
  'granel', pg_temp.seed_res('Tanque 2'), 600, 44.2, 'mezcal', 'carga_inicial',
  p_concepto => pg_temp.seed_con('255e79f1-12b3-5969-8453-e40623275559'),
  p_nota => 'Lo que ya había en el tanque al empezar', p_folio => 'G-INI-01');

-- 2026-09-01 · Aurelia: la Tina 3 ya fermentaba
select pg_temp.seed_como('d0477962-ae6d-40f1-9528-336cb2ddda85');
select registrar_entrada(pg_temp.seed_a(), '3bb90569-4ca5-4b7d-9e95-838eed1b0034', '2026-09-01 10:40:00-06',
  'fermentado', pg_temp.seed_res('Tina 3'), 1300, null, null, 'carga_inicial',
  p_nota => 'Tina que ya fermentaba', p_folio => 'FER-T3-INI');

-- 2026-09-02 · Aurelia: recepción de maguey
select registrar_recepcion_maguey(pg_temp.seed_a(), '32acc743-c1e7-4651-9067-d188d8533f25', '2026-09-02 07:30:00-06',
  8000, pg_temp.seed_esp('67a96efd-2c72-528e-8682-d144fe1f802c'), 'd77f2aa8-7a69-4170-868d-8441d6ecceb2',
  '2e9402c9-2415-4132-a8c8-c102f6fadbdd', 132, 'Piñas de 8 años, buen tamaño', 'MAG-001');

-- 2026-09-02 · Horneado (la simulación lo abría Tomás; §11.1 lo reserva a
-- admin/productor, así que lo abre Aurelia — docs/DECISIONES.md)
select abrir_horneado(pg_temp.seed_a(), '287a4bf4-38c0-497f-be3f-a211d70de146', '2026-09-02 12:00:00-06',
  pg_temp.seed_res('Horno 1'), array[pg_temp.seed_lot('MAG-001')], array[8000::numeric], p_folio => 'HOR-001');
-- 2026-09-06 · Aurelia cierra: 6,200 kg de agave cocido
select cerrar_horneado(pg_temp.seed_a(), 'bf0e02db-bc8b-4053-95d9-9e1173b2d16a', '2026-09-06 08:00:00-06',
  pg_temp.seed_hor('HOR-001'), 6200, 'Leña de encino', p_folio => 'AC-001');

-- 2026-09-07 · Aurelia: formulación repartida a Tina 1 y Tina 2
select registrar_formulacion(pg_temp.seed_a(), '5358d2c5-a0b8-42b7-983d-08ceca1f48ae', '2026-09-07 09:00:00-06',
  pg_temp.seed_res('Tahona'), array[pg_temp.seed_lot('AC-001')], array[6200::numeric], 1900,
  array[pg_temp.seed_res('Tina 1'), pg_temp.seed_res('Tina 2')], array[1400::numeric, 1400::numeric],
  array['7212370c-ed7e-4c95-b751-53cb06f653af'::uuid], array[20::numeric],
  'Tahona con mula', null, 'F-001', array['FER-T1-001', 'FER-T2-001']);

-- Mediciones diarias (escala de actividad 1–6, §18 #1; la simulación traía 7 y 8)
-- Tina 1
select pg_temp.seed_como('4f16c8c6-e2c0-4e78-8c79-0cf3901c8c2f');
select registrar_medicion(pg_temp.seed_a(), '4fa65ff1-1dce-40ca-8def-c5e903bf7cd4', '2026-09-08 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 1, 'minimo', 4,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.5,12.0]::numeric[]);
select pg_temp.seed_como('d0477962-ae6d-40f1-9528-336cb2ddda85');
select registrar_medicion(pg_temp.seed_a(), 'd2105240-06cc-480b-8dc4-b40eccd65708', '2026-09-09 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.0,9.5]::numeric[]);
select pg_temp.seed_como('4f16c8c6-e2c0-4e78-8c79-0cf3901c8c2f');
select registrar_medicion(pg_temp.seed_a(), 'bfa49162-3212-45bb-a5a1-97d3b2b1685d', '2026-09-10 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.5,6.0]::numeric[]);
select pg_temp.seed_como('d0477962-ae6d-40f1-9528-336cb2ddda85');
select registrar_medicion(pg_temp.seed_a(), '1a10798c-8fb4-4b83-881a-0b9336fe03d9', '2026-09-11 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 4, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.5,3.5]::numeric[]);
select pg_temp.seed_como('4f16c8c6-e2c0-4e78-8c79-0cf3901c8c2f');
select registrar_medicion(pg_temp.seed_a(), '5c2ac366-d916-4a9c-8937-c209adce8ef4', '2026-09-12 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 5, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.0,1.5]::numeric[]);
-- Tina 2
select registrar_medicion(pg_temp.seed_a(), 'f52e4c7e-5bfa-4dc9-85e2-e1823bbb6ebd', '2026-09-08 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 1, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.0,12.2]::numeric[]);
select registrar_medicion(pg_temp.seed_a(), 'f1d62432-bd4d-41ac-863d-8cf5f95dd46e', '2026-09-09 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.5,10.1]::numeric[]);
select registrar_medicion(pg_temp.seed_a(), 'c400f340-b0f2-4f1f-89f5-6c08df62d60a', '2026-09-10 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.0,7.4]::numeric[]);

-- 2026-09-12 · Aurelia declara lista la Tina 1
select pg_temp.seed_como('d0477962-ae6d-40f1-9528-336cb2ddda85');
select declarar_tina_lista(pg_temp.seed_a(), 'd4a972ec-eb2d-4ede-acd1-3cc761cecc42', '2026-09-12 17:00:00-06',
  pg_temp.seed_cyc('Tina 1'), 'Día 5: ya no burbujea, sabor seco');

-- 2026-09-13 · Tomás: dos corridas de 1ª pasada desde la Tina 1
select pg_temp.seed_como('4f16c8c6-e2c0-4e78-8c79-0cf3901c8c2f');
select abrir_corrida(pg_temp.seed_a(), 'c61d2e3d-46ee-435b-a58a-9c753bc8972f', '2026-09-13 06:00:00-06',
  pg_temp.seed_res('Alambique 1'), 'primera', array[pg_temp.seed_res('Tina 1')], array[pg_temp.seed_lot('FER-T1-001')], array[290::numeric],
  p_folio => 'DES-001');
select registrar_corte(pg_temp.seed_a(), '715b9afb-19e1-4310-8bff-92224559504b', '2026-09-13 08:00:00-06', pg_temp.seed_run('DES-001'), 'mezcal', 8, 51.0, pg_temp.seed_res('Colector mezcal'), p_folio => 'MEZ-001');
select registrar_corte(pg_temp.seed_a(), 'e4818c09-2784-4d1a-a7f1-dbed8c5c04ea', '2026-09-13 10:00:00-06', pg_temp.seed_run('DES-001'), 'ordinario', 40, 24.0, pg_temp.seed_res('Colector ordinario'), p_folio => 'ORD-001');
select registrar_corte(pg_temp.seed_a(), '7ca1b37e-f395-4bde-8951-b46fecdf8d2c', '2026-09-13 12:00:00-06', pg_temp.seed_run('DES-001'), 'colas', 12, 9.0, pg_temp.seed_res('Colector colas'), p_folio => 'COL-001');
select cerrar_corrida(pg_temp.seed_a(), 'fbfd95e3-3d98-4939-93f7-8b398f7b6375', '2026-09-13 14:00:00-06', pg_temp.seed_run('DES-001'));

select abrir_corrida(pg_temp.seed_a(), 'a2d3e78f-9fdb-4fb2-994e-342e23695b67', '2026-09-13 06:00:00-06',
  pg_temp.seed_res('Alambique 2'), 'primera', array[pg_temp.seed_res('Tina 1')], array[pg_temp.seed_lot('FER-T1-001')], array[240::numeric],
  p_folio => 'DES-002');
select registrar_corte(pg_temp.seed_a(), '55bb3474-f4ce-4d08-b644-86cd80c4ee9b', '2026-09-13 08:00:00-06', pg_temp.seed_run('DES-002'), 'mezcal', 6, 50.0, pg_temp.seed_res('Colector mezcal'));
select registrar_corte(pg_temp.seed_a(), 'c5f83764-a0e2-4343-9758-9c1a04302c4b', '2026-09-13 10:00:00-06', pg_temp.seed_run('DES-002'), 'ordinario', 34, 23.0, pg_temp.seed_res('Colector ordinario'));
select registrar_corte(pg_temp.seed_a(), 'dbaf25f8-0875-46aa-94b8-b82f366221b1', '2026-09-13 12:00:00-06', pg_temp.seed_run('DES-002'), 'colas', 10, 8.0, pg_temp.seed_res('Colector colas'));
select cerrar_corrida(pg_temp.seed_a(), '42dfe165-e9ab-491e-813e-29e4328c9057', '2026-09-13 14:00:00-06', pg_temp.seed_run('DES-002'));

-- 2026-09-15 · Tomás: 2ª pasada con ordinario y colas juntos (aviso + nota)
select abrir_corrida(pg_temp.seed_a(), '8d5bd9c5-805f-496c-addd-f67975e4f4ea', '2026-09-15 06:00:00-06',
  pg_temp.seed_res('Alambique 1'), 'segunda',
  array[pg_temp.seed_res('Colector ordinario'), pg_temp.seed_res('Colector colas')],
  array[pg_temp.seed_lot('ORD-001'), pg_temp.seed_lot('COL-001')], array[74::numeric, 22::numeric],
  'Había olla libre y poca cola; se juntó con el ordinario', 'DES-003');
select registrar_corte(pg_temp.seed_a(), 'ddf72565-a214-4048-915d-c2d1b69b7a1e', '2026-09-15 08:00:00-06', pg_temp.seed_run('DES-003'), 'mezcal', 26, 52.5, pg_temp.seed_res('Colector mezcal'));
select registrar_corte(pg_temp.seed_a(), '81b66f20-d949-446a-919b-f585db634e19', '2026-09-15 10:00:00-06', pg_temp.seed_run('DES-003'), 'colas', 16, 10.0, pg_temp.seed_res('Colector colas'), p_folio => 'COL-002');
select cerrar_corrida(pg_temp.seed_a(), '2ed93b61-7983-4e2f-8657-584664f6259a', '2026-09-15 14:00:00-06', pg_temp.seed_run('DES-003'));

-- 2026-09-16 · Aurelia: el mezcal del colector pasa a granel con folio nuevo
select pg_temp.seed_como('d0477962-ae6d-40f1-9528-336cb2ddda85');
select transferir(pg_temp.seed_a(), '224dc7aa-495d-44ae-a73d-36bf52df3a21', '2026-09-16 09:00:00-06',
  pg_temp.seed_res('Colector mezcal'), pg_temp.seed_res('Tanque 1'), pg_temp.seed_lot('MEZ-001'), 40, 51.6, 'renombrar', 'G-2609-01');
-- Agua para bajar grado: 4 L, declara 43.8 L (contracción) y 47.0 %
select registrar_movimiento_granel(pg_temp.seed_a(), '16637190-5221-4557-9cb3-f638dd14cc1e', '2026-09-16 11:00:00-06',
  pg_temp.seed_con('66a151e2-9a2c-58be-ad4a-b117f1ddb717'), pg_temp.seed_res('Tanque 1'), 4,
  p_lote => pg_temp.seed_lot('G-2609-01'), p_resultado_l => 43.8, p_resultado_abv => 47.0);

-- 2026-09-17 · Benito: puntas guardadas (sin lote) al Tanque 2
select pg_temp.seed_como('2f6e2305-b5a5-4cda-bc25-f74f9145ca72');
select registrar_movimiento_granel(pg_temp.seed_a(), 'a3ee4a1f-07cd-4e96-a6cf-d457ca505103', '2026-09-17 10:00:00-06',
  pg_temp.seed_con('f21aaad8-2ef6-556b-be55-64aa94431ab6'), pg_temp.seed_res('Tanque 2'), 2,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_resultado_l => 602, p_resultado_abv => 44.6, p_abv => 68.0,
  p_nota => 'Puntas guardadas de corridas de agosto, sin lote');
-- 2026-09-18 · Benito: unión de G-2609-01 (Tanque 1) con G-INI-01 (Tanque 2), se conserva el folio mayor
select registrar_movimiento_granel(pg_temp.seed_a(), '44125962-073b-46f9-b781-25db1eaa6eca', '2026-09-18 09:30:00-06',
  pg_temp.seed_con('df427d88-600e-550e-a097-8ffe4f4dd556'), pg_temp.seed_res('Tanque 2'), 43.8,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_lote_origen => pg_temp.seed_lot('G-2609-01'), p_recurso_origen => pg_temp.seed_res('Tanque 1'),
  p_resultado_l => 645.8, p_resultado_abv => 44.9, p_decision => 'conservar', p_nota => 'Se conserva el folio del lote mayor');
-- 2026-09-19 · Benito: compra de granel al Tanque 1
select registrar_movimiento_granel(pg_temp.seed_a(), '458030c8-f58f-4241-9ba3-f1c979b73fb3', '2026-09-19 12:00:00-06',
  pg_temp.seed_con('688430a9-cd2f-5bae-add2-c59bc543d911'), pg_temp.seed_res('Tanque 1'), 250,
  p_resultado_l => 250, p_resultado_abv => 46.0, p_abv => 46.0, p_folio_nuevo => 'G-COMPRA-01',
  p_contraparte => 'Destilados Hermanos Luna', p_documento => 'Remisión 0452',
  p_proveedor => '8e5697a1-0e79-4b89-adc5-02989a728d0a', p_especie => pg_temp.seed_esp('67a96efd-2c72-528e-8682-d144fe1f802c'),
  p_predio_declarado => 'Sola de Vega');

-- 2026-09-19 · Aurelia: muestra de laboratorio
select pg_temp.seed_como('d0477962-ae6d-40f1-9528-336cb2ddda85');
select registrar_movimiento_granel(pg_temp.seed_a(), '36c4168a-617d-4794-9a1b-73484478e18c', '2026-09-19 13:00:00-06',
  pg_temp.seed_con('2d62ab89-6a11-558c-8b46-5c4d30aa1607'), pg_temp.seed_res('Tanque 2'), 1,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Laboratorio ficticio de Oaxaca', p_documento => 'Análisis 2026-311');

-- 2026-09-20/22 · Benito: autoconsumo, venta, regalo
select pg_temp.seed_como('2f6e2305-b5a5-4cda-bc25-f74f9145ca72');
select registrar_movimiento_granel(pg_temp.seed_a(), '8c05b1d4-0b2d-4da8-b9bc-3ddf49b31280', '2026-09-20 13:00:00-06',
  pg_temp.seed_con('fa52f92b-de19-5d0c-972c-beb899bb2ccb'), pg_temp.seed_res('Tanque 2'), 2, p_lote => pg_temp.seed_lot('G-INI-01'));
select registrar_movimiento_granel(pg_temp.seed_a(), 'ed784839-07f3-471a-85d8-6720799bf3d7', '2026-09-22 13:00:00-06',
  pg_temp.seed_con('7b0ca7ca-f8ae-5f33-93d5-f0c174664ec1'), pg_temp.seed_res('Tanque 2'), 300,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.', p_documento => 'Remisión 118');
select registrar_movimiento_granel(pg_temp.seed_a(), '3df21a4b-d6ea-4044-9309-9654cb234802', '2026-09-22 13:00:00-06',
  '98d96d62-b121-4d17-b30b-afdbf021124d', pg_temp.seed_res('Tanque 2'), 1,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.');

reset role;

-- Evidencia de la compra (los adjuntos no son RPC de §12)
insert into attachments (id, organization_id, operation_id, lot_id, kind_item_id, storage_path, caption) values
  ('4c47af86-2666-4444-82a6-1c71d6e28748', pg_temp.seed_a(),
   (select id from operations where organization_id = pg_temp.seed_a() and idempotency_key = '458030c8-f58f-4241-9ba3-f1c979b73fb3'),
   pg_temp.seed_lot('G-COMPRA-01'), pg_temp.seed_cat('0522e23b-3b1d-58be-b50c-8a6ed0627c9f'),
   'evidencias/ab657e37-17a7-4b03-8c0f-2260aed400a5/g-compra-01/remision-0452.jpg', 'Remisión del proveedor');


-- pgTAP · Portal por empresa (PULZ_MAESTRO.md §7.3–§7.5): lo que ve alguien
-- sin sesión. portal_branding es lo único público (anon).
--     supabase db query --linked -f supabase/tests/portal.test.sql


create function pg_temp.test_portal() returns setof text language plpgsql as $$
declare a uuid := 'ab657e37-17a7-4b03-8c0f-2260aed400a5'; b uuid := '86145cbd-63d1-4c31-afc5-2a647c5723e2';
begin
  -- Como anon (sin sesión), que es como llega el navegador y la Pages Function
  execute 'set local role anon';

  return next is((select name from portal_branding('qa-2a405c188267-cuatro-vientos')), 'Mezcal Cuatro Vientos',
                 'portal_branding devuelve la marca por slug');
  return next is((select read_only from portal_branding('qa-2a405c188267-cuatro-vientos')), false,
                 'suscripción en prueba → abierto');
  return next is((select redirect_to from portal_branding('qa-2a405c188267-mezcal-cuatro-vientos')), 'qa-2a405c188267-cuatro-vientos',
                 'el slug viejo redirige al actual (historial de slugs)');
  return next is((select name from portal_branding('QA-2A405C188267-CUATRO-VIENTOS')), 'Mezcal Cuatro Vientos',
                 'el slug no distingue mayúsculas');
  return next is((select count(*) from portal_branding('no-existe')), 0::bigint,
                 'empresa inexistente: ninguna fila');
  -- anon ni siquiera tiene GRANT sobre las tablas de negocio (0013): 42501
  return next throws_ok($q$select count(*) from catalog_items$q$, '42501',
                 null, 'anon no lee nada de negocio por PostgREST (sin grant, no solo RLS)');
  return next throws_ok($q$select is_member('ab657e37-17a7-4b03-8c0f-2260aed400a5')$q$, '42501',
                 null, 'anon no puede ejecutar is_member (revocado)');

  execute 'reset role';
  -- vencida → sigue abierto pero en solo lectura; cancelada → como inexistente
  update subscriptions set status = 'vencida' where organization_id = b;
  execute 'set local role anon';
  return next is((select read_only from portal_branding('qa-2a405c188267-prueba-b')), true, 'vencida → read_only');
  execute 'reset role';
  update subscriptions set status = 'cancelada' where organization_id = b;
  execute 'set local role anon';
  return next is((select count(*) from portal_branding('qa-2a405c188267-prueba-b')), 0::bigint,
                 'cancelada → ninguna fila, idéntico a inexistente (§7.4)');
  execute 'reset role';

  -- has_role rechaza escrituras con suscripción vencida (§11.2)
  update subscriptions set status = 'vencida' where organization_id = a;
  execute 'set local role authenticated';
  execute $q$set local request.jwt.claims = '{"sub":"2f6e2305-b5a5-4cda-bc25-f74f9145ca72","role":"authenticated"}'$q$;
  return next is((select has_role(a, array['admin']::member_role[])), false,
                 'vencida: has_role rechaza al admin (solo lectura)');
  return next is((select is_member(a)), true, 'vencida: is_member sigue en true (la lectura sigue)');
  execute 'reset role';
end $$;

select * from runtests((select nspname from pg_namespace where oid = pg_my_temp_schema())::name, '^test_');


rollback;
