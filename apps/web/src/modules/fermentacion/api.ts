// Fermentación (PULZ_MAESTRO.md §4.4, §13.2 #3–#4; ronda fermentacion/r01).
// Lecturas: vistas de 0026 (tinas_en_uso, mediciones_del_ciclo) con
// instantánea para abrir sin señal. Escrituras: la medición SIEMPRE entra
// por la cola (§8.3); anular, declarar lista, cerrar, formular y "tina que
// ya fermentaba" van directas (requieren señal). "Día del ciclo" y "hoy"
// se calculan aquí, en el navegador (DECISIONES 2026-09-27).
import { supabase } from "../../shared/supabase/client"
import {
  ErrorAcceso,
  esErrorDeRed,
  MENSAJE_RED,
  traducirErrorRpc,
  type ErrorRpc,
} from "../../shared/supabase/errores"
import { encolar, nuevaClave, type ElementoCola } from "../../shared/offline/cola"
import type { FotoPendiente } from "../../shared/offline/fotos"
import { conInstantanea, type ConInstantanea } from "../../shared/offline/instantanea"
export type { ConInstantanea } from "../../shared/offline/instantanea"
import type { Ajustes } from "../configuracion/api"
export { ETIQUETAS_ACIDEZ, ETIQUETAS_ACTIVIDAD, ETIQUETAS_DULZOR, litros } from "./dominio"

export type EstadoCiclo = "fermentando" | "lista" | "en_vaciado" | "cerrado"
export type ModoMedicion = "minimo" | "completo"
export type Variable = "temperatura" | "brix" | "dulzor" | "acidez"
export type Zona = "unica" | "superficie" | "fondo"

export interface UsoTina {
  organization_id: string
  cycle_id: string
  tina_id: string
  tina: string
  capacidad_l: number | null
  capacity_policy: "estricta" | "flexible" | "libre"
  lot_id: string
  folio: string
  status: EstadoCiclo
  formulation_id: string | null
  formulacion: string | null
  started_at: string
  started_by: string | null
  litros: number
  mediciones: number
  ultima_medicion_at: string | null
  ultima_medicion_dia: number | null
  ultima_actividad: number | null
  ultima_temperatura: number | null
  ultimo_brix: number | null
}
export interface Medicion {
  organization_id: string
  cycle_id: string
  measurement_id: string
  day_no: number
  mode: ModoMedicion
  activity: number | null
  notes: string | null
  occurred_at: string
  recorded_at: string
  recorded_by: string | null
  voided_at: string | null
  void_reason: string | null
  temperatura: number | null
  brix: number | null
  temperatura_superficie: number | null
  temperatura_fondo: number | null
  brix_superficie: number | null
  brix_fondo: number | null
  dulzor: number | null
  acidez: number | null
  lecturas: number
}
export interface Lectura {
  variable: Variable
  zona: Zona
  numero: 1 | 2 | 3
  valor: number
}
export interface NuevaMedicion {
  cycle_id: string
  dia: number
  modo: ModoMedicion
  actividad: number | null
  lecturas: Lectura[]
  nota?: string | null
  occurred_at: string | null // null = ahora
  foto?: FotoPendiente
}

// Error de dominio con el código de §12.1 (y el aviso que pide nota)
export class ErrorFermentacion extends Error {
  readonly rpc: ErrorRpc
  constructor(rpc: ErrorRpc) {
    super(rpc.mensaje)
    this.name = "ErrorFermentacion"
    this.rpc = rpc
  }
}
function lanzar(e: unknown): never {
  if (esErrorDeRed(e)) throw new ErrorAcceso("RED", MENSAJE_RED)
  throw new ErrorFermentacion(traducirErrorRpc(e))
}

// ── Funciones puras (con prueba) ───────────────────────────────────────
const fecha = (d: Date) => new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime()

