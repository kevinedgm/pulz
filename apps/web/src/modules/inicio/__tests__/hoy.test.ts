import { flushPromises, mount } from "@vue/test-utils"
import { beforeEach, describe, expect, it, vi } from "vitest"
import { computed, ref, shallowRef } from "vue"
import { createMemoryHistory, createRouter } from "vue-router"
import InicioEmpresaPage from "../pages/InicioEmpresaPage.vue"
import {
  cargarHoy,
  instantaneaMasAntigua,
  recortar,
  resumenHoy,
  rotuloHora,
  rutaCorregir,
  tieneLotes,
  type DatosHoy,
} from "../api"
import { fabAccion } from "../../../app/fab"
import type { UsoTina } from "../../fermentacion/api"
import type { ElementoCola } from "../../../shared/offline/cola"
import { ErrorAcceso } from "../../../shared/supabase/errores"

const contexto = vi.hoisted(() => ({
  acceso: {
    slug: "cuatro-vientos",
    membresiaActual: { organization_id: "org-a", role: "productor", name: "Palenque" },
    modoLectura: false,
  },
  cola: { elementos: [] as unknown[] },
}))
const enLinea = shallowRef(true)
const elementos = ref<ElementoCola[]>([])
const cola = {
  elementos,
  enviando: ref(false),
  pendientes: computed(() => elementos.value.filter((e) => e.estado !== "fallo").length),
  fallos: computed(() => elementos.value.filter((e) => e.estado === "fallo")),
  usarEmpresa: vi.fn(),
  refrescar: vi.fn(),
  enviarAhora: vi.fn(),
  reintentar: vi.fn(),
  corregir: vi.fn(),
  descartar: vi.fn(),
}
vi.mock("../../acceso/store", () => ({ useAcceso: () => contexto.acceso }))
vi.mock("../../../shared/utils/conexion", () => ({ useConexion: () => ({ enLinea }) }))
vi.mock("../../../shared/offline/useCola", () => ({ useCola: () => cola }))
vi.mock("../../../shared/supabase/client", () => ({ supabase: {} }))
vi.mock("../api", async (original) => ({
  ...(await original<typeof import("../api")>()),
  tieneLotes: vi.fn(async () => true),
  cargarHoy: vi.fn(),
}))

const hoyIso = new Date().toISOString()
const ayer = new Date(Date.now() - 26 * 3600_000).toISOString()
const hace9dias = new Date(Date.now() - 9 * 86_400_000).toISOString()
const uso = (p: Partial<UsoTina>): UsoTina =>
  ({
    organization_id: "org-a",
    cycle_id: "c1",
    tina_id: "t1",
    tina: "Tina 1",
    capacidad_l: 1500,
    capacity_policy: "flexible",
    lot_id: "l1",
    folio: "FER-1",
    status: "fermentando",
    formulation_id: null,
    formulacion: null,
    started_at: hace9dias,
    started_by: "Aurelia",
    litros: 1300,
    mediciones: 0,
    ultima_medicion_at: null,
    ultima_medicion_dia: null,
    ultima_actividad: null,
    ultima_temperatura: null,
    ultimo_brix: null,
    ...p,
  }) as UsoTina
const datos = (p: Partial<DatosHoy> = {}): DatosHoy => ({
  usos: [
    uso({ cycle_id: "c3", tina: "Tina 3" }),
    uso({ cycle_id: "c2", tina: "Tina 2", ultima_medicion_at: ayer, litros: 1400 }),
    uso({ cycle_id: "c1", tina: "Tina 1", status: "en_vaciado", ultima_medicion_at: hoyIso }),
  ],
  ajustes: { measurement_reminder_hour: 0, fermentation_expected_days: 7 },
  corridas: [
    {
      organization_id: "org-a",
      run_id: "r1",
      folio: "DES-004",
      still_id: "s1",
      alambique: "Alambique 1",
      capacidad_l: 300,
      pass: "primera",
      status: "abierta",
      started_at: hoyIso,
      started_by: "Tomás",
      closed_at: null,
      litros_cargados: 290,
      origenes: [],
      litros_cortados: 60,
      cortes: [],
    },
  ],
  colectores: [
    {
      resource_id: "col1",
      colector: "Colector mezcal",
      liquid_class: "mezcal",
      capacidad_l: 60,
      lot_id: "lm",
      folio: "MEZ-002",
      litros: 8,
      abv: 51,
      abv_at: hoyIso,
      abv_by: "Tomás",
    },
  ],
  ...p,
})

