// Destilación (PULZ_MAESTRO.md §4.5, §13.2 #5; ronda destilacion/r01).
// Lecturas: corridas y colectores_con_saldo (0026) + recursos activos +
// tinas_en_uso + ajustes, con instantánea. Escrituras: abrir y cerrar
// corrida van directas (consumen saldos: señal); el CORTE entra por la
// cola (§8.3). Reglas que la interfaz conoce antes de enviar: colector por
// clase, puntas solo con record_puntas, capacidad del alambique y del
// colector, ordinario + colas en 2ª.
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
import { guardarInstantanea, leerInstantanea } from "../../shared/offline/instantanea"
import type { Ajustes } from "../configuracion/api"
import type { UsoTina } from "../fermentacion/api"

export type Clase = "mezcal" | "ordinario" | "colas" | "puntas"
export type Pasada = "primera" | "segunda"
export interface Origen {
  resource_id: string | null
  recurso: string | null
  lot_id: string
  folio: string
  litros: number
  abv: number | null
}
export interface Corte {
  movement_id: string
  clase: Clase
  litros: number
  abv: number | null
  resource_id: string | null
  destino: string | null
  lot_id: string
  folio: string
  occurred_at: string
}
export interface Corrida {
  organization_id: string
  run_id: string
  folio: string
  still_id: string
  alambique: string
  capacidad_l: number | null
  pass: Pasada
  status: "abierta" | "cerrada"
  started_at: string
  started_by: string | null
  closed_at: string | null
  litros_cargados: number
  origenes: Origen[]
  litros_cortados: number
  cortes: Corte[]
}
export interface ColectorConSaldo {
  resource_id: string
  colector: string
  liquid_class: Clase
  capacidad_l: number | null
  lot_id: string
  folio: string
  litros: number
  abv: number | null
  abv_at: string | null
  abv_by: string | null
}
export interface RecursoActivo {
  id: string
  code: string
  capacity: number | null
  capacity_policy: "estricta" | "flexible" | "libre"
  liquid_class: Clase | null
}
export interface DatosDestilacion {
  corridas: Corrida[]
  colectores: ColectorConSaldo[]
  colectoresActivos: RecursoActivo[]
  alambiques: RecursoActivo[]
  usos: UsoTina[]
  ajustes: Pick<Ajustes, "record_puntas" | "warn_mixed_second_pass">
  tipoFoto: string | null
}

export class ErrorDestilacion extends Error {
  readonly rpc: ErrorRpc
  constructor(rpc: ErrorRpc) {
    super(rpc.mensaje)
    this.name = "ErrorDestilacion"
    this.rpc = rpc
  }
}
function lanzar(e: unknown): never {
  if (esErrorDeRed(e)) throw new ErrorAcceso("RED", MENSAJE_RED)
  throw new ErrorDestilacion(traducirErrorRpc(e))
}

