-- PULZ · Simulación "Mezcal Cuatro Vientos" (datos ficticios)
-- Correr DESPUÉS de pulz_esquema.sql en Supabase local (supabase db reset).
-- Validado con un verificador propio: columnas, NOT NULL, enums, PK/UNIQUE,
-- 475 llaves foráneas, saldos del ledger y reglas de negocio. NO se
-- ha corrido en Postgres real: no hay Postgres en el entorno donde se generó.
-- auth.users normalmente lo llena Supabase al registrarse; aquí va mínimo.
begin;

-- auth.users
insert into auth.users (instance_id, id, aud, role, email, email_confirmed_at) values
  ('00000000-0000-0000-0000-000000000000', 'f6d4a253-a9a1-508c-9319-d223fe92949e', 'authenticated', 'authenticated', 'tu@pulz.mx', now()),
  ('00000000-0000-0000-0000-000000000000', 'a88771d6-e323-5b36-991d-c42e5880e507', 'authenticated', 'authenticated', 'benito@cuatrovientos.mx', now()),
  ('00000000-0000-0000-0000-000000000000', '417489a3-9fa1-5914-bbc9-92d5334e9734', 'authenticated', 'authenticated', 'aurelia@b66cf468-47f7-51ee-a8f2-994d907440b9.usuarios.pulz.mx', now()),
  ('00000000-0000-0000-0000-000000000000', 'e8e03baf-44a8-5af4-8d68-e0f3e04315a9', 'authenticated', 'authenticated', 'tomas.h@b66cf468-47f7-51ee-a8f2-994d907440b9.usuarios.pulz.mx', now());

-- profiles
insert into profiles (id, full_name) values
  ('f6d4a253-a9a1-508c-9319-d223fe92949e', 'Admin PULZ'),
  ('a88771d6-e323-5b36-991d-c42e5880e507', 'Benito Cruz'),
  ('417489a3-9fa1-5914-bbc9-92d5334e9734', 'Aurelia Santiago'),
  ('e8e03baf-44a8-5af4-8d68-e0f3e04315a9', 'Tomás Hernández');

-- platform_admins
insert into platform_admins (user_id) values
  ('f6d4a253-a9a1-508c-9319-d223fe92949e');

-- plans
insert into plans (id, code, name, price_mxn_month, stripe_price_id) values
  ('ee35d6fd-b4d6-56d6-b7b4-61cb81932b21', 'gratis', 'Gratis', 0, null),
  ('edd15bcf-ad82-5684-a2e7-d85db401885b', 'palenque', 'Palenque', 299, 'price_SIMULADO');

-- plan_limits
insert into plan_limits (plan_id, limit_key, limit_value) values
  ('ee35d6fd-b4d6-56d6-b7b4-61cb81932b21', 'usuarios', 2),
  ('ee35d6fd-b4d6-56d6-b7b4-61cb81932b21', 'lotes_activos', 15),
  ('ee35d6fd-b4d6-56d6-b7b4-61cb81932b21', 'tinas', 4),
  ('edd15bcf-ad82-5684-a2e7-d85db401885b', 'usuarios', 10),
  ('edd15bcf-ad82-5684-a2e7-d85db401885b', 'lotes_activos', null),
  ('edd15bcf-ad82-5684-a2e7-d85db401885b', 'tinas', null);

-- plan_features
insert into plan_features (plan_id, feature_key) values
  ('edd15bcf-ad82-5684-a2e7-d85db401885b', 'exportar_pdf');

-- organizations
insert into organizations (id, name, slug, state, brand_color, logo_path, welcome_message, created_by) values
  ('b66cf468-47f7-51ee-a8f2-994d907440b9', 'Mezcal Cuatro Vientos', 'cuatro-vientos', 'Oaxaca', '#7A3E1D', null, 'Registro de producción del palenque', 'a88771d6-e323-5b36-991d-c42e5880e507');

-- organization_slug_history
insert into organization_slug_history (slug, organization_id, retired_at, retired_by) values
  ('mezcal-cuatro-vientos', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '2026-09-02 09:00:00-06', 'a88771d6-e323-5b36-991d-c42e5880e507');

-- organization_members
insert into organization_members (organization_id, user_id, role, status, username, must_change_password) values
  ('b66cf468-47f7-51ee-a8f2-994d907440b9', 'a88771d6-e323-5b36-991d-c42e5880e507', 'admin', 'activo', null, false),
  ('b66cf468-47f7-51ee-a8f2-994d907440b9', '417489a3-9fa1-5914-bbc9-92d5334e9734', 'productor', 'activo', 'aurelia', false),
  ('b66cf468-47f7-51ee-a8f2-994d907440b9', 'e8e03baf-44a8-5af4-8d68-e0f3e04315a9', 'operador', 'activo', 'tomas.h', true);

-- member_invitations
insert into member_invitations (id, organization_id, user_id, token_hash, expires_at, used_at, created_by) values
  ('180450f7-0604-5777-9484-0fc21b59c0df', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'e8e03baf-44a8-5af4-8d68-e0f3e04315a9', 'sha256:SIMULADO', '2026-09-05 10:00:00-06', null, 'a88771d6-e323-5b36-991d-c42e5880e507');

-- login_throttle
insert into login_throttle (user_id, failed_count, last_failed_at, locked_until) values
  ('e8e03baf-44a8-5af4-8d68-e0f3e04315a9', 3, '2026-09-03 07:12:00-06', null);

-- organization_settings
insert into organization_settings (organization_id, record_puntas, measurement_mode, warn_mixed_second_pass, fermentation_expected_days, measurement_reminder_hour, default_folio_decision) values
  ('b66cf468-47f7-51ee-a8f2-994d907440b9', false, 'minimo', true, 7, 9, 'conservar');

-- subscriptions
insert into subscriptions (organization_id, plan_id, status, current_period_end) values
  ('b66cf468-47f7-51ee-a8f2-994d907440b9', 'edd15bcf-ad82-5684-a2e7-d85db401885b', 'prueba', '2026-10-15 00:00:00-06');

