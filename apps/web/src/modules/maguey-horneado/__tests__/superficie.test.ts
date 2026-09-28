import { afterEach, describe, it, expect, vi } from "vitest"
import { mount, flushPromises, type VueWrapper, DOMWrapper } from "@vue/test-utils"
import { createMemoryHistory, createRouter } from "vue-router"
import SuperficieMH from "../components/SuperficieMH.vue"
import { ejemploMH } from "../ejemplo"
import { leerIntencion, RechazoCapturaMH } from "../intencion"
const wrappers: VueWrapper[] = []
afterEach(() => {
  wrappers.forEach((w) => w.unmount())
  wrappers.length = 0
  document.body.innerHTML = ""
  localStorage.clear()
})
async function render(
  destino: "maguey" | "horneado" = "maguey",
  extra: Record<string, unknown> = {},
) {
  const guardar = vi.fn(async () => "lote")
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [{ path: "/:pathMatch(.*)*", component: { template: "<div />" } }],
  })
  await router.push("/")
  const w = mount(SuperficieMH, {
    attachTo: document.body,
    props: {
      datos: ejemploMH(),
      destino,
      puede: true,
      enLinea: true,
      formulacion: "/formular",
      guardar,
      ...extra,
    },
    global: { plugins: [router] },
  })
  wrappers.push(w)
  await flushPromises()
  return { w, guardar }
}
function boton(w: VueWrapper | DOMWrapper<Element>, texto: string) {
  const b = w.findAll("button").find((x) => x.text() === texto)
  expect(b, `Botón ${texto}`).toBeDefined()
  return b!
}
function campo(w: VueWrapper | DOMWrapper<Element>, etiqueta: string) {
  const l = w.findAll("label").find((x) => x.text() === etiqueta)
  expect(l, `Campo ${etiqueta}`).toBeDefined()
  return w.get(`[id="${l!.attributes("for")}"]`)
}
describe("Maguey/Horneado: recorridos públicos", () => {
  it.each([
    { tipo: "abrir", idem: "x", fecha: "2026-09-01" },
    { tipo: "cocido", idem: "x", fecha: "2026-09-01", kg: "10", folio: "", nota: "" },
    { tipo: "cerrar", idem: "x", fecha: "2026-09-01", kg: 10, folio: "", nota: "" },
  ])("intención incompleta no rompe la vista, no se borra ni reenvía: $tipo", async (corrupta) => {
    const clave = "pulz:mh:intencion:org:persona:maguey"
    const raw = JSON.stringify(corrupta)
    localStorage.setItem(clave, raw)
    const { w, guardar } = await render("maguey", { contexto: "org:persona:maguey" })
    expect(w.get('[role="alert"]').text()).toContain("No se pudo recuperar")
    await boton(w, "Registrar recepción").trigger("click")
    await campo(w, "Kilos (obligatorio)").setValue("50")
    await w.get("form").trigger("submit")
    await flushPromises()
    expect(guardar).not.toHaveBeenCalled()
    expect(localStorage.getItem(clave)).toBe(raw)
  })
  it("la instantánea identifica su fecha y mantiene captura bloqueada", async () => {
    const { w } = await render("maguey", { instantanea: "2026-09-01T12:00:00Z" })
    expect(w.get("time").attributes("datetime")).toBe("2026-09-01T12:00:00Z")
    expect(w.get("time").text()).toContain("2026")
    expect(boton(w, "Registrar recepción").attributes("disabled")).toBeDefined()
  })
  it("HTTP ambiguo congela datos/hora y recupera la intención tras desmontar", async () => {
    const guardar = vi
      .fn()
      .mockRejectedValueOnce(new Error("Bad Gateway"))
      .mockResolvedValue("lote")
    const { w } = await render("maguey", { guardar, contexto: "org:persona:maguey" })
    await boton(w, "Registrar recepción").trigger("click")
    await campo(w, "Kilos (obligatorio)").setValue("50")
    await w.get("form").trigger("submit")
    await flushPromises()
    const original = guardar.mock.calls[0][0]
    expect(original.fecha).toBeTruthy()
    expect(leerIntencion("org:persona:maguey")).toEqual(original)
    await campo(w, "Kilos (obligatorio)").setValue("60")
    await w.get("form").trigger("submit")
    await flushPromises()
    expect(guardar).toHaveBeenCalledTimes(1)
    w.unmount()
    const recuperada = await render("maguey", { guardar, contexto: "org:persona:maguey" })
    expect(recuperada.w.text()).toContain("50 kg")
    await boton(recuperada.w, "Reintentar envío original").trigger("click")
    await flushPromises()
    expect(guardar.mock.calls[1][0]).toEqual(original)
    expect(leerIntencion("org:persona:maguey")).toBeNull()
    expect(recuperada.w.text()).toContain("Recepción registrada · 50 kg")
    expect(document.activeElement).toBe(recuperada.w.get(".mh-result").element)
  })
  it("rechazo confirmado permite corregir; fallo local no envía", async () => {
    const guardar = vi
      .fn()
      .mockRejectedValueOnce(new RechazoCapturaMH("No alcanza"))
      .mockResolvedValue("lote")
    const { w } = await render("maguey", { guardar, contexto: "org:persona:maguey" })
    await boton(w, "Registrar recepción").trigger("click")
    await campo(w, "Kilos (obligatorio)").setValue("50")
    await w.get("form").trigger("submit")
    await flushPromises()
    expect(leerIntencion("org:persona:maguey")).toBeNull()
    await campo(w, "Kilos (obligatorio)").setValue("60")
    await w.get("form").trigger("submit")
    await flushPromises()
    expect(guardar.mock.calls[1][0].kg).toBe(60)
  })
  it("almacenamiento no disponible impide enviar una intención sin proteger", async () => {
    const { w, guardar } = await render("maguey", { contexto: "org:persona:maguey" })
    const spy = vi.spyOn(Storage.prototype, "setItem").mockImplementation(() => {
      throw new Error("Sin almacenamiento")
    })
    await boton(w, "Registrar recepción").trigger("click")
    await campo(w, "Kilos (obligatorio)").setValue("50")
    await w.get("form").trigger("submit")
    await flushPromises()
    expect(guardar).not.toHaveBeenCalled()
    spy.mockRestore()
  })
  it("intenciones no se comparten entre empresas o personas", async () => {
    localStorage.setItem(
      "pulz:mh:intencion:otra:persona:maguey",
      JSON.stringify({ idem: "a", fecha: "2026-09-01", tipo: "cocido", kg: 10 }),
    )
    const { w } = await render("maguey", { contexto: "org:persona:maguey" })
    expect(w.text()).not.toContain("envío sin confirmar")
  })
  it("recepción mínima no asume valores y envía kilos reales", async () => {
    const { w, guardar } = await render()
    await boton(w, "Registrar recepción").trigger("click")
    expect((campo(w, "Kilos (obligatorio)").element as HTMLInputElement).value).toBe("")
    expect((campo(w, "Especie (opcional)").element as HTMLSelectElement).value).toBe("")
    await campo(w, "Kilos (obligatorio)").setValue("123.456")
    await w.get("form").trigger("submit")
    await flushPromises()
    expect(guardar).toHaveBeenCalledWith(
      expect.objectContaining({ tipo: "recepcion", kg: 123.456, especie: "", pinas: null }),
    )
    expect(w.text()).toContain("Recepción registrada · 123.456 kg")
  })
  it("volver a lista y reabrir no borra recepción", async () => {
    const { w } = await render()
    await boton(w, "Registrar recepción").trigger("click")
    await campo(w, "Kilos (obligatorio)").setValue("120")
    await boton(w, "Volver sin borrar").trigger("click")
    await boton(w, "Registrar recepción").trigger("click")
    expect((campo(w, "Kilos (obligatorio)").element as HTMLInputElement).value).toBe("120")
  })
  it("exceso de saldo impide revisar y la corrección elimina aria-invalid", async () => {
    const { w } = await render("horneado")
    await boton(w, "Abrir horneada").trigger("click")
    await campo(w, "Horno").setValue("horno1")
    const i = campo(w, "Kilos de MAG-002 · ejemplo")
    await i.setValue("1500")
    expect(i.attributes("aria-invalid")).toBe("true")
    expect(w.get("button[type=submit]").attributes("disabled")).toBeDefined()
    await i.setValue("1000")
    expect(i.attributes("aria-invalid")).toBeUndefined()
    expect(i.attributes("aria-describedby")).toBeUndefined()
    expect(w.get("button[type=submit]").attributes("disabled")).toBeUndefined()
  })
  it("revisión y retorno mantienen kilos, horno y folio", async () => {
    const { w, guardar } = await render("horneado")
    await boton(w, "Abrir horneada").trigger("click")
    await campo(w, "Horno").setValue("horno1")
    await campo(w, "Kilos de MAG-003 · ejemplo").setValue("0.125")
    await campo(w, "Folio (opcional)").setValue("HOR-MIO")
    await w.get("form").trigger("submit")
    expect(w.text()).toContain("0.125 kg en total")
    await boton(w, "Volver a cantidades").trigger("click")
    await flushPromises()
    expect(document.activeElement).toBe(campo(w, "Horno").element)
    expect((campo(w, "Kilos de MAG-003 · ejemplo").element as HTMLInputElement).value).toBe("0.125")
    expect((campo(w, "Folio (opcional)").element as HTMLInputElement).value).toBe("HOR-MIO")
    expect(guardar).not.toHaveBeenCalled()
  })
  it.each([{ puede: false }, { enLinea: false }])(
    "no permite registrar con restricción %j",
    async (restriccion) => {
      const { w, guardar } = await render("horneado", restriccion)
      await boton(w, "Cerrar horneada").trigger("click")
      expect(document.querySelector("[role=dialog]")).toBeNull()
      expect(guardar).not.toHaveBeenCalled()
    },
  )
  it("cierre cancelado conserva datos al reabrir", async () => {
    const { w } = await render("horneado")
    await boton(w, "Cerrar horneada").trigger("click")
    await flushPromises()
    let d = new DOMWrapper(document.querySelector("[role=dialog]")!)
    await campo(d, "Kilos cocidos").setValue("4321")
    await boton(d, "Cancelar").trigger("click")
    await flushPromises()
    await boton(w, "Cerrar horneada").trigger("click")
    await flushPromises()
    d = new DOMWrapper(document.querySelector("[role=dialog]")!)
    expect((campo(d, "Kilos cocidos").element as HTMLInputElement).value).toBe("4321")
  })
  it("fallo conserva valores y reintento conserva idempotencia", async () => {
    const guardar = vi
      .fn()
      .mockRejectedValueOnce(new Error("Sin conexión; reintenta."))
      .mockResolvedValue("lote")
    const { w } = await render("maguey", { guardar })
    await boton(w, "Registrar recepción").trigger("click")
    await campo(w, "Kilos (obligatorio)").setValue("50")
    await w.get("form").trigger("submit")
    await flushPromises()
    expect(w.text()).toContain("Sin conexión")
    await boton(w, "Reintentar envío original").trigger("click")
    await flushPromises()
    expect(guardar.mock.calls[0][0]).toEqual(guardar.mock.calls[1][0])
    expect(w.text()).toContain("Recepción registrada · 50 kg")
  })
  it("doble envío no duplica llamada", async () => {
    let resolver!: (v: string) => void
    const guardar = vi.fn(() => new Promise<string>((r) => (resolver = r)))
    const { w } = await render("maguey", { guardar })
    await boton(w, "Registrar recepción").trigger("click")
    await campo(w, "Kilos (obligatorio)").setValue("50")
    await w.get("form").trigger("submit")
    await w.get("form").trigger("submit")
    expect(guardar).toHaveBeenCalledTimes(1)
    resolver("lote")
    await flushPromises()
  })
  it("resultado de cierre refleja cantidad y bloquea el fondo", async () => {
    const { w, guardar } = await render("horneado")
    await boton(w, "Cerrar horneada").trigger("click")
    await flushPromises()
    const d = new DOMWrapper(document.querySelector("[role=dialog]")!)
    expect(w.element.parentElement?.inert).toBe(true)
    await campo(d, "Kilos cocidos").setValue("4321")
    await d.get("form").trigger("submit")
    await flushPromises()
    expect(guardar).toHaveBeenCalledWith(expect.objectContaining({ tipo: "cerrar", kg: 4321 }))
    expect(w.text()).toContain("Horneada cerrada · 4,321 kg")
  })
})