// ── Puras ──────────────────────────────────────────────────────────────
export const CLASES: { valor: Clase; etiqueta: string }[] = [
  { valor: "mezcal", etiqueta: "Mezcal" },
  { valor: "ordinario", etiqueta: "Ordinario" },
  { valor: "colas", etiqueta: "Colas" },
  { valor: "puntas", etiqueta: "Puntas" },
]
export function clasesDisponibles(ajustes: { record_puntas: boolean }) {
  return CLASES.filter((c) => c.valor !== "puntas" || ajustes.record_puntas)
}
export function colectoresDeClase(clase: Clase, activos: RecursoActivo[]) {
  return activos.filter((c) => c.liquid_class === clase)
}
export function saldoDe(colectorId: string, conSaldo: ColectorConSaldo[]) {
  return conSaldo.filter((c) => c.resource_id === colectorId).reduce((a, c) => a + c.litros, 0)
}
// Capacidad del destino (colector o alambique): estricta bloquea, flexible avisa
export function avisoCapacidad(
  saldo: number,
  litros: number,
  capacidad: number | null,
  politica: RecursoActivo["capacity_policy"],
): "bloqueo" | "excede_capacidad" | null {
  if (capacidad === null || politica === "libre" || saldo + litros <= capacidad) return null
  return politica === "estricta" ? "bloqueo" : "excede_capacidad"
}
// Avisos al abrir: mezcla ordinario + colas en 2ª (si el ajuste avisa)
export function avisosApertura(
  pasada: Pasada,
  clases: (Clase | null)[],
  ajustes: { warn_mixed_second_pass: boolean },
): string[] {
  const a: string[] = []
  if (
    pasada === "segunda" &&
    ajustes.warn_mixed_second_pass &&
    clases.includes("ordinario") &&
    clases.includes("colas")
  )
    a.push("mezcla_clases_2a")
  return a
}
export function resumenCortes(c: Pick<Corrida, "cortes">): string {
  const por: Partial<Record<Clase, number>> = {}
  for (const k of c.cortes) por[k.clase] = (por[k.clase] ?? 0) + k.litros
  return (["mezcal", "ordinario", "colas", "puntas"] as Clase[])
    .filter((k) => por[k])
    .map((k) => `${k} ${fmt(por[k] as number)}`)
    .join(" · ")
}
export function resumenOrigenes(c: Pick<Corrida, "origenes">): string {
  return c.origenes.map((o) => `${o.recurso ?? "—"} ${o.folio}`).join(" · ")
}
export const fmt = (n: number) => new Intl.NumberFormat("es-MX").format(n)
export const litros = (n: number) => `${fmt(n)} L`

// ── Lecturas con instantánea ───────────────────────────────────────────
export interface ConInstantanea<T> {
  datos: T
  instantanea: string | null
}
async function conInstantanea<T>(
  org: string,
  clave: string,
  pedir: () => Promise<T>,
): Promise<ConInstantanea<T>> {
  try {
    const datos = await pedir()
    guardarInstantanea(org, clave, datos).catch(() => {})
    return { datos, instantanea: null }
  } catch (e) {
    if (!esErrorDeRed(e)) throw e
    const i = await leerInstantanea<T>(org, clave).catch(() => null)
    if (!i) throw new ErrorAcceso("RED", MENSAJE_RED)
    return { datos: i.datos, instantanea: i.guardado_en }
  }
}
export function cargarDestilacion(org: string): Promise<ConInstantanea<DatosDestilacion>> {
  return conInstantanea(org, "destilacion", async () => {
    const [c, s, r, u, a, f] = await Promise.all([
      supabase
        .from("corridas")
        .select("*")
        .eq("organization_id", org)
        .order("started_at", { ascending: false })
        .limit(60),
      supabase.from("colectores_con_saldo").select("*").eq("organization_id", org),
      supabase
        .from("resources")
        .select("id, code, capacity, capacity_policy, liquid_class, kind")
        .eq("organization_id", org)
        .eq("active", true)
        .in("kind", ["colector", "alambique"])
        .order("code"),
      supabase.from("tinas_en_uso").select("*").eq("organization_id", org),
      supabase
        .from("organization_settings")
        .select("record_puntas, warn_mixed_second_pass")
        .eq("organization_id", org)
        .single(),
      supabase
        .from("catalog_items")
        .select("id, name, template_id")
        .eq("organization_id", org)
        .eq("catalog", "tipo_adjunto")
        .eq("active", true),
    ])
    for (const x of [c, s, r, u, a]) if (x.error) lanzar(x.error)
    const recursos = (r.data ?? []) as (RecursoActivo & { kind: string })[]
    const adjuntos = (f.data ?? []) as { id: string; name: string; template_id: string | null }[]
    const foto =
      adjuntos.find((x) => x.template_id === "e4966301-96da-5221-8658-fecbb86b2319") ??
      adjuntos.find((x) => /foto/i.test(x.name)) ??
      null
    return {
      corridas: (c.data ?? []) as Corrida[],
      colectores: (s.data ?? []) as ColectorConSaldo[],
      colectoresActivos: recursos.filter((x) => x.kind === "colector"),
      alambiques: recursos.filter((x) => x.kind === "alambique"),
      usos: (u.data ?? []) as UsoTina[],
      ajustes: a.data as DatosDestilacion["ajustes"],
      tipoFoto: foto?.id ?? null,
    }
  })
}

