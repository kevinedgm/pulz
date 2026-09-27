-- 0001 · Extensiones y tipos de dominio.
-- Solo lo que la lógica necesita fijo (PULZ_MAESTRO.md §10.1: "ENUM solo para
-- mecánica"). Todo lo que un palenque nombra a su manera es catálogo (0004).

create extension if not exists pgcrypto;
-- pgTAP solo se usa en pruebas (supabase test db --linked). No lo usa la app.
create extension if not exists pgtap with schema extensions;

create type member_role         as enum ('admin', 'productor', 'operador');
create type member_status       as enum ('invitado', 'activo', 'suspendido');
create type subscription_status as enum ('gratis', 'prueba', 'activa', 'vencida', 'cancelada');
create type resource_kind       as enum ('horno', 'molino', 'tina', 'alambique', 'colector', 'tanque');
create type capacity_policy     as enum ('estricta', 'flexible', 'libre');
create type material_kind       as enum ('maguey', 'agave_cocido', 'formulacion', 'fermentado', 'destilado', 'granel');
create type liquid_class        as enum ('mezcal', 'ordinario', 'colas', 'puntas');
create type lot_origin          as enum ('producido', 'compra', 'carga_inicial', 'mezcla');
create type lot_status          as enum ('activo', 'agotado', 'cerrado');
create type history_level       as enum ('completa', 'parcial', 'declarada', 'sin_historia');
create type run_status          as enum ('abierta', 'cerrada');
create type distillation_pass   as enum ('primera', 'segunda');
create type cycle_status        as enum ('fermentando', 'lista', 'en_vaciado', 'cerrado');
create type measurement_mode    as enum ('minimo', 'completo');
create type reading_variable    as enum ('temperatura', 'brix', 'dulzor', 'acidez');
create type reading_zone        as enum ('unica', 'superficie', 'fondo');
create type folio_decision      as enum ('conservar', 'renombrar');
create type concept_direction   as enum ('entrada', 'salida');
create type source_lot_rule     as enum ('no_aplica', 'opcional', 'requerido');

-- Qué catálogos existen (los valores dentro de cada uno son editables)
create type catalog_kind as enum (
  'tipo_horno', 'tipo_molino', 'tipo_tina', 'tipo_alambique', 'tipo_colector',
  'tipo_tanque', 'tipo_proveedor', 'tipo_adjunto', 'unidad_insumo');

-- Qué hace cada operación (la mecánica, no la etiqueta que ve el usuario)
create type operation_kind as enum (
  'recepcion_maguey', 'entrada_directa', 'abrir_horneado', 'cerrar_horneado',
  'formulacion', 'medicion', 'anular_medicion', 'tina_lista', 'cerrar_ciclo',
  'abrir_corrida', 'corte', 'cerrar_corrida', 'transferencia',
  'movimiento_granel', 'completar_historia', 'correccion');

-- Tipos de pata en el ledger
create type movement_type as enum (
  'entrada',          -- algo entra al sistema (source null)
  'salida',           -- algo sale del sistema (dest null)
  'transferencia',    -- mismo lote cambia de recurso
  'carga_alambique',  -- sale de tina/colector y se consume en la corrida
  'corte',            -- nace en la corrida y entra a un colector (source null)
  'consumo',          -- un lote se absorbe en otro (unión, renombre)
  'conciliacion',     -- diferencia entre volumen declarado y ledger
  'correccion');

-- updated_at lo fija el servidor (§10.1). Se usa en catálogos, recursos,
-- ajustes y suscripciones.
create function set_updated_at() returns trigger
language plpgsql set search_path = public as $$
begin
  new.updated_at := now();
  return new;
end $$;
