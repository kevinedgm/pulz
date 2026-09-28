// Granel (PULZ_MAESTRO.md §5, §6 bitácora, §13.2 #6; ronda granel/r01).
// Lecturas: tanques y colectores_con_saldo (0026), movement_log (0011),
// conceptos del catálogo, proveedores y especies, ajustes; con instantánea
// (solo lectura sin señal). Escrituras: registrar_movimiento_granel y
// transferir (0019) van DIRECTAS: dependen de saldos que decide el servidor
// (§8.3). El sistema no calcula el grado: la persona declara volumen y
// % Alc. resultantes; la diferencia con el ledger se muestra antes.
import { supabase } from "../../shared/supabase/client"
import {
  ErrorAcceso,
  esErrorDeRed,
  MENSAJE_RED,
  traducirErrorRpc,
  type ErrorRpc,
} from "../../shared/supabase/errores"
import { nuevaClave } from "../../shared/utils/claves"
import { conInstantanea, type ConInstantanea } from "../../shared/offline/instantanea"
export type { ConInstantanea } from "../../shared/offline/instantanea"
import type { Ajustes } from "../configuracion/api"
import type { ColectorConSaldo } from "../destilacion/api"

export type Historia = "completa" | "parcial" | "declarada" | "sin_historia"
export interface LoteEnTanque {
  lot_id: string
  folio: string
  litros: number
  history: Historia
  origin: string
  abv: number | null
  abv_at: string | null
  abv_by: string | null
}
export interface Tanque {
  organization_id: string
  resource_id: string
  tanque: string
  capacidad_l: number | null
  capacity_policy: "estricta" | "flexible" | "libre"
  location: string | null
  litros: number
  lotes: LoteEnTanque[]
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
  sort_order: number
}
export interface Pata {
  movement_id: string
  operation_id: string
  kind: string
  concept: string | null
  movement_type: string
  folio: string
  volume_l: number
  abv: number | null
  source: string | null
  destination: string | null
  occurred_at: string
  recorded_at: string
  recorded_by: string | null
  note: string | null
  // de operations (movement_log no las trae): con quién y qué documento
  counterparty?: string | null
  document_ref?: string | null
}
export interface Proveedor {
  id: string
  name: string
}
export interface Especie {
  id: string
  common_name: string
}
export interface DatosGranel {
  tanques: Tanque[]
  colectores: ColectorConSaldo[]
  conceptos: Concepto[]
  proveedores: Proveedor[]
  especies: Especie[]
  ajustes: Pick<Ajustes, "default_folio_decision" | "abv_warn_min" | "abv_warn_max">
}

export class ErrorGranel extends Error {
  readonly rpc: ErrorRpc
  constructor(rpc: ErrorRpc) {
    super(rpc.mensaje)
    this.name = "ErrorGranel"
    this.rpc = rpc
  }
}
function lanzar(e: unknown): never {
  if (esErrorDeRed(e)) throw new ErrorAcceso("RED", MENSAJE_RED)
  throw new ErrorGranel(traducirErrorRpc(e))
}

// ── Puras (con prueba) ─────────────────────────────────────────────────
export const fmt = (n: number) =>
  new Intl.NumberFormat("es-MX", { maximumFractionDigits: 1 }).format(n)
