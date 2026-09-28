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
-- tomas.h → 'tomas-2026' · dueña B → 'qa-b8a6e2f8ec00-prueba-b-2026' · admin → 'pulz-2026'
-- ---------------------------------------------------------------------
insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
                        raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
                        confirmation_token, recovery_token, email_change_token_new, email_change) values
  ('00000000-0000-0000-0000-000000000000', '2b9a2414-d7b1-43e0-827a-0977c4d7c1ed', 'authenticated', 'authenticated', 'qa-b8a6e2f8ec00-tu@pulz.mx',
   extensions.crypt('pulz-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '17735896-4061-41f7-b1de-878f4d3ddb6f', 'authenticated', 'authenticated', 'qa-b8a6e2f8ec00-benito@cuatrovientos.mx',
   extensions.crypt('benito-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '0afb1de3-0ddd-4cec-8105-c781952d5cee', 'authenticated', 'authenticated', 'qa-b8a6e2f8ec00-aurelia@187a210c-f620-4f5e-b9fa-9f26438e8b7d.usuarios.pulz.mx',
   extensions.crypt('aurelia-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '600a68b2-23f2-4a65-bc8e-0bac8bcb9b64', 'authenticated', 'authenticated', 'qa-b8a6e2f8ec00-tomas.h@187a210c-f620-4f5e-b9fa-9f26438e8b7d.usuarios.pulz.mx',
   extensions.crypt('tomas-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '44e4c261-a622-4295-b679-558d3bc6fe8f', 'authenticated', 'authenticated', 'qa-b8a6e2f8ec00-duena@pruebab.mx',
   extensions.crypt('qa-b8a6e2f8ec00-prueba-b-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '');

insert into profiles (id, full_name) values
  ('2b9a2414-d7b1-43e0-827a-0977c4d7c1ed', 'Admin PULZ'),
  ('17735896-4061-41f7-b1de-878f4d3ddb6f', 'Benito Cruz'),
  ('0afb1de3-0ddd-4cec-8105-c781952d5cee', 'Aurelia Santiago'),
  ('600a68b2-23f2-4a65-bc8e-0bac8bcb9b64', 'Tomás Hernández'),
  ('44e4c261-a622-4295-b679-558d3bc6fe8f', 'Dueña Prueba B');

insert into platform_admins (user_id) values ('2b9a2414-d7b1-43e0-827a-0977c4d7c1ed');

-- Planes (§14, §18 #2 y #3)
-- Fixture: reutiliza plans canónica, sin modificarla.
-- Fixture: reutiliza plan_limits canónica, sin modificarla.
-- Fixture: reutiliza plan_features canónica, sin modificarla.

-- Empresas
insert into organizations (id, name, slug, state, brand_color, logo_path, welcome_message, created_by) values
  ('187a210c-f620-4f5e-b9fa-9f26438e8b7d', 'Mezcal Cuatro Vientos', 'qa-b8a6e2f8ec00-cuatro-vientos', 'Oaxaca', '#7A3E1D', null, 'Registro de producción del palenque', '17735896-4061-41f7-b1de-878f4d3ddb6f'),
  ('0b000ea4-f65f-4949-bf5d-a06b5b14f78f', 'Palenque Prueba B', 'qa-b8a6e2f8ec00-prueba-b', 'Oaxaca', '#173F87', null, 'Empresa de prueba', '44e4c261-a622-4295-b679-558d3bc6fe8f');
insert into organization_slug_history (slug, organization_id, retired_at, retired_by) values
  ('qa-b8a6e2f8ec00-mezcal-cuatro-vientos', '187a210c-f620-4f5e-b9fa-9f26438e8b7d', '2026-09-02 09:00:00-06', '17735896-4061-41f7-b1de-878f4d3ddb6f');
insert into organization_members (organization_id, user_id, role, status, username, must_change_password) values
  ('187a210c-f620-4f5e-b9fa-9f26438e8b7d', '17735896-4061-41f7-b1de-878f4d3ddb6f', 'admin', 'activo', null, false),
  ('187a210c-f620-4f5e-b9fa-9f26438e8b7d', '0afb1de3-0ddd-4cec-8105-c781952d5cee', 'productor', 'activo', 'aurelia', false),
  ('187a210c-f620-4f5e-b9fa-9f26438e8b7d', '600a68b2-23f2-4a65-bc8e-0bac8bcb9b64', 'operador', 'activo', 'tomas.h', true),
  ('0b000ea4-f65f-4949-bf5d-a06b5b14f78f', '44e4c261-a622-4295-b679-558d3bc6fe8f', 'admin', 'activo', null, false);
insert into member_invitations (id, organization_id, user_id, token_hash, expires_at, used_at, created_by) values
  ('39640928-b843-4ea2-95c5-011c5b767601', '187a210c-f620-4f5e-b9fa-9f26438e8b7d', '600a68b2-23f2-4a65-bc8e-0bac8bcb9b64', 'qa-b8a6e2f8ec00:SIMULADO', '2026-09-05 10:00:00-06', null, '17735896-4061-41f7-b1de-878f4d3ddb6f');
insert into login_throttle (user_id, failed_count, last_failed_at, locked_until) values
  ('600a68b2-23f2-4a65-bc8e-0bac8bcb9b64', 3, '2026-09-03 07:12:00-06', null);
insert into organization_settings (organization_id, record_puntas, measurement_mode, warn_mixed_second_pass, fermentation_expected_days, measurement_reminder_hour, default_folio_decision) values
  ('187a210c-f620-4f5e-b9fa-9f26438e8b7d', false, 'minimo', true, 7, 9, 'conservar'),
  ('0b000ea4-f65f-4949-bf5d-a06b5b14f78f', false, 'minimo', true, 7, 9, 'conservar');
insert into subscriptions (organization_id, plan_id, status, current_period_end) values
  ('187a210c-f620-4f5e-b9fa-9f26438e8b7d', 'edd15bcf-ad82-5684-a2e7-d85db401885b', 'prueba', '2026-10-15 00:00:00-06'),
  ('0b000ea4-f65f-4949-bf5d-a06b5b14f78f', 'ee35d6fd-b4d6-56d6-b7b4-61cb81932b21', 'gratis', null);

-- ---------------------------------------------------------------------
-- Plantillas de plataforma (§10.2.1)
-- ---------------------------------------------------------------------
-- Fixture: reutiliza catalog_item_templates canónica, sin modificarla.
-- Fixture: reutiliza movement_concept_templates canónica, sin modificarla.
-- Fixture: reutiliza species_templates canónica, sin modificarla.

select seed_organization_catalogs('187a210c-f620-4f5e-b9fa-9f26438e8b7d');
select seed_organization_catalogs('0b000ea4-f65f-4949-bf5d-a06b5b14f78f');

-- Lo propio de Cuatro Vientos y lo que oculta (§10.2.4)
insert into catalog_items (id, organization_id, template_id, catalog, name, sort_order, created_by) values
  ('9d8ead9c-0e7c-47e1-a665-6a9bb259cdd6', '187a210c-f620-4f5e-b9fa-9f26438e8b7d', null, 'tipo_alambique', 'Refrescadera de cobre', 100, '17735896-4061-41f7-b1de-878f4d3ddb6f');
insert into movement_concepts (id, organization_id, template_id, direction, name, source_lot, creates_lot, asks_result, asks_counterparty, sort_order, created_by) values
  ('343f2b68-41de-491e-a2b2-1583001892e3', '187a210c-f620-4f5e-b9fa-9f26438e8b7d', null, 'salida', 'Regalo a cliente', 'no_aplica', false, false, true, 100, '17735896-4061-41f7-b1de-878f4d3ddb6f');
update catalog_items set active = false
 where organization_id = '187a210c-f620-4f5e-b9fa-9f26438e8b7d'
   and template_id in ('5c985133-23d9-50fa-a252-6ff6b5b74134', 'b1fce67a-21bf-50a7-9344-fdf29eb5331e');
update movement_concepts set active = false
 where organization_id = '187a210c-f620-4f5e-b9fa-9f26438e8b7d'
   and template_id = '8b7f6579-99ef-549e-b427-b1d4d8bea9da';

-- ---------------------------------------------------------------------
-- Ayudas de la semilla (temporales; mueren con la sesión). security definer
-- para que resuelvan ids aunque el rol activo sea 'authenticated'.
-- ---------------------------------------------------------------------
create function pg_temp.seed_a() returns uuid language sql immutable as $$ select '187a210c-f620-4f5e-b9fa-9f26438e8b7d'::uuid $$;
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
  ('d48d00fc-a736-4c0f-92d7-d0f528cbd970', pg_temp.seed_a(), 'Loma del Toro', 'Santiago Matatlán', 'Familia Cruz');
insert into suppliers (id, organization_id, name, type_item_id) values
  ('c896e664-1a3c-4d1a-96b6-3abcef7037c0', pg_temp.seed_a(), 'Magueyes Don Pedro', pg_temp.seed_cat('640b537d-bf52-5c4b-b407-a5f4fb7c5800')),
  ('59d86978-55bd-4a96-a4b0-a12fb1188466', pg_temp.seed_a(), 'Destilados Hermanos Luna', pg_temp.seed_cat('bb234638-3c78-56cd-9f41-2fb38182f181'));
insert into supplies (id, organization_id, name, unit_item_id) values
  ('1248e131-1b91-4815-b5e7-dcd5feb89843', pg_temp.seed_a(), 'Pulque como inóculo', pg_temp.seed_cat('bc6f104d-2841-5b36-b492-76b36becb172'));
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy, liquid_class) values
  ('7568b959-f70d-47b5-9bf4-91d0ec565526', pg_temp.seed_a(), 'horno', 'Horno 1', pg_temp.seed_cat('d53ba2da-cada-5215-804a-ff304d569f97'), 10000, 'kg', 'libre', null),
  ('846202e7-6138-4060-88e1-ec58d98b1b36', pg_temp.seed_a(), 'molino', 'Tahona', pg_temp.seed_cat('60285283-d000-52f0-95da-d2b2e6d70fa1'), null, 'kg', 'libre', null),
  ('ab41357e-d320-4f5f-9fc4-5f3149a15576', pg_temp.seed_a(), 'tina', 'Tina 1', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('e9d2e41a-46c4-4cf6-b8ad-efa0b0b1ba6e', pg_temp.seed_a(), 'tina', 'Tina 2', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('7c78fe8a-4a76-40d3-baaa-39a477613630', pg_temp.seed_a(), 'tina', 'Tina 3', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('07e1a5d2-e40f-4595-818a-c582ca8344eb', pg_temp.seed_a(), 'alambique', 'Alambique 1', pg_temp.seed_cat('af73010e-53f2-5769-b3b1-6cda154e665e'), 300, 'L', 'estricta', null),
  ('778da272-9652-4beb-ab97-8bb2a650e554', pg_temp.seed_a(), 'alambique', 'Alambique 2', '9d8ead9c-0e7c-47e1-a665-6a9bb259cdd6', 250, 'L', 'estricta', null),
  ('d3891453-d68e-41a5-b47f-c70646e4125f', pg_temp.seed_a(), 'colector', 'Colector mezcal', pg_temp.seed_cat('2cd7e70b-6246-543e-8f67-23743fefdf95'), 60, 'L', 'flexible', 'mezcal'),
  ('7b577013-5fa1-485c-a5df-40ebe6c048a3', pg_temp.seed_a(), 'colector', 'Colector ordinario', pg_temp.seed_cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'ordinario'),
  ('807aa2bc-62ed-43fd-b440-526c60ea2f78', pg_temp.seed_a(), 'colector', 'Colector colas', pg_temp.seed_cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'colas'),
  ('c238ff30-8664-4853-af95-f375bd0f4ea1', pg_temp.seed_a(), 'tanque', 'Tanque 1', pg_temp.seed_cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1000, 'L', 'flexible', null),
  ('46a52806-4d1f-4dff-978e-b970a1abc1b3', pg_temp.seed_a(), 'tanque', 'Tanque 2', pg_temp.seed_cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1500, 'L', 'flexible', null);

-- Palenque Prueba B: lo mínimo para probar aislamiento
insert into predios (id, organization_id, name, municipality) values
  ('210def7c-b993-4c37-8d40-2a96c9bad49e', '0b000ea4-f65f-4949-bf5d-a06b5b14f78f', 'Predio B', 'Ejutla');
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy) values
  ('12af2f4a-b01a-4bd7-a120-0ad187d935b8', '0b000ea4-f65f-4949-bf5d-a06b5b14f78f', 'tina', 'Tina B1',
   (select id from catalog_items where organization_id = '0b000ea4-f65f-4949-bf5d-a06b5b14f78f' and template_id = 'b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1000, 'L', 'flexible');

-- =====================================================================
-- Cuatro Vientos: la producción, POR RPC, en orden cronológico
-- =====================================================================

-- 2026-09-01 · Benito: lo que ya había en el Tanque 2 (carga inicial)
select pg_temp.seed_como('17735896-4061-41f7-b1de-878f4d3ddb6f');
select registrar_entrada(pg_temp.seed_a(), 'c59eeeb8-e0e3-436b-9770-ba13c332515e', '2026-09-01 10:15:00-06',
  'granel', pg_temp.seed_res('Tanque 2'), 600, 44.2, 'mezcal', 'carga_inicial',
  p_concepto => pg_temp.seed_con('255e79f1-12b3-5969-8453-e40623275559'),
  p_nota => 'Lo que ya había en el tanque al empezar', p_folio => 'G-INI-01');

-- 2026-09-01 · Aurelia: la Tina 3 ya fermentaba
select pg_temp.seed_como('0afb1de3-0ddd-4cec-8105-c781952d5cee');
select registrar_entrada(pg_temp.seed_a(), 'b2a79d95-1227-413b-9b86-4514f4161628', '2026-09-01 10:40:00-06',
  'fermentado', pg_temp.seed_res('Tina 3'), 1300, null, null, 'carga_inicial',
  p_nota => 'Tina que ya fermentaba', p_folio => 'FER-T3-INI');

-- 2026-09-02 · Aurelia: recepción de maguey
select registrar_recepcion_maguey(pg_temp.seed_a(), '9fbc91c9-03be-4a1f-9179-0d808b7af364', '2026-09-02 07:30:00-06',
  8000, pg_temp.seed_esp('67a96efd-2c72-528e-8682-d144fe1f802c'), 'd48d00fc-a736-4c0f-92d7-d0f528cbd970',
  'c896e664-1a3c-4d1a-96b6-3abcef7037c0', 132, 'Piñas de 8 años, buen tamaño', 'MAG-001');

-- 2026-09-02 · Horneado (la simulación lo abría Tomás; §11.1 lo reserva a
-- admin/productor, así que lo abre Aurelia — docs/DECISIONES.md)
select abrir_horneado(pg_temp.seed_a(), 'badb4a0b-2854-42ab-8f30-89a6145184d0', '2026-09-02 12:00:00-06',
  pg_temp.seed_res('Horno 1'), array[pg_temp.seed_lot('MAG-001')], array[8000::numeric], p_folio => 'HOR-001');
-- 2026-09-06 · Aurelia cierra: 6,200 kg de agave cocido
select cerrar_horneado(pg_temp.seed_a(), 'dae7b5e3-8e75-4c87-93bb-0767b0a79978', '2026-09-06 08:00:00-06',
  pg_temp.seed_hor('HOR-001'), 6200, 'Leña de encino', p_folio => 'AC-001');

-- 2026-09-07 · Aurelia: formulación repartida a Tina 1 y Tina 2
select registrar_formulacion(pg_temp.seed_a(), '3d27f376-e066-4780-8ea3-580b6a113774', '2026-09-07 09:00:00-06',
  pg_temp.seed_res('Tahona'), array[pg_temp.seed_lot('AC-001')], array[6200::numeric], 1900,
  array[pg_temp.seed_res('Tina 1'), pg_temp.seed_res('Tina 2')], array[1400::numeric, 1400::numeric],
  array['1248e131-1b91-4815-b5e7-dcd5feb89843'::uuid], array[20::numeric],
  'Tahona con mula', null, 'F-001', array['FER-T1-001', 'FER-T2-001']);

-- Mediciones diarias (escala de actividad 1–6, §18 #1; la simulación traía 7 y 8)
-- Tina 1
select pg_temp.seed_como('600a68b2-23f2-4a65-bc8e-0bac8bcb9b64');
select registrar_medicion(pg_temp.seed_a(), '8598957d-13f7-4f41-bd70-54cbae637660', '2026-09-08 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 1, 'minimo', 4,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.5,12.0]::numeric[]);
select pg_temp.seed_como('0afb1de3-0ddd-4cec-8105-c781952d5cee');
select registrar_medicion(pg_temp.seed_a(), '6d1b17ca-79d9-4047-9158-e249c3f3b224', '2026-09-09 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.0,9.5]::numeric[]);
select pg_temp.seed_como('600a68b2-23f2-4a65-bc8e-0bac8bcb9b64');
select registrar_medicion(pg_temp.seed_a(), '2e8fa9af-e646-41b4-8fb5-23a40dc8caac', '2026-09-10 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.5,6.0]::numeric[]);
select pg_temp.seed_como('0afb1de3-0ddd-4cec-8105-c781952d5cee');
select registrar_medicion(pg_temp.seed_a(), '883b1110-8321-41f8-b29b-aee4ab78532f', '2026-09-11 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 4, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.5,3.5]::numeric[]);
select pg_temp.seed_como('600a68b2-23f2-4a65-bc8e-0bac8bcb9b64');
select registrar_medicion(pg_temp.seed_a(), 'ad3b2ca4-3caf-41dd-a995-980bd23b853b', '2026-09-12 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 5, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.0,1.5]::numeric[]);
-- Tina 2
select registrar_medicion(pg_temp.seed_a(), '09337ca7-546c-4ce0-b05e-1d7ab0191bcc', '2026-09-08 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 1, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.0,12.2]::numeric[]);
select registrar_medicion(pg_temp.seed_a(), '1dc5bf8e-fd26-406b-94a3-38937f7647b1', '2026-09-09 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.5,10.1]::numeric[]);
select registrar_medicion(pg_temp.seed_a(), 'b5dd74f2-9f49-4108-b8a5-7fc1dfdd514f', '2026-09-10 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.0,7.4]::numeric[]);

-- 2026-09-12 · Aurelia declara lista la Tina 1
select pg_temp.seed_como('0afb1de3-0ddd-4cec-8105-c781952d5cee');
select declarar_tina_lista(pg_temp.seed_a(), '19cb06cd-5264-4aff-b0d4-4506da8bf83a', '2026-09-12 17:00:00-06',
  pg_temp.seed_cyc('Tina 1'), 'Día 5: ya no burbujea, sabor seco');

-- 2026-09-13 · Tomás: dos corridas de 1ª pasada desde la Tina 1
select pg_temp.seed_como('600a68b2-23f2-4a65-bc8e-0bac8bcb9b64');
select abrir_corrida(pg_temp.seed_a(), 'c5894f24-86a7-4af1-a04a-619a4225b264', '2026-09-13 06:00:00-06',
  pg_temp.seed_res('Alambique 1'), 'primera', array[pg_temp.seed_res('Tina 1')], array[pg_temp.seed_lot('FER-T1-001')], array[290::numeric],
  p_folio => 'DES-001');
select registrar_corte(pg_temp.seed_a(), '148fc396-715b-4993-969e-a8844b0a3789', '2026-09-13 08:00:00-06', pg_temp.seed_run('DES-001'), 'mezcal', 8, 51.0, pg_temp.seed_res('Colector mezcal'), p_folio => 'MEZ-001');
select registrar_corte(pg_temp.seed_a(), '82ce0d1b-a4d6-48ae-8953-62061722c290', '2026-09-13 10:00:00-06', pg_temp.seed_run('DES-001'), 'ordinario', 40, 24.0, pg_temp.seed_res('Colector ordinario'), p_folio => 'ORD-001');
select registrar_corte(pg_temp.seed_a(), 'b42dc9b8-d820-4f57-8994-fbd1a4ce8659', '2026-09-13 12:00:00-06', pg_temp.seed_run('DES-001'), 'colas', 12, 9.0, pg_temp.seed_res('Colector colas'), p_folio => 'COL-001');
select cerrar_corrida(pg_temp.seed_a(), '53bb6ae2-338f-417d-beeb-4b63dfa1bfc3', '2026-09-13 14:00:00-06', pg_temp.seed_run('DES-001'));

select abrir_corrida(pg_temp.seed_a(), '2934aaab-d1b6-4954-b5b5-29e3f7883a17', '2026-09-13 06:00:00-06',
  pg_temp.seed_res('Alambique 2'), 'primera', array[pg_temp.seed_res('Tina 1')], array[pg_temp.seed_lot('FER-T1-001')], array[240::numeric],
  p_folio => 'DES-002');
select registrar_corte(pg_temp.seed_a(), 'c008c9b1-cf4e-4917-94bf-d63c31f05ef2', '2026-09-13 08:00:00-06', pg_temp.seed_run('DES-002'), 'mezcal', 6, 50.0, pg_temp.seed_res('Colector mezcal'));
select registrar_corte(pg_temp.seed_a(), 'b8e777b9-e842-46c8-849f-4dd9ab72226a', '2026-09-13 10:00:00-06', pg_temp.seed_run('DES-002'), 'ordinario', 34, 23.0, pg_temp.seed_res('Colector ordinario'));
select registrar_corte(pg_temp.seed_a(), '2e8f92f9-7d66-457e-b32d-e09107c99eee', '2026-09-13 12:00:00-06', pg_temp.seed_run('DES-002'), 'colas', 10, 8.0, pg_temp.seed_res('Colector colas'));
select cerrar_corrida(pg_temp.seed_a(), '8f80b356-17dd-467e-881e-c2ec62e96be0', '2026-09-13 14:00:00-06', pg_temp.seed_run('DES-002'));

-- 2026-09-15 · Tomás: 2ª pasada con ordinario y colas juntos (aviso + nota)
select abrir_corrida(pg_temp.seed_a(), '3b81abbf-c921-4fb6-b992-e17887eb3e13', '2026-09-15 06:00:00-06',
  pg_temp.seed_res('Alambique 1'), 'segunda',
  array[pg_temp.seed_res('Colector ordinario'), pg_temp.seed_res('Colector colas')],
  array[pg_temp.seed_lot('ORD-001'), pg_temp.seed_lot('COL-001')], array[74::numeric, 22::numeric],
  'Había olla libre y poca cola; se juntó con el ordinario', 'DES-003');
select registrar_corte(pg_temp.seed_a(), 'c9e4ff48-93f2-4479-b243-4e3863796083', '2026-09-15 08:00:00-06', pg_temp.seed_run('DES-003'), 'mezcal', 26, 52.5, pg_temp.seed_res('Colector mezcal'));
select registrar_corte(pg_temp.seed_a(), '0e7fe93a-465a-423d-ad9c-4b4089b7351f', '2026-09-15 10:00:00-06', pg_temp.seed_run('DES-003'), 'colas', 16, 10.0, pg_temp.seed_res('Colector colas'), p_folio => 'COL-002');
select cerrar_corrida(pg_temp.seed_a(), '1798dee3-a6ff-4651-8de2-ffee78fb89ca', '2026-09-15 14:00:00-06', pg_temp.seed_run('DES-003'));

-- 2026-09-16 · Aurelia: el mezcal del colector pasa a granel con folio nuevo
select pg_temp.seed_como('0afb1de3-0ddd-4cec-8105-c781952d5cee');
select transferir(pg_temp.seed_a(), '741cb14a-c935-4c88-9ebe-568e83e9c1d9', '2026-09-16 09:00:00-06',
  pg_temp.seed_res('Colector mezcal'), pg_temp.seed_res('Tanque 1'), pg_temp.seed_lot('MEZ-001'), 40, 51.6, 'renombrar', 'G-2609-01');
-- Agua para bajar grado: 4 L, declara 43.8 L (contracción) y 47.0 %
select registrar_movimiento_granel(pg_temp.seed_a(), '9f494662-9367-4a97-867e-328b11f1e903', '2026-09-16 11:00:00-06',
  pg_temp.seed_con('66a151e2-9a2c-58be-ad4a-b117f1ddb717'), pg_temp.seed_res('Tanque 1'), 4,
  p_lote => pg_temp.seed_lot('G-2609-01'), p_resultado_l => 43.8, p_resultado_abv => 47.0);

-- 2026-09-17 · Benito: puntas guardadas (sin lote) al Tanque 2
select pg_temp.seed_como('17735896-4061-41f7-b1de-878f4d3ddb6f');
select registrar_movimiento_granel(pg_temp.seed_a(), '9abebf25-3ef1-43dd-9dfe-c6f0966ea6e0', '2026-09-17 10:00:00-06',
  pg_temp.seed_con('f21aaad8-2ef6-556b-be55-64aa94431ab6'), pg_temp.seed_res('Tanque 2'), 2,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_resultado_l => 602, p_resultado_abv => 44.6, p_abv => 68.0,
  p_nota => 'Puntas guardadas de corridas de agosto, sin lote');
-- 2026-09-18 · Benito: unión de G-2609-01 (Tanque 1) con G-INI-01 (Tanque 2), se conserva el folio mayor
select registrar_movimiento_granel(pg_temp.seed_a(), 'a146d73f-d7ff-4beb-9093-b8cc8435a37f', '2026-09-18 09:30:00-06',
  pg_temp.seed_con('df427d88-600e-550e-a097-8ffe4f4dd556'), pg_temp.seed_res('Tanque 2'), 43.8,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_lote_origen => pg_temp.seed_lot('G-2609-01'), p_recurso_origen => pg_temp.seed_res('Tanque 1'),
  p_resultado_l => 645.8, p_resultado_abv => 44.9, p_decision => 'conservar', p_nota => 'Se conserva el folio del lote mayor');
-- 2026-09-19 · Benito: compra de granel al Tanque 1
select registrar_movimiento_granel(pg_temp.seed_a(), '4cc100a6-66e1-4a86-889c-efe9364c722f', '2026-09-19 12:00:00-06',
  pg_temp.seed_con('688430a9-cd2f-5bae-add2-c59bc543d911'), pg_temp.seed_res('Tanque 1'), 250,
  p_resultado_l => 250, p_resultado_abv => 46.0, p_abv => 46.0, p_folio_nuevo => 'G-COMPRA-01',
  p_contraparte => 'Destilados Hermanos Luna', p_documento => 'Remisión 0452',
  p_proveedor => '59d86978-55bd-4a96-a4b0-a12fb1188466', p_especie => pg_temp.seed_esp('67a96efd-2c72-528e-8682-d144fe1f802c'),
  p_predio_declarado => 'Sola de Vega');

-- 2026-09-19 · Aurelia: muestra de laboratorio
select pg_temp.seed_como('0afb1de3-0ddd-4cec-8105-c781952d5cee');
select registrar_movimiento_granel(pg_temp.seed_a(), '1387a2a9-5215-4a2a-a937-d3f3fec6cadc', '2026-09-19 13:00:00-06',
  pg_temp.seed_con('2d62ab89-6a11-558c-8b46-5c4d30aa1607'), pg_temp.seed_res('Tanque 2'), 1,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Laboratorio ficticio de Oaxaca', p_documento => 'Análisis 2026-311');

-- 2026-09-20/22 · Benito: autoconsumo, venta, regalo
select pg_temp.seed_como('17735896-4061-41f7-b1de-878f4d3ddb6f');
select registrar_movimiento_granel(pg_temp.seed_a(), 'ac38d167-9b52-4cc6-813c-564da6c32632', '2026-09-20 13:00:00-06',
  pg_temp.seed_con('fa52f92b-de19-5d0c-972c-beb899bb2ccb'), pg_temp.seed_res('Tanque 2'), 2, p_lote => pg_temp.seed_lot('G-INI-01'));
select registrar_movimiento_granel(pg_temp.seed_a(), '7f5f285b-a512-4b31-8c4e-83acff7e7af5', '2026-09-22 13:00:00-06',
  pg_temp.seed_con('7b0ca7ca-f8ae-5f33-93d5-f0c174664ec1'), pg_temp.seed_res('Tanque 2'), 300,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.', p_documento => 'Remisión 118');
select registrar_movimiento_granel(pg_temp.seed_a(), '968c6792-774b-484a-ab8d-90eecf924ab1', '2026-09-22 13:00:00-06',
  '343f2b68-41de-491e-a2b2-1583001892e3', pg_temp.seed_res('Tanque 2'), 1,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.');

reset role;

-- Evidencia de la compra (los adjuntos no son RPC de §12)
insert into attachments (id, organization_id, operation_id, lot_id, kind_item_id, storage_path, caption) values
  ('38f6cf11-a505-49d0-ad65-396cbc006a62', pg_temp.seed_a(),
   (select id from operations where organization_id = pg_temp.seed_a() and idempotency_key = '4cc100a6-66e1-4a86-889c-efe9364c722f'),
   pg_temp.seed_lot('G-COMPRA-01'), pg_temp.seed_cat('0522e23b-3b1d-58be-b50c-8a6ed0627c9f'),
   'evidencias/187a210c-f620-4f5e-b9fa-9f26438e8b7d/g-compra-01/remision-0452.jpg', 'Remisión del proveedor');


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
  a uuid := '187a210c-f620-4f5e-b9fa-9f26438e8b7d';      -- Cuatro Vientos
  b uuid := '0b000ea4-f65f-4949-bf5d-a06b5b14f78f';      -- Prueba B
  admin_a uuid := '17735896-4061-41f7-b1de-878f4d3ddb6f';
  prod_a  uuid := '0afb1de3-0ddd-4cec-8105-c781952d5cee';
  oper_a  uuid := '600a68b2-23f2-4a65-bc8e-0bac8bcb9b64';
  admin_b uuid := '44e4c261-a622-4295-b679-558d3bc6fe8f';
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
  update organizations set slug = 'qa-b8a6e2f8ec00-cuatro-vientos-mezcal' where id = a;
  return next is((select organization_id from organization_slug_history where slug = 'qa-b8a6e2f8ec00-cuatro-vientos'), a,
                 'el slug viejo queda en el historial');
  return next is((select redirect_to from portal_branding('qa-b8a6e2f8ec00-cuatro-vientos')), 'qa-b8a6e2f8ec00-cuatro-vientos-mezcal',
                 'el portal del slug viejo redirige al nuevo');
  return next is((select logo_path from portal_branding('qa-b8a6e2f8ec00-cuatro-vientos-mezcal')), a::text || '/logo.png',
                 'el portal publica la ruta del logo');
  perform pg_temp.como(admin_b);
  return next throws_like(
    format($q$update organizations set slug = 'qa-b8a6e2f8ec00-cuatro-vientos' where id = '%s'$q$, b),
    '%', 'nadie más puede tomar un slug retirado');

  -- ── Primer arranque: carga inicial en tanque y tina ──────────────────
  perform pg_temp.como(admin_a);
  v_lot := registrar_entrada(a, 'a4fb5222-b26c-42a2-b94a-e4e47ef2a86b', now(), 'granel', v_tanque, 300, 47);
  return next is(registrar_entrada(a, 'a4fb5222-b26c-42a2-b94a-e4e47ef2a86b', now(), 'granel', v_tanque, 300, 47), v_lot,
                 'reintentar con la misma idempotency_key no duplica');
  perform pg_temp.superuser();   -- resource_balance es interna (sin execute para authenticated)
  return next is(resource_balance(a, v_tanque), 300::numeric, 'la carga inicial deja 300 L en el tanque nuevo');
  return next is((select origin from lots where id = v_lot), 'carga_inicial'::lot_origin, 'el lote nace como carga inicial');
  return next is((select count(*) from lots where organization_id = a and operation_id in
                    (select id from operations where organization_id = a and idempotency_key = 'a4fb5222-b26c-42a2-b94a-e4e47ef2a86b')),
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
