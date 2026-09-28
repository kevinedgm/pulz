import { beforeEach, describe, expect, it, vi } from "vitest"
import { createPinia, setActivePinia } from "pinia"
import { flushPromises } from "@vue/test-utils"
import { useAcceso } from "../store"
const api = vi.hoisted(() => ({
  haySesion: vi.fn(),
  misMembresias: vi.fn(),
  cerrarSesion: vi.fn(),
}))
vi.mock("../api", () => ({ ...api, entrar: vi.fn(), portalBranding: vi.fn() }))
beforeEach(() => {
  setActivePinia(createPinia())
  vi.resetAllMocks()
  api.haySesion.mockResolvedValue(true)
  api.cerrarSesion.mockResolvedValue(undefined)
})
describe("sesiones concurrentes", () => {
  it("descarta membresías antiguas si C responde antes que B", async () => {
    let resolverB!: (v: unknown[]) => void
    let resolverC!: (v: unknown[]) => void
    api.misMembresias
      .mockReturnValueOnce(
        new Promise((r) => {
          resolverB = r
        }),
      )
      .mockReturnValueOnce(
        new Promise((r) => {
          resolverC = r
        }),
      )
    const store = useAcceso()
    store.slug = "empresa"
    const b = store.cargarSesion(true)
    await flushPromises()
    const c = store.cargarSesion(true)
    await flushPromises()
    resolverC([{ slug: "empresa", role: "operador" }])
    await c
    resolverB([{ slug: "empresa", role: "admin" }])
    await b
    expect(store.membresiaActual?.role).toBe("operador")
    expect(store.esAdmin).toBe(false)
  })
  it("salir invalida una consulta que aún está en vuelo", async () => {
    let resolver!: (v: unknown[]) => void
    api.misMembresias.mockReturnValue(
      new Promise((r) => {
        resolver = r
      }),
    )
    const store = useAcceso()
    const consulta = store.cargarSesion(true)
    await flushPromises()
    await store.cerrarSesion()
    resolver([{ slug: "empresa", role: "admin" }])
    await consulta
    expect(store.sesion).toBe(false)
    expect(store.membresias).toEqual([])
  })
})