// Día del ciclo: días naturales desde started_at (zona del navegador) + 1.
export function diaDelCiclo(startedAt: string, hoy = new Date()): number {
  const dias = Math.round((fecha(hoy) - fecha(new Date(startedAt))) / 86_400_000)
  return Math.max(1, dias + 1)
}
export function esHoy(iso: string | null | undefined, hoy = new Date()): boolean {
  return Boolean(iso) && fecha(new Date(iso as string)) === fecha(hoy)
}
// «Toca medir hoy»: fermentando y sin medición válida con fecha local de hoy
export function tocaMedirHoy(u: UsoTina, hoy = new Date()): boolean {
  return u.status === "fermentando" && !esHoy(u.ultima_medicion_at, hoy)
}
export interface Grupos {
  porMedir: UsoTina[]
  medidas: UsoTina[]
  listas: UsoTina[]
}
export function agrupar(usos: UsoTina[], hoy = new Date()): Grupos {
  const g: Grupos = { porMedir: [], medidas: [], listas: [] }
  for (const u of usos) {
    if (u.status !== "fermentando") g.listas.push(u)
    else if (tocaMedirHoy(u, hoy)) g.porMedir.push(u)
    else g.medidas.push(u)
  }
  // Más días sin medir primero; después por nombre de tina
  const orden = (a: UsoTina, b: UsoTina) =>
    (a.ultima_medicion_at ?? "").localeCompare(b.ultima_medicion_at ?? "") ||
    a.tina.localeCompare(b.tina, "es")
  g.porMedir.sort(orden)
  g.medidas.sort((a, b) => a.tina.localeCompare(b.tina, "es"))
  g.listas.sort((a, b) => a.tina.localeCompare(b.tina, "es"))
  return g
}
export function promedio(valores: (number | null)[]): number | null {
  const v = valores.filter((x): x is number => typeof x === "number" && Number.isFinite(x))
  return v.length ? Math.round((v.reduce((a, b) => a + b, 0) / v.length) * 100) / 100 : null
}
// Aviso blando conocido antes de enviar (rangos de la empresa, §2.1)
export function avisoBrix(
  brix: number | null,
  a: Pick<Ajustes, "brix_warn_min" | "brix_warn_max"> | null,
): "brix_fuera_rango" | null {
  if (brix === null || !a) return null
  return brix < a.brix_warn_min || brix > a.brix_warn_max ? "brix_fuera_rango" : null
}
// registrar_medicion recibe arreglos paralelos (0017)
export function lecturasParaRpc(lecturas: Lectura[]) {
  return {
    p_variables: lecturas.map((l) => l.variable),
    p_zonas: lecturas.map((l) => l.zona),
    p_numeros: lecturas.map((l) => l.numero),
    p_valores: lecturas.map((l) => l.valor),
  }
}

// ── Lecturas con instantánea ───────────────────────────────────────────
export interface DatosFermentacion {
  usos: UsoTina[]
  ajustes: Ajustes
  // id del elemento "Foto" del catálogo tipo_adjunto (para la evidencia)
  tipoFoto: string | null
}
export function cargarUsos(org: string): Promise<ConInstantanea<DatosFermentacion>> {
  return conInstantanea(org, "fermentacion", async () => {
    const [u, a, f] = await Promise.all([
      supabase.from("tinas_en_uso").select("*").eq("organization_id", org),
      supabase.from("organization_settings").select("*").eq("organization_id", org).single(),
      supabase
        .from("catalog_items")
        .select("id, name, template_id")
        .eq("organization_id", org)
        .eq("catalog", "tipo_adjunto")
        .eq("active", true),
    ])
    if (u.error) lanzar(u.error)
    if (a.error) lanzar(a.error)
    const adjuntos = (f.data ?? []) as { id: string; name: string; template_id: string | null }[]
    const foto =
      adjuntos.find((x) => x.template_id === "e4966301-96da-5221-8658-fecbb86b2319") ??
      adjuntos.find((x) => /foto/i.test(x.name)) ??
      null
    return {
      usos: (u.data ?? []) as UsoTina[],
      ajustes: a.data as Ajustes,
      tipoFoto: foto?.id ?? null,
    }
  })
}
export function cargarMediciones(
  org: string,
  cycleId: string,
): Promise<ConInstantanea<Medicion[]>> {
  return conInstantanea(org, `mediciones:${cycleId}`, async () => {
    const { data, error } = await supabase
      .from("mediciones_del_ciclo")
      .select("*")
      .eq("organization_id", org)
      .eq("cycle_id", cycleId)
      .order("occurred_at", { ascending: false })
    if (error) lanzar(error)
    return (data ?? []) as Medicion[]
  })
}

// ── Escrituras ─────────────────────────────────────────────────────────
// La medición entra SIEMPRE por la cola: una sola ruta de escritura.
export async function encolarMedicion(
  org: string,
  m: NuevaMedicion,
  resumen: string,
): Promise<ElementoCola> {
  const idem = nuevaClave()
  const occurred = m.occurred_at ? new Date(m.occurred_at).toISOString() : new Date().toISOString()
  return encolar({
    id: idem,
    org,
    rpc: "registrar_medicion",
    resumen,
    occurred_at: occurred,
    params: {
      p_org: org,
      p_idem: idem,
      p_fecha: occurred,
      p_ciclo: m.cycle_id,
      p_dia: m.dia,
      p_modo: m.modo,
      p_actividad: m.actividad,
      ...lecturasParaRpc(m.lecturas),
      p_nota: m.nota?.trim() || null,
    },
    ...(m.foto ? { foto: m.foto } : {}),
  })
}
const ahora = (iso: string | null) => (iso ? new Date(iso).toISOString() : new Date().toISOString())

