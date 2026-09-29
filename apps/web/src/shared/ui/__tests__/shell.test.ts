// Contratos de las piezas del shell (registry: page-header, side-nav,
// bottom-nav, fab; ronda shell/r01) y del tema.
import { afterEach, beforeEach, describe, expect, it } from "vitest"
import { mount } from "@vue/test-utils"
import { createMemoryHistory, createRouter } from "vue-router"
import { defineComponent, h } from "vue"
import { BotonFlotante, CabeceraPagina, NavInferior, NavLateral, type ItemNav } from "../index"
import { aplicarTema, aplicarTemaGuardado, useTema } from "../../../app/tema"

const items: ItemNav[] = [
  { id: "inicio", etiqueta: "Inicio", icono: "i-home", to: "/e/cv/inicio" },
  { id: "fermentacion", etiqueta: "Fermentación", icono: "i-tina", to: "/e/cv/fermentacion" },
  { id: "destilacion", etiqueta: "Destilación", icono: "i-destila", to: "/e/cv/destilacion" },
  { id: "granel", etiqueta: "Granel", icono: "i-tanque", to: "/e/cv/granel" },
]
const Vacia = defineComponent({ render: () => h("div") })
async function router() {
  const r = createRouter({
    history: createMemoryHistory(),
    routes: [{ path: "/:pathMatch(.*)*", component: Vacia }],
  })
  await r.push("/e/cv/inicio")
  return r
}

describe("NavInferior (bottom-nav)", () => {
  it("4 fijos + Más; el actual por aria-current; Más es un botón con aria-haspopup", async () => {
    const w = mount(NavInferior, {
      props: { items, actual: "granel" },
      global: { plugins: [await router()] },
    })
    const enlaces = w.findAll("a")
    expect(enlaces).toHaveLength(4)
    expect(enlaces.map((a) => a.attributes("href"))).toContain("/e/cv/granel")
    expect(w.find('a[aria-current="page"]').text()).toContain("Granel")
    const mas = w.get("button")
    expect(mas.text()).toContain("Más")
    expect(mas.attributes("aria-haspopup")).toBe("dialog")
    expect(mas.attributes("aria-expanded")).toBe("false")
    await mas.trigger("click")
    expect(w.emitted("mas")).toHaveLength(1)
  })

  it("con teclado virtual (oculta) no se muestra", async () => {
    const w = mount(NavInferior, {
      props: { items, actual: "inicio", oculta: true },
      global: { plugins: [await router()] },
    })
    expect(w.get("nav").classes()).toContain("inf--oculta")
  })
})

describe("NavLateral (side-nav)", () => {
  it("empresa con nombre completo en title, destinos con aria-current, cuenta solo si se pasa", async () => {
    const w = mount(NavLateral, {
      props: {
        items,
        actual: "fermentacion",
        empresa: { nombre: "Destilería Artesanal de los Cuatro Vientos", iniciales: "DA" },
        cuenta: { nombre: "titular", subtitulo: "admin · cuenta", iniciales: "T" },
        ancho: "expanded",
      },
      global: { plugins: [await router()] },
    })
    expect(w.get(".lat__empresa").attributes("title")).toBe(
      "Destilería Artesanal de los Cuatro Vientos",
    )
    expect(w.findAll("a")).toHaveLength(4)
    const destino = w.get('a[aria-current="page"]')
    expect(destino.text().replaceAll("\u00ad", "")).toBe("Fermentación")
    expect(destino.attributes("aria-label")).toBe("Fermentación")
    await w.get("button").trigger("click")
    expect(w.emitted("cuenta")).toHaveLength(1)

    const sinCuenta = mount(NavLateral, {
      props: {
        items,
        actual: "inicio",
        empresa: { nombre: "MC", iniciales: "MC" },
        ancho: "medium",
      },
      global: { plugins: [await router()] },
    })
    expect(sinCuenta.find("button").exists()).toBe(false)
    expect(sinCuenta.get("nav").classes()).toContain("lat--medium")
  })
})

describe("CabeceraPagina (page-header)", () => {
  it("con empresa: botón que abre la cuenta y h1 del destino; sin empresa: solo h1", async () => {
    const w = mount(CabeceraPagina, {
      props: {
        titulo: "Inicio",
        empresa: {
          nombre: "Mezcal Cuatro Vientos",
          subtitulo: "titular · admin",
          iniciales: "MC",
          acento: "#7A3E1D",
        },
      },
    })
    expect(w.get("h1").text()).toBe("Inicio")
    const b = w.get("button")
    expect(b.attributes("aria-haspopup")).toBe("dialog")
    expect(b.attributes("title")).toBe("Mezcal Cuatro Vientos")
    expect((w.get("header").element as HTMLElement).style.getPropertyValue("--acento")).toBe(
      "#7A3E1D",
    )
    await b.trigger("click")
    expect(w.emitted("cuenta")).toHaveLength(1)

    const solo = mount(CabeceraPagina, { props: { titulo: "Equipo" } })
    expect(solo.find("button").exists()).toBe(false)
    expect(solo.get("h1").text()).toBe("Equipo")
  })
})

describe("BotonFlotante (fab)", () => {
  it("es un botón con texto; deshabilitado no emite", async () => {
    const w = mount(BotonFlotante, { props: { etiqueta: "Medir", icono: "i-medir" } })
    expect(w.get("button").text()).toContain("Medir")
    await w.get("button").trigger("click")
    expect(w.emitted("click")).toHaveLength(1)
    const d = mount(BotonFlotante, { props: { etiqueta: "Medir", disabled: true } })
    expect(d.get("button").attributes("aria-disabled")).toBe("true")
  })
})

describe("tema", () => {
  beforeEach(() => localStorage.clear())
  afterEach(() => delete document.documentElement.dataset.theme)

  it("sistema = sin data-theme; claro/oscuro se guardan y se aplican", () => {
    aplicarTema("oscuro")
    expect(document.documentElement.dataset.theme).toBe("dark")
    expect(localStorage.getItem("pulz:tema")).toBe("oscuro")
    aplicarTema("claro")
    expect(document.documentElement.dataset.theme).toBe("light")
    aplicarTema("sistema")
    expect(document.documentElement.dataset.theme).toBeUndefined()
    expect(localStorage.getItem("pulz:tema")).toBeNull()
  })

  it("sincroniza <meta theme-color> con la elección manual y la restaura en sistema", () => {
    document.head.innerHTML =
      '<meta name="theme-color" media="(prefers-color-scheme: light)" content="#6D4AFF">' +
      '<meta name="theme-color" media="(prefers-color-scheme: dark)" content="#A590FD">'
    const metas = () =>
      [...document.querySelectorAll<HTMLMetaElement>('meta[name="theme-color"]')].map(
        (m) => m.content,
      )
    aplicarTema("oscuro")
    expect(metas()).toEqual(["#A590FD", "#A590FD"])
    aplicarTema("claro")
    expect(metas()).toEqual(["#6D4AFF", "#6D4AFF"])
    aplicarTema("sistema")
    expect(metas()).toEqual(["#6D4AFF", "#A590FD"])
  })

  it("al arrancar aplica lo guardado", () => {
    localStorage.setItem("pulz:tema", "oscuro")
    aplicarTemaGuardado()
    expect(document.documentElement.dataset.theme).toBe("dark")
    expect(useTema().tema.value).toBe("oscuro")
  })
})
