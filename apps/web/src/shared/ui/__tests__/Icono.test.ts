import { mount } from "@vue/test-utils"
import { describe, expect, it } from "vitest"
import Icono from "../Icono.vue"
import type { IconoNombre } from "../tipos"

const nombres: IconoNombre[] = [
  "i-maguey",
  "i-horno",
  "i-molienda",
  "i-tina",
  "i-destila",
  "i-lote",
  "i-home",
  "i-medir",
  "i-mas",
  "i-bell",
  "i-clock",
  "i-tanque",
  "i-traza",
  "i-ajustes",
  "i-menu",
]

describe("entrega canónica de iconos", () => {
  it.each(nombres)("%s es SVG Lucide autónomo, decorativo y de trazo 2", (nombre) => {
    const wrapper = mount(Icono, { props: { nombre } })
    const svg = wrapper.get("svg")
    expect(svg.attributes()).toMatchObject({
      viewBox: "0 0 24 24",
      width: "24",
      height: "24",
      "stroke-width": "2",
      "aria-hidden": "true",
      fill: "none",
    })
    expect(svg.classes()).toContain("lucide")
    expect(wrapper.find("use").exists()).toBe(false)
    wrapper.unmount()
  })
  it("un icono informativo recibe nombre y mantiene tamaño al cambiar de concepto", async () => {
    const wrapper = mount(Icono, {
      props: { nombre: "i-medir", titulo: "Medir temperatura", size: 20 },
    })
    expect(wrapper.get('[role="img"]').attributes("aria-label")).toBe("Medir temperatura")
    expect(wrapper.get("svg").attributes("aria-hidden")).toBeUndefined()
    const dibujo = wrapper.html()
    await wrapper.setProps({ nombre: "i-clock", titulo: "Hora de medición" })
    expect(wrapper.html()).not.toBe(dibujo)
    expect(wrapper.get("svg").attributes()).toMatchObject({
      width: "20",
      height: "20",
      "aria-label": "Hora de medición",
    })
    wrapper.unmount()
  })
  it("preserva el logotipo propio, sin depender de una inyección global", () => {
    const wrapper = mount(Icono, { props: { nombre: "pulz-mark", size: 22, titulo: "PULZ" } })
    expect(wrapper.get("svg").attributes()).toMatchObject({
      viewBox: "0 0 96 96",
      width: "22",
      "aria-label": "PULZ",
    })
    expect(wrapper.get("circle").attributes()).toMatchObject({ cx: "48", cy: "48", r: "42" })
    expect(wrapper.findAll("path")).toHaveLength(3)
    expect(wrapper.find("use").exists()).toBe(false)
    wrapper.unmount()
  })
})