export async function anularMedicion(
  org: string,
  medicionId: string,
  motivo: string,
): Promise<void> {
  const { error } = await supabase.rpc("anular_medicion", {
    p_org: org,
    p_idem: nuevaClave(),
    p_fecha: new Date().toISOString(),
    p_medicion: medicionId,
    p_motivo: motivo.trim(),
  })
  if (error) lanzar(error)
}
export async function declararLista(
  org: string,
  cycleId: string,
  nota: string | null,
  cuando: string | null,
): Promise<void> {
  const { error } = await supabase.rpc("declarar_tina_lista", {
    p_org: org,
    p_idem: nuevaClave(),
    p_fecha: ahora(cuando),
    p_ciclo: cycleId,
    p_nota: nota?.trim() || null,
  })
  if (error) lanzar(error)
}
export async function cerrarCiclo(
  org: string,
  cycleId: string,
  nota: string | null,
  cuando: string | null,
): Promise<void> {
  const { error } = await supabase.rpc("cerrar_ciclo", {
    p_org: org,
    p_idem: nuevaClave(),
    p_fecha: ahora(cuando),
    p_ciclo: cycleId,
    p_nota: nota?.trim() || null,
  })
  if (error) lanzar(error)
}

// Formulación (§4.3): agave cocido con saldo, molinos, insumos, tinas libres
export interface LoteCocido {
  lot_id: string
  folio: string
  remaining_kg: number
}
export interface RecursoBreve {
  id: string
  code: string
  capacity: number | null
  capacity_policy: "estricta" | "flexible" | "libre"
}
export interface Insumo {
  id: string
  name: string
}
export async function lotesCocido(org: string): Promise<LoteCocido[]> {
  const { data, error } = await supabase
    .from("solid_lot_balances")
    .select("lot_id, folio, remaining_kg")
    .eq("organization_id", org)
    .eq("material", "agave_cocido")
    .gt("remaining_kg", 0)
    .order("folio")
  if (error) lanzar(error)
  return (data ?? []) as LoteCocido[]
}
export async function recursosDe(org: string, kind: "tina" | "molino"): Promise<RecursoBreve[]> {
  const { data, error } = await supabase
    .from("resources")
    .select("id, code, capacity, capacity_policy")
    .eq("organization_id", org)
    .eq("kind", kind)
    .eq("active", true)
    .order("code")
  if (error) lanzar(error)
  return (data ?? []) as RecursoBreve[]
}
export async function tinasLibres(org: string, usos: UsoTina[]): Promise<RecursoBreve[]> {
  const ocupadas = new Set(usos.map((u) => u.tina_id))
  return (await recursosDe(org, "tina")).filter((t) => !ocupadas.has(t.id))
}
export async function insumos(org: string): Promise<Insumo[]> {
  const { data, error } = await supabase
    .from("supplies")
    .select("id, name")
    .eq("organization_id", org)
    .eq("active", true)
    .order("name")
  if (error) lanzar(error)
  return (data ?? []) as Insumo[]
}
export interface Formulacion {
  molino: string | null
  cocido: { lot_id: string; kg: number }[]
  agua_l: number
  insumos: { supply_id: string; cantidad: number }[]
  tinas: { tina_id: string; litros: number; folio?: string | null }[]
  metodo?: string | null
  nota?: string | null
  occurred_at: string | null
}
export async function registrarFormulacion(org: string, f: Formulacion): Promise<string> {
  const { data, error } = await supabase.rpc("registrar_formulacion", {
    p_org: org,
    p_idem: nuevaClave(),
    p_fecha: ahora(f.occurred_at),
    p_molino: f.molino,
    p_lotes_cocido: f.cocido.map((c) => c.lot_id),
    p_kilos: f.cocido.map((c) => c.kg),
    p_agua_l: f.agua_l,
    p_tinas: f.tinas.map((t) => t.tina_id),
    p_litros: f.tinas.map((t) => t.litros),
    p_insumos: f.insumos.length ? f.insumos.map((i) => i.supply_id) : null,
    p_cantidades: f.insumos.length ? f.insumos.map((i) => i.cantidad) : null,
    p_metodo: f.metodo?.trim() || null,
    p_nota: f.nota?.trim() || null,
    p_folios_tina: f.tinas.some((t) => t.folio)
      ? f.tinas.map((t) => t.folio?.trim() || null)
      : null,
  })
  if (error) lanzar(error)
  return String(data)
}
// Tina que ya fermentaba (DUDAS #7): entrada 'fermentado' abre un ciclo sin formulación
export async function tinaQueYaFermentaba(
  org: string,
  tinaId: string,
  litros: number,
  cuando: string | null,
): Promise<string> {
  const { data, error } = await supabase.rpc("registrar_entrada", {
    p_org: org,
    p_idem: nuevaClave(),
    p_fecha: ahora(cuando),
    p_material: "fermentado",
    p_recurso: tinaId,
    p_cantidad: litros,
    p_origen: "carga_inicial",
  })
  if (error) lanzar(error)
  return String(data)
}

// Formato corto para la lista: "ayer 08:30", "hoy 07:10", "12 sep"
export function cuandoCorto(iso: string | null, hoy = new Date()): string {
  if (!iso) return "nunca"
  const d = new Date(iso)
  const hora = new Intl.DateTimeFormat("es-MX", { hour: "2-digit", minute: "2-digit" }).format(d)
  const dias = Math.round((fecha(hoy) - fecha(d)) / 86_400_000)
  if (dias === 0) return `hoy ${hora}`
  if (dias === 1) return `ayer ${hora}`
  return new Intl.DateTimeFormat("es-MX", { day: "numeric", month: "short" }).format(d)
}
