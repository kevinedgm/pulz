import { mount, flushPromises } from "@vue/test-utils"
import { createRouter, createMemoryHistory } from "vue-router"
import { describe, expect, it } from "vitest"
import NavLateral from "../NavLateral.vue"
import NavInferior from "../NavInferior.vue"
import { etiquetaNav } from "../etiquetaNav"

describe("MH-NAV-05 · etiquetas completas", () => {
  it.each(["Fermentación", "Destilación", "Inicio", "Granel"])(
    "%s conserva todos los caracteres de la etiqueta original",
    (nombre) => expect(etiquetaNav(nombre).replaceAll("\u00ad", "")).toBe(nombre),
  )
  it("usa un corte silábico explícito, no una letra huérfana", () => {
    expect(etiquetaNav("Fermentación")).toBe("Fermenta\u00adción")
    expect(etiquetaNav("Destilación")).toBe("Destila\u00adción")
  })
  it.each([NavLateral, NavInferior])(
    "preserva nombre accesible, ruta y destino activo",
    async (nav) => {
      const router = createRouter({
        history: createMemoryHistory(),
        routes: [{ path: "/fermentacion", component: { template: "<p>Destino</p>" } }],
      })
      await router.push("/fermentacion")
      const wrapper = mount(nav, {
        props: {
          actual: "fermentacion",
          items: [
            { id: "fermentacion", etiqueta: "Fermentación", icono: "i-tina", to: "/fermentacion" },
          ],
        },
        global: { plugins: [router] },
      })
      await flushPromises()
      expect(wrapper.get("a").attributes()).toMatchObject({
        "aria-label": "Fermentación",
        "aria-current": "page",
        href: "/fermentacion",
      })
      expect(wrapper.get("a span").text()).toBe("Fermenta\u00adción")
      wrapper.unmount()
    },
  )
})
