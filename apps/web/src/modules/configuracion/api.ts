// Configuración (PULZ_MAESTRO.md §13.2 #8; ronda configuracion/r01). Todo
// va por PostgREST bajo RLS (0013): admin escribe recursos, catálogos,
// ajustes y marca; nadie borra (active = false). recurso_en_uso (0025)
// avisa antes de desactivar. El logo va a Storage 'branding' (0024).
import { supabase } from "../../shared/supabase/client"
import { ErrorAcceso, esErrorDeRed, MENSAJE_RED } from "../../shared/supabase/errores"

export type ResourceKind = "horno" | "molino" | "tina" | "alambique" | "colector" | "tanque"
export type CapacityPolicy = "estricta" | "flexible" | "libre"
export type LiquidClass = "mezcal" | "ordinario" | "colas" | "puntas"
export type CatalogKind =
  | "tipo_horno"
  | "tipo_molino"
  | "tipo_tina"
  | "tipo_alambique"
  | "tipo_colector"
  | "tipo_tanque"
  | "tipo_proveedor"
  | "tipo_adjunto"
  | "unidad_insumo"

export const KINDS: {
  valor: ResourceKind
  etiqueta: string
  plural: string
  unidad: "L" | "kg"
}[] = [
  { valor: "horno", etiqueta: "Horno", plural: "Hornos", unidad: "kg" },
  { valor: "molino", etiqueta: "Molino", plural: "Molinos", unidad: "kg" },
  { valor: "tina", etiqueta: "Tina", plural: "Tinas", unidad: "L" },
  { valor: "alambique", etiqueta: "Alambique", plural: "Alambiques", unidad: "L" },
  { valor: "colector", etiqueta: "Colector", plural: "Colectores", unidad: "L" },
  { valor: "tanque", etiqueta: "Tanque", plural: "Tanques", unidad: "L" },
]
export const catalogoDeKind = (k: ResourceKind): CatalogKind => `tipo_${k}` as CatalogKind

export interface Recurso {
  id: string
  organization_id: string
  kind: ResourceKind
  code: string
  type_item_id: string | null
  capacity: number | null
  capacity_unit: string
  capacity_policy: CapacityPolicy
  liquid_class: LiquidClass | null
  location: string | null
  active: boolean
}
export interface RecursoEnUso {
  resource_id: string
  saldo_l: number
  ciclos_abiertos: number
}
export interface ElementoCatalogo {
  id: string
  catalog: CatalogKind
  name: string
  template_id: string | null
  sort_order: number
  active: boolean
}
export interface Concepto {
  id: string
  direction: "entrada" | "salida"
  name: string
  source_lot: "no_aplica" | "opcional" | "requerido"
  creates_lot: boolean
  asks_result: boolean
  asks_counterparty: boolean
  template_id: string | null
  active: boolean
}
export interface Especie {
  id: string
  common_name: string
  scientific_name: string | null
  template_id: string | null
  active: boolean
}
export interface Predio {
  id: string
  name: string
  municipality: string | null
  owner_name: string | null
  notes: string | null
  active: boolean
}
export interface Proveedor {
  id: string
  name: string
  type_item_id: string | null
  phone: string | null
  notes: string | null
  active: boolean
}
export interface Insumo {
  id: string
  name: string
  unit_item_id: string
  active: boolean
}
export interface Ajustes {
  organization_id: string
  record_puntas: boolean
  measurement_mode: "minimo" | "completo"
  warn_mixed_second_pass: boolean
  fermentation_expected_days: number
  measurement_reminder_hour: number
  default_folio_decision: "conservar" | "renombrar"
  abv_warn_min: number
  abv_warn_max: number
  brix_warn_min: number
  brix_warn_max: number
}
export interface Marca {
  id: string
  name: string
  slug: string
  state: string | null
  brand_color: string | null
  logo_path: string | null
  welcome_message: string | null
}

