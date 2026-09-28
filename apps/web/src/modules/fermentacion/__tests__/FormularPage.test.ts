import { flushPromises, mount, type VueWrapper } from "@vue/test-utils"
import { beforeEach, describe, expect, it, vi } from "vitest"
import { shallowRef } from "vue"
import { createMemoryHistory, createRouter } from "vue-router"
import FormularPage from "../pages/FormularPage.vue"
import { ErrorFermentacion, registrarFormulacion, tinasLibres } from "../api"

const contexto = vi.hoisted(() => ({
  acceso: {
    membresiaActual: { organization_id: "org-a", role: "productor", name: "Palenque" },
    modoLectura: false,
  },
}))
const enLinea = shallowRef(true)
vi.mock("../../acceso/store", () => ({ useAcceso: () => contexto.acceso }))
vi.mock("../../../shared/utils/conexion", () => ({ useConexion: () => ({ enLinea }) }))
vi.mock("../../../shared/supabase/client", () => ({ supabase: {} }))
vi.mock("../api", async (original) => ({
  ...(await original<typeof import("../api")>()),
  cargarUsos: vi.fn(async () => ({ datos: { usos: [] }, instantanea: null })),
  lotesCocido: vi.fn(async () => [{ lot_id: "cocido", folio: "AC-1", remaining_kg: 2000 }]),
  recursosDe: vi.fn(async () => []),
  insumos: vi.fn(async () => []),
  tinasLibres: vi.fn(),
  registrarFormulacion: vi.fn(),
}))

beforeEach(() => {
  vi.clearAllMocks()
  enLinea.value = true
  contexto.acceso.membresiaActual.role = "productor"
  contexto.acceso.modoLectura = false
  vi.mocked(tinasLibres).mockResolvedValue([
    { id: "tina", code: "Tina 1", capacity: 1500, capacity_policy: "flexible" },
  ])
  vi.mocked(registrarFormulacion).mockReset().mockResolvedValue("formulacion")
})

async function render() {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: "/e/:slug/fermentacion/formular", component: FormularPage },
      { path: "/e/:slug/fermentacion", component: { template: "<div />" } },
    ],
  })
  await router.push("/e/cuatro-vientos/fermentacion/formular")
  const wrapper = mount(FormularPage, { global: { plugins: [router] } })
  await flushPromises()
  return wrapper
}
function campo(wrapper: VueWrapper, etiqueta: string) {
  const label = wrapper.findAll("label").find((l) => l.text() === etiqueta)
  expect(label, `Existe etiqueta ${etiqueta}`).toBeDefined()
  return wrapper.get(`input[id="${label!.attributes("for")}"]`)
}
async function llenar(wrapper: VueWrapper, kilos = "100", litros = "1600") {
  await campo(wrapper, "Kilos").setValue(kilos)
  await campo(wrapper, "Litros").setValue(litros)
}

describe("Formular respeta las reglas duras y blandas del maestro", () => {
  it("capacidad flexible: permite enviar, pide la nota del servidor y conserva los datos", async () => {
    vi.mocked(registrarFormulacion).mockRejectedValueOnce(
      new ErrorFermentacion({
        codigo: "NOTA",
        requiereNota: "excede_capacidad",
        mensaje: "Requiere nota",
      }),
    )
    const wrapper = await render()
    await llenar(wrapper)
    expect(wrapper.get('button[type="submit"]').attributes("disabled")).toBeUndefined()
    expect(wrapper.text()).not.toContain("Solo hay 1,500")
    await wrapper.get("form").trigger("submit")
    await flushPromises()
    expect(wrapper.get('[role="alert"]').text()).toContain("política flexible")
    expect(wrapper.get('button[type="submit"]').attributes("disabled")).toBeDefined()
    await campo(wrapper, "Nota (obligatoria por el aviso)").setValue(
      "La capacidad real admite esta carga",
    )
    await wrapper.get("form").trigger("submit")
    await flushPromises()
    expect(registrarFormulacion).toHaveBeenLastCalledWith(
      "org-a",
      expect.objectContaining({
        tinas: [{ tina_id: "tina", litros: 1600, folio: null }],
        cocido: [{ lot_id: "cocido", kg: 100 }],
        nota: "La capacidad real admite esta carga",
      }),
    )
    wrapper.unmount()
  })
  it("capacidad estricta: bloquea antes de enviar", async () => {
    vi.mocked(tinasLibres).mockResolvedValue([
      { id: "tina", code: "Tina 1", capacity: 1500, capacity_policy: "estricta" },
    ])
    const wrapper = await render()
    await llenar(wrapper)
    expect(wrapper.get('button[type="submit"]').attributes("disabled")).toBeDefined()
    await wrapper.get("form").trigger("submit")
    expect(registrarFormulacion).not.toHaveBeenCalled()
    wrapper.unmount()
  })
  it("saldo de cocido sigue siendo un límite duro", async () => {
    const wrapper = await render()
    await llenar(wrapper, "2100", "1000")
    await wrapper.get("form").trigger("submit")
    expect(registrarFormulacion).not.toHaveBeenCalled()
    expect(wrapper.text()).toContain("Solo hay 2,000 kg")
    wrapper.unmount()
  })
  it("sin conexión no envía ni siquiera mediante submit del formulario", async () => {
    const wrapper = await render()
    await llenar(wrapper)
    enLinea.value = false
    await wrapper.get("form").trigger("submit")
    expect(registrarFormulacion).not.toHaveBeenCalled()
    wrapper.unmount()
  })
  it.each(["operador", "solo-lectura"])("%s no puede formular por URL", async (caso) => {
    if (caso === "operador") contexto.acceso.membresiaActual.role = caso
    else contexto.acceso.modoLectura = true
    const wrapper = await render()
    expect(wrapper.find("form").exists()).toBe(false)
    expect(wrapper.text()).toContain("Solo el administrador o un productor")
    expect(registrarFormulacion).not.toHaveBeenCalled()
    wrapper.unmount()
  })
})