beforeEach(() => {
  vi.clearAllMocks()
  enLinea.value = true
  elementos.value = []
  contexto.acceso.membresiaActual.role = "productor"
  contexto.acceso.modoLectura = false
  vi.mocked(tieneLotes).mockResolvedValue(true)
  vi.mocked(cargarHoy).mockResolvedValue({ datos: datos(), instantanea: null })
})

async function render(query = "") {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: "/e/:slug/inicio", component: InicioEmpresaPage },
      { path: "/:pathMatch(.*)*", component: { template: "<div />" } },
    ],
  })
  await router.push(`/e/cuatro-vientos/inicio${query}`)
  const wrapper = mount(InicioEmpresaPage, { global: { plugins: [router] } })
  await flushPromises()
  return { wrapper, router }
}
const hrefs = (w: {
  findAll: (s: string) => { attributes: (a: string) => string | undefined }[]
}) => w.findAll("a").map((a) => a.attributes("href"))

describe("puras de Hoy", () => {
  it("rotuloHora: antes de la hora del recordatorio solo cambia el rótulo", () => {
    expect(rotuloHora(new Date(2026, 8, 28, 8, 20), 9)).toBe("toca desde las 9:00")
    expect(rotuloHora(new Date(2026, 8, 28, 9, 0), 9)).toBe("toca medir")
  })
  it("resumenHoy pluraliza y dice cuando no hay nada", () => {
    expect(resumenHoy({ porMedir: 3, corridas: 1, cola: 2 })).toBe(
      "3 tinas por medir · 1 corrida abierta · 2 capturas por enviar",
    )
    expect(resumenHoy({ porMedir: 1, corridas: 0, cola: 0 })).toBe(
      "1 tina por medir · sin corridas · nada por enviar",
    )
  })
  it("recortar deja 8 y cuenta el resto; la instantánea que se muestra es la más antigua", () => {
    expect(recortar(Array.from({ length: 14 }, (_, i) => i))).toEqual({
      visibles: [0, 1, 2, 3, 4, 5, 6, 7],
      restantes: 6,
    })
    expect(instantaneaMasAntigua("2026-09-28T08:55:00Z", "2026-09-28T09:10:00Z")).toBe(
      "2026-09-28T08:55:00Z",
    )
    expect(instantaneaMasAntigua(null, "x")).toBe("x")
    expect(instantaneaMasAntigua(null, null)).toBeNull()
  })
  it("rutaCorregir solo cuando la captura pide nota, a su pantalla de origen", () => {
    const base = {
      id: "k1",
      org: "o",
      occurred_at: hoyIso,
      creado_en: hoyIso,
      orden: 1,
      estado: "fallo",
      intentos: 1,
      resumen: "",
    }
    expect(
      rutaCorregir("cv", {
        ...base,
        rpc: "registrar_medicion",
        params: { p_ciclo: "c2" },
        requiereNota: "brix",
      } as ElementoCola),
    ).toBe("/e/cv/fermentacion/c2/medir?corregir=k1&volver=inicio")
    expect(
      rutaCorregir("cv", {
        ...base,
        rpc: "registrar_corte",
        params: { p_corrida: "r1" },
        requiereNota: "abv",
      } as ElementoCola),
    ).toBe("/e/cv/destilacion/r1/corte?corregir=k1")
    expect(
      rutaCorregir("cv", { ...base, rpc: "registrar_corte", params: {} } as ElementoCola),
    ).toBeNull()
  })
})