-- catalog_items
insert into catalog_items (id, organization_id, catalog, name, sort_order, active, created_by) values
  ('d53ba2da-cada-5215-804a-ff304d569f97', null, 'tipo_horno', 'Horno cónico de tierra', 10, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('c7fe4317-eee8-5851-936c-8ee8401b62fd', null, 'tipo_horno', 'Horno de mampostería', 20, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('5c985133-23d9-50fa-a252-6ff6b5b74134', null, 'tipo_horno', 'Autoclave', 30, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('60285283-d000-52f0-95da-d2b2e6d70fa1', null, 'tipo_molino', 'Tahona', 10, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('6aeb9612-2d23-5668-9c4d-6ea032baccb1', null, 'tipo_molino', 'Desgarradora mecánica', 20, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('df280582-a9a4-5254-8aae-d8811a18800f', null, 'tipo_molino', 'A mano (mazo)', 30, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('b16c7c9d-baa4-59f0-abdb-cc7638918cd2', null, 'tipo_tina', 'Tina de sabino', 10, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('136c642b-becb-5169-ac2e-a27bf9b006f4', null, 'tipo_tina', 'Tina de pino', 20, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('7db30ace-d5f8-5fc0-910a-4c52a7d620a5', null, 'tipo_tina', 'Tina de piel', 30, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('b1fce67a-21bf-50a7-9344-fdf29eb5331e', null, 'tipo_tina', 'Tina de acero inoxidable', 40, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('af73010e-53f2-5769-b3b1-6cda154e665e', null, 'tipo_alambique', 'Alambique de cobre', 10, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('c2be5c85-01a5-5443-8374-d877abb2e071', null, 'tipo_alambique', 'Olla de barro', 20, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('a97347b5-a0f4-569e-86ff-a42705f77f3c', null, 'tipo_alambique', 'Alambique de acero inoxidable', 30, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('2cd7e70b-6246-543e-8f67-23743fefdf95', null, 'tipo_colector', 'Garrafa de plástico', 10, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('66962503-9abc-56c9-b239-065de0a68eba', null, 'tipo_colector', 'Tambo', 20, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('71f28344-d71e-5ec6-9756-05138855186c', null, 'tipo_colector', 'Contenedor de acero', 30, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('51470f4b-702a-5bd5-b38d-90d2a82f9648', null, 'tipo_tanque', 'Tanque de acero inoxidable', 10, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('4232c321-9c07-52b5-9cab-75c3ff07c696', null, 'tipo_tanque', 'Tanque de plástico grado alimenticio', 20, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('f3c7a408-abad-50f1-b662-9cb137985e37', null, 'tipo_tanque', 'Garrafón de vidrio', 30, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('640b537d-bf52-5c4b-b407-a5f4fb7c5800', null, 'tipo_proveedor', 'Maguey', 10, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('bb234638-3c78-56cd-9f41-2fb38182f181', null, 'tipo_proveedor', 'Granel', 20, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('22ad3852-832d-5644-a9cb-8e640e01dee4', null, 'tipo_proveedor', 'Insumos', 30, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('4c852aa8-ced5-5522-a210-1d8c2ab9e403', null, 'tipo_adjunto', 'Certificado', 10, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('5dd028c8-9700-5c02-a7c0-1d079e62b487', null, 'tipo_adjunto', 'Análisis de laboratorio', 20, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('e4966301-96da-5221-8658-fecbb86b2319', null, 'tipo_adjunto', 'Foto', 30, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('0522e23b-3b1d-58be-b50c-8a6ed0627c9f', null, 'tipo_adjunto', 'Remisión o factura', 40, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('2668f647-07d8-5a88-9597-5068d7bed437', null, 'unidad_insumo', 'kg', 10, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('bc6f104d-2841-5b36-b492-76b36becb172', null, 'unidad_insumo', 'L', 20, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('c1c0eead-305b-5d29-bd5f-ba91fd584a71', null, 'unidad_insumo', 'pieza', 30, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('29da31b1-2580-5943-873c-afc18495a601', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'tipo_alambique', 'Refrescadera de cobre', 100, true, 'a88771d6-e323-5b36-991d-c42e5880e507');

-- catalog_item_hidden
insert into catalog_item_hidden (organization_id, item_id, hidden_by) values
  ('b66cf468-47f7-51ee-a8f2-994d907440b9', '5c985133-23d9-50fa-a252-6ff6b5b74134', 'a88771d6-e323-5b36-991d-c42e5880e507'),
  ('b66cf468-47f7-51ee-a8f2-994d907440b9', 'b1fce67a-21bf-50a7-9344-fdf29eb5331e', 'a88771d6-e323-5b36-991d-c42e5880e507');

-- movement_concepts
insert into movement_concepts (id, organization_id, direction, name, source_lot, creates_lot, asks_result, asks_counterparty, sort_order, active, created_by) values
  ('66a151e2-9a2c-58be-ad4a-b117f1ddb717', null, 'entrada', 'Agua para bajar grado', 'no_aplica', false, true, false, 10, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('f21aaad8-2ef6-556b-be55-64aa94431ab6', null, 'entrada', 'Puntas para subir grado', 'opcional', false, true, false, 20, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('df427d88-600e-550e-a097-8ffe4f4dd556', null, 'entrada', 'Unión con otro lote', 'requerido', false, true, false, 30, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('688430a9-cd2f-5bae-add2-c59bc543d911', null, 'entrada', 'Compra de granel', 'no_aplica', true, true, true, 40, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('255e79f1-12b3-5969-8453-e40623275559', null, 'entrada', 'Carga inicial', 'no_aplica', true, true, false, 50, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('dfd383f9-01d4-58b3-9334-6624bb5d0a43', null, 'entrada', 'Ajuste de inventario (+)', 'no_aplica', false, true, false, 60, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('7b0ca7ca-f8ae-5f33-93d5-f0c174664ec1', null, 'salida', 'Venta a granel', 'no_aplica', false, false, true, 70, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('8b7f6579-99ef-549e-b427-b1d4d8bea9da', null, 'salida', 'Envasado', 'no_aplica', false, false, false, 80, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('2d62ab89-6a11-558c-8b46-5c4d30aa1607', null, 'salida', 'Muestra de laboratorio', 'no_aplica', false, false, true, 90, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('a65efc9d-4b6c-53c5-b447-6db090589bb9', null, 'salida', 'Muestra comercial', 'no_aplica', false, false, true, 100, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('fa52f92b-de19-5d0c-972c-beb899bb2ccb', null, 'salida', 'Autoconsumo', 'no_aplica', false, false, false, 110, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('b3a02d59-4538-5755-8324-d6853eb0b99e', null, 'salida', 'Merma', 'no_aplica', false, false, false, 120, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('a02083d4-7c78-55ac-896c-ca27e4fece88', null, 'salida', 'Ajuste de inventario (−)', 'no_aplica', false, false, false, 130, true, 'f6d4a253-a9a1-508c-9319-d223fe92949e'),
  ('85bbba70-4fc8-5fa2-ba03-af5475085b7a', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'salida', 'Regalo a cliente', 'no_aplica', false, false, true, 100, true, 'a88771d6-e323-5b36-991d-c42e5880e507');

-- movement_concept_hidden
insert into movement_concept_hidden (organization_id, concept_id, hidden_by) values
  ('b66cf468-47f7-51ee-a8f2-994d907440b9', '8b7f6579-99ef-549e-b427-b1d4d8bea9da', 'a88771d6-e323-5b36-991d-c42e5880e507');

-- species
insert into species (id, organization_id, common_name, scientific_name, active) values
  ('67a96efd-2c72-528e-8682-d144fe1f802c', null, 'Espadín', 'Agave angustifolia', true),
  ('eb38c785-7a22-56ba-b9c0-478d969c0b40', null, 'Tobalá', 'Agave potatorum', true),
  ('456cac87-94e1-57a6-90ac-838470b7f0b5', null, 'Tepeztate', 'Agave marmorata', true),
  ('63eaa5a1-cd89-5176-bc54-95236a43f0d3', null, 'Cuishe', 'Agave karwinskii', true),
  ('01921edd-9eb2-58b0-af80-3ce782f8fc28', null, 'Arroqueño', 'Agave americana var. oaxacensis', true);

-- predios
insert into predios (id, organization_id, name, municipality, owner_name, active) values
  ('031951e6-6a4f-5abc-8db6-79dfc4a43afa', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'Loma del Toro', 'Santiago Matatlán', 'Familia Cruz', true);

-- suppliers
insert into suppliers (id, organization_id, name, type_catalog, type_item_id, active) values
  ('d1b5acf3-3fc9-59f3-a7d5-b82846bd82bc', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'Magueyes Don Pedro', 'tipo_proveedor', '640b537d-bf52-5c4b-b407-a5f4fb7c5800', true),
  ('3037cfb3-d2c6-5dcd-bb3b-743136024e9c', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'Destilados Hermanos Luna', 'tipo_proveedor', 'bb234638-3c78-56cd-9f41-2fb38182f181', true);

-- supplies
insert into supplies (id, organization_id, name, unit_catalog, unit_item_id, active) values
  ('1d55b594-99c2-5fe5-8081-4b6874e5a1d5', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'Pulque como inóculo', 'unidad_insumo', 'bc6f104d-2841-5b36-b492-76b36becb172', true);

-- resources
insert into resources (id, organization_id, kind, code, type_catalog, type_item_id, capacity, capacity_unit, capacity_policy, liquid_class, active) values
  ('1e75aadc-221d-5614-98a3-de77defa5bb6', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'horno', 'Horno 1', 'tipo_horno', 'd53ba2da-cada-5215-804a-ff304d569f97', 10000, 'kg', 'libre', null, true),
  ('d79b3908-f952-5556-a7bd-b55c6a071001', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'molino', 'Tahona', 'tipo_molino', '60285283-d000-52f0-95da-d2b2e6d70fa1', null, 'kg', 'libre', null, true),
  ('32a9508c-17b3-51b8-9c03-21af27b29ac5', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'tina', 'Tina 1', 'tipo_tina', 'b16c7c9d-baa4-59f0-abdb-cc7638918cd2', 1500, 'L', 'flexible', null, true),
  ('55226f86-ec84-5917-a97b-23e072c1a7fc', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'tina', 'Tina 2', 'tipo_tina', 'b16c7c9d-baa4-59f0-abdb-cc7638918cd2', 1500, 'L', 'flexible', null, true),
  ('d4bef388-6b84-5a2d-8471-41c2d4e05e94', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'tina', 'Tina 3', 'tipo_tina', 'b16c7c9d-baa4-59f0-abdb-cc7638918cd2', 1500, 'L', 'flexible', null, true),
  ('65c839c8-13c0-5ad1-95be-642782860c7c', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'alambique', 'Alambique 1', 'tipo_alambique', 'af73010e-53f2-5769-b3b1-6cda154e665e', 300, 'L', 'estricta', null, true),
  ('19a3b420-6f96-5e62-92c7-7f09ba5e15a1', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'alambique', 'Alambique 2', 'tipo_alambique', '29da31b1-2580-5943-873c-afc18495a601', 250, 'L', 'estricta', null, true),
  ('863122f8-e9e7-51ac-b5af-d86f9e56e573', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'colector', 'Colector mezcal', 'tipo_colector', '2cd7e70b-6246-543e-8f67-23743fefdf95', 60, 'L', 'flexible', 'mezcal', true),
  ('ffffb8f2-cc46-57d0-89c2-bf433f1657e3', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'colector', 'Colector ordinario', 'tipo_colector', '66962503-9abc-56c9-b239-065de0a68eba', 200, 'L', 'flexible', 'ordinario', true),
  ('ea0bebaa-bb90-52be-96f7-ca86a2be27a3', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'colector', 'Colector colas', 'tipo_colector', '66962503-9abc-56c9-b239-065de0a68eba', 200, 'L', 'flexible', 'colas', true),
  ('79c172ed-037e-506b-aaaf-5ce0e3786115', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'tanque', 'Tanque 1', 'tipo_tanque', '51470f4b-702a-5bd5-b38d-90d2a82f9648', 1000, 'L', 'flexible', null, true),
  ('ab25af8c-1b30-5c28-866d-d1b1fec3d565', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'tanque', 'Tanque 2', 'tipo_tanque', '51470f4b-702a-5bd5-b38d-90d2a82f9648', 1500, 'L', 'flexible', null, true);

-- operations
insert into operations (id, organization_id, kind, concept_id, occurred_at, recorded_at, recorded_by, idempotency_key, result_resource_id, result_volume_l, result_abv, note, result_lot_id, folio_decision, counterparty, document_ref) values
  ('dbb84c5b-adca-565a-97d0-142cd0389064', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'entrada_directa', '255e79f1-12b3-5969-8453-e40623275559', '2026-09-01 10:15:00-06', '2026-09-01 10:15:00-06', 'a88771d6-e323-5b36-991d-c42e5880e507', 'a6bee2ee-6d0d-5a95-82d7-caf669e464ad', 'ab25af8c-1b30-5c28-866d-d1b1fec3d565', 600, 44.2, 'Lo que ya había en el tanque al empezar', '5d6310f2-1e38-5087-a02d-716257bf0fcc', null, null, null),
  ('9b403c43-6958-5c96-b667-973cf2ad6938', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'entrada_directa', null, '2026-09-01 10:40:00-06', '2026-09-01 10:40:00-06', '417489a3-9fa1-5914-bbc9-92d5334e9734', '34ad45d4-295e-52e3-9bed-513b0645affc', 'd4bef388-6b84-5a2d-8471-41c2d4e05e94', 1300, null, 'Tina que ya fermentaba', 'fcd93468-aba9-5f9a-8ff1-e8041c33e52b', null, null, null),
  ('90d7611b-acc0-59d1-8fa3-1fe183f9d025', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'recepcion_maguey', null, '2026-09-02 07:30:00-06', '2026-09-02 07:30:00-06', '417489a3-9fa1-5914-bbc9-92d5334e9734', 'b0e2b5c0-93e4-5aae-8c91-a1ff708a01a5', null, null, null, null, '28c31736-e265-58d8-84bc-e2d7227fe0c4', null, null, null),
  ('0c10e939-4a94-599c-be3b-c3a7ce6ec310', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'abrir_horneado', null, '2026-09-02 12:00:00-06', '2026-09-02 12:00:00-06', 'e8e03baf-44a8-5af4-8d68-e0f3e04315a9', 'eaeb6cca-51bc-5c93-b541-b4c47d0d677e', null, null, null, null, null, null, null, null),
  ('c7f94b27-6b4d-581e-970e-3af11359e5bd', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'cerrar_horneado', null, '2026-09-06 08:00:00-06', '2026-09-06 08:00:00-06', '417489a3-9fa1-5914-bbc9-92d5334e9734', '4144eb6c-4512-5681-9d1a-a542a9f1d1b2', null, null, null, null, '2317004e-57d3-530d-85cd-70b9e0c3b824', null, null, null),
  ('973e5d7c-6536-5027-b35b-dc962d95ed1e', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'formulacion', null, '2026-09-07 09:00:00-06', '2026-09-07 09:00:00-06', '417489a3-9fa1-5914-bbc9-92d5334e9734', '728c141b-f5d1-572c-ba7f-162234654078', null, null, null, null, '05be43d5-0d2f-5fa3-8675-825f1c398650', null, null, null),
  ('b16ca2ef-d150-5c69-bd3a-33583bf78e38', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'medicion', null, '2026-09-08 08:30:00-06', '2026-09-08 08:30:00-06', 'e8e03baf-44a8-5af4-8d68-e0f3e04315a9', '22f10d47-238b-5768-a841-6bf074592670', null, null, null, null, null, null, null, null),
  ('7055fc6b-78ff-5279-8e3e-3c39862ac99c', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'medicion', null, '2026-09-09 08:30:00-06', '2026-09-09 08:30:00-06', '417489a3-9fa1-5914-bbc9-92d5334e9734', '0386f30b-7d35-5bbc-a193-78b79f6cfdf0', null, null, null, null, null, null, null, null),
  ('d045ba98-5826-5cf4-b801-532521c80618', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'medicion', null, '2026-09-10 08:30:00-06', '2026-09-10 08:30:00-06', 'e8e03baf-44a8-5af4-8d68-e0f3e04315a9', '31b0b2a4-b818-5092-b9df-c1b2448f5690', null, null, null, null, null, null, null, null),
  ('482db62c-542a-53fe-afde-85fd2dc89e5f', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'medicion', null, '2026-09-11 08:30:00-06', '2026-09-11 08:30:00-06', '417489a3-9fa1-5914-bbc9-92d5334e9734', 'cdd6a93c-c0b1-5551-a59f-4674c9ee84f4', null, null, null, null, null, null, null, null),
  ('4d344728-f48d-5b75-9361-873592c5ddb8', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'medicion', null, '2026-09-12 08:30:00-06', '2026-09-12 08:30:00-06', 'e8e03baf-44a8-5af4-8d68-e0f3e04315a9', '4011808e-68f9-5526-8b79-30e82ac78214', null, null, null, null, null, null, null, null),
  ('df9bd519-800a-5d77-8450-574ee1452944', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'medicion', null, '2026-09-08 08:30:00-06', '2026-09-08 08:30:00-06', 'e8e03baf-44a8-5af4-8d68-e0f3e04315a9', '1e6a3d3f-c5b9-5cde-8cdd-ce76a9afa27e', null, null, null, null, null, null, null, null),
  ('9f4f4aec-843d-5639-b30b-3deb96e2cc5f', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'medicion', null, '2026-09-09 08:30:00-06', '2026-09-09 08:30:00-06', 'e8e03baf-44a8-5af4-8d68-e0f3e04315a9', '171ce5f6-e4d5-519d-a62f-19e996c5c9a2', null, null, null, null, null, null, null, null),
  ('16d569a9-e2f2-5961-8c2d-2c739404247e', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'medicion', null, '2026-09-10 08:30:00-06', '2026-09-10 08:30:00-06', 'e8e03baf-44a8-5af4-8d68-e0f3e04315a9', '2f7365d3-d391-5f94-b57d-78205828b117', null, null, null, null, null, null, null, null),
  ('e13566e5-27ec-5735-a1b6-e16320757cd5', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'tina_lista', null, '2026-09-12 17:00:00-06', '2026-09-12 17:00:00-06', '417489a3-9fa1-5914-bbc9-92d5334e9734', '8fc25a57-fca4-5578-ae15-b332d195f446', null, null, null, 'Día 5: ya no burbujea, sabor seco', null, null, null, null),
  ('8784ef6e-dc22-59e7-8ecc-ac58f7964d0c', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'abrir_corrida', null, '2026-09-13 06:00:00-06', '2026-09-13 06:00:00-06', 'e8e03baf-44a8-5af4-8d68-e0f3e04315a9', '95396c14-d8ff-531b-b508-22041fbd1dcb', null, null, null, null, null, null, null, null),
  ('cc83b84c-0e06-58f6-9087-7700d10a928b', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'cerrar_corrida', null, '2026-09-13 14:00:00-06', '2026-09-13 14:00:00-06', 'e8e03baf-44a8-5af4-8d68-e0f3e04315a9', '2d6ca406-3cd1-57bd-a7a7-b7856193e1c3', null, null, null, null, null, null, null, null),
  ('bf2eaa16-3f3e-5d47-9e8b-f2600c4a53b7', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'corte', null, '2026-09-13 08:00:00-06', '2026-09-13 08:00:00-06', 'e8e03baf-44a8-5af4-8d68-e0f3e04315a9', '1bf82a44-2a65-5177-958a-f060c67948c0', null, null, null, null, null, null, null, null),
  ('c4b2ac32-745e-5cde-8fbc-3414df667048', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'corte', null, '2026-09-13 10:00:00-06', '2026-09-13 10:00:00-06', 'e8e03baf-44a8-5af4-8d68-e0f3e04315a9', 'cdcd222b-5a48-556f-acfd-11f4e61bbf87', null, null, null, null, null, null, null, null),
  ('8d868fa2-8ec5-50a3-adda-28551769bfa9', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'corte', null, '2026-09-13 12:00:00-06', '2026-09-13 12:00:00-06', 'e8e03baf-44a8-5af4-8d68-e0f3e04315a9', '6af9c1fe-c3af-5689-a8cb-03a49becb924', null, null, null, null, null, null, null, null),
  ('97dad407-7879-5e96-b375-d8c85c9a70c5', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'abrir_corrida', null, '2026-09-13 06:00:00-06', '2026-09-13 06:00:00-06', 'e8e03baf-44a8-5af4-8d68-e0f3e04315a9', '14defd90-d826-5001-8ca2-b2d29871581f', null, null, null, null, null, null, null, null),
  ('1f273880-c320-5dcd-af8d-c4676a33a228', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'cerrar_corrida', null, '2026-09-13 14:00:00-06', '2026-09-13 14:00:00-06', 'e8e03baf-44a8-5af4-8d68-e0f3e04315a9', 'ba376939-6965-5be2-aa13-ece0c9df9e8d', null, null, null, null, null, null, null, null),
  ('d5ad5cbf-facb-57ed-a386-6f15e94ee7a3', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'corte', null, '2026-09-13 08:00:00-06', '2026-09-13 08:00:00-06', 'e8e03baf-44a8-5af4-8d68-e0f3e04315a9', '50492caf-f331-5dd6-ba7d-20c122844289', null, null, null, null, null, null, null, null),
  ('54436bc9-fc29-5d8d-9a50-c3bacfbaf566', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'corte', null, '2026-09-13 10:00:00-06', '2026-09-13 10:00:00-06', 'e8e03baf-44a8-5af4-8d68-e0f3e04315a9', '1474ad37-af06-5d6f-8c68-4edffb6f3eef', null, null, null, null, null, null, null, null),
  ('059a0541-0a20-5e3a-b218-ddbc962483ca', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'corte', null, '2026-09-13 12:00:00-06', '2026-09-13 12:00:00-06', 'e8e03baf-44a8-5af4-8d68-e0f3e04315a9', 'e2369747-95f8-59fa-a0e7-b56bbd81c43a', null, null, null, null, null, null, null, null),
  ('13a2a72f-b69f-5c28-88cc-a60665263bd0', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'abrir_corrida', null, '2026-09-15 06:00:00-06', '2026-09-15 06:00:00-06', 'e8e03baf-44a8-5af4-8d68-e0f3e04315a9', 'cf64c4a7-8ed1-50dd-a355-f717963193ed', null, null, null, null, null, null, null, null),
  ('574a04c1-3466-5415-9a19-c4ab891d0cf7', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'cerrar_corrida', null, '2026-09-15 14:00:00-06', '2026-09-15 14:00:00-06', 'e8e03baf-44a8-5af4-8d68-e0f3e04315a9', 'd71575ac-74c5-5d3e-b36f-87ed0ec93d84', null, null, null, null, null, null, null, null),
  ('8231d949-412a-5902-80ad-1400c06e5b0c', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'corte', null, '2026-09-15 08:00:00-06', '2026-09-15 08:00:00-06', 'e8e03baf-44a8-5af4-8d68-e0f3e04315a9', '82ba4428-7331-5f28-a403-b4e935f66816', null, null, null, null, null, null, null, null),
  ('a45f7146-569e-54b2-9a8a-f31509f0b28a', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'corte', null, '2026-09-15 10:00:00-06', '2026-09-15 10:00:00-06', 'e8e03baf-44a8-5af4-8d68-e0f3e04315a9', '1e408333-3484-5089-9895-e19c0cfb28d6', null, null, null, null, null, null, null, null),
  ('ac30d3b0-b678-5951-8cbc-b8e7649f4942', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'transferencia', null, '2026-09-16 09:00:00-06', '2026-09-16 09:00:00-06', '417489a3-9fa1-5914-bbc9-92d5334e9734', '47984f8a-d5fe-59d3-a01b-c390c12dc2d2', '79c172ed-037e-506b-aaaf-5ce0e3786115', 40, 51.6, null, 'a863fa73-1e8d-5762-9a09-d70f2861421d', 'renombrar', null, null),
  ('63a19b6f-1407-58c9-be57-a365c4659690', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'movimiento_granel', '66a151e2-9a2c-58be-ad4a-b117f1ddb717', '2026-09-16 11:00:00-06', '2026-09-16 11:00:00-06', '417489a3-9fa1-5914-bbc9-92d5334e9734', '54b7ab34-90ce-5aa6-8ccc-f61fab8b28bf', '79c172ed-037e-506b-aaaf-5ce0e3786115', 43.8, 47.0, null, 'a863fa73-1e8d-5762-9a09-d70f2861421d', null, null, null),
  ('60368fd2-ab44-5b3f-9afc-196117acec3c', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'movimiento_granel', 'f21aaad8-2ef6-556b-be55-64aa94431ab6', '2026-09-17 10:00:00-06', '2026-09-17 10:00:00-06', 'a88771d6-e323-5b36-991d-c42e5880e507', '08ab7b69-5b76-5372-96bc-c5d785007f9a', 'ab25af8c-1b30-5c28-866d-d1b1fec3d565', 602, 44.6, 'Puntas guardadas de corridas de agosto, sin lote', '5d6310f2-1e38-5087-a02d-716257bf0fcc', null, null, null),
  ('07b8acc6-4b24-5b80-9ab9-190a842c6de5', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'movimiento_granel', 'df427d88-600e-550e-a097-8ffe4f4dd556', '2026-09-18 09:30:00-06', '2026-09-18 09:30:00-06', 'a88771d6-e323-5b36-991d-c42e5880e507', '35a4103c-b45e-5e64-88ea-5e0062aa2231', 'ab25af8c-1b30-5c28-866d-d1b1fec3d565', 645.8, 44.9, 'Se conserva el folio del lote mayor', '5d6310f2-1e38-5087-a02d-716257bf0fcc', 'conservar', null, null),
  ('b42136c2-2b89-5a3a-877d-7ba5b374d71e', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'movimiento_granel', '688430a9-cd2f-5bae-add2-c59bc543d911', '2026-09-19 12:00:00-06', '2026-09-19 12:00:00-06', 'a88771d6-e323-5b36-991d-c42e5880e507', '1ecd0c93-8ab5-5602-9a3d-cd8e017b1e76', '79c172ed-037e-506b-aaaf-5ce0e3786115', 250, 46.0, null, '0fad69fd-ee8b-5d4f-9fdf-57c11a62561e', null, 'Destilados Hermanos Luna', 'Remisión 0452'),
  ('08425892-236e-51a0-a67a-a8549dea6b0e', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'movimiento_granel', '2d62ab89-6a11-558c-8b46-5c4d30aa1607', '2026-09-19 13:00:00-06', '2026-09-19 13:00:00-06', '417489a3-9fa1-5914-bbc9-92d5334e9734', 'edb99ba0-e1e2-5537-b7f0-9005ea3d1886', null, null, null, null, null, null, 'Laboratorio ficticio de Oaxaca', 'Análisis 2026-311'),
  ('2506ff1d-dde2-5fe2-b6a0-08d8df85638b', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'movimiento_granel', 'fa52f92b-de19-5d0c-972c-beb899bb2ccb', '2026-09-20 13:00:00-06', '2026-09-20 13:00:00-06', 'a88771d6-e323-5b36-991d-c42e5880e507', 'fac42efe-57e6-532d-8156-ff649279a923', null, null, null, null, null, null, null, null),
  ('d36f5f1c-8b67-5646-a604-e25085851347', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'movimiento_granel', '7b0ca7ca-f8ae-5f33-93d5-f0c174664ec1', '2026-09-22 13:00:00-06', '2026-09-22 13:00:00-06', 'a88771d6-e323-5b36-991d-c42e5880e507', '19acbfa4-6b5f-5e10-be05-a82959e592e7', null, null, null, null, null, null, 'Cliente ficticio S.A.', 'Remisión 118'),
  ('9926f1bc-7394-5113-ad7e-a50980966e9e', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'movimiento_granel', '85bbba70-4fc8-5fa2-ba03-af5475085b7a', '2026-09-22 13:00:00-06', '2026-09-22 13:00:00-06', 'a88771d6-e323-5b36-991d-c42e5880e507', 'ef7a7ad6-2540-5dcf-bdcf-e520d9e6baef', null, null, null, null, null, null, 'Cliente ficticio S.A.', null);

-- operation_warnings
insert into operation_warnings (operation_id, organization_id, code, note) values
  ('13a2a72f-b69f-5c28-88cc-a60665263bd0', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'mezcla_clases_2a', 'Había olla libre y poca cola; se juntó con el ordinario'),
  ('63a19b6f-1407-58c9-be57-a365c4659690', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'diferencia_volumen', 'Declarado 43.8 L; ledger 44.0 L. Contracción al agregar agua.');

-- lots
insert into lots (id, organization_id, operation_id, folio, material, liquid_class, origin, status, history, unit, initial_quantity, declared_origin) values
  ('5d6310f2-1e38-5087-a02d-716257bf0fcc', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'dbb84c5b-adca-565a-97d0-142cd0389064', 'G-INI-01', 'granel', 'mezcal', 'carga_inicial', 'activo', 'parcial', 'L', null, null),
  ('fcd93468-aba9-5f9a-8ff1-e8041c33e52b', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '9b403c43-6958-5c96-b667-973cf2ad6938', 'FER-T3-INI', 'fermentado', null, 'carga_inicial', 'activo', 'sin_historia', 'L', null, null),
  ('28c31736-e265-58d8-84bc-e2d7227fe0c4', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '90d7611b-acc0-59d1-8fa3-1fe183f9d025', 'MAG-001', 'maguey', null, 'producido', 'activo', 'completa', 'kg', 8000, null),
  ('2317004e-57d3-530d-85cd-70b9e0c3b824', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'c7f94b27-6b4d-581e-970e-3af11359e5bd', 'AC-001', 'agave_cocido', null, 'producido', 'activo', 'completa', 'kg', 6200, null),
  ('05be43d5-0d2f-5fa3-8675-825f1c398650', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '973e5d7c-6536-5027-b35b-dc962d95ed1e', 'F-001', 'formulacion', null, 'producido', 'activo', 'completa', 'L', 2800, null),
  ('33e7114d-2aef-51ea-9e0e-b6f490e57b83', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '973e5d7c-6536-5027-b35b-dc962d95ed1e', 'FER-T1-001', 'fermentado', null, 'producido', 'activo', 'completa', 'L', null, null),
  ('10293664-627e-55e4-80ae-e80309c9cc7e', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '973e5d7c-6536-5027-b35b-dc962d95ed1e', 'FER-T2-001', 'fermentado', null, 'producido', 'activo', 'completa', 'L', null, null),
  ('d8dbbf34-8889-5de4-9657-558675fcf33e', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'bf2eaa16-3f3e-5d47-9e8b-f2600c4a53b7', 'MEZ-001', 'destilado', 'mezcal', 'producido', 'agotado', 'completa', 'L', null, null),
  ('47364f91-6ad8-55e9-a92a-5d7c57730172', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'c4b2ac32-745e-5cde-8fbc-3414df667048', 'ORD-001', 'destilado', 'ordinario', 'producido', 'agotado', 'completa', 'L', null, null),
  ('9455002b-70eb-546d-8293-adaa09c96223', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '8d868fa2-8ec5-50a3-adda-28551769bfa9', 'COL-001', 'destilado', 'colas', 'producido', 'agotado', 'completa', 'L', null, null),
  ('8c0536f0-a84f-5e75-bf01-1c374fb0ba4a', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'a45f7146-569e-54b2-9a8a-f31509f0b28a', 'COL-002', 'destilado', 'colas', 'producido', 'activo', 'completa', 'L', null, null),
  ('a863fa73-1e8d-5762-9a09-d70f2861421d', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'ac30d3b0-b678-5951-8cbc-b8e7649f4942', 'G-2609-01', 'granel', 'mezcal', 'producido', 'agotado', 'completa', 'L', null, null),
  ('0fad69fd-ee8b-5d4f-9fdf-57c11a62561e', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'b42136c2-2b89-5a3a-877d-7ba5b374d71e', 'G-COMPRA-01', 'granel', 'mezcal', 'compra', 'activo', 'declarada', 'L', null, 'Espadín de Sola de Vega, según el proveedor');

-- lot_lineage
insert into lot_lineage (id, organization_id, operation_id, child_lot_id, parent_lot_id, quantity, unit, abv, retroactive) values
  ('6f49f08d-43c8-5196-ba79-d39c64662fba', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'c7f94b27-6b4d-581e-970e-3af11359e5bd', '2317004e-57d3-530d-85cd-70b9e0c3b824', '28c31736-e265-58d8-84bc-e2d7227fe0c4', 8000, 'kg', null, false),
  ('945ab911-95d2-5946-9e50-972b5f110c1c', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '973e5d7c-6536-5027-b35b-dc962d95ed1e', '05be43d5-0d2f-5fa3-8675-825f1c398650', '2317004e-57d3-530d-85cd-70b9e0c3b824', 6200, 'kg', null, false),
  ('c051c0c9-9b98-5983-b5af-28081747fd16', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '973e5d7c-6536-5027-b35b-dc962d95ed1e', '33e7114d-2aef-51ea-9e0e-b6f490e57b83', '05be43d5-0d2f-5fa3-8675-825f1c398650', 1400, 'L', null, false),
  ('b60e74c5-8e52-5bb3-be3b-4829dda76c77', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '973e5d7c-6536-5027-b35b-dc962d95ed1e', '10293664-627e-55e4-80ae-e80309c9cc7e', '05be43d5-0d2f-5fa3-8675-825f1c398650', 1400, 'L', null, false),
  ('b287e21f-cce0-533e-b702-d54ebefe2df8', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'bf2eaa16-3f3e-5d47-9e8b-f2600c4a53b7', 'd8dbbf34-8889-5de4-9657-558675fcf33e', '33e7114d-2aef-51ea-9e0e-b6f490e57b83', 8.0, 'L', null, false),
  ('2069c5a4-5c51-5772-a3de-bfd67a3183af', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'c4b2ac32-745e-5cde-8fbc-3414df667048', '47364f91-6ad8-55e9-a92a-5d7c57730172', '33e7114d-2aef-51ea-9e0e-b6f490e57b83', 40.0, 'L', null, false),
  ('d0ff9cdf-8ad4-56b5-acc2-0c775ae10163', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '8d868fa2-8ec5-50a3-adda-28551769bfa9', '9455002b-70eb-546d-8293-adaa09c96223', '33e7114d-2aef-51ea-9e0e-b6f490e57b83', 12.0, 'L', null, false),
  ('5d263e18-4e7e-556e-b39e-02b2ed232e9e', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'd5ad5cbf-facb-57ed-a386-6f15e94ee7a3', 'd8dbbf34-8889-5de4-9657-558675fcf33e', '33e7114d-2aef-51ea-9e0e-b6f490e57b83', 6.0, 'L', null, false),
  ('1142c6ee-dcd8-5985-b1fd-aa6d22c3aab8', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '54436bc9-fc29-5d8d-9a50-c3bacfbaf566', '47364f91-6ad8-55e9-a92a-5d7c57730172', '33e7114d-2aef-51ea-9e0e-b6f490e57b83', 34.0, 'L', null, false),
  ('6994141b-d685-597c-8da2-b2539de5244d', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '059a0541-0a20-5e3a-b218-ddbc962483ca', '9455002b-70eb-546d-8293-adaa09c96223', '33e7114d-2aef-51ea-9e0e-b6f490e57b83', 10.0, 'L', null, false),
  ('826f3716-a9ba-5246-bff0-4f1be212aa9e', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '8231d949-412a-5902-80ad-1400c06e5b0c', 'd8dbbf34-8889-5de4-9657-558675fcf33e', '47364f91-6ad8-55e9-a92a-5d7c57730172', 20.042, 'L', null, false),
  ('7d697bb3-3dcb-55b2-8bc3-d6da77ef8d45', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '8231d949-412a-5902-80ad-1400c06e5b0c', 'd8dbbf34-8889-5de4-9657-558675fcf33e', '9455002b-70eb-546d-8293-adaa09c96223', 5.958, 'L', null, false),
  ('2f038e4e-d77f-541d-9db9-5a431c623f76', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'a45f7146-569e-54b2-9a8a-f31509f0b28a', '8c0536f0-a84f-5e75-bf01-1c374fb0ba4a', '47364f91-6ad8-55e9-a92a-5d7c57730172', 12.333, 'L', null, false),
  ('26565c85-66a8-5aa5-97cb-ddf615ea68a8', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'a45f7146-569e-54b2-9a8a-f31509f0b28a', '8c0536f0-a84f-5e75-bf01-1c374fb0ba4a', '9455002b-70eb-546d-8293-adaa09c96223', 3.667, 'L', null, false),
  ('5212d283-c5af-5024-b5a2-a9f782cf13f0', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'ac30d3b0-b678-5951-8cbc-b8e7649f4942', 'a863fa73-1e8d-5762-9a09-d70f2861421d', 'd8dbbf34-8889-5de4-9657-558675fcf33e', 40, 'L', 51.6, false),
  ('900d04bc-fb28-5f4c-924a-8bb7bdaf6e29', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '07b8acc6-4b24-5b80-9ab9-190a842c6de5', '5d6310f2-1e38-5087-a02d-716257bf0fcc', 'a863fa73-1e8d-5762-9a09-d70f2861421d', 43.8, 'L', 47.0, false);

-- lot_external_sources
insert into lot_external_sources (lot_id, organization_id, supplier_id, certificate_folio, certifying_body, declared_species_id, declared_predio) values
  ('0fad69fd-ee8b-5d4f-9fdf-57c11a62561e', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '3037cfb3-d2c6-5dcd-bb3b-743136024e9c', null, null, '67a96efd-2c72-528e-8682-d144fe1f802c', 'Sola de Vega');

-- maguey_receptions
insert into maguey_receptions (lot_id, organization_id, species_id, predio_id, supplier_id, pina_count, weight_kg, quality_note) values
  ('28c31736-e265-58d8-84bc-e2d7227fe0c4', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '67a96efd-2c72-528e-8682-d144fe1f802c', '031951e6-6a4f-5abc-8db6-79dfc4a43afa', 'd1b5acf3-3fc9-59f3-a7d5-b82846bd82bc', 132, 8000, 'Piñas de 8 años, buen tamaño');

-- liquid_movements
insert into liquid_movements (id, organization_id, operation_id, movement_type, lot_id, source_resource_id, dest_resource_id, volume_l, abv) values
  ('53a429f7-ea05-5795-bdbf-933b7a7354b1', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'dbb84c5b-adca-565a-97d0-142cd0389064', 'entrada', '5d6310f2-1e38-5087-a02d-716257bf0fcc', null, 'ab25af8c-1b30-5c28-866d-d1b1fec3d565', 600, 44.2),
  ('d0c7be1d-6579-520b-a4de-de42cfc194c6', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '9b403c43-6958-5c96-b667-973cf2ad6938', 'entrada', 'fcd93468-aba9-5f9a-8ff1-e8041c33e52b', null, 'd4bef388-6b84-5a2d-8471-41c2d4e05e94', 1300, null),
  ('8e1806bb-3ea8-5c14-9c96-b6c6774c164c', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '973e5d7c-6536-5027-b35b-dc962d95ed1e', 'entrada', '33e7114d-2aef-51ea-9e0e-b6f490e57b83', null, '32a9508c-17b3-51b8-9c03-21af27b29ac5', 1400, null),
  ('19d1f782-9ebb-5fe6-ad82-ebd8ed793285', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '973e5d7c-6536-5027-b35b-dc962d95ed1e', 'entrada', '10293664-627e-55e4-80ae-e80309c9cc7e', null, '55226f86-ec84-5917-a97b-23e072c1a7fc', 1400, null),
  ('538e5b6b-8754-5562-baf4-a5cce298c332', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '8784ef6e-dc22-59e7-8ecc-ac58f7964d0c', 'carga_alambique', '33e7114d-2aef-51ea-9e0e-b6f490e57b83', '32a9508c-17b3-51b8-9c03-21af27b29ac5', null, 290, null),
  ('d3f9ec61-a049-53d4-b346-c49e42228b14', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'bf2eaa16-3f3e-5d47-9e8b-f2600c4a53b7', 'corte', 'd8dbbf34-8889-5de4-9657-558675fcf33e', null, '863122f8-e9e7-51ac-b5af-d86f9e56e573', 8, 51.0),
  ('03abe73b-91a8-5228-aad9-103488ba78b5', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'c4b2ac32-745e-5cde-8fbc-3414df667048', 'corte', '47364f91-6ad8-55e9-a92a-5d7c57730172', null, 'ffffb8f2-cc46-57d0-89c2-bf433f1657e3', 40, 24.0),
  ('aba57f66-6f2e-5c09-a5ec-dda3f4c1d9d7', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '8d868fa2-8ec5-50a3-adda-28551769bfa9', 'corte', '9455002b-70eb-546d-8293-adaa09c96223', null, 'ea0bebaa-bb90-52be-96f7-ca86a2be27a3', 12, 9.0),
  ('2ab072f6-f8f8-51d6-9c5b-186ea07e2751', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '97dad407-7879-5e96-b375-d8c85c9a70c5', 'carga_alambique', '33e7114d-2aef-51ea-9e0e-b6f490e57b83', '32a9508c-17b3-51b8-9c03-21af27b29ac5', null, 240, null),
  ('0677e694-efa4-57f7-9031-ac2d1e7cac00', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'd5ad5cbf-facb-57ed-a386-6f15e94ee7a3', 'corte', 'd8dbbf34-8889-5de4-9657-558675fcf33e', null, '863122f8-e9e7-51ac-b5af-d86f9e56e573', 6, 50.0),
  ('266825e5-38a4-5836-af87-13f1dbabf9b0', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '54436bc9-fc29-5d8d-9a50-c3bacfbaf566', 'corte', '47364f91-6ad8-55e9-a92a-5d7c57730172', null, 'ffffb8f2-cc46-57d0-89c2-bf433f1657e3', 34, 23.0),
  ('49e793e0-7b93-5385-9011-2051b3bdf898', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '059a0541-0a20-5e3a-b218-ddbc962483ca', 'corte', '9455002b-70eb-546d-8293-adaa09c96223', null, 'ea0bebaa-bb90-52be-96f7-ca86a2be27a3', 10, 8.0),
  ('1a269beb-92b6-501e-b539-725ddc97988c', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '13a2a72f-b69f-5c28-88cc-a60665263bd0', 'carga_alambique', '47364f91-6ad8-55e9-a92a-5d7c57730172', 'ffffb8f2-cc46-57d0-89c2-bf433f1657e3', null, 74, null),
  ('da25c04a-56a2-5542-9629-9185ed00b134', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '13a2a72f-b69f-5c28-88cc-a60665263bd0', 'carga_alambique', '9455002b-70eb-546d-8293-adaa09c96223', 'ea0bebaa-bb90-52be-96f7-ca86a2be27a3', null, 22, null),
  ('55f8700c-fc81-59ed-8313-33f7b40d8586', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '8231d949-412a-5902-80ad-1400c06e5b0c', 'corte', 'd8dbbf34-8889-5de4-9657-558675fcf33e', null, '863122f8-e9e7-51ac-b5af-d86f9e56e573', 26, 52.5),
  ('df5de70f-7011-587b-ab03-8d628dab3c1f', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'a45f7146-569e-54b2-9a8a-f31509f0b28a', 'corte', '8c0536f0-a84f-5e75-bf01-1c374fb0ba4a', null, 'ea0bebaa-bb90-52be-96f7-ca86a2be27a3', 16, 10.0),
  ('ea87ad90-80e2-52a5-b0c0-e5e4c79b154f', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'ac30d3b0-b678-5951-8cbc-b8e7649f4942', 'consumo', 'd8dbbf34-8889-5de4-9657-558675fcf33e', '863122f8-e9e7-51ac-b5af-d86f9e56e573', null, 40, null),
  ('a7717691-7df6-5b9e-aa0e-23b0d179f6e0', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'ac30d3b0-b678-5951-8cbc-b8e7649f4942', 'entrada', 'a863fa73-1e8d-5762-9a09-d70f2861421d', null, '79c172ed-037e-506b-aaaf-5ce0e3786115', 40, 51.6),
  ('763e72f5-df18-56c5-aa96-fd3b444ce0ea', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '63a19b6f-1407-58c9-be57-a365c4659690', 'entrada', 'a863fa73-1e8d-5762-9a09-d70f2861421d', null, '79c172ed-037e-506b-aaaf-5ce0e3786115', 4, null),
  ('478896ed-62f6-55d7-8b87-f1b64d21c4bc', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '63a19b6f-1407-58c9-be57-a365c4659690', 'conciliacion', 'a863fa73-1e8d-5762-9a09-d70f2861421d', '79c172ed-037e-506b-aaaf-5ce0e3786115', null, 0.2, null),
  ('ba517524-c612-542d-b7c8-b96831ea92ec', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '60368fd2-ab44-5b3f-9afc-196117acec3c', 'entrada', '5d6310f2-1e38-5087-a02d-716257bf0fcc', null, 'ab25af8c-1b30-5c28-866d-d1b1fec3d565', 2, 68.0),
  ('16e9d3d3-b051-58da-8c4e-34bf043fbe84', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '07b8acc6-4b24-5b80-9ab9-190a842c6de5', 'consumo', 'a863fa73-1e8d-5762-9a09-d70f2861421d', '79c172ed-037e-506b-aaaf-5ce0e3786115', null, 43.8, null),
  ('19d59875-7453-5285-8995-21978f1714c0', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '07b8acc6-4b24-5b80-9ab9-190a842c6de5', 'entrada', '5d6310f2-1e38-5087-a02d-716257bf0fcc', null, 'ab25af8c-1b30-5c28-866d-d1b1fec3d565', 43.8, 47.0),
  ('0874c5f1-ee64-5db6-8dd3-9974f8fe2e4b', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'b42136c2-2b89-5a3a-877d-7ba5b374d71e', 'entrada', '0fad69fd-ee8b-5d4f-9fdf-57c11a62561e', null, '79c172ed-037e-506b-aaaf-5ce0e3786115', 250, 46.0),
  ('117ad20c-28ee-5c01-87d5-44679991a74c', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '08425892-236e-51a0-a67a-a8549dea6b0e', 'salida', '5d6310f2-1e38-5087-a02d-716257bf0fcc', 'ab25af8c-1b30-5c28-866d-d1b1fec3d565', null, 1, null),
  ('fb59ea3a-cbc1-54c5-aa80-dde884746b40', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '2506ff1d-dde2-5fe2-b6a0-08d8df85638b', 'salida', '5d6310f2-1e38-5087-a02d-716257bf0fcc', 'ab25af8c-1b30-5c28-866d-d1b1fec3d565', null, 2, null),
  ('29a69e76-0a83-5774-9c93-6fdb325d959e', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'd36f5f1c-8b67-5646-a604-e25085851347', 'salida', '5d6310f2-1e38-5087-a02d-716257bf0fcc', 'ab25af8c-1b30-5c28-866d-d1b1fec3d565', null, 300, null),
  ('69826718-232c-5352-89be-173c789eb965', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '9926f1bc-7394-5113-ad7e-a50980966e9e', 'salida', '5d6310f2-1e38-5087-a02d-716257bf0fcc', 'ab25af8c-1b30-5c28-866d-d1b1fec3d565', null, 1, null);

-- attachments
insert into attachments (id, organization_id, operation_id, lot_id, kind_catalog, kind_item_id, storage_path, caption) values
  ('c53faa19-4982-57d1-92e9-d5b61c05a1cd', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'b42136c2-2b89-5a3a-877d-7ba5b374d71e', '0fad69fd-ee8b-5d4f-9fdf-57c11a62561e', 'tipo_adjunto', '0522e23b-3b1d-58be-b50c-8a6ed0627c9f', 'evidencias/b66cf468-47f7-51ee-a8f2-994d907440b9/0fad69fd-ee8b-5d4f-9fdf-57c11a62561e/remision-0452.jpg', 'Remisión del proveedor');

-- roasting_runs
insert into roasting_runs (id, organization_id, operation_id, closed_operation_id, folio, oven_id, status, started_at, ended_at, cooked_kg, fuel_note, output_lot_id) values
  ('a6bbe833-f46a-5e04-9262-e290b9624402', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '0c10e939-4a94-599c-be3b-c3a7ce6ec310', 'c7f94b27-6b4d-581e-970e-3af11359e5bd', 'HOR-001', '1e75aadc-221d-5614-98a3-de77defa5bb6', 'cerrada', '2026-09-02 12:00:00-06', '2026-09-06 08:00:00-06', 6200, 'Leña de encino', '2317004e-57d3-530d-85cd-70b9e0c3b824');

-- roasting_run_inputs
insert into roasting_run_inputs (run_id, organization_id, lot_id, quantity_kg) values
  ('a6bbe833-f46a-5e04-9262-e290b9624402', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '28c31736-e265-58d8-84bc-e2d7227fe0c4', 8000);

-- formulations
insert into formulations (id, organization_id, operation_id, folio, mill_id, method_note, water_l, result_volume_l, output_lot_id) values
  ('3dbf1551-c331-5a4b-ab2c-27d2208770b3', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '973e5d7c-6536-5027-b35b-dc962d95ed1e', 'F-001', 'd79b3908-f952-5556-a7bd-b55c6a071001', 'Tahona con mula', 1900, 2800, '05be43d5-0d2f-5fa3-8675-825f1c398650');

-- formulation_inputs
insert into formulation_inputs (formulation_id, organization_id, lot_id, quantity_kg) values
  ('3dbf1551-c331-5a4b-ab2c-27d2208770b3', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '2317004e-57d3-530d-85cd-70b9e0c3b824', 6200);

-- formulation_supplies
insert into formulation_supplies (formulation_id, organization_id, supply_id, quantity) values
  ('3dbf1551-c331-5a4b-ab2c-27d2208770b3', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '1d55b594-99c2-5fe5-8081-4b6874e5a1d5', 20);

-- fermentation_cycles
insert into fermentation_cycles (id, organization_id, operation_id, tina_id, lot_id, status, formulation_id, ready_operation_id) values
  ('e3e94e31-e89b-5c85-a8d0-6c2f50ebd39a', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '9b403c43-6958-5c96-b667-973cf2ad6938', 'd4bef388-6b84-5a2d-8471-41c2d4e05e94', 'fcd93468-aba9-5f9a-8ff1-e8041c33e52b', 'fermentando', null, null),
  ('035bf790-9290-55aa-bac0-8a0c4206f04a', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '973e5d7c-6536-5027-b35b-dc962d95ed1e', '32a9508c-17b3-51b8-9c03-21af27b29ac5', '33e7114d-2aef-51ea-9e0e-b6f490e57b83', 'en_vaciado', '3dbf1551-c331-5a4b-ab2c-27d2208770b3', 'e13566e5-27ec-5735-a1b6-e16320757cd5'),
  ('f867a3ac-6b23-5879-b23e-17820afb444c', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '973e5d7c-6536-5027-b35b-dc962d95ed1e', '55226f86-ec84-5917-a97b-23e072c1a7fc', '10293664-627e-55e4-80ae-e80309c9cc7e', 'fermentando', '3dbf1551-c331-5a4b-ab2c-27d2208770b3', null);

-- fermentation_measurements
insert into fermentation_measurements (id, organization_id, operation_id, cycle_id, day_no, mode, activity) values
  ('9e898669-e43a-57ff-9bf2-8b5f29ccbf3f', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'b16ca2ef-d150-5c69-bd3a-33583bf78e38', '035bf790-9290-55aa-bac0-8a0c4206f04a', 1, 'minimo', 4),
  ('d02a95b2-b214-5195-b9c9-683f07198c87', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '7055fc6b-78ff-5279-8e3e-3c39862ac99c', '035bf790-9290-55aa-bac0-8a0c4206f04a', 2, 'minimo', 7),
  ('93c4cac8-b7aa-5c38-b7e2-07f030eeb786', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'd045ba98-5826-5cf4-b801-532521c80618', '035bf790-9290-55aa-bac0-8a0c4206f04a', 3, 'minimo', 8),
  ('fa241739-f079-5e7b-b293-1c8599941854', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '482db62c-542a-53fe-afde-85fd2dc89e5f', '035bf790-9290-55aa-bac0-8a0c4206f04a', 4, 'minimo', 6),
  ('f0601fe6-20b0-569d-b59e-f9d0a440e61a', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '4d344728-f48d-5b75-9361-873592c5ddb8', '035bf790-9290-55aa-bac0-8a0c4206f04a', 5, 'minimo', 3),
  ('6144d628-b3cd-5bc1-8f64-330c944c2a01', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'df9bd519-800a-5d77-8450-574ee1452944', 'f867a3ac-6b23-5879-b23e-17820afb444c', 1, 'minimo', 3),
  ('f7781e09-3439-56a0-832a-f55b88ae4209', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '9f4f4aec-843d-5639-b30b-3deb96e2cc5f', 'f867a3ac-6b23-5879-b23e-17820afb444c', 2, 'minimo', 6),
  ('d343bd33-f9f4-57ce-b1fd-e24e2af8f144', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '16d569a9-e2f2-5961-8c2d-2c739404247e', 'f867a3ac-6b23-5879-b23e-17820afb444c', 3, 'minimo', 8);

-- measurement_readings
insert into measurement_readings (measurement_id, organization_id, variable, zone, reading_no, value) values
  ('9e898669-e43a-57ff-9bf2-8b5f29ccbf3f', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'temperatura', 'unica', 1, 27.5),
  ('9e898669-e43a-57ff-9bf2-8b5f29ccbf3f', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'brix', 'unica', 1, 12.0),
  ('d02a95b2-b214-5195-b9c9-683f07198c87', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'temperatura', 'unica', 1, 29.0),
  ('d02a95b2-b214-5195-b9c9-683f07198c87', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'brix', 'unica', 1, 9.5),
  ('93c4cac8-b7aa-5c38-b7e2-07f030eeb786', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'temperatura', 'unica', 1, 30.5),
  ('93c4cac8-b7aa-5c38-b7e2-07f030eeb786', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'brix', 'unica', 1, 6.0),
  ('fa241739-f079-5e7b-b293-1c8599941854', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'temperatura', 'unica', 1, 29.5),
  ('fa241739-f079-5e7b-b293-1c8599941854', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'brix', 'unica', 1, 3.5),
  ('f0601fe6-20b0-569d-b59e-f9d0a440e61a', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'temperatura', 'unica', 1, 28.0),
  ('f0601fe6-20b0-569d-b59e-f9d0a440e61a', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'brix', 'unica', 1, 1.5),
  ('6144d628-b3cd-5bc1-8f64-330c944c2a01', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'temperatura', 'unica', 1, 27.0),
  ('6144d628-b3cd-5bc1-8f64-330c944c2a01', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'brix', 'unica', 1, 12.2),
  ('f7781e09-3439-56a0-832a-f55b88ae4209', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'temperatura', 'unica', 1, 28.5),
  ('f7781e09-3439-56a0-832a-f55b88ae4209', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'brix', 'unica', 1, 10.1),
  ('d343bd33-f9f4-57ce-b1fd-e24e2af8f144', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'temperatura', 'unica', 1, 30.0),
  ('d343bd33-f9f4-57ce-b1fd-e24e2af8f144', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'brix', 'unica', 1, 7.4);

-- distillation_runs
insert into distillation_runs (id, organization_id, operation_id, closed_operation_id, folio, still_id, status, "pass") values
  ('6315291a-6943-50ac-90d7-735770f3e875', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '8784ef6e-dc22-59e7-8ecc-ac58f7964d0c', 'cc83b84c-0e06-58f6-9087-7700d10a928b', 'DES-001', '65c839c8-13c0-5ad1-95be-642782860c7c', 'cerrada', 'primera'),
  ('133433db-1837-5b85-bccc-c263cd5dd33d', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '97dad407-7879-5e96-b375-d8c85c9a70c5', '1f273880-c320-5dcd-af8d-c4676a33a228', 'DES-002', '19a3b420-6f96-5e62-92c7-7f09ba5e15a1', 'cerrada', 'primera'),
  ('42532f2c-e46a-5e90-8dfa-6fb2b1960702', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '13a2a72f-b69f-5c28-88cc-a60665263bd0', '574a04c1-3466-5415-9a19-c4ab891d0cf7', 'DES-003', '65c839c8-13c0-5ad1-95be-642782860c7c', 'cerrada', 'segunda');

-- distillation_run_inputs
insert into distillation_run_inputs (run_id, organization_id, movement_id) values
  ('6315291a-6943-50ac-90d7-735770f3e875', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '538e5b6b-8754-5562-baf4-a5cce298c332'),
  ('133433db-1837-5b85-bccc-c263cd5dd33d', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '2ab072f6-f8f8-51d6-9c5b-186ea07e2751'),
  ('42532f2c-e46a-5e90-8dfa-6fb2b1960702', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '1a269beb-92b6-501e-b539-725ddc97988c'),
  ('42532f2c-e46a-5e90-8dfa-6fb2b1960702', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'da25c04a-56a2-5542-9629-9185ed00b134');

-- distillation_cuts
insert into distillation_cuts (run_id, organization_id, movement_id, cut_class) values
  ('6315291a-6943-50ac-90d7-735770f3e875', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'd3f9ec61-a049-53d4-b346-c49e42228b14', 'mezcal'),
  ('6315291a-6943-50ac-90d7-735770f3e875', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '03abe73b-91a8-5228-aad9-103488ba78b5', 'ordinario'),
  ('6315291a-6943-50ac-90d7-735770f3e875', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'aba57f66-6f2e-5c09-a5ec-dda3f4c1d9d7', 'colas'),
  ('133433db-1837-5b85-bccc-c263cd5dd33d', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '0677e694-efa4-57f7-9031-ac2d1e7cac00', 'mezcal'),
  ('133433db-1837-5b85-bccc-c263cd5dd33d', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '266825e5-38a4-5836-af87-13f1dbabf9b0', 'ordinario'),
  ('133433db-1837-5b85-bccc-c263cd5dd33d', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '49e793e0-7b93-5385-9011-2051b3bdf898', 'colas'),
  ('42532f2c-e46a-5e90-8dfa-6fb2b1960702', 'b66cf468-47f7-51ee-a8f2-994d907440b9', '55f8700c-fc81-59ed-8313-33f7b40d8586', 'mezcal'),
  ('42532f2c-e46a-5e90-8dfa-6fb2b1960702', 'b66cf468-47f7-51ee-a8f2-994d907440b9', 'df5de70f-7011-587b-ab03-8d628dab3c1f', 'colas');

commit;