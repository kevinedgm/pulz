import { errorCaptura, type CapturaMH } from "./modelo"

const registro = (v: unknown): v is Record<string, unknown> =>
  typeof v === "object" && v !== null && !Array.isArray(v)
const cadena = (v: unknown): v is string => typeof v === "string"
function capturaValida(v: unknown): v is CapturaMH {
  if (
    !registro(v) ||
    !cadena(v.idem) ||
    !v.idem ||
    !cadena(v.fecha) ||
    !Number.isFinite(Date.parse(v.fecha)) ||
    !cadena(v.folio) ||
    !cadena(v.nota)
  )
    return false
  switch (v.tipo) {
    case "abrir":
      if (
        !cadena(v.horno) ||
        !Array.isArray(v.lotes) ||
        !v.lotes.every((l) => registro(l) && cadena(l.id) && typeof l.kg === "number")
      )
        return false
      break
    case "recepcion":
      if (
        typeof v.kg !== "number" ||
        (v.pinas !== null && typeof v.pinas !== "number") ||
        !cadena(v.especie) ||
        !cadena(v.predio) ||
        !cadena(v.proveedor)
      )
        return false
      break
    case "cerrar":
      if (typeof v.kg !== "number" || !cadena(v.horneada) || !v.horneada || !cadena(v.combustible))
        return false
      break
    case "cocido":
      if (typeof v.kg !== "number") return false
      break
    default:
      return false
  }
  return errorCaptura(v as unknown as CapturaMH) === null
}

// Sólo se usa para intenciones online cuyo resultado puede ser incierto.
// No es una cola offline: nunca se envía automáticamente.
const clave = (contexto: string) => `pulz:mh:intencion:${contexto}`
export function leerIntencion(contexto: string): CapturaMH | null {
  if (!contexto) return null
  const raw = localStorage.getItem(clave(contexto))
  if (!raw) return null
  const c: unknown = JSON.parse(raw)
  if (!capturaValida(c))
    throw new Error(
      "No se pudo leer el envío pendiente. No vuelvas a capturarlo: requiere revisión.",
    )
  return c
}
export function guardarIntencion(contexto: string, c: CapturaMH | null) {
  if (!contexto) return
  if (c) localStorage.setItem(clave(contexto), JSON.stringify(c))
  else localStorage.removeItem(clave(contexto))
}
export class RechazoCapturaMH extends Error {}
