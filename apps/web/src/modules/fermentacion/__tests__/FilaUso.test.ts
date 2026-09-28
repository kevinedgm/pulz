import { mount } from "@vue/test-utils"
import { describe, expect, it } from "vitest"
import { createMemoryHistory, createRouter } from "vue-router"
import FilaUso from "../components/FilaUso.vue"
import type { UsoTina } from "../api"

const AHORA = new Date("2026-09-27T12:00:00-06:00").getTime()
const base: UsoTina = {
  organization_id: "org-1",
  cycle_id: "ciclo-2",
  tina_id: "tina-2",
  tina: "Tina 2",
  capacidad_l: 1500,
  capacity_policy: "flexible",
  lot_id: "lote-2",
  folio: "FER-T2-001",
  status: "fermentando",
  formulation_id: "form-1",
  formulacion: "Formulación 1",
  started_at: "2026-09-22T08:00:00-06:00",
  started_by: "user-1",
  litros: 1300,
  mediciones: 4,
  ultima_medicion_at: "2026-09-26T08:00:00-06:00",
  ultima_medicion_dia: 5,
  ultima_actividad: 4,
  ultima_temperatura: 28.5,
  ultimo_brix: 10.1,
}

async function render(uso: UsoTina = base) {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [{ path: "/e/:slug/fermentacion/:ciclo/medir", component: { template: "<div />" } }],
  })
  await router.push("/")
  await router.isReady()
  return mount(FilaUso, {
    global: { plugins: [router] },
    props: {
      uso,
      dia: 6,
      esperados: 7,
      slug: "cuatro-vientos",
      puedeMedir: true,
      puedeGestionar: false,
      ahoraMs: AHORA,
    },
  })
}

describe("FilaUso como tina en fermentación", () => {
  it("muestra la identidad, las tres métricas y la acción real", async () => {
    const wrapper = await render()
    expect(wrapper.text()).toContain("Tina 2")
    expect(wrapper.text()).toContain("día 6")
    expect(wrapper.text()).toContain("28.5 °C")
    expect(wrapper.text()).toContain("10.1 °Bx")
    expect(wrapper.text()).toContain("Media · 4/6")
    expect(wrapper.get('a[aria-label="Registrar medición en Tina 2"]').text()).toContain(
      "Registrar medición",
    )
  })

  it("marca con texto una medición estrictamente mayor a 24 horas", async () => {
    const wrapper = await render()
    expect(wrapper.text()).toContain("Hace 28 h")
    expect(wrapper.text()).toContain("Medición atrasada")
    expect(wrapper.classes()).toContain("tina-fermentacion--atrasada")
  })

  it("explica el estado sin mediciones y no inventa valores", async () => {
    const wrapper = await render({
      ...base,
      ultima_medicion_at: null,
      ultima_actividad: null,
      ultima_temperatura: null,
      ultimo_brix: null,
    })
    expect(wrapper.text()).toContain("Sin mediciones")
    expect(wrapper.text()).toContain("Registra la primera medición")
    expect(wrapper.findAll("dd").map((node) => node.text())).toEqual(["—", "—", "—"])
  })

  it("oculta la acción primaria cuando el rol es solo lectura", async () => {
    const wrapper = await render()
    await wrapper.setProps({ puedeMedir: false })
    expect(wrapper.find('a[aria-label="Registrar medición en Tina 2"]').exists()).toBe(false)
    expect(wrapper.text()).toContain("No tienes permiso para registrar mediciones.")
  })

  it("no marca atraso cuando han pasado exactamente 24 horas", async () => {
    const wrapper = await render({
      ...base,
      ultima_medicion_at: new Date(AHORA - 24 * 3_600_000).toISOString(),
    })
    expect(wrapper.text()).toContain("Hace 24 h")
    expect(wrapper.text()).not.toContain("Medición atrasada")
  })

  it("bloquea acciones repetidas mientras abre el registro", async () => {
    const wrapper = await render()
    await wrapper.setProps({ registrando: true })
    const accion = wrapper.get('a[aria-label="Registrar medición en Tina 2"]')
    expect(accion.attributes("aria-busy")).toBe("true")
    expect(accion.attributes("aria-disabled")).toBe("true")
  })
})
