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

begin;

-- ---------------------------------------------------------------------
-- auth.users (mínimo). Tokens como '' y no NULL (§17).
-- ---------------------------------------------------------------------
insert into auth.users (instance_id, id, aud, role, email, email_confirmed_at,
                        raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
                        confirmation_token, recovery_token, email_change_token_new, email_change) values
  ('00000000-0000-0000-0000-000000000000', 'f6d4a253-a9a1-508c-9319-d223fe92949e', 'authenticated', 'authenticated', 'tu@pulz.mx', now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', 'a88771d6-e323-5b36-991d-c42e5880e507', 'authenticated', 'authenticated', 'benito@cuatrovientos.mx', now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '417489a3-9fa1-5914-bbc9-92d5334e9734', 'authenticated', 'authenticated', 'aurelia@b66cf468-47f7-51ee-a8f2-994d907440b9.usuarios.pulz.mx', now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', 'e8e03baf-44a8-5af4-8d68-e0f3e04315a9', 'authenticated', 'authenticated', 'tomas.h@b66cf468-47f7-51ee-a8f2-994d907440b9.usuarios.pulz.mx', now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', 'c0ffee00-0000-4000-8000-0000000000b1', 'authenticated', 'authenticated', 'duena@pruebab.mx', now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '');

insert into profiles (id, full_name) values
  ('f6d4a253-a9a1-508c-9319-d223fe92949e', 'Admin PULZ'),
  ('a88771d6-e323-5b36-991d-c42e5880e507', 'Benito Cruz'),
  ('417489a3-9fa1-5914-bbc9-92d5334e9734', 'Aurelia Santiago'),
  ('e8e03baf-44a8-5af4-8d68-e0f3e04315a9', 'Tomás Hernández'),
  ('c0ffee00-0000-4000-8000-0000000000b1', 'Dueña Prueba B');

insert into platform_admins (user_id) values ('f6d4a253-a9a1-508c-9319-d223fe92949e');

-- Planes (§14, §18 #2 y #3)
insert into plans (id, code, name, price_mxn_month, stripe_price_id) values
  ('ee35d6fd-b4d6-56d6-b7b4-61cb81932b21', 'gratis', 'Gratis', 0, null),
  ('edd15bcf-ad82-5684-a2e7-d85db401885b', 'palenque', 'Palenque', 299, 'price_SIMULADO');
insert into plan_limits (plan_id, limit_key, limit_value) values
  ('ee35d6fd-b4d6-56d6-b7b4-61cb81932b21', 'usuarios', 2),
  ('ee35d6fd-b4d6-56d6-b7b4-61cb81932b21', 'lotes_activos', 15),
  ('ee35d6fd-b4d6-56d6-b7b4-61cb81932b21', 'tinas', 4),
  ('edd15bcf-ad82-5684-a2e7-d85db401885b', 'usuarios', 10),
  ('edd15bcf-ad82-5684-a2e7-d85db401885b', 'lotes_activos', null),
  ('edd15bcf-ad82-5684-a2e7-d85db401885b', 'tinas', null);
insert into plan_features (plan_id, feature_key) values
  ('edd15bcf-ad82-5684-a2e7-d85db401885b', 'exportar_pdf');

-- Empresas
insert into organizations (id, name, slug, state, brand_color, logo_path, welcome_message, created_by) values
  ('b66cf468-47f7-51ee-a8f2-994d907440b9', 'Mezcal Cuatro Vientos', 'cuatro-vientos', 'Oaxaca', '#7A3E1D', null, 'Registro de producción del palenque', 'a88771d6-e323-5b36-991d-c42e5880e507'),
  ('b0000000-0000-4000-8000-0000000000b0', 'Palenque Prueba B', 'prueba-b', 'Oaxaca', '#173F87', null, 'Empresa de prueba', 'c0ffee00-0000-4000-8000-0000000000b1');
insert into organization_slug_history (slug, organization_id, retired_at, retired_by) values
  ('mezcal-cuatro-vientos', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '2026-09-02 09:00:00-06', 'a88771d6-e323-5b36-991d-c42e5880e507');
insert into organization_members (organization_id, user_id, role, status, username, must_change_password) values
  ('b66cf468-47f7-51ee-a8f2-994d907440b9', 'a88771d6-e323-5b36-991d-c42e5880e507', 'admin', 'activo', null, false),
  ('b66cf468-47f7-51ee-a8f2-994d907440b9', '417489a3-9fa1-5914-bbc9-92d5334e9734', 'productor', 'activo', 'aurelia', false),
  ('b66cf468-47f7-51ee-a8f2-994d907440b9', 'e8e03baf-44a8-5af4-8d68-e0f3e04315a9', 'operador', 'activo', 'tomas.h', true),
  ('b0000000-0000-4000-8000-0000000000b0', 'c0ffee00-0000-4000-8000-0000000000b1', 'admin', 'activo', null, false);
insert into member_invitations (id, organization_id, user_id, token_hash, expires_at, used_at, created_by) values
  ('180450f7-0604-5777-9484-0fc21b59c0df', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'e8e03baf-44a8-5af4-8d68-e0f3e04315a9', 'sha256:SIMULADO', '2026-09-05 10:00:00-06', null, 'a88771d6-e323-5b36-991d-c42e5880e507');
insert into login_throttle (user_id, failed_count, last_failed_at, locked_until) values
  ('e8e03baf-44a8-5af4-8d68-e0f3e04315a9', 3, '2026-09-03 07:12:00-06', null);
insert into organization_settings (organization_id, record_puntas, measurement_mode, warn_mixed_second_pass, fermentation_expected_days, measurement_reminder_hour, default_folio_decision) values
  ('b66cf468-47f7-51ee-a8f2-994d907440b9', false, 'minimo', true, 7, 9, 'conservar'),
  ('b0000000-0000-4000-8000-0000000000b0', false, 'minimo', true, 7, 9, 'conservar');
insert into subscriptions (organization_id, plan_id, status, current_period_end) values
  ('b66cf468-47f7-51ee-a8f2-994d907440b9', 'edd15bcf-ad82-5684-a2e7-d85db401885b', 'prueba', '2026-10-15 00:00:00-06'),
  ('b0000000-0000-4000-8000-0000000000b0', 'ee35d6fd-b4d6-56d6-b7b4-61cb81932b21', 'gratis', null);

-- ---------------------------------------------------------------------
-- Plantillas de plataforma (§10.2.1)
-- ---------------------------------------------------------------------
insert into catalog_item_templates (id, catalog, name, sort_order) values
  ('d53ba2da-cada-5215-804a-ff304d569f97', 'tipo_horno', 'Horno cónico de tierra', 10),
  ('c7fe4317-eee8-5851-936c-8ee8401b62fd', 'tipo_horno', 'Horno de mampostería', 20),
  ('5c985133-23d9-50fa-a252-6ff6b5b74134', 'tipo_horno', 'Autoclave', 30),
  ('60285283-d000-52f0-95da-d2b2e6d70fa1', 'tipo_molino', 'Tahona', 10),
  ('6aeb9612-2d23-5668-9c4d-6ea032baccb1', 'tipo_molino', 'Desgarradora mecánica', 20),
  ('df280582-a9a4-5254-8aae-d8811a18800f', 'tipo_molino', 'A mano (mazo)', 30),
  ('b16c7c9d-baa4-59f0-abdb-cc7638918cd2', 'tipo_tina', 'Tina de sabino', 10),
  ('136c642b-becb-5169-ac2e-a27bf9b006f4', 'tipo_tina', 'Tina de pino', 20),
  ('7db30ace-d5f8-5fc0-910a-4c52a7d620a5', 'tipo_tina', 'Tina de piel', 30),
  ('b1fce67a-21bf-50a7-9344-fdf29eb5331e', 'tipo_tina', 'Tina de acero inoxidable', 40),
  ('af73010e-53f2-5769-b3b1-6cda154e665e', 'tipo_alambique', 'Alambique de cobre', 10),
  ('c2be5c85-01a5-5443-8374-d877abb2e071', 'tipo_alambique', 'Olla de barro', 20),
  ('a97347b5-a0f4-569e-86ff-a42705f77f3c', 'tipo_alambique', 'Alambique de acero inoxidable', 30),
  ('2cd7e70b-6246-543e-8f67-23743fefdf95', 'tipo_colector', 'Garrafa de plástico', 10),
  ('66962503-9abc-56c9-b239-065de0a68eba', 'tipo_colector', 'Tambo', 20),
  ('71f28344-d71e-5ec6-9756-05138855186c', 'tipo_colector', 'Contenedor de acero', 30),
  ('51470f4b-702a-5bd5-b38d-90d2a82f9648', 'tipo_tanque', 'Tanque de acero inoxidable', 10),
  ('4232c321-9c07-52b5-9cab-75c3ff07c696', 'tipo_tanque', 'Tanque de plástico grado alimenticio', 20),
  ('f3c7a408-abad-50f1-b662-9cb137985e37', 'tipo_tanque', 'Garrafón de vidrio', 30),
  ('640b537d-bf52-5c4b-b407-a5f4fb7c5800', 'tipo_proveedor', 'Maguey', 10),
  ('bb234638-3c78-56cd-9f41-2fb38182f181', 'tipo_proveedor', 'Granel', 20),
  ('22ad3852-832d-5644-a9cb-8e640e01dee4', 'tipo_proveedor', 'Insumos', 30),
  ('4c852aa8-ced5-5522-a210-1d8c2ab9e403', 'tipo_adjunto', 'Certificado', 10),
  ('5dd028c8-9700-5c02-a7c0-1d079e62b487', 'tipo_adjunto', 'Análisis de laboratorio', 20),
  ('e4966301-96da-5221-8658-fecbb86b2319', 'tipo_adjunto', 'Foto', 30),
  ('0522e23b-3b1d-58be-b50c-8a6ed0627c9f', 'tipo_adjunto', 'Remisión o factura', 40),
  ('2668f647-07d8-5a88-9597-5068d7bed437', 'unidad_insumo', 'kg', 10),
  ('bc6f104d-2841-5b36-b492-76b36becb172', 'unidad_insumo', 'L', 20),
  ('c1c0eead-305b-5d29-bd5f-ba91fd584a71', 'unidad_insumo', 'pieza', 30);
insert into movement_concept_templates (id, direction, name, source_lot, creates_lot, asks_result, asks_counterparty, sort_order) values
  ('66a151e2-9a2c-58be-ad4a-b117f1ddb717', 'entrada', 'Agua para bajar grado', 'no_aplica', false, true, false, 10),
  ('f21aaad8-2ef6-556b-be55-64aa94431ab6', 'entrada', 'Puntas para subir grado', 'opcional', false, true, false, 20),
  ('df427d88-600e-550e-a097-8ffe4f4dd556', 'entrada', 'Unión con otro lote', 'requerido', false, true, false, 30),
  ('688430a9-cd2f-5bae-add2-c59bc543d911', 'entrada', 'Compra de granel', 'no_aplica', true, true, true, 40),
  ('255e79f1-12b3-5969-8453-e40623275559', 'entrada', 'Carga inicial', 'no_aplica', true, true, false, 50),
  ('dfd383f9-01d4-58b3-9334-6624bb5d0a43', 'entrada', 'Ajuste de inventario (+)', 'no_aplica', false, true, false, 60),
  ('7b0ca7ca-f8ae-5f33-93d5-f0c174664ec1', 'salida', 'Venta a granel', 'no_aplica', false, false, true, 70),
  ('8b7f6579-99ef-549e-b427-b1d4d8bea9da', 'salida', 'Envasado', 'no_aplica', false, false, false, 80),
  ('2d62ab89-6a11-558c-8b46-5c4d30aa1607', 'salida', 'Muestra de laboratorio', 'no_aplica', false, false, true, 90),
  ('a65efc9d-4b6c-53c5-b447-6db090589bb9', 'salida', 'Muestra comercial', 'no_aplica', false, false, true, 100),
  ('fa52f92b-de19-5d0c-972c-beb899bb2ccb', 'salida', 'Autoconsumo', 'no_aplica', false, false, false, 110),
  ('b3a02d59-4538-5755-8324-d6853eb0b99e', 'salida', 'Merma', 'no_aplica', false, false, false, 120),
  ('a02083d4-7c78-55ac-896c-ca27e4fece88', 'salida', 'Ajuste de inventario (−)', 'no_aplica', false, false, false, 130);
insert into species_templates (id, common_name, scientific_name) values
  ('67a96efd-2c72-528e-8682-d144fe1f802c', 'Espadín', 'Agave angustifolia'),
  ('eb38c785-7a22-56ba-b9c0-478d969c0b40', 'Tobalá', 'Agave potatorum'),
  ('456cac87-94e1-57a6-90ac-838470b7f0b5', 'Tepeztate', 'Agave marmorata'),
  ('63eaa5a1-cd89-5176-bc54-95236a43f0d3', 'Cuishe', 'Agave karwinskii'),
  ('01921edd-9eb2-58b0-af80-3ce782f8fc28', 'Arroqueño', 'Agave americana var. oaxacensis');

select seed_organization_catalogs('b66cf468-47f7-51ee-a8f2-994d907440b9');
select seed_organization_catalogs('b0000000-0000-4000-8000-0000000000b0');

-- Lo propio de Cuatro Vientos y lo que oculta (§10.2.4)
insert into catalog_items (id, organization_id, template_id, catalog, name, sort_order, created_by) values
  ('29da31b1-2580-5943-873c-afc18495a601', 'b66cf468-47f7-51ee-a8f2-994d907440b9', null, 'tipo_alambique', 'Refrescadera de cobre', 100, 'a88771d6-e323-5b36-991d-c42e5880e507');
insert into movement_concepts (id, organization_id, template_id, direction, name, source_lot, creates_lot, asks_result, asks_counterparty, sort_order, created_by) values
  ('85bbba70-4fc8-5fa2-ba03-af5475085b7a', 'b66cf468-47f7-51ee-a8f2-994d907440b9', null, 'salida', 'Regalo a cliente', 'no_aplica', false, false, true, 100, 'a88771d6-e323-5b36-991d-c42e5880e507');
update catalog_items set active = false
 where organization_id = 'b66cf468-47f7-51ee-a8f2-994d907440b9'
   and template_id in ('5c985133-23d9-50fa-a252-6ff6b5b74134', 'b1fce67a-21bf-50a7-9344-fdf29eb5331e');
update movement_concepts set active = false
 where organization_id = 'b66cf468-47f7-51ee-a8f2-994d907440b9'
   and template_id = '8b7f6579-99ef-549e-b427-b1d4d8bea9da';

-- ---------------------------------------------------------------------
-- Ayudas de la semilla (temporales; mueren con la sesión). security definer
-- para que resuelvan ids aunque el rol activo sea 'authenticated'.
-- ---------------------------------------------------------------------
create function pg_temp.a() returns uuid language sql immutable as $$ select 'b66cf468-47f7-51ee-a8f2-994d907440b9'::uuid $$;
create function pg_temp.cat(t uuid) returns uuid language sql stable security definer as $$
  select id from catalog_items where organization_id = pg_temp.a() and template_id = t $$;
create function pg_temp.con(t uuid) returns uuid language sql stable security definer as $$
  select id from movement_concepts where organization_id = pg_temp.a() and template_id = t $$;
create function pg_temp.esp(t uuid) returns uuid language sql stable security definer as $$
  select id from species where organization_id = pg_temp.a() and template_id = t $$;
create function pg_temp.res(c text) returns uuid language sql stable security definer as $$
  select id from resources where organization_id = pg_temp.a() and code = c $$;
create function pg_temp.lot(f text) returns uuid language sql stable security definer as $$
  select id from lots where organization_id = pg_temp.a() and folio = f $$;
create function pg_temp.cyc(tina text) returns uuid language sql stable security definer as $$
  select c.id from fermentation_cycles c join resources r on r.id = c.tina_id
   where c.organization_id = pg_temp.a() and r.code = tina and c.status <> 'cerrado' $$;
create function pg_temp.hor(f text) returns uuid language sql stable security definer as $$
  select id from roasting_runs where organization_id = pg_temp.a() and folio = f $$;
create function pg_temp.run(f text) returns uuid language sql stable security definer as $$
  select id from distillation_runs where organization_id = pg_temp.a() and folio = f $$;
-- Simula la sesión de un usuario, como lo haría PostgREST
create function pg_temp.como(u uuid) returns void language plpgsql as $$
begin
  execute 'set local role authenticated';
  execute format('set local request.jwt.claims = %L', json_build_object('sub', u, 'role', 'authenticated')::text);
end $$;

-- ---------------------------------------------------------------------
-- Cuatro Vientos: predios, proveedores, insumos, recursos (configuración)
-- ---------------------------------------------------------------------
insert into predios (id, organization_id, name, municipality, owner_name) values
  ('031951e6-6a4f-5abc-8db6-79dfc4a43afa', pg_temp.a(), 'Loma del Toro', 'Santiago Matatlán', 'Familia Cruz');
insert into suppliers (id, organization_id, name, type_item_id) values
  ('d1b5acf3-3fc9-59f3-a7d5-b82846bd82bc', pg_temp.a(), 'Magueyes Don Pedro', pg_temp.cat('640b537d-bf52-5c4b-b407-a5f4fb7c5800')),
  ('3037cfb3-d2c6-5dcd-bb3b-743136024e9c', pg_temp.a(), 'Destilados Hermanos Luna', pg_temp.cat('bb234638-3c78-56cd-9f41-2fb38182f181'));
insert into supplies (id, organization_id, name, unit_item_id) values
  ('1d55b594-99c2-5fe5-8081-4b6874e5a1d5', pg_temp.a(), 'Pulque como inóculo', pg_temp.cat('bc6f104d-2841-5b36-b492-76b36becb172'));
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy, liquid_class) values
  ('1e75aadc-221d-5614-98a3-de77defa5bb6', pg_temp.a(), 'horno', 'Horno 1', pg_temp.cat('d53ba2da-cada-5215-804a-ff304d569f97'), 10000, 'kg', 'libre', null),
  ('d79b3908-f952-5556-a7bd-b55c6a071001', pg_temp.a(), 'molino', 'Tahona', pg_temp.cat('60285283-d000-52f0-95da-d2b2e6d70fa1'), null, 'kg', 'libre', null),
  ('32a9508c-17b3-51b8-9c03-21af27b29ac5', pg_temp.a(), 'tina', 'Tina 1', pg_temp.cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('55226f86-ec84-5917-a97b-23e072c1a7fc', pg_temp.a(), 'tina', 'Tina 2', pg_temp.cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('d4bef388-6b84-5a2d-8471-41c2d4e05e94', pg_temp.a(), 'tina', 'Tina 3', pg_temp.cat('b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1500, 'L', 'flexible', null),
  ('65c839c8-13c0-5ad1-95be-642782860c7c', pg_temp.a(), 'alambique', 'Alambique 1', pg_temp.cat('af73010e-53f2-5769-b3b1-6cda154e665e'), 300, 'L', 'estricta', null),
  ('19a3b420-6f96-5e62-92c7-7f09ba5e15a1', pg_temp.a(), 'alambique', 'Alambique 2', '29da31b1-2580-5943-873c-afc18495a601', 250, 'L', 'estricta', null),
  ('863122f8-e9e7-51ac-b5af-d86f9e56e573', pg_temp.a(), 'colector', 'Colector mezcal', pg_temp.cat('2cd7e70b-6246-543e-8f67-23743fefdf95'), 60, 'L', 'flexible', 'mezcal'),
  ('ffffb8f2-cc46-57d0-89c2-bf433f1657e3', pg_temp.a(), 'colector', 'Colector ordinario', pg_temp.cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'ordinario'),
  ('ea0bebaa-bb90-52be-96f7-ca86a2be27a3', pg_temp.a(), 'colector', 'Colector colas', pg_temp.cat('66962503-9abc-56c9-b239-065de0a68eba'), 200, 'L', 'flexible', 'colas'),
  ('79c172ed-037e-506b-aaaf-5ce0e3786115', pg_temp.a(), 'tanque', 'Tanque 1', pg_temp.cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1000, 'L', 'flexible', null),
  ('ab25af8c-1b30-5c28-866d-d1b1fec3d565', pg_temp.a(), 'tanque', 'Tanque 2', pg_temp.cat('51470f4b-702a-5bd5-b38d-90d2a82f9648'), 1500, 'L', 'flexible', null);

-- Palenque Prueba B: lo mínimo para probar aislamiento
insert into predios (id, organization_id, name, municipality) values
  ('b0000000-0000-4000-8000-0000000000a1', 'b0000000-0000-4000-8000-0000000000b0', 'Predio B', 'Ejutla');
insert into resources (id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy) values
  ('b0000000-0000-4000-8000-0000000000a2', 'b0000000-0000-4000-8000-0000000000b0', 'tina', 'Tina B1',
   (select id from catalog_items where organization_id = 'b0000000-0000-4000-8000-0000000000b0' and template_id = 'b16c7c9d-baa4-59f0-abdb-cc7638918cd2'), 1000, 'L', 'flexible');

-- =====================================================================
-- Cuatro Vientos: la producción, POR RPC, en orden cronológico
-- =====================================================================

-- 2026-09-01 · Benito: lo que ya había en el Tanque 2 (carga inicial)
select pg_temp.como('a88771d6-e323-5b36-991d-c42e5880e507');
select registrar_entrada(pg_temp.a(), 'a6bee2ee-6d0d-5a95-82d7-caf669e464ad', '2026-09-01 10:15:00-06',
  'granel', pg_temp.res('Tanque 2'), 600, 44.2, 'mezcal', 'carga_inicial',
  p_concepto => pg_temp.con('255e79f1-12b3-5969-8453-e40623275559'),
  p_nota => 'Lo que ya había en el tanque al empezar', p_folio => 'G-INI-01');

-- 2026-09-01 · Aurelia: la Tina 3 ya fermentaba
select pg_temp.como('417489a3-9fa1-5914-bbc9-92d5334e9734');
select registrar_entrada(pg_temp.a(), '34ad45d4-295e-52e3-9bed-513b0645affc', '2026-09-01 10:40:00-06',
  'fermentado', pg_temp.res('Tina 3'), 1300, null, null, 'carga_inicial',
  p_nota => 'Tina que ya fermentaba', p_folio => 'FER-T3-INI');

-- 2026-09-02 · Aurelia: recepción de maguey
select registrar_recepcion_maguey(pg_temp.a(), 'b0e2b5c0-93e4-5aae-8c91-a1ff708a01a5', '2026-09-02 07:30:00-06',
  8000, pg_temp.esp('67a96efd-2c72-528e-8682-d144fe1f802c'), '031951e6-6a4f-5abc-8db6-79dfc4a43afa',
  'd1b5acf3-3fc9-59f3-a7d5-b82846bd82bc', 132, 'Piñas de 8 años, buen tamaño', 'MAG-001');

-- 2026-09-02 · Horneado (la simulación lo abría Tomás; §11.1 lo reserva a
-- admin/productor, así que lo abre Aurelia — docs/DECISIONES.md)
select abrir_horneado(pg_temp.a(), 'eaeb6cca-51bc-5c93-b541-b4c47d0d677e', '2026-09-02 12:00:00-06',
  pg_temp.res('Horno 1'), array[pg_temp.lot('MAG-001')], array[8000::numeric], p_folio => 'HOR-001');
-- 2026-09-06 · Aurelia cierra: 6,200 kg de agave cocido
select cerrar_horneado(pg_temp.a(), '4144eb6c-4512-5681-9d1a-a542a9f1d1b2', '2026-09-06 08:00:00-06',
  pg_temp.hor('HOR-001'), 6200, 'Leña de encino', p_folio => 'AC-001');

-- 2026-09-07 · Aurelia: formulación repartida a Tina 1 y Tina 2
select registrar_formulacion(pg_temp.a(), '728c141b-f5d1-572c-ba7f-162234654078', '2026-09-07 09:00:00-06',
  pg_temp.res('Tahona'), array[pg_temp.lot('AC-001')], array[6200::numeric], 1900,
  array[pg_temp.res('Tina 1'), pg_temp.res('Tina 2')], array[1400::numeric, 1400::numeric],
  array['1d55b594-99c2-5fe5-8081-4b6874e5a1d5'::uuid], array[20::numeric],
  'Tahona con mula', null, 'F-001', array['FER-T1-001', 'FER-T2-001']);

-- Mediciones diarias (escala de actividad 1–6, §18 #1; la simulación traía 7 y 8)
-- Tina 1
select pg_temp.como('e8e03baf-44a8-5af4-8d68-e0f3e04315a9');
select registrar_medicion(pg_temp.a(), '22f10d47-238b-5768-a841-6bf074592670', '2026-09-08 08:30:00-06', pg_temp.cyc('Tina 1'), 1, 'minimo', 4,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.5,12.0]::numeric[]);
select pg_temp.como('417489a3-9fa1-5914-bbc9-92d5334e9734');
select registrar_medicion(pg_temp.a(), '0386f30b-7d35-5bbc-a193-78b79f6cfdf0', '2026-09-09 08:30:00-06', pg_temp.cyc('Tina 1'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.0,9.5]::numeric[]);
select pg_temp.como('e8e03baf-44a8-5af4-8d68-e0f3e04315a9');
select registrar_medicion(pg_temp.a(), '31b0b2a4-b818-5092-b9df-c1b2448f5690', '2026-09-10 08:30:00-06', pg_temp.cyc('Tina 1'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.5,6.0]::numeric[]);
select pg_temp.como('417489a3-9fa1-5914-bbc9-92d5334e9734');
select registrar_medicion(pg_temp.a(), 'cdd6a93c-c0b1-5551-a59f-4674c9ee84f4', '2026-09-11 08:30:00-06', pg_temp.cyc('Tina 1'), 4, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[29.5,3.5]::numeric[]);
select pg_temp.como('e8e03baf-44a8-5af4-8d68-e0f3e04315a9');
select registrar_medicion(pg_temp.a(), '4011808e-68f9-5526-8b79-30e82ac78214', '2026-09-12 08:30:00-06', pg_temp.cyc('Tina 1'), 5, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.0,1.5]::numeric[]);
-- Tina 2
select registrar_medicion(pg_temp.a(), '1e6a3d3f-c5b9-5cde-8cdd-ce76a9afa27e', '2026-09-08 08:30:00-06', pg_temp.cyc('Tina 2'), 1, 'minimo', 3,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[27.0,12.2]::numeric[]);
select registrar_medicion(pg_temp.a(), '171ce5f6-e4d5-519d-a62f-19e996c5c9a2', '2026-09-09 08:30:00-06', pg_temp.cyc('Tina 2'), 2, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[28.5,10.1]::numeric[]);
select registrar_medicion(pg_temp.a(), '2f7365d3-d391-5f94-b57d-78205828b117', '2026-09-10 08:30:00-06', pg_temp.cyc('Tina 2'), 3, 'minimo', 6,
  array['temperatura','brix']::reading_variable[], array['unica','unica']::reading_zone[], array[1,1]::smallint[], array[30.0,7.4]::numeric[]);

-- 2026-09-12 · Aurelia declara lista la Tina 1
select pg_temp.como('417489a3-9fa1-5914-bbc9-92d5334e9734');
select declarar_tina_lista(pg_temp.a(), '8fc25a57-fca4-5578-ae15-b332d195f446', '2026-09-12 17:00:00-06',
  pg_temp.cyc('Tina 1'), 'Día 5: ya no burbujea, sabor seco');

-- 2026-09-13 · Tomás: dos corridas de 1ª pasada desde la Tina 1
select pg_temp.como('e8e03baf-44a8-5af4-8d68-e0f3e04315a9');
select abrir_corrida(pg_temp.a(), '95396c14-d8ff-531b-b508-22041fbd1dcb', '2026-09-13 06:00:00-06',
  pg_temp.res('Alambique 1'), 'primera', array[pg_temp.res('Tina 1')], array[pg_temp.lot('FER-T1-001')], array[290::numeric],
  p_folio => 'DES-001');
select registrar_corte(pg_temp.a(), '1bf82a44-2a65-5177-958a-f060c67948c0', '2026-09-13 08:00:00-06', pg_temp.run('DES-001'), 'mezcal', 8, 51.0, pg_temp.res('Colector mezcal'), p_folio => 'MEZ-001');
select registrar_corte(pg_temp.a(), 'cdcd222b-5a48-556f-acfd-11f4e61bbf87', '2026-09-13 10:00:00-06', pg_temp.run('DES-001'), 'ordinario', 40, 24.0, pg_temp.res('Colector ordinario'), p_folio => 'ORD-001');
select registrar_corte(pg_temp.a(), '6af9c1fe-c3af-5689-a8cb-03a49becb924', '2026-09-13 12:00:00-06', pg_temp.run('DES-001'), 'colas', 12, 9.0, pg_temp.res('Colector colas'), p_folio => 'COL-001');
select cerrar_corrida(pg_temp.a(), '2d6ca406-3cd1-57bd-a7a7-b7856193e1c3', '2026-09-13 14:00:00-06', pg_temp.run('DES-001'));

select abrir_corrida(pg_temp.a(), '14defd90-d826-5001-8ca2-b2d29871581f', '2026-09-13 06:00:00-06',
  pg_temp.res('Alambique 2'), 'primera', array[pg_temp.res('Tina 1')], array[pg_temp.lot('FER-T1-001')], array[240::numeric],
  p_folio => 'DES-002');
select registrar_corte(pg_temp.a(), '50492caf-f331-5dd6-ba7d-20c122844289', '2026-09-13 08:00:00-06', pg_temp.run('DES-002'), 'mezcal', 6, 50.0, pg_temp.res('Colector mezcal'));
select registrar_corte(pg_temp.a(), '1474ad37-af06-5d6f-8c68-4edffb6f3eef', '2026-09-13 10:00:00-06', pg_temp.run('DES-002'), 'ordinario', 34, 23.0, pg_temp.res('Colector ordinario'));
select registrar_corte(pg_temp.a(), 'e2369747-95f8-59fa-a0e7-b56bbd81c43a', '2026-09-13 12:00:00-06', pg_temp.run('DES-002'), 'colas', 10, 8.0, pg_temp.res('Colector colas'));
select cerrar_corrida(pg_temp.a(), 'ba376939-6965-5be2-aa13-ece0c9df9e8d', '2026-09-13 14:00:00-06', pg_temp.run('DES-002'));

-- 2026-09-15 · Tomás: 2ª pasada con ordinario y colas juntos (aviso + nota)
select abrir_corrida(pg_temp.a(), 'cf64c4a7-8ed1-50dd-a355-f717963193ed', '2026-09-15 06:00:00-06',
  pg_temp.res('Alambique 1'), 'segunda',
  array[pg_temp.res('Colector ordinario'), pg_temp.res('Colector colas')],
  array[pg_temp.lot('ORD-001'), pg_temp.lot('COL-001')], array[74::numeric, 22::numeric],
  'Había olla libre y poca cola; se juntó con el ordinario', 'DES-003');
select registrar_corte(pg_temp.a(), '82ba4428-7331-5f28-a403-b4e935f66816', '2026-09-15 08:00:00-06', pg_temp.run('DES-003'), 'mezcal', 26, 52.5, pg_temp.res('Colector mezcal'));
select registrar_corte(pg_temp.a(), '1e408333-3484-5089-9895-e19c0cfb28d6', '2026-09-15 10:00:00-06', pg_temp.run('DES-003'), 'colas', 16, 10.0, pg_temp.res('Colector colas'), p_folio => 'COL-002');
select cerrar_corrida(pg_temp.a(), 'd71575ac-74c5-5d3e-b36f-87ed0ec93d84', '2026-09-15 14:00:00-06', pg_temp.run('DES-003'));

-- 2026-09-16 · Aurelia: el mezcal del colector pasa a granel con folio nuevo
select pg_temp.como('417489a3-9fa1-5914-bbc9-92d5334e9734');
select transferir(pg_temp.a(), '47984f8a-d5fe-59d3-a01b-c390c12dc2d2', '2026-09-16 09:00:00-06',
  pg_temp.res('Colector mezcal'), pg_temp.res('Tanque 1'), pg_temp.lot('MEZ-001'), 40, 51.6, 'renombrar', 'G-2609-01');
-- Agua para bajar grado: 4 L, declara 43.8 L (contracción) y 47.0 %
select registrar_movimiento_granel(pg_temp.a(), '54b7ab34-90ce-5aa6-8ccc-f61fab8b28bf', '2026-09-16 11:00:00-06',
  pg_temp.con('66a151e2-9a2c-58be-ad4a-b117f1ddb717'), pg_temp.res('Tanque 1'), 4,
  p_lote => pg_temp.lot('G-2609-01'), p_resultado_l => 43.8, p_resultado_abv => 47.0);

-- 2026-09-17 · Benito: puntas guardadas (sin lote) al Tanque 2
select pg_temp.como('a88771d6-e323-5b36-991d-c42e5880e507');
select registrar_movimiento_granel(pg_temp.a(), '08ab7b69-5b76-5372-96bc-c5d785007f9a', '2026-09-17 10:00:00-06',
  pg_temp.con('f21aaad8-2ef6-556b-be55-64aa94431ab6'), pg_temp.res('Tanque 2'), 2,
  p_lote => pg_temp.lot('G-INI-01'), p_resultado_l => 602, p_resultado_abv => 44.6, p_abv => 68.0,
  p_nota => 'Puntas guardadas de corridas de agosto, sin lote');
-- 2026-09-18 · Benito: unión de G-2609-01 (Tanque 1) con G-INI-01 (Tanque 2), se conserva el folio mayor
select registrar_movimiento_granel(pg_temp.a(), '35a4103c-b45e-5e64-88ea-5e0062aa2231', '2026-09-18 09:30:00-06',
  pg_temp.con('df427d88-600e-550e-a097-8ffe4f4dd556'), pg_temp.res('Tanque 2'), 43.8,
  p_lote => pg_temp.lot('G-INI-01'), p_lote_origen => pg_temp.lot('G-2609-01'), p_recurso_origen => pg_temp.res('Tanque 1'),
  p_resultado_l => 645.8, p_resultado_abv => 44.9, p_decision => 'conservar', p_nota => 'Se conserva el folio del lote mayor');
-- 2026-09-19 · Benito: compra de granel al Tanque 1
select registrar_movimiento_granel(pg_temp.a(), '1ecd0c93-8ab5-5602-9a3d-cd8e017b1e76', '2026-09-19 12:00:00-06',
  pg_temp.con('688430a9-cd2f-5bae-add2-c59bc543d911'), pg_temp.res('Tanque 1'), 250,
  p_resultado_l => 250, p_resultado_abv => 46.0, p_abv => 46.0, p_folio_nuevo => 'G-COMPRA-01',
  p_contraparte => 'Destilados Hermanos Luna', p_documento => 'Remisión 0452',
  p_proveedor => '3037cfb3-d2c6-5dcd-bb3b-743136024e9c', p_especie => pg_temp.esp('67a96efd-2c72-528e-8682-d144fe1f802c'),
  p_predio_declarado => 'Sola de Vega');

-- 2026-09-19 · Aurelia: muestra de laboratorio
select pg_temp.como('417489a3-9fa1-5914-bbc9-92d5334e9734');
select registrar_movimiento_granel(pg_temp.a(), 'edb99ba0-e1e2-5537-b7f0-9005ea3d1886', '2026-09-19 13:00:00-06',
  pg_temp.con('2d62ab89-6a11-558c-8b46-5c4d30aa1607'), pg_temp.res('Tanque 2'), 1,
  p_lote => pg_temp.lot('G-INI-01'), p_contraparte => 'Laboratorio ficticio de Oaxaca', p_documento => 'Análisis 2026-311');

-- 2026-09-20/22 · Benito: autoconsumo, venta, regalo
select pg_temp.como('a88771d6-e323-5b36-991d-c42e5880e507');
select registrar_movimiento_granel(pg_temp.a(), 'fac42efe-57e6-532d-8156-ff649279a923', '2026-09-20 13:00:00-06',
  pg_temp.con('fa52f92b-de19-5d0c-972c-beb899bb2ccb'), pg_temp.res('Tanque 2'), 2, p_lote => pg_temp.lot('G-INI-01'));
select registrar_movimiento_granel(pg_temp.a(), '19acbfa4-6b5f-5e10-be05-a82959e592e7', '2026-09-22 13:00:00-06',
  pg_temp.con('7b0ca7ca-f8ae-5f33-93d5-f0c174664ec1'), pg_temp.res('Tanque 2'), 300,
  p_lote => pg_temp.lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.', p_documento => 'Remisión 118');
select registrar_movimiento_granel(pg_temp.a(), 'ef7a7ad6-2540-5dcf-bdcf-e520d9e6baef', '2026-09-22 13:00:00-06',
  '85bbba70-4fc8-5fa2-ba03-af5475085b7a', pg_temp.res('Tanque 2'), 1,
  p_lote => pg_temp.lot('G-INI-01'), p_contraparte => 'Cliente ficticio S.A.');

reset role;

-- Evidencia de la compra (los adjuntos no son RPC de §12)
insert into attachments (id, organization_id, operation_id, lot_id, kind_item_id, storage_path, caption) values
  ('c53faa19-4982-57d1-92e9-d5b61c05a1cd', pg_temp.a(),
   (select id from operations where organization_id = pg_temp.a() and idempotency_key = '1ecd0c93-8ab5-5602-9a3d-cd8e017b1e76'),
   pg_temp.lot('G-COMPRA-01'), pg_temp.cat('0522e23b-3b1d-58be-b50c-8a6ed0627c9f'),
   'evidencias/b66cf468-47f7-51ee-a8f2-994d907440b9/g-compra-01/remision-0452.jpg', 'Remisión del proveedor');

commit;
