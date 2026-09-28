// Cola offline (§8.3, §16 Fase 5): en orden, una sola vez, un fallo de red
// detiene, un fallo de dominio no bloquea a los demás, y sobrevive a
// "recargar" (misma IndexedDB). IndexedDB real de mentira: fake-indexeddb.
import "fake-indexeddb/auto"
import { IDBFactory } from "fake-indexeddb"
import { beforeEach, describe, expect, it, vi } from "vitest"
import {
  _reiniciarDb,
  corregir,
  descartar,
  encolar,
  enviar,
  listar,
  reintentar,
  type Llamador,
} from "../cola"
import { guardarInstantanea, haceCuanto, leerInstantanea } from "../instantanea"

vi.mock("../../supabase/client", () => ({ supabase: {} }))

const ORG = "org-a"
const medicion = (n: number) => ({
  id: `idem-${n}`,
  org: ORG,
  rpc: "registrar_medicion" as const,
  params: { p_org: ORG, p_idem: `idem-${n}`, p_dia: n },
  resumen: `Medición · Tina 1 · día ${n}`,
  occurred_at: `2026-09-2${n}T08:30:00.000Z`,
})

function llamadorFalso(
  respuestas: Record<string, () => Promise<{ data: unknown; error: unknown }>>,
) {
  const llamadas: string[] = []
  const l: Llamador = {
    rpc: async (_nombre, params) => {
      const idem = String(params.p_idem)
      llamadas.push(idem)
      const r = respuestas[idem]
      return r ? r() : { data: `op-${idem}`, error: null }
    },
    subirFoto: vi.fn(async () => {}),
  }
  return { l, llamadas }
}

beforeEach(() => {
  // Base nueva por prueba (fake-indexeddb en memoria)
  ;(globalThis as unknown as { indexedDB: IDBFactory }).indexedDB = new IDBFactory()
  _reiniciarDb()
})