// ── Escrituras ─────────────────────────────────────────────────────────
const ahora = (iso: string | null) => (iso ? new Date(iso).toISOString() : new Date().toISOString())
export interface NuevaCorrida {
  alambique: string
  pasada: Pasada
  origenes: { resource_id: string; lot_id: string; litros: number }[]
  nota?: string | null
  folio?: string | null
  occurred_at: string | null
}
export async function abrirCorrida(org: string, c: NuevaCorrida): Promise<string> {
  const { data, error } = await supabase.rpc("abrir_corrida", {
    p_org: org,
    p_idem: nuevaClave(),
    p_fecha: ahora(c.occurred_at),
    p_alambique: c.alambique,
    p_pasada: c.pasada,
    p_recursos: c.origenes.map((o) => o.resource_id),
    p_lotes: c.origenes.map((o) => o.lot_id),
    p_litros: c.origenes.map((o) => o.litros),
    p_nota: c.nota?.trim() || null,
    p_folio: c.folio?.trim() || null,
  })
  if (error) lanzar(error)
  return String(data)
}
export interface NuevoCorte {
  corrida: string
  folioCorrida: string
  clase: Clase
  litros: number
  abv: number
  colector: string
  colectorNombre: string
  nota?: string | null
  folio?: string | null
  occurred_at: string | null
  foto?: FotoPendiente
}
// El corte entra SIEMPRE por la cola (una sola ruta de escritura)
export async function encolarCorte(org: string, k: NuevoCorte): Promise<ElementoCola> {
  const idem = nuevaClave()
  const occurred = ahora(k.occurred_at)
  return encolar({
    id: idem,
    org,
    rpc: "registrar_corte",
    resumen: `Corte · ${k.folioCorrida} · ${k.clase} ${fmt(k.litros)} L → ${k.colectorNombre}`,
    occurred_at: occurred,
    params: {
      p_org: org,
      p_idem: idem,
      p_fecha: occurred,
      p_corrida: k.corrida,
      p_clase: k.clase,
      p_litros: k.litros,
      p_abv: k.abv,
      p_colector: k.colector,
      p_nota: k.nota?.trim() || null,
      p_folio: k.folio?.trim() || null,
    },
    ...(k.foto ? { foto: k.foto } : {}),
  })
}
export async function cerrarCorrida(
  org: string,
  corrida: string,
  nota: string | null,
  cuando: string | null,
): Promise<void> {
  const { error } = await supabase.rpc("cerrar_corrida", {
    p_org: org,
    p_idem: nuevaClave(),
    p_fecha: ahora(cuando),
    p_corrida: corrida,
    p_nota: nota?.trim() || null,
  })
  if (error) lanzar(error)
}
export function cuandoCorto(iso: string | null, hoy = new Date()): string {
  if (!iso) return "—"
  const d = new Date(iso)
  const hora = new Intl.DateTimeFormat("es-MX", { hour: "2-digit", minute: "2-digit" }).format(d)
  const f = (x: Date) => new Date(x.getFullYear(), x.getMonth(), x.getDate()).getTime()
  const dias = Math.round((f(hoy) - f(d)) / 86_400_000)
  if (dias === 0) return `hoy ${hora}`
  if (dias === 1) return `ayer ${hora}`
  return new Intl.DateTimeFormat("es-MX", { day: "numeric", month: "short" }).format(d)
}
