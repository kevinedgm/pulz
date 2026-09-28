import "fake-indexeddb/auto"
import { IDBFactory } from "fake-indexeddb"
import { beforeEach, describe, expect, it, vi } from "vitest"
import { _reiniciarDb } from "../cola"
import { conInstantanea, guardarInstantanea, leerInstantanea } from "../instantanea"
import { ErrorAcceso } from "../../supabase/errores"

vi.mock("../../supabase/client", () => ({ supabase: {} }))

beforeEach(() => {
  vi.restoreAllMocks()
  globalThis.indexedDB = new IDBFactory()
  _reiniciarDb()
})

describe("conInstantanea compartida", () => {
  it("entrega datos frescos y deja la copia disponible antes de resolver", async () => {
    expect(await conInstantanea("a", "maguey", async () => [2000])).toEqual({
      datos: [2000],
      instantanea: null,
    })
    expect((await leerInstantanea("a", "maguey"))?.datos).toEqual([2000])
  })
  it.each([
    new TypeError("Failed to fetch"),
    new ErrorAcceso("RED", "No pudimos conectar. Revisa tu señal."),
    { message: "TypeError: Failed to fetch", code: "" },
  ])("recupera una instantánea ante un fallo de red: %s", async (error) => {
    await guardarInstantanea("a", "maguey", [2000])
    const resultado = await conInstantanea("a", "maguey", async () => {
      throw error
    })
    expect(resultado.datos).toEqual([2000])
    expect(resultado.instantanea).toEqual(expect.any(String))
  })
  it("no cruza la empresa ni el nombre de la consulta", async () => {
    await guardarInstantanea("a", "maguey", [2000])
    const sinRed = async () => {
      throw new TypeError("Failed to fetch")
    }
    await expect(conInstantanea("b", "maguey", sinRed)).rejects.toMatchObject({ codigo: "RED" })
    await expect(conInstantanea("a", "horneado", sinRed)).rejects.toMatchObject({ codigo: "RED" })
  })
  it.each([
    { code: "42501", message: "permission denied" },
    { code: "P0001", message: "NO_PERMITIDO: no tienes permiso" },
    Object.assign(new Error("No tienes permiso"), { rpc: { codigo: "PERMISO" } }),
    new ErrorAcceso("RECHAZO", "Usuario o contraseña incorrectos"),
  ])("no oculta un rechazo con datos antiguos incluso sin señal: %s", async (error) => {
    await guardarInstantanea("a", "maguey", [2000])
    vi.spyOn(navigator, "onLine", "get").mockReturnValue(false)
    await expect(
      conInstantanea("a", "maguey", async () => {
        throw error
      }),
    ).rejects.toBe(error)
  })
})
