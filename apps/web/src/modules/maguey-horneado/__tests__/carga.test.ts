import { describe, it, expect, vi } from "vitest"
import { cargarMH } from "../api"
const from = vi.hoisted(() => vi.fn())
vi.mock("../../../shared/supabase/client", () => ({ supabase: { from } }))
vi.mock("../../../shared/offline/instantanea", () => ({
  conInstantanea: async (_org: string, _nombre: string, pedir: () => Promise<unknown>) => ({
    datos: await pedir(),
    instantanea: null,
  }),
}))
describe("lectura real de contratos de cocido (transporte simulado)", () => {
  it("distingue resultado de horneada, carga inicial y compra sin inventar recepción", async () => {
    const tablas: Record<string, Record<string, unknown>[]> = {
      lots: [
        { id: "producido", material: "agave_cocido", origin: "producido" },
        { id: "inicial", material: "agave_cocido", origin: "carga_inicial" },
        { id: "compra", material: "agave_cocido", origin: "compra" },
        { id: "desconocido", material: "agave_cocido", origin: "producido" },
        { id: "maguey", material: "maguey", origin: "compra" },
      ],
      roasting_runs: [{ id: "h1", folio: "HOR-001", output_lot_id: "producido" }],
    }
    const consultas: { tabla: string; campos?: string; org?: string }[] = []
    from.mockImplementation((tabla: string) => {
      const consulta = { tabla } as (typeof consultas)[number]
      consultas.push(consulta)
      const q = {
        select: (campos: string) => {
          consulta.campos = campos
          return q
        },
        eq: (_campo: string, org: string) => {
          consulta.org = org
          return q
        },
        order: () => q,
        range: async () => ({ data: tablas[tabla] ?? [], error: null }),
      }
      return q
    })
    const { datos } = await cargarMH("tenant-autorizado")
    const contexto = Object.fromEntries(datos.lotes.map((l) => [l.id, l.contexto]))
    expect(contexto).toEqual({
      producido: "De horneada HOR-001",
      inicial: "Carga inicial sin historia de horneado",
      compra: "Compra de agave cocido",
      desconocido: "Agave cocido · origen de horneado no disponible",
      maguey: "Especie sin especificar",
    })
    expect(consultas.every((c) => c.org === "tenant-autorizado")).toBe(true)
    expect(consultas.find((c) => c.tabla === "lots")?.campos).toContain("origin")
    expect(consultas.find((c) => c.tabla === "roasting_runs")?.campos).toContain("output_lot_id")
  })
})