export const litros = (n: number) => `${fmt(n)} L`
export const HISTORIA: Record<Historia, string> = {
  completa: "historia completa",
  parcial: "historia parcial",
  declarada: "historia declarada",
  sin_historia: "sin historia",
}
// Qué campos pide un concepto (§5.2): el formulario se arma con esto
export interface Campos {
  litros: true
  loteAfectado: boolean // el tanque tiene más de un lote
  origen: "no" | "opcional" | "requerido"
  decision: boolean // unión con lote en el destino
  resultado: boolean
  contraparte: boolean
  certificado: boolean
  folioNuevo: boolean
}
export function camposDe(c: Concepto, lotesEnTanque: number): Campos {
  return {
    litros: true,
    loteAfectado: lotesEnTanque > 1 && !c.creates_lot,
    origen: c.creates_lot ? "no" : c.source_lot === "no_aplica" ? "no" : c.source_lot,
    decision: c.source_lot === "requerido" && lotesEnTanque > 0,
    resultado: c.direction === "entrada" && c.asks_result,
    contraparte: c.asks_counterparty,
    certificado: c.creates_lot && c.asks_counterparty,
    folioNuevo: c.creates_lot,
  }
}
// El ledger después de la entrada (sin conciliación) y la diferencia con lo declarado
export function ledgerEsperado(
  saldoLote: number,
  litrosEntran: number,
  renombra = false,
  saldoOrigenSeUne = 0,
) {
  return Math.round((saldoLote + litrosEntran + (renombra ? saldoOrigenSeUne : 0)) * 1000) / 1000
}
export function diferencia(resultado: number | null, ledger: number): number | null {
  if (resultado === null) return null
  const d = Math.round((resultado - ledger) * 1000) / 1000
  return Math.abs(d) < 0.001 ? 0 : d
}
// Avisos conocidos antes de enviar (§2.1): diferencia de volumen, % Alc. fuera de rango, capacidad flexible
export function avisosEntrada(
  dif: number | null,
  abv: number | null,
  ajustes: Pick<Ajustes, "abv_warn_min" | "abv_warn_max">,
  capacidad: {
    saldo: number
    litros: number
    capacidad: number | null
    politica: Tanque["capacity_policy"]
  } | null,
): string[] {
  const a: string[] = []
  if (dif !== null && dif !== 0) a.push("diferencia_volumen")
  if (abv !== null && (abv < ajustes.abv_warn_min || abv > ajustes.abv_warn_max))
    a.push("abv_fuera_rango")
  if (
    capacidad &&
    capacidad.capacidad !== null &&
    capacidad.politica === "flexible" &&
    capacidad.saldo + capacidad.litros > capacidad.capacidad
  )
    a.push("excede_capacidad")
  return a
}
export function bloqueaCapacidad(
  saldo: number,
  litrosEntran: number,
  t: Pick<Tanque, "capacidad_l" | "capacity_policy">,
) {
  return (
    t.capacidad_l !== null &&
    t.capacity_policy === "estricta" &&
    saldo + litrosEntran > t.capacidad_l
  )
}
// Folio sugerido al juntar: el del lote que ya está en el destino (el mayor)
export function folioSugerido(lotesDestino: LoteEnTanque[]): LoteEnTanque | null {
  return [...lotesDestino].sort((a, b) => b.litros - a.litros)[0] ?? null
}
export const loteVivo = (t: Tanque) => folioSugerido(t.lotes)

// ── Lecturas con instantánea ───────────────────────────────────────────
export function cargarGranel(org: string): Promise<ConInstantanea<DatosGranel>> {
  return conInstantanea(org, "granel", async () => {
    const [t, c, k, p, e, a] = await Promise.all([
      supabase.from("tanques").select("*").eq("organization_id", org).order("tanque"),
      supabase
        .from("colectores_con_saldo")
        .select("*")
        .eq("organization_id", org)
        .eq("liquid_class", "mezcal"),
      supabase
        .from("movement_concepts")
        .select(
          "id, direction, name, source_lot, creates_lot, asks_result, asks_counterparty, template_id, sort_order",
        )
        .eq("organization_id", org)
        .eq("active", true)
        .order("sort_order"),
      supabase
        .from("suppliers")
        .select("id, name")
        .eq("organization_id", org)
        .eq("active", true)
        .order("name"),
      supabase
        .from("species")
        .select("id, common_name")
        .eq("organization_id", org)
        .eq("active", true)
        .order("common_name"),
      supabase
        .from("organization_settings")
        .select("default_folio_decision, abv_warn_min, abv_warn_max")
        .eq("organization_id", org)
        .single(),
    ])
    for (const x of [t, c, k, p, e, a]) if (x.error) lanzar(x.error)
    return {
      tanques: (t.data ?? []) as Tanque[],
      colectores: (c.data ?? []) as ColectorConSaldo[],
      conceptos: (k.data ?? []) as Concepto[],
      proveedores: (p.data ?? []) as Proveedor[],
      especies: (e.data ?? []) as Especie[],
      ajustes: a.data as DatosGranel["ajustes"],
    }
  })
}
export function cargarHistorial(org: string, resourceId: string): Promise<ConInstantanea<Pata[]>> {
  return conInstantanea(org, `historial:${resourceId}`, async () => {
    // movement_log expone códigos de recurso, no ids: se filtra por el código
    const t = await supabase.from("resources").select("code").eq("id", resourceId).single()
    if (t.error) lanzar(t.error)
    const code = (t.data as { code: string }).code
    const r = await supabase
      .from("movement_log")
      .select("*")
      .eq("organization_id", org)
      .or(`source.eq.${code},destination.eq.${code}`)
      .order("occurred_at", { ascending: false })
      .limit(100)
    if (r.error) lanzar(r.error)
    const patas = (r.data ?? []) as Pata[]
    const ids = [...new Set(patas.map((p) => p.operation_id))]
    if (ids.length) {
      const o = await supabase
        .from("operations")
        .select("id, counterparty, document_ref")
        .eq("organization_id", org)
        .in("id", ids)
      if (o.error) lanzar(o.error)
      const por = new Map((o.data ?? []).map((x) => [x.id as string, x]))
      for (const p of patas) {
        const op = por.get(p.operation_id)
        p.counterparty = (op?.counterparty as string | null) ?? null
        p.document_ref = (op?.document_ref as string | null) ?? null
      }
    }
    return patas
  })
}

