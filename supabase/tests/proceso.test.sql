-- pgTAP · Proceso (Fase 5): las vistas de 0026 contra la simulación de
-- Cuatro Vientos (deben coincidir con PULZ_MAESTRO.md §15.1 y con la
-- semilla), aislamiento (Prueba B ve vacío) y el bucket 'evidencias' con
-- sus políticas y la fila de attachments (0027).
--     supabase db query --linked -f supabase/tests/proceso.test.sql

begin;

create function pg_temp.como(u uuid) returns void language plpgsql as $$
begin
  execute 'set local role authenticated';
  execute format('set local request.jwt.claims = %L', json_build_object('sub', u, 'role', 'authenticated')::text);
end $$;

create function pg_temp.test_proceso() returns setof text language plpgsql as $$
declare
  a uuid := 'b66cf468-47f7-51ee-a8f2-994d907440b9';      -- Cuatro Vientos
  b uuid := 'b0000000-0000-4000-8000-0000000000b0';      -- Prueba B
  admin_a uuid := 'a88771d6-e323-5b36-991d-c42e5880e507'; -- Benito
  oper_a  uuid := 'e8e03baf-44a8-5af4-8d68-e0f3e04315a9'; -- Tomás
  admin_b uuid := 'c0ffee00-0000-4000-8000-0000000000b1';
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
  select id into v_op   from operations where organization_id = a and idempotency_key = '22f10d47-238b-5768-a841-6bf074592670';
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
