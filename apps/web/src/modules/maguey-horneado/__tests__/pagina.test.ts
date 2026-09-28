import { afterEach, describe, expect, it, vi } from "vitest"
import type { AuthChangeEvent, Session } from "@supabase/supabase-js"
import { reactive, ref } from "vue"
import { mount, flushPromises } from "@vue/test-utils"
import Pagina from "../pages/ProcesoSolidoPage.vue"
import Superficie from "../components/SuperficieMH.vue"
import { ejemploMH } from "../ejemplo"
const cargar = vi.hoisted(() => vi.fn())
const auth = vi.hoisted(() => ({
  escuchar: vi.fn(),
  salir: vi.fn(),
  refrescar: vi.fn(async () => {}),
}))
const online = ref(false)
const acceso = reactive({
  membresiaActual: { organization_id: "org", role: "productor" },
  modoLectura: false,
  cargarSesion: auth.refrescar,
})
vi.mock("vue-router", () => ({
  useRoute: () => ({ meta: { destino: "maguey" }, params: { slug: "ejemplo" } }),
}))
vi.mock("../../acceso/store", () => ({ useAcceso: () => acceso }))
vi.mock("../../../shared/utils/conexion", () => ({ useConexion: () => ({ enLinea: online }) }))
vi.mock("../api", () => ({ cargarMH: cargar, guardarMH: vi.fn() }))
vi.mock("../../../shared/supabase/client", () => ({
  supabase: {
    auth: {
      getSession: async () => ({ data: { session: { user: { id: "persona" } } } }),
      onAuthStateChange: auth.escuchar.mockReturnValue({
        data: { subscription: { unsubscribe: auth.salir } },
      }),
    },
  },
}))
afterEach(() => {
  vi.clearAllMocks()
  online.value = false
  vi.useRealTimers()
})
describe("ruta Maguey/Horneado", () => {
  it("cambiar persona en la misma empresa invalida datos/permisos y cambia partición", async () => {
    vi.useFakeTimers()
    cargar.mockResolvedValue({ datos: ejemploMH(), instantanea: null })
    const w = mount(Pagina, { global: { stubs: { SuperficieMH: true } } })
    await flushPromises()
    const callback = auth.escuchar.mock.calls[0][0] as (
      event: AuthChangeEvent,
      session: Session | null,
    ) => void
    callback("SIGNED_IN", { user: { id: "otra-persona" } } as Session)
    await w.vm.$nextTick()
    expect(w.getComponent(Superficie).props("contexto")).toBe("org:otra-persona:maguey")
    expect(w.getComponent(Superficie).props("puede")).toBe(false)
    expect(w.getComponent(Superficie).props("datos")).toBeNull()
    await vi.runAllTimersAsync()
    await flushPromises()
    expect(auth.refrescar).toHaveBeenCalledWith(true)
    expect(w.getComponent(Superficie).props("puede")).toBe(true)
    callback("SIGNED_OUT", null)
    await w.vm.$nextTick()
    expect(w.getComponent(Superficie).props("contexto")).toBe("")
    expect(w.getComponent(Superficie).props("puede")).toBe(false)
    w.unmount()
    expect(auth.salir).toHaveBeenCalledOnce()
  })
  it("recupera datos frescos al volver la señal y particiona intención por usuario/empresa", async () => {
    cargar
      .mockResolvedValueOnce({ datos: ejemploMH(), instantanea: "2026-09-01" })
      .mockResolvedValueOnce({ datos: ejemploMH(), instantanea: null })
    const w = mount(Pagina, { global: { stubs: { SuperficieMH: true } } })
    await flushPromises()
    expect(w.getComponent(Superficie).props("instantanea")).toBe("2026-09-01")
    expect(w.getComponent(Superficie).props("contexto")).toBe("org:persona:maguey")
    online.value = true
    await flushPromises()
    expect(cargar).toHaveBeenCalledTimes(2)
    expect(w.getComponent(Superficie).props("instantanea")).toBeNull()
    w.unmount()
  })
})
