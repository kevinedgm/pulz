import { describe, it, expect, vi, beforeEach } from "vitest"
import { errorCaptura, type CapturaMH } from "../modelo"
import { parametrosMH, guardarMH } from "../api"
const rpc = vi.hoisted(() => vi.fn())
vi.mock("../../../shared/supabase/client", () => ({ supabase: { rpc } }))
const base = { idem: "clave-estable", fecha: "2026-09-01T12:00:00Z", folio: "", nota: "" }
const recepcion = (): CapturaMH => ({
  ...base,
  tipo: "recepcion",
  kg: 123.456,
  pinas: null,
  especie: "",
  predio: "",
  proveedor: "",
})
beforeEach(() => rpc.mockReset().mockResolvedValue({ data: "lote-real", error: null }))
describe("Contratos RPC y validación", () => {
  it("opcionales vacíos se envían como null, sin catálogo supuesto", () => {
    const p = parametrosMH("org", recepcion())
    expect(p.rpc).toBe("registrar_recepcion_maguey")
    expect(p.params).toMatchObject({
      p_kg: 123.456,
      p_especie: null,
      p_predio: null,
      p_proveedor: null,
      p_pinas: null,
      p_idem: "clave-estable",
      p_org: "org",
    })
  })
  it("apertura conserva correspondencia lote/kilos", () => {
    const p = parametrosMH("org", {
      ...base,
      tipo: "abrir",
      horno: "h",
      lotes: [
        { id: "a", kg: 0.125 },
        { id: "b", kg: 80 },
      ],
    })
    expect(p.rpc).toBe("abrir_horneado")
    expect(p.params).toMatchObject({ p_lotes: ["a", "b"], p_kilos: [0.125, 80], p_horno: "h" })
  })
  it("cierre usa RPC y parámetros existentes", () => {
    expect(
      parametrosMH("org", {
        ...base,
        tipo: "cerrar",
        horneada: "h",
        kg: 4321,
        combustible: " encino ",
      }),
    ).toMatchObject({
      rpc: "cerrar_horneado",
      params: { p_horneado: "h", p_kilos_cocidos: 4321, p_combustible: "encino" },
    })
  })
  it("entrada directa es agave cocido sin recurso ni historia supuesta", () => {
    expect(parametrosMH("org", { ...base, tipo: "cocido", kg: 90 })).toMatchObject({
      rpc: "registrar_entrada",
      params: {
        p_material: "agave_cocido",
        p_recurso: null,
        p_origen: "carga_inicial",
        p_cantidad: 90,
      },
    })
  })
  it.each([0, -1, NaN, Infinity])("rechaza kilos inválidos %s", (kg) => {
    expect(errorCaptura({ ...base, tipo: "cocido", kg })).not.toBeNull()
  })
  it("rechaza lote duplicado para no consumirlo dos veces", () => {
    expect(
      errorCaptura({
        ...base,
        tipo: "abrir",
        horno: "h",
        lotes: [
          { id: "a", kg: 1 },
          { id: "a", kg: 2 },
        ],
      }),
    ).toContain("una sola vez")
  })
  it("rechaza piñas fraccionales", () => {
    expect(
      errorCaptura({
        ...base,
        tipo: "recepcion",
        kg: 10,
        pinas: 2.5,
        especie: "",
        predio: "",
        proveedor: "",
      }),
    ).toContain("entero")
  })
  it("rechaza fecha inválida/futura", () => {
    expect(errorCaptura({ ...base, tipo: "cocido", kg: 1, fecha: "invalida" })).toContain("fecha")
    expect(errorCaptura({ ...base, tipo: "cocido", kg: 1, fecha: "2999-01-01" })).toContain(
      "futuro",
    )
  })
  it("reintenta con la misma clave suministrada por el formulario", async () => {
    await guardarMH("org", recepcion())
    await guardarMH("org", recepcion())
    expect(rpc).toHaveBeenCalledTimes(2)
    expect(rpc.mock.calls[0][1].p_idem).toBe(rpc.mock.calls[1][1].p_idem)
  })
  it("no llama RPC ante captura inválida", async () => {
    await expect(guardarMH("org", { ...base, tipo: "cocido", kg: 0 })).rejects.toThrow()
    expect(rpc).not.toHaveBeenCalled()
  })
})
