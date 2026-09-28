// Instantánea por empresa de lo último que el servidor respondió (tinas en
// uso, corridas, colectores, ajustes…) para que Fermentación y Destilación
// se abran sin señal con "datos de hace X". No es caché de verdad: es lo
// mínimo para poder capturar donde no hay señal (§8.3).
import { abrirDb, STORE_INSTANTANEAS } from "./cola"
import { ErrorAcceso, esErrorDeRed, MENSAJE_RED } from "../supabase/errores"

export interface ConInstantanea<T> {
  datos: T
  instantanea: string | null
}

// Solo una pérdida de red permite datos antiguos; un rechazo de permisos
// o del dominio nunca se sustituye por una lectura de caché.
export async function conInstantanea<T>(
  org: string,
  nombre: string,
  pedir: () => Promise<T>,
): Promise<ConInstantanea<T>> {
  try {
    const datos = await pedir()
    await guardarInstantanea(org, nombre, datos).catch(() => {})
    return { datos, instantanea: null }
  } catch (e) {
    if (!esErrorDeRed(e)) throw e
    const guardada = await leerInstantanea<T>(org, nombre).catch(() => null)
    if (!guardada) throw new ErrorAcceso("RED", MENSAJE_RED)
    return { datos: guardada.datos, instantanea: guardada.guardado_en }
  }
}

export interface Instantanea<T> {
  datos: T
  guardado_en: string
}

const clave = (org: string, nombre: string) => `${org}:${nombre}`

export async function guardarInstantanea<T>(org: string, nombre: string, datos: T): Promise<void> {
  const d = await abrirDb()
  await new Promise<void>((resolve, reject) => {
    const r = d
      .transaction(STORE_INSTANTANEAS, "readwrite")
      .objectStore(STORE_INSTANTANEAS)
      .put({ clave: clave(org, nombre), datos, guardado_en: new Date().toISOString() })
    r.onsuccess = () => resolve()
    r.onerror = () => reject(r.error)
  })
}

export async function leerInstantanea<T>(
  org: string,
  nombre: string,
): Promise<Instantanea<T> | null> {
  const d = await abrirDb()
  return new Promise((resolve, reject) => {
    const r = d
      .transaction(STORE_INSTANTANEAS, "readonly")
      .objectStore(STORE_INSTANTANEAS)
      .get(clave(org, nombre))
    r.onsuccess = () => {
      const v = r.result as (Instantanea<T> & { clave: string }) | undefined
      resolve(v ? { datos: v.datos, guardado_en: v.guardado_en } : null)
    }
    r.onerror = () => reject(r.error)
  })
}

// "hace 3 min", "hace 2 h", "ayer": corto, para el aviso de instantánea.
export function haceCuanto(iso: string, ahora = Date.now()): string {
  const s = Math.max(0, Math.round((ahora - new Date(iso).getTime()) / 1000))
  if (s < 60) return "hace un momento"
  const m = Math.round(s / 60)
  if (m < 60) return `hace ${m} min`
  const h = Math.round(m / 60)
  if (h < 24) return `hace ${h} h`
  const d = Math.round(h / 24)
  return d === 1 ? "ayer" : `hace ${d} días`
}