describe("cola", () => {
  it("encola en orden y lista solo lo de la empresa", async () => {
    await encolar(medicion(1))
    await encolar(medicion(2))
    await encolar({ ...medicion(3), org: "otra" })
    const l = await listar(ORG)
    expect(l.map((e) => e.id)).toEqual(["idem-1", "idem-2"])
    expect(l[0].estado).toBe("pendiente")
    expect(l[0].intentos).toBe(0)
  })

  it("envía en orden y borra lo enviado (una sola vez)", async () => {
    for (const n of [1, 2, 3]) await encolar(medicion(n))
    const { l, llamadas } = llamadorFalso({})
    const r = await enviar(ORG, l)
    expect(r).toEqual({ enviados: 3, fallos: 0, detenidoPorRed: false })
    expect(llamadas).toEqual(["idem-1", "idem-2", "idem-3"])
    expect(await listar(ORG)).toEqual([])
    await enviar(ORG, l)
    expect(llamadas).toHaveLength(3) // nada se reenvía
  })

  it("un fallo de red detiene el envío y deja lo demás pendiente; al reconectar sigue donde iba", async () => {
    for (const n of [1, 2, 3]) await encolar(medicion(n))
    let sinRed = true
    const { l, llamadas } = llamadorFalso({
      "idem-2": async () => {
        if (sinRed) throw new TypeError("Failed to fetch")
        return { data: "op-2", error: null }
      },
    })
    const r1 = await enviar(ORG, l)
    expect(r1).toEqual({ enviados: 1, fallos: 0, detenidoPorRed: true })
    expect(llamadas).toEqual(["idem-1", "idem-2"]) // la 3 ni se intentó
    expect((await listar(ORG)).map((e) => [e.id, e.estado])).toEqual([
      ["idem-2", "pendiente"],
      ["idem-3", "pendiente"],
    ])
    sinRed = false
    const r2 = await enviar(ORG, l)
    expect(r2).toEqual({ enviados: 2, fallos: 0, detenidoPorRed: false })
    expect(llamadas).toEqual(["idem-1", "idem-2", "idem-2", "idem-3"])
    expect(await listar(ORG)).toEqual([])
  })

  it("un error de dominio marca fallo con el mensaje traducido y no bloquea al siguiente", async () => {
    for (const n of [1, 2, 3]) await encolar(medicion(n))
    const { l, llamadas } = llamadorFalso({
      "idem-1": async () => ({
        data: null,
        error: { message: "REQUIERE_NOTA:brix_fuera_rango", code: "P0001" },
      }),
      "idem-2": async () => ({
        data: null,
        error: { message: "NO_PERMITIDO: el ciclo ya estaba cerrado" },
      }),
    })
    const r = await enviar(ORG, l)
    expect(r).toEqual({ enviados: 1, fallos: 2, detenidoPorRed: false })
    expect(llamadas).toEqual(["idem-1", "idem-2", "idem-3"])
    const [a, b] = await listar(ORG)
    expect(a.estado).toBe("fallo")
    expect(a.errorCodigo).toBe("NOTA")
    expect(a.requiereNota).toBe("brix_fuera_rango")
    expect(a.error).toMatch(/Brix.*nota/)
    expect(b.errorCodigo).toBe("PERMISO")
    expect(b.error).toBe("el ciclo ya estaba cerrado")
    // los fallos no se reintentan solos
    await enviar(ORG, l)
    expect(llamadas).toHaveLength(3)
  })

  it("corregir agrega la nota y vuelve a enviar; descartar solo borra fallos", async () => {
    await encolar(medicion(1))
    await encolar(medicion(2))
    let conNota = false
    const { l } = llamadorFalso({
      "idem-1": async () =>
        conNota
          ? { data: "op-1", error: null }
          : { data: null, error: { message: "REQUIERE_NOTA:brix_fuera_rango" } },
    })
    await enviar(ORG, l)
    expect((await listar(ORG)).map((e) => e.estado)).toEqual(["fallo"])
    await descartar("idem-2") // pendiente ya se envió; no existe
    await corregir("idem-1", { p_nota: "Brix alto por calor" })
    conNota = true
    const el = (await listar(ORG))[0]
    expect(el.estado).toBe("pendiente")
    expect(el.params.p_nota).toBe("Brix alto por calor")
    await enviar(ORG, l)
    expect(await listar(ORG)).toEqual([])
  })

  it("reintentar devuelve un fallo a pendiente; descartar lo borra", async () => {
    await encolar(medicion(1))
    const { l } = llamadorFalso({
      "idem-1": async () => ({
        data: null,
        error: { message: "SALDO_INSUFICIENTE: la tina tiene 10 L" },
      }),
    })
    await enviar(ORG, l)
    expect((await listar(ORG))[0].error).toBe("No alcanza: la tina tiene 10 L")
    await reintentar("idem-1")
    expect((await listar(ORG))[0].estado).toBe("pendiente")
    await enviar(ORG, l)
    await descartar("idem-1")
    expect(await listar(ORG)).toEqual([])
  })

  it("la foto sube después de la RPC; si la subida falla por red, la RPC no se repite", async () => {
    const foto = {
      blob: new Blob(["x"], { type: "image/jpeg" }),
      tipo: "image/jpeg",
      lot_id: "l1",
      kind_item_id: "k1",
    }
    await encolar({ ...medicion(1), foto })
    let sinRed = true
    const llamadas: string[] = []
    const l: Llamador = {
      rpc: async (_n, p) => {
        llamadas.push(String(p.p_idem))
        return { data: "op-1", error: null }
      },
      subirFoto: async () => {
        if (sinRed) throw new TypeError("NetworkError when attempting to fetch resource.")
      },
    }
    const r1 = await enviar(ORG, l)
    expect(r1.detenidoPorRed).toBe(true)
    const el = (await listar(ORG))[0]
    expect(el.estado).toBe("pendiente")
    expect(el.resultado).toBe("op-1")
    sinRed = false
    await enviar(ORG, l)
    expect(llamadas).toEqual(["idem-1"]) // la RPC solo una vez
    expect(await listar(ORG)).toEqual([])
  })

  it("sobrevive a recargar: otra conexión a la misma base ve la fila", async () => {
    await encolar(medicion(1))
    _reiniciarDb() // como si la app se hubiera cerrado
    expect((await listar(ORG)).map((e) => e.id)).toEqual(["idem-1"])
  })
})

describe("instantánea", () => {
  it("guarda y lee por empresa con su fecha", async () => {
    await guardarInstantanea(ORG, "tinas", [{ tina: "Tina 1" }])
    const i = await leerInstantanea<{ tina: string }[]>(ORG, "tinas")
    expect(i?.datos).toEqual([{ tina: "Tina 1" }])
    expect(i?.guardado_en).toMatch(/^\d{4}-/)
    expect(await leerInstantanea("otra", "tinas")).toBeNull()
  })

  it("haceCuanto: corto y en el idioma del palenque", () => {
    const ahora = Date.parse("2026-09-27T12:00:00Z")
    expect(haceCuanto("2026-09-27T11:59:40Z", ahora)).toBe("hace un momento")
    expect(haceCuanto("2026-09-27T11:45:00Z", ahora)).toBe("hace 15 min")
    expect(haceCuanto("2026-09-27T09:00:00Z", ahora)).toBe("hace 3 h")
    expect(haceCuanto("2026-09-26T12:00:00Z", ahora)).toBe("ayer")
    expect(haceCuanto("2026-09-24T12:00:00Z", ahora)).toBe("hace 3 días")
  })
})