// ── Escrituras (señal) ─────────────────────────────────────────────────
const ahora = (iso: string | null) => (iso ? new Date(iso).toISOString() : new Date().toISOString())
export interface Movimiento {
  concepto: string
  tanque: string
  litros: number
  lote?: string | null
  lote_origen?: string | null
  recurso_origen?: string | null
  resultado_l?: number | null
  resultado_abv?: number | null
  abv?: number | null
  decision?: "conservar" | "renombrar" | null
  folio_nuevo?: string | null
  contraparte?: string | null
  documento?: string | null
  proveedor?: string | null
  proveedor_nombre?: string | null
  folio_certificado?: string | null
  organismo?: string | null
  especie?: string | null
  predio_declarado?: string | null
  nota?: string | null
  occurred_at: string | null
}
export async function registrarMovimiento(org: string, m: Movimiento): Promise<string> {
  const { data, error } = await supabase.rpc("registrar_movimiento_granel", {
    p_org: org,
    p_idem: nuevaClave(),
    p_fecha: ahora(m.occurred_at),
    p_concepto: m.concepto,
    p_tanque: m.tanque,
    p_litros: m.litros,
    p_lote: m.lote ?? null,
    p_lote_origen: m.lote_origen ?? null,
    p_recurso_origen: m.recurso_origen ?? null,
    p_resultado_l: m.resultado_l ?? null,
    p_resultado_abv: m.resultado_abv ?? null,
    p_abv: m.abv ?? null,
    p_decision: m.decision ?? null,
    p_folio_nuevo: m.folio_nuevo?.trim() || null,
    p_contraparte: m.contraparte?.trim() || null,
    p_documento: m.documento?.trim() || null,
    p_proveedor: m.proveedor || null,
    p_proveedor_nombre: m.proveedor_nombre?.trim() || null,
    p_folio_certificado: m.folio_certificado?.trim() || null,
    p_organismo: m.organismo?.trim() || null,
    p_especie: m.especie || null,
    p_predio_declarado: m.predio_declarado?.trim() || null,
    p_nota: m.nota?.trim() || null,
  })
  if (error) lanzar(error)
  return String(data)
}
export interface Transferencia {
  origen: string
  destino: string
  lote: string
  litros: number
  abv?: number | null
  decision?: "conservar" | "renombrar" | null
  folio_nuevo?: string | null
  nota?: string | null
  occurred_at: string | null
}
export async function transferir(org: string, t: Transferencia): Promise<string> {
  const { data, error } = await supabase.rpc("transferir", {
    p_org: org,
    p_idem: nuevaClave(),
    p_fecha: ahora(t.occurred_at),
    p_origen: t.origen,
    p_destino: t.destino,
    p_lote: t.lote,
    p_litros: t.litros,
    p_abv: t.abv ?? null,
    p_decision: t.decision ?? null,
    p_folio_nuevo: t.folio_nuevo?.trim() || null,
    p_nota: t.nota?.trim() || null,
  })
  if (error) lanzar(error)
  return String(data)
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
