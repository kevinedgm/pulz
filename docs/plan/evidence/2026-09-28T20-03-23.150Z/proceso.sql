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
-- tomas.h → 'tomas-2026' · dueña B → 'qa-dadd1761b07f-prueba-b-2026' · admin → 'pulz-2026'
-- ---------------------------------------------------------------------
insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
                        raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
                        confirmation_token, recovery_token, email_change_token_new, email_change) values
  ('00000000-0000-0000-0000-000000000000', 'ded5b9de-d4a6-4973-8270-d2c0f772041a', 'authenticated', 'authenticated', 'qa-dadd1761b07f-tu@pulz.mx',
   extensions.crypt('pulz-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '70f1ff64-7885-462f-b439-d50e85d40722', 'authenticated', 'authenticated', 'qa-dadd1761b07f-benito@cuatrovientos.mx',
   extensions.crypt('benito-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '48ec7074-20f8-4da8-9503-d2abda91a566', 'authenticated', 'authenticated', 'qa-dadd1761b07f-aurelia@1707d06f-108d-4f3c-b420-7756f58b6062.usuarios.pulz.mx',
   extensions.crypt('aurelia-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '185833e6-981d-47b1-aa3c-e1b8dd2469ce', 'authenticated', 'authenticated', 'qa-dadd1761b07f-tomas.h@1707d06f-108d-4f3c-b420-7756f58b6062.usuarios.pulz.mx',
   extensions.crypt('tomas-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', 'f108aa54-ece2-4ab9-a9c5-d97162dca24e', 'authenticated', 'authenticated', 'qa-dadd1761b07f-duena@pruebab.mx',
   extensions.crypt('qa-dadd1761b07f-prueba-b-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '');

insert into profiles (id, full_name) values
  ('ded5b9de-d4a6-4973-8270-d2c0f772041a', 'Admin PULZ'),
  ('70f1ff64-7885-462f-b439-d50e85d40722', 'Benito Cruz'),
  ('48ec7074-20f8-4da8-9503-d2abda91a566', 'Aurelia Santiago'),
  ('185833e6-981d-47b1-aa3c-e1b8dd2469ce', 'Tomás Hernández'),
  ('f108aa54-ece2-4ab9-a9c5-d97162dca24e', 'Dueña Prueba B');

insert into platform_admins (user_id) values ('ded5b9de-d4a6-4973-8270-d2c0f772041a');

-- Planes (§14, §18 #2 y #3)
-- Fixture: reutiliza plans canónica, sin modificarla.
-- Fixture: reutiliza plan_limits canónica, sin modificarla.
-- Fixture: reutiliza plan_features canónica, sin modificarla.

-- Empresas
insert into organizations (id, name, slug, state, brand_color, logo_path, welcome_message, created_by) values
  ('1707d06f-108d-4f3c-b420-7756f58b6062', 'Mezcal Cuatro Vientos', 'qa-dadd1761b07f-cuatro-vientos', 'Oaxaca', '#7A3E1D', null, 'Registro de producción del palenque', '70f1ff64-7885-462f-b439-d50e85d40722'),
  ('23ed64b3-0562-4c95-8489-385fb7b59c3a', 'Palenque Prueba B', 'qa-dadd1761b07f-prueba-b', 'Oaxaca', '#173F87', null, 'Empresa de prueba', 'f108aa54-ece2-4ab9-a9c5-d97162dca24e');
insert into organization_slug_history (slug, organization_id, retired_at, retired_by) values
  ('qa-dadd1761b07f-mezcal-cuatro-vientos', '1707d06f-108d-4f3c-b420-7756f58b6062', '2026-09-02 09:00:00-06', '70f1ff64-7885-462f-b439-d50e85d40722');
insert into organization_members (organization_id, user_id, role, status, username, must_change_password) values
  ('1707d06f-108d-4f3c-b420-7756f58b6062', '70f1ff64-7885-462f-b439-d50e85d40722', 'admin', 'activo', null, false),
  ('1707d06f-108d-4f3c-b420-7756f58b6062', '48ec7074-20f8-4da8-9503-d2abda91a566', 'productor', 'activo', 'aurelia', false),
  ('1707d06f-108d-4f3c-b420-7756f58b6062', '185833e6-981d-47b1-aa3c-e1b8dd2469ce', 'operador', 'activo', 'tomas.h', true),
  ('23ed64b3-0562-4c95-8489-385fb7b59c3a', 'f108aa54-ece2-4ab9-a9c5-d97162dca24e', 'admin', 'activo', null, false);
insert into member_invitations (id, organization_id, user_id, token_hash, expires_at, used_at, created_by) values
  ('1dcfa09d-756c-4f42-b289-208691e65bcb', '1707d06f-108d-4f3c-b420-7756f58b6062', '185833e6-981d-47b1-aa3c-e1b8dd2469ce', 'qa-dadd1761b07f:SIMULADO', '2026-09-05 10:00:00-06', null, '70f1ff64-7885-462f-b439-d50e85d40722');
insert into login_throttle (user_id, failed_count, last_failed_at, locked_until) values
  ('185833e6-981d-47b1-aa3c-e1b8dd2469ce', 3, '2026-09-03 07:12:00-06', null);
insert into organization_settings (organization_id, record_puntas, measurement_mode, warn_mixed_second_pass, fermentation_expected_days, measurement_reminder_hour, default_folio_decision) values
  ('1707d06f-108d-4f3c-b420-7756f58b6062', false, 'minimo', true, 7, 9, 'conservar'),
  ('23ed64b3-0562-4c95-8489-385fb7b59c3a', false, 'minimo', true, 7, 9, 'conservar');
insert into subscriptions (organization_id, plan_id, status, current_period_end) values
  ('1707d06f-108d-4f3c-b420-7756f58b6062', 'edd15bcf-ad82-5684-a2e7-d85db401885b', 'prueba', '2026-10-15 00:00:00-06'),
  ('23ed64b3-0562-4c95-8489-385fb7b59c3a', 'ee35d6fd-b4d6-56d6-b7b4-61cb81932b21', 'gratis', null);

-- ---------------------------------------------------------------------
-- Plantillas de plataforma (§10.2.1)
-- ---------------------------------------------------------------------
-- Fixture: reutiliza catalog_item_templates canónica, sin modificarla.
-- Fixture: reutiliza movement_concept_templates canónica, sin modificarla.
-- Fixture: reutiliza species_templates canónica, sin modificarla.

select seed_organization_catalogs('1707d06f-108d-4f3c-b420-7756f58b6062');
select seed_organization_catalogs('23ed64b3-0562-4c95-8489-385fb7b59c3a');

-- Lo propio de Cuatro Vientos y lo que oculta (§10.2.4)
insert into catalog_items (id, organization_id, template_id, catalog, name, sort_order, created_by) values
  ('d0baf311-885a-434c-9bfb-ca70154899c9', '1707d06f-108d-4f3c-b420-7756f58b6062', null, 'tipo_alambique', 'Refrescadera de cobre', 100, '70f1ff64-7885-462f-b439-d50e85d40722');
insert into movement_concepts (id, organization_id, template_id, direction, name, source_lot, creates_lot, asks_result, asks_counterparty, sort_order, created_by) values
  ('68eafc6c-8eb6-46b4-a499-b162d9094cdc', '1707d06f-108d-4f3c-b420-7756f58b6062', null, 'salida', 'Regalo a cliente', 'no_aplica', false, false, true, 100, '70f1ff64-7885-462f-b439-d50e85d40722');
update catalog_items set active = false
 where organization_id = '1707d06f-108d-4f3c-b420-7756f58b6062'
   and template_id in ('5c985133-23d9-50fa-a252-6ff6b5b74134', 'b1fce67a-21bf-50a7-9344-fdf29eb5331e');
update movement_concepts set active = false
 where organization_id = '1707d06f-108d-4f3c-b420-7756f58b6062'
   and template_id = '8b7f6579-99ef-549e-b427-b1d4d8bea9da';

-- ---------------------------------------------------------------------
-- Ayudas de la semilla (temporales; mueren con la sesión). security definer
-- para que resuelvan ids aunque el rol activo sea 'authenticated'.
-- ---------------------------------------------------------------------
create function pg_temp.seed_a() returns uuid language sql immutable as $$ select '1707d06f-108d-4f3c-b420-7756f58b6062'::uuid $$;
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
  ('3af59185-b3af-4a62-a9fc-57b62cf5fef7', pg_temp.seed_a(), 'Loma del Toro', 'Santiago Matatlán', 'Familia Cruz');
insert into suppliers (id, organization_id, name, type_item_id) values
  ('4f94e9b7-d01f-40ef-b8ba-f19f872f5085', pg_temp.seed_a(), 'Magueyes Don Pedro', pg_temp.seed_cat('640b537d-bf52-5c4b-b407-a5f4fb7c5800')),
  ('1d1999cb-d87f-4f1b-8a26-52152f633330', pg_temp.seed_a(), 'Destilados Hermanos Luna', pg_temp.seed_cat('bb234638-3c78-56cd-9f41-2fb38182f181'));
insert into supplies (id, organization_id, name, unit_item_id) values
  ('5733cbee-a083-4974-be12-a9772e021ddc', pg_temp.seed_a(), 'Pulque como inóculo', pg_temp.seed_cat('bc6f104d-2841-5b36-b492-76b36becb172'));
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy, liquid_class) values
  ('1a0e1a2d-61a8-487a-8813-d736c2286eef', pg_temp.seed_a(), 'horno', 'Horno 1', pg_temp.seed_cat('d53ba2da-cada-5215-804a-ff304d569f97'), 10000, 'kg', 'libre', null),
  ('05169f75-1d1e-46dd-8acd-e4d93a817ff9', pg_temp.seed_a(), 'molino', 'Tahona', pg_temp.seed_cat('60285283-d000-52f0-95da-d2b2e6d70fa1'), null, 'kg', 'libre', null),
  ('ffd5a8f9-2cee-44e4-859f-b757d9575a45', pg_temp.seed_a(), 'tina', 'Tina 1', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('14230d34-fbcc-447f-8451-7991d0098f9b', pg_temp.seed_a(), 'tina', 'Tina 2', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('20cce8dd-b815-440b-933b-21060503681c', pg_temp.seed_a(), 'tina', 'Tina 3', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('59ff2060-55bc-4254-b609-8e6641687935', pg_temp.seed_a(), 'alambique', 'Alambique 1', pg_temp.seed_cat('af73010e-53f2-5769-b3b1-6cda154e665e'), 300, 'L', 'estricta', null),
  ('d9a6de6d-33d4-4200-a537-bfc4740be2c2', pg_temp.seed_a(), 'alambique', 'Alambique 2', 'd0baf311-885a-434c-9bfb-ca70154899c9', 250, 'L', 'estricta', null),
  ('56636274-47de-43d4-ba3e-452dc71a3e12', pg_temp.seed_a(), 'colector', 'Colector mezcal', pg_temp.seed_cat('2cd7e70b-6246-543e-8f67-23743fefdf95'), 60, 'L', 'flexible', 'mezcal'),
  ('ef65a396-a0a3-4b0f-900b-eb22e1f4818c', pg_temp.seed_a(), 'colector', 'Colector ordinario', pg_temp.seed_cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'ordinario'),
  ('fca2401e-fc24-4d19-ae97-6693ccfe7dbf', pg_temp.seed_a(), 'colector', 'Colector colas', pg_temp.seed_cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'colas'),
  ('a9fc7ae4-c1f7-4dea-a0ec-1e3c97e02c50', pg_temp.seed_a(), 'tanque', 'Tanque 1', pg_temp.seed_cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1000, 'L', 'flexible', null),
  ('6f212381-1fcc-444c-9055-02d4c8c04280', pg_temp.seed_a(), 'tanque', 'Tanque 2', pg_temp.seed_cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1500, 'L', 'flexible', null);

-- Palenque Prueba B: lo mínimo para probar aislamiento
insert into predios (id, organization_id, name, municipality) values
  ('0983fdb5-8992-4234-ad7c-97713a685b44', '23ed64b3-0562-4c95-8489-385fb7b59c3a', 'Predio B', 'Ejutla');
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy) values
  ('9112e7d8-da41-49e0-bd36-f9071b67e7b9', '23ed64b3-0562-4c95-8489-385fb7b59c3a', 'tina', 'Tina B1',
   (select id from catalog_items where organization_id = '23ed64b3-0562-4c95-8489-385fb7b59c3a' and template_id = 'b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1000, 'L', 'flexible');

-- =====================================================================
-- Cuatro Vientos: la producción, POR RPC, en orden cronológico
-- =====================================================================

-- 2026-09-01 · Benito: lo que ya había en el Tanque 2 (carga inicial)
select pg_temp.seed_como('70f1ff64-7885-462f-b439-d50e85d40722');
select registrar_entrada(pg_temp.seed_a(), '8c21b006-8f5a-4da5-9dd0-fb80df31c2e1', '2026-09-01 10:15:00-06',
  'granel', pg_temp.seed_res('Tanque 2'), 600, 44.2, 'mezcal', 'carga_inicial',
  p_concepto => pg_temp.seed_con('255e79f1-12b3-5969-8453-e40623275559'),
  p_nota => 'Lo que ya había en el tanque al empezar', p_folio => 'G-INI-01');

-- 2026-09-01 · Aurelia: la Tina 3 ya fermentaba
select pg_temp.seed_como('48ec7074-20f8-4da8-9503-d2abda91a566');
select registrar_entrada(pg_temp.seed_a(), '5671b544-ff70-4d88-8a0a-d4616e214eca', '2026-09-01 10:40:00-06',
  'fermentado', pg_temp.seed_res('Tina 3'), 1300, null, null, 'carga_inicial',
  p_nota => 'Tina que ya fermentaba', p_folio => 'FER-T3-INI');

-- 2026-09-02 · Aurelia: recepción de maguey
select registrar_recepcion_maguey(pg_temp.seed_a(), '61703520-91f9-443d-9961-0df04712016b', '2026-09-02 07:30:00-06',
  8000, pg_temp.seed_esp('67a96efd-2c72-528e-8682-d144fe1f802c'), '3af59185-b3af-4a62-a9fc-57b62cf5fef7',
  '4f94e9b7-d01f-40ef-b8ba-f19f872f5085', 132, 'Piñas de 8 años, buen tamaño', 'MAG-001');

-- 2026-09-02 · Horneado (la simulación lo abría Tomás; §11.1 lo reserva a
-- admin/productor, así que lo abre Aurelia — docs/DECISIONES.md)
select abrir_horneado(pg_temp.seed_a(), '69e4c7c9-a707-435c-b232-59b37220b604', '2026-09-02 12:00:00-06',
  pg_temp.seed_res('Horno 1'), array[pg_temp.seed_lot('MAG-001')], array[8000::numeric], p_folio => 'HOR-001');
-- 2026-09-06 · Aurelia cierra: 6,200 kg de agave cocido
select cerrar_horneado(pg_temp.seed_a(), 'd69ee3db-e9d8-4327-bc0b-3eebb46b33a9', '2026-09-06 08:00:00-06',
  pg_temp.seed_hor('HOR-001'), 6200, 'Leña de encino', p_folio => 'AC-001');

-- 2026-09-07 · Aurelia: formulación repartida a Tina 1 y Tina 2
select registrar_formulacion(pg_temp.seed_a(), '2e5be9b4-fdef-4677-8e51-e3c7145f1267', '2026-09-07 09:00:00-06',
  pg_temp.seed_res('Tahona'), array[pg_temp.seed_lot('AC-001')], array[6200::numeric], 1900,
  array[pg_temp.seed_res('Tina 1'), pg_temp.seed_res('Tina 2')], array[1400::numeric, 1400::numeric],
  array['5733cbee-a083-4974-be12-a9772e021ddc'::uuid], array[20::numeric],
  'Tahona con mula', null, 'F-001', array['FER-T1-001', 'FER-T2-001']);

-- Mediciones diarias (escala de actividad 1–6, §18 #1; la simulación traía 7 y 8)
-- Tina 1
select pg_temp.seed_como('185833e6-981d-47b1-aa3c-e1b8dd2469ce');
select registrar_medicion(pg_temp.seed_a(), '682396af-c64a-4880-940c-153d0e056efe', '2026-09-08 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 1, 'minimo', 4,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.5,12.0]::numeric[]);
select pg_temp.seed_como('48ec7074-20f8-4da8-9503-d2abda91a566');
select registrar_medicion(pg_temp.seed_a(), '86360ca8-cbba-4861-9ac6-e9d3a1e593e5', '2026-09-09 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.0,9.5]::numeric[]);
select pg_temp.seed_como('185833e6-981d-47b1-aa3c-e1b8dd2469ce');
select registrar_medicion(pg_temp.seed_a(), '9244b68f-deda-4d48-b24a-79238e823bb7', '2026-09-10 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.5,6.0]::numeric[]);
select pg_temp.seed_como('48ec7074-20f8-4da8-9503-d2abda91a566');
select registrar_medicion(pg_temp.seed_a(), 'aa909a97-2277-482a-918e-0b6f2094c9eb', '2026-09-11 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 4, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.5,3.5]::numeric[]);
select pg_temp.seed_como('185833e6-981d-47b1-aa3c-e1b8dd2469ce');
select registrar_medicion(pg_temp.seed_a(), '62b04b72-81ce-4cd0-b7b7-2e54f15daee3', '2026-09-12 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 5, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.0,1.5]::numeric[]);
-- Tina 2
select registrar_medicion(pg_temp.seed_a(), 'd283996f-e463-4c9f-bf5d-853ed91b431a', '2026-09-08 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 1, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.0,12.2]::numeric[]);
select registrar_medicion(pg_temp.seed_a(), '4230bd4e-dbdd-4cec-9c16-c7a55f3a37c9', '2026-09-09 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.5,10.1]::numeric[]);
select registrar_medicion(pg_temp.seed_a(), '40afb49a-1180-4c04-98ad-f15c5abf718d', '2026-09-10 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.0,7.4]::numeric[]);

-- 2026-09-12 · Aurelia declara lista la Tina 1
select pg_temp.seed_como('48ec7074-20f8-4da8-9503-d2abda91a566');
select declarar_tina_lista(pg_temp.seed_a(), 'b0778b5f-e189-4d19-a754-20a1ca39603a', '2026-09-12 17:00:00-06',
  pg_temp.seed_cyc('Tina 1'), 'Día 5: ya no burbujea, sabor seco');

-- 2026-09-13 · Tomás: dos corridas de 1ª pasada desde la Tina 1
select pg_temp.seed_como('185833e6-981d-47b1-aa3c-e1b8dd2469ce');
select abrir_corrida(pg_temp.seed_a(), '8fead351-8866-4ead-a14d-b4eb11301c02', '2026-09-13 06:00:00-06',
  pg_temp.seed_res('Alambique 1'), 'primera', array[pg_temp.seed_res('Tina 1')], array[pg_temp.seed_lot('FER-T1-001')], array[290::numeric],
  p_folio => 'DES-001');
select registrar_corte(pg_temp.seed_a(), 'ffd62048-efa7-45ab-8809-f4d6a1d6fc4a', '2026-09-13 08:00:00-06', pg_temp.seed_run('DES-001'), 'mezcal', 8, 51.0, pg_temp.seed_res('Colector mezcal'), p_folio => 'MEZ-001');
select registrar_corte(pg_temp.seed_a(), '926e3e37-f9f7-4b8b-b1fa-d2d315cacaf0', '2026-09-13 10:00:00-06', pg_temp.seed_run('DES-001'), 'ordinario', 40, 24.0, pg_temp.seed_res('Colector ordinario'), p_folio => 'ORD-001');
select registrar_corte(pg_temp.seed_a(), 'd6b9eab5-7d58-4628-a01c-6e5a054ff473', '2026-09-13 12:00:00-06', pg_temp.seed_run('DES-001'), 'colas', 12, 9.0, pg_temp.seed_res('Colector colas'), p_folio => 'COL-001');
select cerrar_corrida(pg_temp.seed_a(), '041a60a0-521e-43e2-b3c9-1730fb278c9d', '2026-09-13 14:00:00-06', pg_temp.seed_run('DES-001'));

select abrir_corrida(pg_temp.seed_a(), 'efcdfc3a-481a-4422-a521-9aab24fb25a7', '2026-09-13 06:00:00-06',
  pg_temp.seed_res('Alambique 2'), 'primera', array[pg_temp.seed_res('Tina 1')], array[pg_temp.seed_lot('FER-T1-001')], array[240::numeric],
  p_folio => 'DES-002');
select registrar_corte(pg_temp.seed_a(), '6fbf1025-633e-472a-bd7a-fbf86e3e2073', '2026-09-13 08:00:00-06', pg_temp.seed_run('DES-002'), 'mezcal', 6, 50.0, pg_temp.seed_res('Colector mezcal'));
select registrar_corte(pg_temp.seed_a(), '4436998c-08d6-487c-9f7b-d88c106dd977', '2026-09-13 10:00:00-06', pg_temp.seed_run('DES-002'), 'ordinario', 34, 23.0, pg_temp.seed_res('Colector ordinario'));
select registrar_corte(pg_temp.seed_a(), '00964079-c313-4da9-b208-d7fe258ade6e', '2026-09-13 12:00:00-06', pg_temp.seed_run('DES-002'), 'colas', 10, 8.0, pg_temp.seed_res('Colector colas'));
select cerrar_corrida(pg_temp.seed_a(), 'e6a63362-4402-4301-b40a-c95528d495ec', '2026-09-13 14:00:00-06', pg_temp.seed_run('DES-002'));

-- 2026-09-15 · Tomás: 2ª pasada con ordinario y colas juntos (aviso + nota)
select abrir_corrida(pg_temp.seed_a(), '196fee78-bc07-499b-ab00-6cc7a847838c', '2026-09-15 06:00:00-06',
  pg_temp.seed_res('Alambique 1'), 'segunda',
  array[pg_temp.seed_res('Colector ordinario'), pg_temp.seed_res('Colector colas')],
  array[pg_temp.seed_lot('ORD-001'), pg_temp.seed_lot('COL-001')], array[74::numeric, 22::numeric],
  'Había olla libre y poca cola; se juntó con el ordinario', 'DES-003');
select registrar_corte(pg_temp.seed_a(), 'd702786f-bf64-4db9-a75d-04020b641f6c', '2026-09-15 08:00:00-06', pg_temp.seed_run('DES-003'), 'mezcal', 26, 52.5, pg_temp.seed_res('Colector mezcal'));
select registrar_corte(pg_temp.seed_a(), 'c920a12a-46cc-436f-8c9a-4fb13506553e', '2026-09-15 10:00:00-06', pg_temp.seed_run('DES-003'), 'colas', 16, 10.0, pg_temp.seed_res('Colector colas'), p_folio => 'COL-002');
select cerrar_corrida(pg_temp.seed_a(), 'e7bbdbe1-7f68-4719-9bdd-a895af58aa53', '2026-09-15 14:00:00-06', pg_temp.seed_run('DES-003'));

-- 2026-09-16 · Aurelia: el mezcal del colector pasa a granel con folio nuevo
select pg_temp.seed_como('48ec7074-20f8-4da8-9503-d2abda91a566');
select transferir(pg_temp.seed_a(), '7ebe230b-c46b-40e2-ad14-2bbe5d963b21', '2026-09-16 09:00:00-06',
  pg_temp.seed_res('Colector mezcal'), pg_temp.seed_res('Tanque 1'), pg_temp.seed_lot('MEZ-001'), 40, 51.6, 'renombrar', 'G-2609-01');
-- Agua para bajar grado: 4 L, declara 43.8 L (contracción) y 47.0 %
select registrar_movimiento_granel(pg_temp.seed_a(), 'bedf3def-2e16-464c-a2d7-bef6380d8151', '2026-09-16 11:00:00-06',
  pg_temp.seed_con('66a151e2-9a2c-58be-ad4a-b117f1ddb717'), pg_temp.seed_res('Tanque 1'), 4,
  p_lote => pg_temp.seed_lot('G-2609-01'), p_resultado_l => 43.8, p_resultado_abv => 47.0);

-- 2026-09-17 · Benito: puntas guardadas (sin lote) al Tanque 2
select pg_temp.seed_como('70f1ff64-7885-462f-b439-d50e85d40722');
select registrar_movimiento_granel(pg_temp.seed_a(), '3ecce857-39fb-4f25-9f97-796772a4df01', '2026-09-17 10:00:00-06',
  pg_temp.seed_con('f21aaad8-2ef6-556b-be55-64aa94431ab6'), pg_temp.seed_res('Tanque 2'), 2,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_resultado_l => 602, p_resultado_abv => 44.6, p_abv => 68.0,
  p_nota => 'Puntas guardadas de corridas de agosto, sin lote');
-- 2026-09-18 · Benito: unión de G-2609-01 (Tanque 1) con G-INI-01 (Tanque 2), se conserva el folio mayor
select registrar_movimiento_granel(pg_temp.seed_a(), '5e4fa122-56ab-4a9e-b71a-dfcc14026f55', '2026-09-18 09:30:00-06',
  pg_temp.seed_con('df427d88-600e-550e-a097-8ffe4f4dd556'), pg_temp.seed_res('Tanque 2'), 43.8,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_lote_origen => pg_temp.seed_lot('G-2609-01'), p_recurso_origen => pg_temp.seed_res('Tanque 1'),
  p_resultado_l => 645.8, p_resultado_abv => 44.9, p_decision => 'conservar', p_nota => 'Se conserva el folio del lote mayor');
-- 2026-09-19 · Benito: compra de granel al Tanque 1
select registrar_movimiento_granel(pg_temp.seed_a(), '6aa8caf0-e7c3-4783-9fcf-e5c851d3b9df', '2026-09-19 12:00:00-06',
  pg_temp.seed_con('688430a9-cd2f-5bae-add2-c59bc543d911'), pg_temp.seed_res('Tanque 1'), 250,
  p_resultado_l => 250, p_resultado_abv => 46.0, p_abv => 46.0, p_folio_nuevo => 'G-COMPRA-01',
  p_contraparte => 'Destilados Hermanos Luna', p_documento => 'Remisión 0452',
  p_proveedor => '1d1999cb-d87f-4f1b-8a26-52152f633330', p_especie => pg_temp.seed_esp('67a96efd-2c72-528e-8682-d144fe1f802c'),
  p_predio_declarado => 'Sola de Vega');

-- 2026-09-19 · Aurelia: muestra de laboratorio
select pg_temp.seed_como('48ec7074-20f8-4da8-9503-d2abda91a566');
select registrar_movimiento_granel(pg_temp.seed_a(), 'fadfeca5-7f19-43d1-bbd9-97f09656622a', '2026-09-19 13:00:00-06',
  pg_temp.seed_con('2d62ab89-6a11-558c-8b46-5c4d30aa1607'), pg_temp.seed_res('Tanque 2'), 1,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Laboratorio ficticio de Oaxaca', p_documento => 'Análisis 2026-311');

-- 2026-09-20/22 · Benito: autoconsumo, venta, regalo
select pg_temp.seed_como('70f1ff64-7885-462f-b439-d50e85d40722');
select registrar_movimiento_granel(pg_temp.seed_a(), '95e7f76d-63f7-4b4f-ac97-b63a629b4e9b', '2026-09-20 13:00:00-06',
  pg_temp.seed_con('fa52f92b-de19-5d0c-972c-beb899bb2ccb'), pg_temp.seed_res('Tanque 2'), 2, p_lote => pg_temp.seed_lot('G-INI-01'));
select registrar_movimiento_granel(pg_temp.seed_a(), 'a8875299-1b30-4703-ac1f-cc6fc588b568', '2026-09-22 13:00:00-06',
  pg_temp.seed_con('7b0ca7ca-f8ae-5f33-93d5-f0c174664ec1'), pg_temp.seed_res('Tanque 2'), 300,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.', p_documento => 'Remisión 118');
select registrar_movimiento_granel(pg_temp.seed_a(), '01211f88-07cd-42da-8780-cb446f1f9ac5', '2026-09-22 13:00:00-06',
  '68eafc6c-8eb6-46b4-a499-b162d9094cdc', pg_temp.seed_res('Tanque 2'), 1,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.');

reset role;

-- Evidencia de la compra (los adjuntos no son RPC de §12)
insert into attachments (id, organization_id, operation_id, lot_id, kind_item_id, storage_path, caption) values
  ('4319306c-5eb6-4bd1-93ac-e2e40c55a786', pg_temp.seed_a(),
   (select id from operations where organization_id = pg_temp.seed_a() and idempotency_key = '6aa8caf0-e7c3-4783-9fcf-e5c851d3b9df'),
   pg_temp.seed_lot('G-COMPRA-01'), pg_temp.seed_cat('0522e23b-3b1d-58be-b50c-8a6ed0627c9f'),
   'evidencias/1707d06f-108d-4f3c-b420-7756f58b6062/g-compra-01/remision-0452.jpg', 'Remisión del proveedor');


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
  a uuid := '1707d06f-108d-4f3c-b420-7756f58b6062';      -- Cuatro Vientos
  b uuid := '23ed64b3-0562-4c95-8489-385fb7b59c3a';      -- Prueba B
  admin_a uuid := '70f1ff64-7885-462f-b439-d50e85d40722'; -- Benito
  oper_a  uuid := '185833e6-981d-47b1-aa3c-e1b8dd2469ce'; -- Tomás
  admin_b uuid := 'f108aa54-ece2-4ab9-a9c5-d97162dca24e';
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

  -- Regresión: una unión guarda el grado del aporte en el ledger y el
  -- grado resultante en operations, con EXACTAMENTE la misma fecha.
  return next ok(exists (
    select 1 from operations o join liquid_movements m on m.operation_id = o.id
     where o.organization_id = a and o.result_lot_id = m.lot_id
       and o.result_abv = 44.9 and m.abv = 47.0 and m.movement_type = 'entrada'
  ), 'fixture: aporte 47 y resultado 44.9 coexisten en la misma operación');
  return next is((select d.abv from lot_declared_abv d join lots l on l.id = d.lot_id
                  where d.organization_id = a and l.folio = 'G-INI-01'),
                 44.9::numeric, 'grado vigente prioriza resultado declarado, no grado del aporte');

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
  select id into v_op   from operations where organization_id = a and idempotency_key = '682396af-c64a-4880-940c-153d0e056efe';
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
