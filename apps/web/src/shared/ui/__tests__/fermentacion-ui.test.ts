// Contratos de las piezas nuevas de fermentacion/r01: big-number-field,
// scale-choice, datetime-field, step-flow, soft-warning-note; extensiones
// de status-chip (pending/failed) y banner (cola).
import { describe, expect, it } from "vitest"
import { mount } from "@vue/test-utils"
import { defineComponent, h } from "vue"
import Aviso from "../Aviso.vue"
import AvisoNota from "../AvisoNota.vue"
import CampoCuando from "../CampoCuando.vue"
import CampoGrande from "../CampoGrande.vue"
import ChipEstado from "../ChipEstado.vue"
import EscalaOpciones from "../EscalaOpciones.vue"
import FlujoPasos from "../FlujoPasos.vue"

describe("CampoGrande (big-number-field)", () => {
  it("número o null, coma decimal, teclado decimal, unidad y rango como texto", async () => {
    const w = mount(CampoGrande, {
      props: { modelValue: null, etiqueta: "Temperatura", unidad: "°C", rango: "entre 0 y 100" },
    })
    const input = w.get("input")
    expect(input.attributes("inputmode")).toBe("decimal")
    expect(w.text()).toContain("°C · entre 0 y 100")
    await input.setValue("27,5")
    expect(w.emitted("update:modelValue")?.[0]).toEqual([27.5])
    await input.setValue("")
    expect(w.emitted("update:modelValue")?.[1]).toEqual([null])
    expect(input.attributes("aria-describedby")).toBeTruthy()
  })
  it("error: aria-invalid y texto; sin spinners", () => {
    const w = mount(CampoGrande, {
      props: { modelValue: 300, etiqueta: "Brix", error: "Entre 0 y 40." },
    })
    expect(w.get("input").attributes("aria-invalid")).toBe("true")
    expect(w.get("input").attributes("type")).toBe("text")
    expect(w.text()).toContain("Entre 0 y 40.")
  })
})

describe("EscalaOpciones (scale-choice)", () => {
  const etiquetas = ["quieta", "apenas", "poca", "media", "mucha", "muy activa"]
  it("radiogroup de 6 con etiqueta viva; flechas mueven; nunca fuera de rango", async () => {
    const w = mount(EscalaOpciones, {
      props: { modelValue: null, etiqueta: "Actividad", etiquetas },
    })
    const radios = w.findAll("[role=radio]")
    expect(radios).toHaveLength(6)
    expect(w.text()).toContain("Elige un valor")
    await radios[3].trigger("click")
    expect(w.emitted("update:modelValue")?.[0]).toEqual([4])
    await w.setProps({ modelValue: 4 })
    expect(w.text()).toContain("4 · media")
    expect(radios[3].attributes("aria-checked")).toBe("true")
    expect(radios[3].attributes("aria-label")).toBe("4 · media")
    await radios[3].trigger("keydown", { key: "ArrowRight" })
    expect(w.emitted("update:modelValue")?.[1]).toEqual([5])
    await w.setProps({ modelValue: 6 })
    await radios[5].trigger("keydown", { key: "ArrowRight" })
    expect(w.emitted("update:modelValue")?.[2]).toEqual([6])
  })
})

describe("CampoCuando (datetime-field)", () => {
  it("por defecto «ahora» (null); cambiar abre datetime-local; «ahora» vuelve a null; nunca futuro", async () => {
    const w = mount(CampoCuando, { props: { modelValue: null } })
    expect(w.text()).toContain("ahora")
    await w.get("button").trigger("click")
    const e = w.emitted("update:modelValue")?.[0]?.[0] as string
    expect(e).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/)
    await w.setProps({ modelValue: e })
    const input = w.get("input[type=datetime-local]")
    expect(input.attributes("max")).toBeTruthy()
    const futuro = new Date(Date.now() + 3 * 3600_000)
    const p = (n: number) => String(n).padStart(2, "0")
    const iso = `${futuro.getFullYear()}-${p(futuro.getMonth() + 1)}-${p(futuro.getDate())}T${p(futuro.getHours())}:${p(futuro.getMinutes())}`
    await w.setProps({ modelValue: iso })
    await input.trigger("blur")
    expect(w.text()).toContain("No puede ser en el futuro.")
    await w.get("button").trigger("click") // «ahora»
    expect(w.emitted("update:modelValue")?.at(-1)).toEqual([null])
  })
})

describe("FlujoPasos (step-flow)", () => {
  const Host = defineComponent({
    props: { paso: { type: Number, required: true } },
    setup: (p) => () =>
      h(
        FlujoPasos,
        { paso: p.paso, total: 3, etiquetaSiguiente: p.paso === 3 ? "Guardar" : "Siguiente" },
        {
          cabecera: () => h("h2", "Tina 2"),
          default: () => h("input", { id: `campo-${p.paso}` }),
        },
      ),
  })
  it("Paso n de N en role=status; Cancelar solo en el primero; una primaria; el foco va al primer control", async () => {
    const w = mount(Host, { props: { paso: 1 }, attachTo: document.body })
    expect(w.get("[role=status]").text()).toBe("Paso 1 de 3")
    expect(w.findAll("button").map((b) => b.text())).toEqual(["Cancelar", "Siguiente"])
    expect(w.findAll(".boton--primary")).toHaveLength(1)
    await w.setProps({ paso: 2 })
    await new Promise((r) => setTimeout(r, 0))
    expect(w.findAll("button").map((b) => b.text())).toEqual(["Atrás", "Siguiente"])
    expect(document.activeElement?.id).toBe("campo-2")
    await w.setProps({ paso: 3 })
    expect(w.get(".boton--primary").text()).toBe("Guardar")
    w.unmount()
  })
})

describe("AvisoNota (soft-warning-note)", () => {
  it("oculto sin código; con código muestra el texto del aviso y pide la nota", async () => {
    const w = mount(AvisoNota, { props: { codigo: null, modelValue: "" } })
    expect(w.html()).toBe("<!--v-if-->")
    await w.setProps({ codigo: "brix_fuera_rango" })
    expect(w.get("[role=alert]").text()).toContain("Brix está fuera del rango habitual")
    expect(w.get("input").attributes("required")).toBeDefined()
    await w.get("input").setValue("Calor de mediodía")
    expect(w.emitted("update:modelValue")?.[0]).toEqual(["Calor de mediodía"])
  })
  it("un código desconocido no rompe: texto genérico", () => {
    const w = mount(AvisoNota, { props: { codigo: "algo_nuevo", modelValue: "" } })
    expect(w.text()).toContain("necesita una nota")
  })
})

describe("extensiones: status-chip y banner", () => {
  it("chip pending y failed llevan el texto (nunca color solo)", () => {
    expect(
      mount(ChipEstado, {
        props: { variante: "pending" },
        slots: { default: "pendiente de enviar" },
      }).classes(),
    ).toContain("chip--pending")
    expect(
      mount(ChipEstado, { props: { variante: "failed" }, slots: { default: "falló" } }).text(),
    ).toBe("falló")
  })
  it("banner cola con acción", () => {
    const w = mount(Aviso, {
      props: { variante: "cola", titulo: "2 capturas pendientes de enviar." },
      slots: { default: "Se envían al volver la señal.", accion: "<button>Reintentar</button>" },
    })
    expect(w.attributes("role")).toBe("status")
    expect(w.get("button").text()).toBe("Reintentar")
    expect(w.classes()).toContain("aviso--cola")
  })
})
