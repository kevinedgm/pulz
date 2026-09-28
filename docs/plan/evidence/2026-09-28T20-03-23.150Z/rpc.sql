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
-- tomas.h → 'tomas-2026' · dueña B → 'qa-64334e1a1329-prueba-b-2026' · admin → 'pulz-2026'
-- ---------------------------------------------------------------------
insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
                        raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
                        confirmation_token, recovery_token, email_change_token_new, email_change) values
  ('00000000-0000-0000-0000-000000000000', 'fca0098f-fa5d-4d0f-94e4-3b6cb6763116', 'authenticated', 'authenticated', 'qa-64334e1a1329-tu@pulz.mx',
   extensions.crypt('pulz-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', 'c3cf5aaf-9b89-4929-b575-522e88800bce', 'authenticated', 'authenticated', 'qa-64334e1a1329-benito@cuatrovientos.mx',
   extensions.crypt('benito-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', 'a56b331a-c95f-4f6a-b4ad-f6347cea524e', 'authenticated', 'authenticated', 'qa-64334e1a1329-aurelia@689bf2e9-504f-46ba-b52c-b501cd39e28b.usuarios.pulz.mx',
   extensions.crypt('aurelia-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '51f9c07e-697f-401b-a7a8-203df5f5f486', 'authenticated', 'authenticated', 'qa-64334e1a1329-tomas.h@689bf2e9-504f-46ba-b52c-b501cd39e28b.usuarios.pulz.mx',
   extensions.crypt('tomas-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '3b1b9ff8-f2be-4eb0-a81c-36f440183ee5', 'authenticated', 'authenticated', 'qa-64334e1a1329-duena@pruebab.mx',
   extensions.crypt('qa-64334e1a1329-prueba-b-2026', extensions.gen_salt('bf')), now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '');

insert into profiles (id, full_name) values
  ('fca0098f-fa5d-4d0f-94e4-3b6cb6763116', 'Admin PULZ'),
  ('c3cf5aaf-9b89-4929-b575-522e88800bce', 'Benito Cruz'),
  ('a56b331a-c95f-4f6a-b4ad-f6347cea524e', 'Aurelia Santiago'),
  ('51f9c07e-697f-401b-a7a8-203df5f5f486', 'Tomás Hernández'),
  ('3b1b9ff8-f2be-4eb0-a81c-36f440183ee5', 'Dueña Prueba B');

insert into platform_admins (user_id) values ('fca0098f-fa5d-4d0f-94e4-3b6cb6763116');

-- Planes (§14, §18 #2 y #3)
-- Fixture: reutiliza plans canónica, sin modificarla.
-- Fixture: reutiliza plan_limits canónica, sin modificarla.
-- Fixture: reutiliza plan_features canónica, sin modificarla.

-- Empresas
insert into organizations (id, name, slug, state, brand_color, logo_path, welcome_message, created_by) values
  ('689bf2e9-504f-46ba-b52c-b501cd39e28b', 'Mezcal Cuatro Vientos', 'qa-64334e1a1329-cuatro-vientos', 'Oaxaca', '#7A3E1D', null, 'Registro de producción del palenque', 'c3cf5aaf-9b89-4929-b575-522e88800bce'),
  ('6e70795d-37ce-41f9-88dd-fac83ef63d0a', 'Palenque Prueba B', 'qa-64334e1a1329-prueba-b', 'Oaxaca', '#173F87', null, 'Empresa de prueba', '3b1b9ff8-f2be-4eb0-a81c-36f440183ee5');
insert into organization_slug_history (slug, organization_id, retired_at, retired_by) values
  ('qa-64334e1a1329-mezcal-cuatro-vientos', '689bf2e9-504f-46ba-b52c-b501cd39e28b', '2026-09-02 09:00:00-06', 'c3cf5aaf-9b89-4929-b575-522e88800bce');
insert into organization_members (organization_id, user_id, role, status, username, must_change_password) values
  ('689bf2e9-504f-46ba-b52c-b501cd39e28b', 'c3cf5aaf-9b89-4929-b575-522e88800bce', 'admin', 'activo', null, false),
  ('689bf2e9-504f-46ba-b52c-b501cd39e28b', 'a56b331a-c95f-4f6a-b4ad-f6347cea524e', 'productor', 'activo', 'aurelia', false),
  ('689bf2e9-504f-46ba-b52c-b501cd39e28b', '51f9c07e-697f-401b-a7a8-203df5f5f486', 'operador', 'activo', 'tomas.h', true),
  ('6e70795d-37ce-41f9-88dd-fac83ef63d0a', '3b1b9ff8-f2be-4eb0-a81c-36f440183ee5', 'admin', 'activo', null, false);
insert into member_invitations (id, organization_id, user_id, token_hash, expires_at, used_at, created_by) values
  ('598e1f1b-8cc0-4ac4-95cd-ae032929e186', '689bf2e9-504f-46ba-b52c-b501cd39e28b', '51f9c07e-697f-401b-a7a8-203df5f5f486', 'qa-64334e1a1329:SIMULADO', '2026-09-05 10:00:00-06', null, 'c3cf5aaf-9b89-4929-b575-522e88800bce');
insert into login_throttle (user_id, failed_count, last_failed_at, locked_until) values
  ('51f9c07e-697f-401b-a7a8-203df5f5f486', 3, '2026-09-03 07:12:00-06', null);
insert into organization_settings (organization_id, record_puntas, measurement_mode, warn_mixed_second_pass, fermentation_expected_days, measurement_reminder_hour, default_folio_decision) values
  ('689bf2e9-504f-46ba-b52c-b501cd39e28b', false, 'minimo', true, 7, 9, 'conservar'),
  ('6e70795d-37ce-41f9-88dd-fac83ef63d0a', false, 'minimo', true, 7, 9, 'conservar');
insert into subscriptions (organization_id, plan_id, status, current_period_end) values
  ('689bf2e9-504f-46ba-b52c-b501cd39e28b', 'edd15bcf-ad82-5684-a2e7-d85db401885b', 'prueba', '2026-10-15 00:00:00-06'),
  ('6e70795d-37ce-41f9-88dd-fac83ef63d0a', 'ee35d6fd-b4d6-56d6-b7b4-61cb81932b21', 'gratis', null);

-- ---------------------------------------------------------------------
-- Plantillas de plataforma (§10.2.1)
-- ---------------------------------------------------------------------
-- Fixture: reutiliza catalog_item_templates canónica, sin modificarla.
-- Fixture: reutiliza movement_concept_templates canónica, sin modificarla.
-- Fixture: reutiliza species_templates canónica, sin modificarla.

select seed_organization_catalogs('689bf2e9-504f-46ba-b52c-b501cd39e28b');
select seed_organization_catalogs('6e70795d-37ce-41f9-88dd-fac83ef63d0a');

-- Lo propio de Cuatro Vientos y lo que oculta (§10.2.4)
insert into catalog_items (id, organization_id, template_id, catalog, name, sort_order, created_by) values
  ('eb8575ed-649e-41de-b378-60065711415b', '689bf2e9-504f-46ba-b52c-b501cd39e28b', null, 'tipo_alambique', 'Refrescadera de cobre', 100, 'c3cf5aaf-9b89-4929-b575-522e88800bce');
insert into movement_concepts (id, organization_id, template_id, direction, name, source_lot, creates_lot, asks_result, asks_counterparty, sort_order, created_by) values
  ('8c693b6e-b665-4413-8530-730e2bf0a21b', '689bf2e9-504f-46ba-b52c-b501cd39e28b', null, 'salida', 'Regalo a cliente', 'no_aplica', false, false, true, 100, 'c3cf5aaf-9b89-4929-b575-522e88800bce');
update catalog_items set active = false
 where organization_id = '689bf2e9-504f-46ba-b52c-b501cd39e28b'
   and template_id in ('5c985133-23d9-50fa-a252-6ff6b5b74134', 'b1fce67a-21bf-50a7-9344-fdf29eb5331e');
update movement_concepts set active = false
 where organization_id = '689bf2e9-504f-46ba-b52c-b501cd39e28b'
   and template_id = '8b7f6579-99ef-549e-b427-b1d4d8bea9da';

-- ---------------------------------------------------------------------
-- Ayudas de la semilla (temporales; mueren con la sesión). security definer
-- para que resuelvan ids aunque el rol activo sea 'authenticated'.
-- ---------------------------------------------------------------------
create function pg_temp.seed_a() returns uuid language sql immutable as $$ select '689bf2e9-504f-46ba-b52c-b501cd39e28b'::uuid $$;
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
  ('f6ba98d3-7d99-4260-b4f8-35fb0307d986', pg_temp.seed_a(), 'Loma del Toro', 'Santiago Matatlán', 'Familia Cruz');
insert into suppliers (id, organization_id, name, type_item_id) values
  ('ba004327-352c-4325-adc9-50d9ae86e6e7', pg_temp.seed_a(), 'Magueyes Don Pedro', pg_temp.seed_cat('640b537d-bf52-5c4b-b407-a5f4fb7c5800')),
  ('914a16bc-0484-407e-8c0f-1369b09eb6f8', pg_temp.seed_a(), 'Destilados Hermanos Luna', pg_temp.seed_cat('bb234638-3c78-56cd-9f41-2fb38182f181'));
insert into supplies (id, organization_id, name, unit_item_id) values
  ('42e8972c-557a-4877-8b19-9d73b17a8ae2', pg_temp.seed_a(), 'Pulque como inóculo', pg_temp.seed_cat('bc6f104d-2841-5b36-b492-76b36becb172'));
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy, liquid_class) values
  ('a15d817c-8186-4441-bcaa-768ff0565440', pg_temp.seed_a(), 'horno', 'Horno 1', pg_temp.seed_cat('d53ba2da-cada-5215-804a-ff304d569f97'), 10000, 'kg', 'libre', null),
  ('3f7fef06-2580-4bb7-8d0c-0808e4b92a55', pg_temp.seed_a(), 'molino', 'Tahona', pg_temp.seed_cat('60285283-d000-52f0-95da-d2b2e6d70fa1'), null, 'kg', 'libre', null),
  ('c4a316b6-72f3-48f4-be4d-f93d715af0f3', pg_temp.seed_a(), 'tina', 'Tina 1', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('e981a79a-8078-4099-ad93-855065a11fd6', pg_temp.seed_a(), 'tina', 'Tina 2', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('3b1453e8-61e8-40c5-920e-dea334609603', pg_temp.seed_a(), 'tina', 'Tina 3', pg_temp.seed_cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('3f2c7e05-4875-4e7c-ab31-ebce2a854330', pg_temp.seed_a(), 'alambique', 'Alambique 1', pg_temp.seed_cat('af73010e-53f2-5769-b3b1-6cda154e665e'), 300, 'L', 'estricta', null),
  ('97a0d7b3-1d8c-49f7-bd88-f69bc71f284c', pg_temp.seed_a(), 'alambique', 'Alambique 2', 'eb8575ed-649e-41de-b378-60065711415b', 250, 'L', 'estricta', null),
  ('00f7ceee-54f4-43c1-af16-c04746201eac', pg_temp.seed_a(), 'colector', 'Colector mezcal', pg_temp.seed_cat('2cd7e70b-6246-543e-8f67-23743fefdf95'), 60, 'L', 'flexible', 'mezcal'),
  ('7392bd6e-ec96-4b69-98b6-c77660281a97', pg_temp.seed_a(), 'colector', 'Colector ordinario', pg_temp.seed_cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'ordinario'),
  ('e020c907-9dcd-49b2-b0a3-5d47e895b598', pg_temp.seed_a(), 'colector', 'Colector colas', pg_temp.seed_cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'colas'),
  ('13fbb676-fd39-4905-b4f4-e9c47c806fd9', pg_temp.seed_a(), 'tanque', 'Tanque 1', pg_temp.seed_cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1000, 'L', 'flexible', null),
  ('21a43763-1f79-40fa-95c4-bf1e8bdd7b05', pg_temp.seed_a(), 'tanque', 'Tanque 2', pg_temp.seed_cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1500, 'L', 'flexible', null);

-- Palenque Prueba B: lo mínimo para probar aislamiento
insert into predios (id, organization_id, name, municipality) values
  ('27456933-b9cc-4b1d-abaf-2765ffbc4a20', '6e70795d-37ce-41f9-88dd-fac83ef63d0a', 'Predio B', 'Ejutla');
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy) values
  ('8a6ebe10-3dd4-46c6-8b22-923f5ba82874', '6e70795d-37ce-41f9-88dd-fac83ef63d0a', 'tina', 'Tina B1',
   (select id from catalog_items where organization_id = '6e70795d-37ce-41f9-88dd-fac83ef63d0a' and template_id = 'b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1000, 'L', 'flexible');

-- =====================================================================
-- Cuatro Vientos: la producción, POR RPC, en orden cronológico
-- =====================================================================

-- 2026-09-01 · Benito: lo que ya había en el Tanque 2 (carga inicial)
select pg_temp.seed_como('c3cf5aaf-9b89-4929-b575-522e88800bce');
select registrar_entrada(pg_temp.seed_a(), '5aed7235-14c0-435a-9b59-8469f4bd3397', '2026-09-01 10:15:00-06',
  'granel', pg_temp.seed_res('Tanque 2'), 600, 44.2, 'mezcal', 'carga_inicial',
  p_concepto => pg_temp.seed_con('255e79f1-12b3-5969-8453-e40623275559'),
  p_nota => 'Lo que ya había en el tanque al empezar', p_folio => 'G-INI-01');

-- 2026-09-01 · Aurelia: la Tina 3 ya fermentaba
select pg_temp.seed_como('a56b331a-c95f-4f6a-b4ad-f6347cea524e');
select registrar_entrada(pg_temp.seed_a(), '6365c3aa-9e06-4831-810c-6faa017ea6c8', '2026-09-01 10:40:00-06',
  'fermentado', pg_temp.seed_res('Tina 3'), 1300, null, null, 'carga_inicial',
  p_nota => 'Tina que ya fermentaba', p_folio => 'FER-T3-INI');

-- 2026-09-02 · Aurelia: recepción de maguey
select registrar_recepcion_maguey(pg_temp.seed_a(), '4e6940d6-eda3-41c8-b141-41615a0565f2', '2026-09-02 07:30:00-06',
  8000, pg_temp.seed_esp('67a96efd-2c72-528e-8682-d144fe1f802c'), 'f6ba98d3-7d99-4260-b4f8-35fb0307d986',
  'ba004327-352c-4325-adc9-50d9ae86e6e7', 132, 'Piñas de 8 años, buen tamaño', 'MAG-001');

-- 2026-09-02 · Horneado (la simulación lo abría Tomás; §11.1 lo reserva a
-- admin/productor, así que lo abre Aurelia — docs/DECISIONES.md)
select abrir_horneado(pg_temp.seed_a(), '320b3a1a-8559-4d26-95ca-7cd4d335d537', '2026-09-02 12:00:00-06',
  pg_temp.seed_res('Horno 1'), array[pg_temp.seed_lot('MAG-001')], array[8000::numeric], p_folio => 'HOR-001');
-- 2026-09-06 · Aurelia cierra: 6,200 kg de agave cocido
select cerrar_horneado(pg_temp.seed_a(), '08ef8fc1-9979-450a-8db3-91256ca434f3', '2026-09-06 08:00:00-06',
  pg_temp.seed_hor('HOR-001'), 6200, 'Leña de encino', p_folio => 'AC-001');

-- 2026-09-07 · Aurelia: formulación repartida a Tina 1 y Tina 2
select registrar_formulacion(pg_temp.seed_a(), 'e4a91eff-fda8-4034-bebf-03ce51d73e6d', '2026-09-07 09:00:00-06',
  pg_temp.seed_res('Tahona'), array[pg_temp.seed_lot('AC-001')], array[6200::numeric], 1900,
  array[pg_temp.seed_res('Tina 1'), pg_temp.seed_res('Tina 2')], array[1400::numeric, 1400::numeric],
  array['42e8972c-557a-4877-8b19-9d73b17a8ae2'::uuid], array[20::numeric],
  'Tahona con mula', null, 'F-001', array['FER-T1-001', 'FER-T2-001']);

-- Mediciones diarias (escala de actividad 1–6, §18 #1; la simulación traía 7 y 8)
-- Tina 1
select pg_temp.seed_como('51f9c07e-697f-401b-a7a8-203df5f5f486');
select registrar_medicion(pg_temp.seed_a(), '13407c14-cd9f-4b1d-9ebd-dee8b1515af3', '2026-09-08 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 1, 'minimo', 4,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.5,12.0]::numeric[]);
select pg_temp.seed_como('a56b331a-c95f-4f6a-b4ad-f6347cea524e');
select registrar_medicion(pg_temp.seed_a(), 'a7d162ed-16db-48a1-b255-51998d5f17fe', '2026-09-09 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.0,9.5]::numeric[]);
select pg_temp.seed_como('51f9c07e-697f-401b-a7a8-203df5f5f486');
select registrar_medicion(pg_temp.seed_a(), '13311400-5dbd-4584-bbcd-8400881444b8', '2026-09-10 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.5,6.0]::numeric[]);
select pg_temp.seed_como('a56b331a-c95f-4f6a-b4ad-f6347cea524e');
select registrar_medicion(pg_temp.seed_a(), '4690272d-4cc0-4691-a6be-617e442f1649', '2026-09-11 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 4, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.5,3.5]::numeric[]);
select pg_temp.seed_como('51f9c07e-697f-401b-a7a8-203df5f5f486');
select registrar_medicion(pg_temp.seed_a(), '98ca59ee-6c62-4248-a0d5-eb8401cce8e5', '2026-09-12 08:30:00-06', pg_temp.seed_cyc('Tina 1'), 5, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.0,1.5]::numeric[]);
-- Tina 2
select registrar_medicion(pg_temp.seed_a(), '253bf1b4-a1b1-48ca-b609-5dd1a664e1ff', '2026-09-08 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 1, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.0,12.2]::numeric[]);
select registrar_medicion(pg_temp.seed_a(), '31682148-b7eb-470e-9785-56e02b567f8c', '2026-09-09 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.5,10.1]::numeric[]);
select registrar_medicion(pg_temp.seed_a(), 'e713bb2e-995d-4cb1-bc17-5e2bcca853b9', '2026-09-10 08:30:00-06', pg_temp.seed_cyc('Tina 2'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.0,7.4]::numeric[]);

-- 2026-09-12 · Aurelia declara lista la Tina 1
select pg_temp.seed_como('a56b331a-c95f-4f6a-b4ad-f6347cea524e');
select declarar_tina_lista(pg_temp.seed_a(), '4f480627-4fee-4fda-9433-cb5e6f7c2f83', '2026-09-12 17:00:00-06',
  pg_temp.seed_cyc('Tina 1'), 'Día 5: ya no burbujea, sabor seco');

-- 2026-09-13 · Tomás: dos corridas de 1ª pasada desde la Tina 1
select pg_temp.seed_como('51f9c07e-697f-401b-a7a8-203df5f5f486');
select abrir_corrida(pg_temp.seed_a(), '1d0a4755-10ac-4831-b15b-f51c33716e04', '2026-09-13 06:00:00-06',
  pg_temp.seed_res('Alambique 1'), 'primera', array[pg_temp.seed_res('Tina 1')], array[pg_temp.seed_lot('FER-T1-001')], array[290::numeric],
  p_folio => 'DES-001');
select registrar_corte(pg_temp.seed_a(), 'bcd537e7-f53c-4d5f-8459-074640f90931', '2026-09-13 08:00:00-06', pg_temp.seed_run('DES-001'), 'mezcal', 8, 51.0, pg_temp.seed_res('Colector mezcal'), p_folio => 'MEZ-001');
select registrar_corte(pg_temp.seed_a(), '74822241-1842-4a79-9c64-afd428c29bc9', '2026-09-13 10:00:00-06', pg_temp.seed_run('DES-001'), 'ordinario', 40, 24.0, pg_temp.seed_res('Colector ordinario'), p_folio => 'ORD-001');
select registrar_corte(pg_temp.seed_a(), '3b35233c-ff70-48c7-a212-85c53592b1a7', '2026-09-13 12:00:00-06', pg_temp.seed_run('DES-001'), 'colas', 12, 9.0, pg_temp.seed_res('Colector colas'), p_folio => 'COL-001');
select cerrar_corrida(pg_temp.seed_a(), '10e6bbdb-c04d-4062-b4c1-b425b6784d9a', '2026-09-13 14:00:00-06', pg_temp.seed_run('DES-001'));

select abrir_corrida(pg_temp.seed_a(), '8834d511-0fbd-473b-9d73-3db7a25422d1', '2026-09-13 06:00:00-06',
  pg_temp.seed_res('Alambique 2'), 'primera', array[pg_temp.seed_res('Tina 1')], array[pg_temp.seed_lot('FER-T1-001')], array[240::numeric],
  p_folio => 'DES-002');
select registrar_corte(pg_temp.seed_a(), '37bf3347-24b3-47c6-86d3-b66680b86c0f', '2026-09-13 08:00:00-06', pg_temp.seed_run('DES-002'), 'mezcal', 6, 50.0, pg_temp.seed_res('Colector mezcal'));
select registrar_corte(pg_temp.seed_a(), 'a47632f1-edec-4cb7-a111-cb3de600dc70', '2026-09-13 10:00:00-06', pg_temp.seed_run('DES-002'), 'ordinario', 34, 23.0, pg_temp.seed_res('Colector ordinario'));
select registrar_corte(pg_temp.seed_a(), '6646dad2-0db1-4e33-a0df-c39dd1b2a1e4', '2026-09-13 12:00:00-06', pg_temp.seed_run('DES-002'), 'colas', 10, 8.0, pg_temp.seed_res('Colector colas'));
select cerrar_corrida(pg_temp.seed_a(), '8ef9d0b0-80f6-4916-8f3a-a90bfd477e6f', '2026-09-13 14:00:00-06', pg_temp.seed_run('DES-002'));

-- 2026-09-15 · Tomás: 2ª pasada con ordinario y colas juntos (aviso + nota)
select abrir_corrida(pg_temp.seed_a(), '9e7fa8bf-13ad-45ac-af9c-d2bebe18677b', '2026-09-15 06:00:00-06',
  pg_temp.seed_res('Alambique 1'), 'segunda',
  array[pg_temp.seed_res('Colector ordinario'), pg_temp.seed_res('Colector colas')],
  array[pg_temp.seed_lot('ORD-001'), pg_temp.seed_lot('COL-001')], array[74::numeric, 22::numeric],
  'Había olla libre y poca cola; se juntó con el ordinario', 'DES-003');
select registrar_corte(pg_temp.seed_a(), 'dc83fc88-cea0-4655-96ee-bf040331b2a8', '2026-09-15 08:00:00-06', pg_temp.seed_run('DES-003'), 'mezcal', 26, 52.5, pg_temp.seed_res('Colector mezcal'));
select registrar_corte(pg_temp.seed_a(), 'ec2d4166-5b52-4969-a462-d61c5865d1f5', '2026-09-15 10:00:00-06', pg_temp.seed_run('DES-003'), 'colas', 16, 10.0, pg_temp.seed_res('Colector colas'), p_folio => 'COL-002');
select cerrar_corrida(pg_temp.seed_a(), 'f9fdd198-4468-49e6-9913-26897c0c9c3d', '2026-09-15 14:00:00-06', pg_temp.seed_run('DES-003'));

-- 2026-09-16 · Aurelia: el mezcal del colector pasa a granel con folio nuevo
select pg_temp.seed_como('a56b331a-c95f-4f6a-b4ad-f6347cea524e');
select transferir(pg_temp.seed_a(), '163196b7-bea5-4629-90b4-2b9c8396adfa', '2026-09-16 09:00:00-06',
  pg_temp.seed_res('Colector mezcal'), pg_temp.seed_res('Tanque 1'), pg_temp.seed_lot('MEZ-001'), 40, 51.6, 'renombrar', 'G-2609-01');
-- Agua para bajar grado: 4 L, declara 43.8 L (contracción) y 47.0 %
select registrar_movimiento_granel(pg_temp.seed_a(), 'a8ec7b15-078b-4930-ae6f-ddda4ca28f2c', '2026-09-16 11:00:00-06',
  pg_temp.seed_con('66a151e2-9a2c-58be-ad4a-b117f1ddb717'), pg_temp.seed_res('Tanque 1'), 4,
  p_lote => pg_temp.seed_lot('G-2609-01'), p_resultado_l => 43.8, p_resultado_abv => 47.0);

-- 2026-09-17 · Benito: puntas guardadas (sin lote) al Tanque 2
select pg_temp.seed_como('c3cf5aaf-9b89-4929-b575-522e88800bce');
select registrar_movimiento_granel(pg_temp.seed_a(), '435b526b-62b0-4095-9189-0fb604aa57db', '2026-09-17 10:00:00-06',
  pg_temp.seed_con('f21aaad8-2ef6-556b-be55-64aa94431ab6'), pg_temp.seed_res('Tanque 2'), 2,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_resultado_l => 602, p_resultado_abv => 44.6, p_abv => 68.0,
  p_nota => 'Puntas guardadas de corridas de agosto, sin lote');
-- 2026-09-18 · Benito: unión de G-2609-01 (Tanque 1) con G-INI-01 (Tanque 2), se conserva el folio mayor
select registrar_movimiento_granel(pg_temp.seed_a(), 'c0502f30-a4dd-4f2b-b3af-20d43b3f188f', '2026-09-18 09:30:00-06',
  pg_temp.seed_con('df427d88-600e-550e-a097-8ffe4f4dd556'), pg_temp.seed_res('Tanque 2'), 43.8,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_lote_origen => pg_temp.seed_lot('G-2609-01'), p_recurso_origen => pg_temp.seed_res('Tanque 1'),
  p_resultado_l => 645.8, p_resultado_abv => 44.9, p_decision => 'conservar', p_nota => 'Se conserva el folio del lote mayor');
-- 2026-09-19 · Benito: compra de granel al Tanque 1
select registrar_movimiento_granel(pg_temp.seed_a(), 'eb40d7da-d130-422b-86b6-79d1f3e4c6be', '2026-09-19 12:00:00-06',
  pg_temp.seed_con('688430a9-cd2f-5bae-add2-c59bc543d911'), pg_temp.seed_res('Tanque 1'), 250,
  p_resultado_l => 250, p_resultado_abv => 46.0, p_abv => 46.0, p_folio_nuevo => 'G-COMPRA-01',
  p_contraparte => 'Destilados Hermanos Luna', p_documento => 'Remisión 0452',
  p_proveedor => '914a16bc-0484-407e-8c0f-1369b09eb6f8', p_especie => pg_temp.seed_esp('67a96efd-2c72-528e-8682-d144fe1f802c'),
  p_predio_declarado => 'Sola de Vega');

-- 2026-09-19 · Aurelia: muestra de laboratorio
select pg_temp.seed_como('a56b331a-c95f-4f6a-b4ad-f6347cea524e');
select registrar_movimiento_granel(pg_temp.seed_a(), '4207f165-0402-429b-a245-dd21c862d92a', '2026-09-19 13:00:00-06',
  pg_temp.seed_con('2d62ab89-6a11-558c-8b46-5c4d30aa1607'), pg_temp.seed_res('Tanque 2'), 1,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Laboratorio ficticio de Oaxaca', p_documento => 'Análisis 2026-311');

-- 2026-09-20/22 · Benito: autoconsumo, venta, regalo
select pg_temp.seed_como('c3cf5aaf-9b89-4929-b575-522e88800bce');
select registrar_movimiento_granel(pg_temp.seed_a(), 'aa9fdba7-dac7-4cc9-815a-3cd16be4a1d1', '2026-09-20 13:00:00-06',
  pg_temp.seed_con('fa52f92b-de19-5d0c-972c-beb899bb2ccb'), pg_temp.seed_res('Tanque 2'), 2, p_lote => pg_temp.seed_lot('G-INI-01'));
select registrar_movimiento_granel(pg_temp.seed_a(), 'fe16417a-05bf-414d-883c-8c6590072146', '2026-09-22 13:00:00-06',
  pg_temp.seed_con('7b0ca7ca-f8ae-5f33-93d5-f0c174664ec1'), pg_temp.seed_res('Tanque 2'), 300,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.', p_documento => 'Remisión 118');
select registrar_movimiento_granel(pg_temp.seed_a(), '7adc109f-48dd-41fc-9f11-3a2402bda257', '2026-09-22 13:00:00-06',
  '8c693b6e-b665-4413-8530-730e2bf0a21b', pg_temp.seed_res('Tanque 2'), 1,
  p_lote => pg_temp.seed_lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.');

reset role;

-- Evidencia de la compra (los adjuntos no son RPC de §12)
insert into attachments (id, organization_id, operation_id, lot_id, kind_item_id, storage_path, caption) values
  ('ff125ef2-0c75-435e-8907-02d78c975f0a', pg_temp.seed_a(),
   (select id from operations where organization_id = pg_temp.seed_a() and idempotency_key = 'eb40d7da-d130-422b-86b6-79d1f3e4c6be'),
   pg_temp.seed_lot('G-COMPRA-01'), pg_temp.seed_cat('0522e23b-3b1d-58be-b50c-8a6ed0627c9f'),
   'evidencias/689bf2e9-504f-46ba-b52c-b501cd39e28b/g-compra-01/remision-0452.jpg', 'Remisión del proveedor');


-- pgTAP · Comandos (RPC) — PULZ_MAESTRO.md §12, §16 Fase 2.
-- Se corre igual que el de aislamiento (sin Docker):
--     supabase db query --linked -f supabase/tests/rpc.test.sql
-- Todo dentro de una transacción que termina en rollback.
--
-- Parte del estado que deja seed.sql (construido por RPC): comprueba los
-- saldos de §15.1, la idempotencia, cada regla dura, los avisos blandos, la
-- regla de acumulación de colectores, transferir y la conciliación.


create function pg_temp.a() returns uuid language sql immutable as $$ select '689bf2e9-504f-46ba-b52c-b501cd39e28b'::uuid $$;
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
  benito  uuid := 'c3cf5aaf-9b89-4929-b575-522e88800bce';
  aurelia uuid := 'a56b331a-c95f-4f6a-b4ad-f6347cea524e';
  tomas   uuid := '51f9c07e-697f-401b-a7a8-203df5f5f486';
  duena_b uuid := '3b1b9ff8-f2be-4eb0-a81c-36f440183ee5';
  n0 bigint; v uuid; v2 uuid; v_op uuid;
begin
  -- 1) La simulación construida por RPC da exactamente §15.1
  return next results_eq(
    $q$select r.code, l.folio, b.volume_l::numeric(12,3)
         from resource_lot_balances b
         join resources r on r.id = b.resource_id
         join lots l on l.id = b.lot_id
        where b.organization_id = '689bf2e9-504f-46ba-b52c-b501cd39e28b'
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
  select registrar_movimiento_granel(pg_temp.a(), 'aa9fdba7-dac7-4cc9-815a-3cd16be4a1d1', '2026-09-20 13:00:00-06',
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
    format($q$select registrar_medicion('%s', 'f5e6fdad-a834-4532-afd4-109023ba0cf1', now(), '%s', 1::smallint, 'minimo', 3::smallint,
              array['brix']::reading_variable[], array['unica']::reading_zone[], array[1]::smallint[], array[20.0]::numeric[],
              'Brix alto, agua dura')$q$,
           pg_temp.a(), pg_temp.cyc('Tina 2')),
    'blanda: con nota, la medición se registra');
  return next is((select count(*) from operation_warnings w join operations o on o.id = w.operation_id
                   where o.idempotency_key = 'f5e6fdad-a834-4532-afd4-109023ba0cf1' and w.code = 'brix_fuera_rango'), 1::bigint,
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
  select registrar_movimiento_granel(pg_temp.a(), '366e7a83-cfcf-4650-888c-8a1e00077d87', now(),
    pg_temp.con('66a151e2-9a2c-58be-ad4a-b117f1ddb717'), pg_temp.res('Tanque 2'), 10,
    p_lote => pg_temp.lot('G-INI-01'), p_resultado_l => 351.0, p_resultado_abv => 43.0) into v;
  select id into v_op from operations where idempotency_key = '366e7a83-cfcf-4650-888c-8a1e00077d87';
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
