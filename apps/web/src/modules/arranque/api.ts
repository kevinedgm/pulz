// Primer arranque (§13.2 #2; ronda arranque/r01): una carga inicial por
// recipiente con registrar_entrada (0015), idempotente por tarjeta.
import { supabase } from "../../shared/supabase/client"
import { ErrorAcceso, esErrorDeRed, MENSAJE_RED } from "../../shared/supabase/errores"
import type { ResourceKind } from "../configuracion/api"

export type KindRecipiente = Extract<ResourceKind, "tanque" | "tina" | "colector">
export const KINDS_RECIPIENTE: KindRecipiente[] = ["tanque", "tina", "colector"]
export const esRecipiente = (k: ResourceKind): k is KindRecipiente =>
  (KINDS_RECIPIENTE as ResourceKind[]).includes(k)

// Material por tipo de recipiente (0015): granel → tanque; fermentado → tina
// (abre un ciclo sin formulación, DUDAS #7); destilado → colector (la clase
// la da el recurso).
export const materialDe = (k: KindRecipiente) =>
  k === "tanque" ? "granel" : k === "tina" ? "fermentado" : "destilado"

export function mensajeDeCarga(e: unknown, code: string): string {
  const msg = (e as { message?: string })?.message ?? String(e)
  if (esErrorDeRed(e)) return MENSAJE_RED
  if (/CAPACIDAD:/i.test(msg))
    return `No cabe: ${code} tiene política estricta. Baja los litros o cambia la política en Recursos.`
  if (/ya tiene un ciclo abierto/i.test(msg))
    return "Esta tina ya tiene contenido registrado (un ciclo abierto). Revísala en Fermentación."
  if (/NO_PERMITIDO/i.test(msg)) return msg.replace(/^NO_PERMITIDO:\s*/i, "")
  if (/permission denied|row-level/i.test(msg)) return "No tienes permiso para registrar cargas."
  return msg
}

export async function cargaInicial(
  org: string,
  idem: string,
  kind: KindRecipiente,
  resourceId: string,
  litros: number,
  abv: number | null,
  code: string,
): Promise<string> {
  const { data, error } = await supabase.rpc("registrar_entrada", {
    p_org: org,
    p_idem: idem,
    p_fecha: new Date().toISOString(),
    p_material: materialDe(kind),
    p_recurso: resourceId,
    p_cantidad: litros,
    p_abv: abv,
    p_origen: "carga_inicial",
  })
  if (error)
    throw new ErrorAcceso(esErrorDeRed(error) ? "RED" : "SERVIDOR", mensajeDeCarga(error, code))
  return data as string
}

// Estado local por empresa: clave de idempotencia por recipiente y "vacío"
// (que no existe en la base). Lo real (saldo, ciclo) sale de recurso_en_uso.
export interface EstadoLocal {
  [resourceId: string]: { idem: string; vacio: boolean }
}
const CLAVE = (org: string) => `pulz:arranque:${org}`
export function leerEstado(org: string): EstadoLocal {
  try {
    return JSON.parse(localStorage.getItem(CLAVE(org)) ?? "{}") as EstadoLocal
  } catch {
    return {}
  }
}
export function guardarEstado(org: string, e: EstadoLocal) {
  try {
    localStorage.setItem(CLAVE(org), JSON.stringify(e))
  } catch {
    /* sin almacenamiento: solo en memoria */
  }
}
export const nuevaClave = () =>
  typeof crypto !== "undefined" && "randomUUID" in crypto
    ? crypto.randomUUID()
    : `${Date.now()}-${Math.random().toString(16).slice(2)}`