// Errores de PostgREST/Postgres → texto para la persona (bajo el campo)
export function mensajeDeError(
  e: unknown,
  contexto: "recurso" | "catalogo" | "ajustes" | "marca",
): string {
  const msg = (e as { message?: string })?.message ?? String(e)
  const code = (e as { code?: string })?.code
  if (esErrorDeRed(e)) return MENSAJE_RED
  if (code === "23505" || /duplicate key|already exists/i.test(msg)) {
    return contexto === "recurso"
      ? "Ya hay un recurso con ese código."
      : contexto === "marca"
        ? "Ese enlace ya está en uso."
        : "Ya existe un elemento con ese nombre."
  }
  if (/reservado|reserved/i.test(msg)) return "Ese enlace está reservado."
  if (/retirado|slug_history|otra empresa/i.test(msg)) return "Ese enlace ya lo usó otra empresa."
  if (code === "23514" || /check constraint|violates check/i.test(msg)) {
    if (/abv/i.test(msg) || /brix/i.test(msg)) return "El mínimo debe ser menor que el máximo."
    if (/brand_color/i.test(msg)) return "El color debe ser #RRGGBB."
    if (/welcome_message/i.test(msg)) return "El mensaje no puede pasar de 140 caracteres."
    if (/slug/i.test(msg)) return "Minúsculas, números y guiones (3 a 40), sin guiones dobles."
    if (/liquid_class|colector/i.test(msg)) return "Un colector necesita clase de líquido."
    return "Un valor no es válido."
  }
  if (/no es de tipo/i.test(msg)) return "El tipo no corresponde a ese recurso."
  if (code === "42501" || /row-level security/i.test(msg))
    return "No tienes permiso para hacer esto."
  return msg
}

function lanzar(e: unknown, contexto: Parameters<typeof mensajeDeError>[1]): never {
  throw new ErrorAcceso(esErrorDeRed(e) ? "RED" : "SERVIDOR", mensajeDeError(e, contexto))
}

// ── Recursos ─────────────────────────────────────────────────────────────
export async function recursos(org: string): Promise<Recurso[]> {
  const { data, error } = await supabase
    .from("resources")
    .select(
      "id, organization_id, kind, code, type_item_id, capacity, capacity_unit, capacity_policy, liquid_class, location, active",
    )
    .eq("organization_id", org)
    .order("kind")
    .order("code")
  if (error) lanzar(error, "recurso")
  return (data ?? []) as Recurso[]
}
export async function recursosEnUso(org: string): Promise<RecursoEnUso[]> {
  const { data, error } = await supabase.rpc("recurso_en_uso", { p_org: org })
  if (error) lanzar(error, "recurso")
  return (data ?? []) as RecursoEnUso[]
}
export type RecursoAlta = Omit<Recurso, "id" | "organization_id" | "active">
export async function crearRecurso(org: string, r: RecursoAlta): Promise<void> {
  const { error } = await supabase.from("resources").insert({ organization_id: org, ...r })
  if (error) lanzar(error, "recurso")
}
export async function editarRecurso(
  org: string,
  id: string,
  r: Partial<Omit<Recurso, "id" | "organization_id" | "kind">>,
): Promise<void> {
  const { error, count } = await supabase
    .from("resources")
    .update(r, { count: "exact" })
    .eq("organization_id", org)
    .eq("id", id)
  if (error) lanzar(error, "recurso")
  if (count === 0) throw new ErrorAcceso("SERVIDOR", "No tienes permiso para hacer esto.")
}

// ── Catálogos ────────────────────────────────────────────────────────────
export const CATALOGOS: { valor: CatalogKind; etiqueta: string; singular: string }[] = [
  { valor: "tipo_horno", etiqueta: "Tipos de horno", singular: "tipo de horno" },
  { valor: "tipo_molino", etiqueta: "Tipos de molino", singular: "tipo de molino" },
  { valor: "tipo_tina", etiqueta: "Tipos de tina", singular: "tipo de tina" },
  { valor: "tipo_alambique", etiqueta: "Tipos de alambique", singular: "tipo de alambique" },
  { valor: "tipo_colector", etiqueta: "Tipos de colector", singular: "tipo de colector" },
  { valor: "tipo_tanque", etiqueta: "Tipos de tanque", singular: "tipo de tanque" },
  { valor: "tipo_proveedor", etiqueta: "Tipos de proveedor", singular: "tipo de proveedor" },
  { valor: "tipo_adjunto", etiqueta: "Tipos de adjunto", singular: "tipo de adjunto" },
  { valor: "unidad_insumo", etiqueta: "Unidades de insumo", singular: "unidad de insumo" },
]
export type Tabla =
  "catalog_items" | "movement_concepts" | "species" | "predios" | "suppliers" | "supplies"

