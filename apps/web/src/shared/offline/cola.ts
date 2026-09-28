// Cola offline (PULZ_MAESTRO.md §8.3): solo mediciones, cortes y fotos se
// capturan sin señal. Cada elemento lleva la idempotency_key generada en el
// teléfono y el occurred_at del momento real; al volver la señal se envía
// EN ORDEN. Reenviar es seguro: la RPC devuelve el resultado original si la
// clave ya existe (§12.1). Un error de red detiene el envío (lo reintenta
// el siguiente disparo); un error de dominio marca el elemento como fallo
// con el mensaje traducido y sigue con el siguiente.
import { supabase } from "../supabase/client"
import { esErrorDeRed, traducirErrorRpc, type ErrorRpc } from "../supabase/errores"
import { subirEvidencia, type FotoPendiente } from "./fotos"
export { nuevaClave } from "../utils/claves"

export type RpcEnCola = "registrar_medicion" | "registrar_corte"
export type EstadoElemento = "pendiente" | "enviando" | "fallo"

export interface ElementoCola {
  id: string // = idempotency_key (uuid del teléfono)
  org: string
  rpc: RpcEnCola
  params: Record<string, unknown>
  resumen: string // "Medición · Tina 1 · día 3" (para la lista de pendientes)
  occurred_at: string
  creado_en: string
  orden: number
  estado: EstadoElemento
  intentos: number
  error?: string
  errorCodigo?: ErrorRpc["codigo"]
  requiereNota?: string
  resultado?: string // id de la operación cuando la RPC ya pasó (falta la foto)
  foto?: FotoPendiente
}

export interface Llamador {
  rpc: (
    nombre: RpcEnCola,
    params: Record<string, unknown>,
  ) => Promise<{ data: unknown; error: unknown }>
  subirFoto: (org: string, resultado: string, foto: FotoPendiente, rpc: RpcEnCola) => Promise<void>
}

const NOMBRE_DB = "pulz-cola"
const VERSION = 1
export const STORE_ELEMENTOS = "elementos"
export const STORE_INSTANTANEAS = "instantaneas"

let db: Promise<IDBDatabase> | null = null
let contador = 0

export function abrirDb(): Promise<IDBDatabase> {
  if (db) return db
  db = new Promise((resolve, reject) => {
    const req = indexedDB.open(NOMBRE_DB, VERSION)
    req.onupgradeneeded = () => {
      const d = req.result
      if (!d.objectStoreNames.contains(STORE_ELEMENTOS)) {
        const s = d.createObjectStore(STORE_ELEMENTOS, { keyPath: "id" })
        s.createIndex("org", "org")
      }
      if (!d.objectStoreNames.contains(STORE_INSTANTANEAS)) {
        d.createObjectStore(STORE_INSTANTANEAS, { keyPath: "clave" })
      }
    }
    req.onsuccess = () => resolve(req.result)
    req.onerror = () => reject(req.error)
  })
  return db
}

// Solo para pruebas: cierra y olvida la conexión (fake-indexeddb nueva).
export function _reiniciarDb() {
  db = null
}

function pedir<T>(r: IDBRequest<T>): Promise<T> {
  return new Promise((resolve, reject) => {
    r.onsuccess = () => resolve(r.result)
    r.onerror = () => reject(r.error)
  })
}

async function store(modo: IDBTransactionMode, nombre = STORE_ELEMENTOS) {
  const d = await abrirDb()
  return d.transaction(nombre, modo).objectStore(nombre)
}

export async function encolar(
  e: Omit<ElementoCola, "creado_en" | "orden" | "estado" | "intentos">,
): Promise<ElementoCola> {
  const el: ElementoCola = {
    ...e,
    creado_en: new Date().toISOString(),
    orden: Date.now() * 1000 + (contador++ % 1000),
    estado: "pendiente",
    intentos: 0,
  }
  await pedir((await store("readwrite")).put(el))
  return el
}

export async function listar(org: string): Promise<ElementoCola[]> {
  const s = await store("readonly")
  const todos = await pedir(s.index("org").getAll(org))
  return (todos as ElementoCola[]).sort((a, b) => a.orden - b.orden)
}

async function guardar(el: ElementoCola) {
  await pedir((await store("readwrite")).put(el))
}
async function borrar(id: string) {
  await pedir((await store("readwrite")).delete(id))
}

export async function reintentar(id: string) {
  const s = await store("readwrite")
  const el = (await pedir(s.get(id))) as ElementoCola | undefined
  if (!el) return
  el.estado = "pendiente"
  delete el.error
  delete el.errorCodigo
  delete el.requiereNota
  await pedir(s.put(el))
}

// Solo un elemento en fallo se puede descartar: lo pendiente se envía.
export async function descartar(id: string) {
  const s = await store("readwrite")
  const el = (await pedir(s.get(id))) as ElementoCola | undefined
  if (el && el.estado === "fallo") await pedir(s.delete(id))
}

// Corrige los parámetros de un elemento en fallo (p. ej. agrega la nota que
// pedía el aviso) y lo vuelve a poner en la fila.
export async function corregir(id: string, params: Record<string, unknown>) {
  const s = await store("readwrite")
  const el = (await pedir(s.get(id))) as ElementoCola | undefined
  if (!el) return
  el.params = { ...el.params, ...params }
  el.estado = "pendiente"
  delete el.error
  delete el.errorCodigo
  delete el.requiereNota
  await pedir(s.put(el))
}

export const llamadorReal: Llamador = {
  rpc: async (nombre, params) => {
    const { data, error } = await supabase.rpc(nombre, params)
    return { data, error }
  },
  subirFoto: subirEvidencia,
}

export interface ResultadoEnvio {
  enviados: number
  fallos: number
  detenidoPorRed: boolean
}

let enviando: Promise<ResultadoEnvio> | null = null

// Recorre la cola de una empresa en orden. Nunca corre dos veces a la vez.
export function enviar(org: string, llamador: Llamador = llamadorReal): Promise<ResultadoEnvio> {
  if (enviando) return enviando
  enviando = enviarAhora(org, llamador).finally(() => (enviando = null))
  return enviando
}

async function enviarAhora(org: string, llamador: Llamador): Promise<ResultadoEnvio> {
  const r: ResultadoEnvio = { enviados: 0, fallos: 0, detenidoPorRed: false }
  for (const el of await listar(org)) {
    if (el.estado === "fallo") continue
    el.estado = "enviando"
    el.intentos += 1
    await guardar(el)
    try {
      if (!el.resultado) {
        const { data, error } = await llamador.rpc(el.rpc, el.params)
        if (error) throw error
        el.resultado = String(data)
        await guardar(el)
      }
      if (el.foto) await llamador.subirFoto(org, el.resultado, el.foto, el.rpc)
      await borrar(el.id)
      r.enviados += 1
    } catch (e) {
      if (esErrorDeRed(e)) {
        el.estado = "pendiente"
        await guardar(el)
        r.detenidoPorRed = true
        break
      }
      const t = traducirErrorRpc(e)
      el.estado = "fallo"
      el.error = t.mensaje
      el.errorCodigo = t.codigo
      if (t.requiereNota) el.requiereNota = t.requiereNota
      await guardar(el)
      r.fallos += 1
    }
  }
  return r
}