describe("Inicio / Hoy", () => {
  it("compone Toca medir (orden de Fermentación), Destilación y el FAB a la primera tina", async () => {
    const { wrapper } = await render()
    expect(wrapper.get("[role=status]").text()).toBe(
      "2 tinas por medir · 1 corrida abierta · nada por enviar",
    )
    const tinas = wrapper.findAll("h3").map((h) => h.text())
    expect(tinas[1]).toContain("Tina 3")
    expect(tinas[2]).toContain("Tina 2")
    expect(wrapper.text()).toContain("día 10 de 7")
    expect(wrapper.text()).toContain("1 lista para destilar")
    expect(hrefs(wrapper)).toContain("/e/cuatro-vientos/fermentacion/c3/medir?volver=inicio")
    // una sola primaria: el Medir de la más atrasada
    const primarias = wrapper.findAll(".boton--primary")
    expect(primarias).toHaveLength(1)
    expect(primarias[0]!.text()).toBe("Medir")
    expect(typeof fabAccion.value).toBe("function")
    expect(hrefs(wrapper)).toContain("/e/cuatro-vientos/destilacion/r1/corte")
    expect(hrefs(wrapper)).toContain("/e/cuatro-vientos/granel/transferir?origen=col1")
    expect(wrapper.text()).not.toContain("Por enviar")
    wrapper.unmount()
    expect(fabAccion.value).toBeNull()
  })

  it("operador: mide y corta pero no pasa a granel; solo lectura no captura", async () => {
    contexto.acceso.membresiaActual.role = "operador"
    let r = await render()
    expect(hrefs(r.wrapper)).toContain("/e/cuatro-vientos/fermentacion/c3/medir?volver=inicio")
    expect(hrefs(r.wrapper)).toContain("/e/cuatro-vientos/destilacion/r1/corte")
    expect(hrefs(r.wrapper)).not.toContain("/e/cuatro-vientos/granel/transferir?origen=col1")
    r.wrapper.unmount()
    contexto.acceso.modoLectura = true
    r = await render()
    expect(r.wrapper.text()).not.toContain("Medir")
    expect(r.wrapper.text()).not.toContain("Cortar")
    expect(fabAccion.value).toBeNull()
    r.wrapper.unmount()
  })

  it("todo medido y nada pendiente; sin lotes ofrece el arranque", async () => {
    vi.mocked(cargarHoy).mockResolvedValue({
      datos: datos({
        usos: [uso({ cycle_id: "c1", tina: "Tina 1", ultima_medicion_at: hoyIso })],
        corridas: [],
        colectores: [],
      }),
      instantanea: null,
    })
    let r = await render()
    expect(r.wrapper.text()).toContain("Hoy no hay nada pendiente")
    r.wrapper.unmount()
    vi.mocked(cargarHoy).mockResolvedValue({
      datos: datos({ usos: [uso({ cycle_id: "c1", ultima_medicion_at: hoyIso })] }),
      instantanea: null,
    })
    r = await render()
    expect(r.wrapper.text()).toContain("Todo medido por hoy")
    r.wrapper.unmount()
    vi.mocked(tieneLotes).mockResolvedValue(false)
    r = await render()
    expect(r.wrapper.text()).toContain("¿Qué tienes hoy?")
    expect(hrefs(r.wrapper)).toContain("/e/cuatro-vientos/arranque")
    r.wrapper.unmount()
  })

  it("Por enviar: fallo con motivo → Reintentar y Corregir; pendiente espera señal", async () => {
    elementos.value = [
      {
        id: "k1",
        org: "org-a",
        rpc: "registrar_medicion",
        params: { p_ciclo: "c2" },
        resumen: "Medición · Tina 2 · día 22",
        occurred_at: hoyIso,
        creado_en: hoyIso,
        orden: 1,
        estado: "fallo",
        intentos: 1,
        error: "Brix fuera de rango: escribe una nota",
        requiereNota: "brix_fuera_rango",
      },
      {
        id: "k2",
        org: "org-a",
        rpc: "registrar_corte",
        params: { p_corrida: "r1" },
        resumen: "Corte · DES-004 · mezcal 20 L",
        occurred_at: hoyIso,
        creado_en: hoyIso,
        orden: 2,
        estado: "pendiente",
        intentos: 0,
      },
    ] as ElementoCola[]
    const { wrapper } = await render()
    expect(wrapper.get("[role=status]").text()).toContain("2 capturas por enviar")
    expect(wrapper.text()).toContain("Por enviar · 2")
    expect(wrapper.text()).toContain("Falló: Brix fuera de rango")
    expect(hrefs(wrapper)).toContain(
      "/e/cuatro-vientos/fermentacion/c2/medir?corregir=k1&volver=inicio",
    )
    expect(wrapper.text()).toContain("pendiente · espera señal")
    await wrapper
      .findAll("button")
      .find((b) => b.text() === "Reintentar")!
      .trigger("click")
    expect(cola.reintentar).toHaveBeenCalledWith("k1")
    wrapper.unmount()
  })

  it("sin señal muestra la fecha de la instantánea y conserva Medir", async () => {
    // tieneLotes no tiene instantánea: un fallo de red no tumba Hoy
    vi.mocked(tieneLotes).mockRejectedValue(new ErrorAcceso("RED", "Sin señal"))
    vi.mocked(cargarHoy).mockResolvedValue({ datos: datos(), instantanea: "2026-09-28T14:55:00Z" })
    const { wrapper } = await render("?aviso=medida")
    expect(wrapper.text()).toContain("Mostrando datos guardados el")
    expect(wrapper.get("time").attributes("datetime")).toBe("2026-09-28T14:55:00Z")
    expect(wrapper.text()).toContain("Medición guardada.")
    expect(hrefs(wrapper)).toContain("/e/cuatro-vientos/fermentacion/c3/medir?volver=inicio")
    wrapper.unmount()
  })
})