export async function elementosCatalogo(
  org: string,
  catalog: CatalogKind,
): Promise<ElementoCatalogo[]> {
  const { data, error } = await supabase
    .from("catalog_items")
    .select("id, catalog, name, template_id, sort_order, active")
    .eq("organization_id", org)
    .eq("catalog", catalog)
    .order("sort_order")
    .order("name")
  if (error) lanzar(error, "catalogo")
  return (data ?? []) as ElementoCatalogo[]
}
export async function listar<T>(
  org: string,
  tabla: Exclude<Tabla, "catalog_items">,
  columnas: string,
  orden: string,
): Promise<T[]> {
  const { data, error } = await supabase
    .from(tabla)
    .select(columnas)
    .eq("organization_id", org)
    .order(orden)
  if (error) lanzar(error, "catalogo")
  return (data ?? []) as T[]
}
export async function insertar(
  org: string,
  tabla: Tabla,
  fila: Record<string, unknown>,
): Promise<void> {
  const { error } = await supabase.from(tabla).insert({ organization_id: org, ...fila })
  if (error) lanzar(error, "catalogo")
}
export async function actualizar(
  org: string,
  tabla: Tabla,
  id: string,
  fila: Record<string, unknown>,
): Promise<void> {
  const { error, count } = await supabase
    .from(tabla)
    .update(fila, { count: "exact" })
    .eq("organization_id", org)
    .eq("id", id)
  if (error) lanzar(error, "catalogo")
  if (count === 0) throw new ErrorAcceso("SERVIDOR", "No tienes permiso para hacer esto.")
}

// ── Ajustes ──────────────────────────────────────────────────────────────
export async function ajustes(org: string): Promise<Ajustes> {
  const { data, error } = await supabase
    .from("organization_settings")
    .select("*")
    .eq("organization_id", org)
    .single()
  if (error) lanzar(error, "ajustes")
  return data as Ajustes
}
export async function guardarAjustes(
  org: string,
  a: Omit<Ajustes, "organization_id">,
): Promise<void> {
  const { error, count } = await supabase
    .from("organization_settings")
    .update(a, { count: "exact" })
    .eq("organization_id", org)
  if (error) lanzar(error, "ajustes")
  if (count === 0) throw new ErrorAcceso("SERVIDOR", "No tienes permiso para hacer esto.")
}

// ── Portal y marca ───────────────────────────────────────────────────────
export async function marca(org: string): Promise<Marca> {
  const { data, error } = await supabase
    .from("organizations")
    .select("id, name, slug, state, brand_color, logo_path, welcome_message")
    .eq("id", org)
    .single()
  if (error) lanzar(error, "marca")
  return data as Marca
}
export async function guardarMarca(org: string, m: Partial<Omit<Marca, "id">>): Promise<void> {
  const { error, count } = await supabase
    .from("organizations")
    .update(m, { count: "exact" })
    .eq("id", org)
  if (error) lanzar(error, "marca")
  if (count === 0) throw new ErrorAcceso("SERVIDOR", "No tienes permiso para hacer esto.")
}
export async function subirLogo(
  org: string,
  blob: Blob,
  ext: "png" | "jpg" | "webp",
): Promise<string> {
  const path = `${org}/logo.${ext}`
  const { error } = await supabase.storage
    .from("branding")
    .upload(path, blob, { upsert: true, contentType: blob.type, cacheControl: "60" })
  if (error)
    throw new ErrorAcceso(
      "SERVIDOR",
      /mime|type/i.test(error.message)
        ? "Solo PNG, JPG o WebP."
        : /size|large|exceed/i.test(error.message)
          ? "El logo pesa más de 2 MB."
          : error.message,
    )
  return path
}
export async function quitarLogo(org: string, path: string): Promise<void> {
  const { error } = await supabase.storage.from("branding").remove([path])
  if (error) throw new ErrorAcceso("SERVIDOR", error.message)
  await guardarMarca(org, { logo_path: null })
}
export const urlLogoPublico = (path: string | null) =>
  path
    ? `${supabase.storage.from("branding").getPublicUrl(path).data.publicUrl}?v=${Date.now()}`
    : null

export const SLUG_RE = /^[a-z0-9]([a-z0-9-]{1,38}[a-z0-9])$/
export const slugValido = (s: string) => SLUG_RE.test(s) && !s.includes("--")
