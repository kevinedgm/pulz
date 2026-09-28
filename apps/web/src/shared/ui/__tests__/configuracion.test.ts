// Contratos de las piezas de configuracion/r01: select, number-field,
// switch, color-field, file-picker, brand-block.
import { describe, expect, it } from "vitest"
import { mount } from "@vue/test-utils"
import {
  BloqueMarca,
  CampoColor,
  CampoNumero,
  Interruptor,
  Selector,
  SelectorArchivo,
} from "../index"

describe("Selector (select)", () => {
  it("etiqueta ligada, opciones, placeholder deshabilitado, emite al cambiar", async () => {
    const w = mount(Selector, {
      props: {
        modelValue: "",
        etiqueta: "Catálogo",
        placeholder: "Elige uno",
        opciones: [
          { valor: "a", etiqueta: "Tipos de tina" },
          { valor: "b", etiqueta: "Especies", disabled: true },
        ],
        ayuda: "Solo los visibles.",
      },
    })
    const sel = w.get("select")
    expect(w.get("label").attributes("for")).toBe(sel.attributes("id"))
    const ops = w.findAll("option")
    expect(ops).toHaveLength(3)
    expect(ops[0].attributes("disabled")).toBeDefined()
    expect(ops[2].attributes("disabled")).toBeDefined()
    expect(w.get(`[id="${sel.attributes("aria-describedby")}"]`).text()).toBe("Solo los visibles.")
    await sel.setValue("a")
    expect(w.emitted("update:modelValue")?.[0]).toEqual(["a"])
    await w.setProps({ error: "Elige uno." })
    expect(w.get("select").attributes("aria-invalid")).toBe("true")
  })
})

describe("CampoNumero (number-field)", () => {
  it("emite número o null, acepta coma decimal y muestra la unidad", async () => {
    const w = mount(CampoNumero, {
      props: { modelValue: null, etiqueta: "Capacidad", unidad: "L" },
    })
    expect(w.get("input").attributes("inputmode")).toBe("decimal")
    expect(w.text()).toContain("L")
    await w.get("input").setValue("1500,5")
    expect(w.emitted("update:modelValue")?.[0]).toEqual([1500.5])
    await w.get("input").setValue("")
    expect(w.emitted("update:modelValue")?.[1]).toEqual([null])
    await w.get("input").setValue("abc")
    expect(w.emitted("update:modelValue")?.[2]).toEqual([null])
    const e = mount(CampoNumero, { props: { modelValue: 9, etiqueta: "Hora", decimales: false } })
    expect(e.get("input").attributes("inputmode")).toBe("numeric")
    expect((e.get("input").element as HTMLInputElement).value).toBe("9")
  })
})

describe("Interruptor (switch)", () => {
  it("role=switch con aria-checked y texto Sí/No; emite al pulsar", async () => {
    const w = mount(Interruptor, {
      props: { modelValue: false, etiqueta: "¿Capturan puntas?", ayuda: "Casi nadie." },
    })
    const b = w.get("[role=switch]")
    expect(b.attributes("aria-checked")).toBe("false")
    expect(b.text()).toContain("No")
    expect(document.getElementById(b.attributes("aria-labelledby")!)).toBeNull() // no montado en body: solo se comprueba que exista el id
    expect(w.get(`[id="${b.attributes("aria-labelledby")}"]`).text()).toBe("¿Capturan puntas?")
    await b.trigger("click")
    expect(w.emitted("update:modelValue")?.[0]).toEqual([true])
    await w.setProps({ modelValue: true })
    expect(w.get("[role=switch]").attributes("aria-checked")).toBe("true")
    expect(w.get("[role=switch]").text()).toContain("Sí")
  })
})

describe("CampoColor (color-field)", () => {
  it("hex editable en mayúsculas con # automático; el color nativo emite en mayúsculas", async () => {
    const w = mount(CampoColor, {
      props: { modelValue: "#7A3E1D", etiqueta: "Color de la empresa" },
    })
    const [color, hex] = w.findAll("input")
    expect(color.attributes("type")).toBe("color")
    expect((hex.element as HTMLInputElement).value).toBe("#7A3E1D")
    await hex.setValue("173f87")
    expect(w.emitted("update:modelValue")?.[0]).toEqual(["#173F87"])
    await color.setValue("#287a55")
    expect(w.emitted("update:modelValue")?.[1]).toEqual(["#287A55"])
    await w.setProps({ error: "Debe ser #RRGGBB." })
    expect(w.findAll("input")[1].attributes("aria-invalid")).toBe("true")
  })
})

describe("SelectorArchivo (file-picker)", () => {
  const archivo = (tipo: string, bytes: number) =>
    new File([new Uint8Array(bytes)], "logo", { type: tipo })
  const cambiar = async (w: ReturnType<typeof mount>, f: File) => {
    const input = w.get('input[type="file"]').element as HTMLInputElement
    Object.defineProperty(input, "files", { value: [f], configurable: true })
    await w.get('input[type="file"]').trigger("change")
  }
  it("acepta png dentro del tope y rechaza tipo o tamaño con motivo", async () => {
    const w = mount(SelectorArchivo, { props: { etiqueta: "Logo", maxBytes: 1000 } })
    await cambiar(w, archivo("image/png", 500))
    expect(w.emitted("elegir")).toHaveLength(1)
    await cambiar(w, archivo("image/svg+xml", 10))
    expect(w.emitted("rechazar")?.[0]).toEqual(["Solo PNG, JPG o WebP."])
    await cambiar(w, archivo("image/png", 5000))
    expect(w.emitted("rechazar")?.[1]?.[0]).toContain("pesa más")
  })
  it("con vista previa ofrece Quitar", async () => {
    const w = mount(SelectorArchivo, {
      props: { etiqueta: "Logo", previewUrl: "https://x/logo.png" },
    })
    expect(w.get("img").attributes("src")).toBe("https://x/logo.png")
    await w.findAll("button")[1].trigger("click")
    expect(w.emitted("quitar")).toHaveLength(1)
  })
})

describe("BloqueMarca (brand-block)", () => {
  it("monograma cuando no hay logo, nombre completo en title, acento como variable; esqueleto sin marca", () => {
    const w = mount(BloqueMarca, {
      props: { marca: { nombre: "Mezcal Cuatro Vientos", mensaje: "Hola", acento: "#7A3E1D" } },
    })
    expect(w.get(".marca__monograma").text()).toBe("MC")
    expect(w.get("h1").attributes("title")).toBe("Mezcal Cuatro Vientos")
    expect((w.get("header").element as HTMLElement).style.getPropertyValue("--acento")).toBe(
      "#7A3E1D",
    )
    expect(w.text()).toContain("Hola")
    const p = mount(BloqueMarca, {
      props: { marca: { nombre: "X", logoUrl: "https://x/l.png" }, nivel: "p" },
    })
    expect(p.get("img").attributes("src")).toBe("https://x/l.png")
    expect(p.find("h1").exists()).toBe(false)
    const s = mount(BloqueMarca)
    expect(s.find("[aria-busy=true]").exists()).toBe(true)
  })
})
