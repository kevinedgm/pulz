// Contratos del sistema (design-hub/system/registry.json, ronda acceso/r01).
// Se prueba lo que un consumidor depende: semántica, atributos, foco y
// comportamiento por teclado — no estilos.
/* eslint-disable vue/one-component-per-file -- páginas vacías para el router de prueba */
import { afterEach, describe, expect, it, vi } from "vitest"
import { mount } from "@vue/test-utils"
import { createMemoryHistory, createRouter } from "vue-router"
import { defineComponent, h, nextTick } from "vue"
import {
  Aviso,
  BloqueEstado,
  Boton,
  CampoContrasena,
  CampoTexto,
  CapaTarea,
  ChipEstado,
  MenuFila,
  SegmentoOpciones,
} from "../index"

afterEach(() => {
  document.body.innerHTML = ""
})

describe("Boton (button)", () => {
  it("es <button type=button> por defecto y pasa los atributos sueltos al control", () => {
    const w = mount(Boton, {
      attrs: { form: "f1", "aria-expanded": "false" },
      slots: { default: "Entrar" },
    })
    const b = w.get("button")
    expect(b.attributes("type")).toBe("button")
    expect(b.attributes("form")).toBe("f1")
    expect(b.attributes("aria-expanded")).toBe("false")
  })

  it("type=submit sigue siendo un botón de envío", () => {
    const w = mount(Boton, { props: { type: "submit" } })
    expect(w.get("button").attributes("type")).toBe("submit")
  })

  it("href → <a href> (navegar nunca es un botón)", () => {
    const w = mount(Boton, { props: { href: "https://pulz.mx" }, slots: { default: "Conoce" } })
    expect(w.get("a").attributes("href")).toBe("https://pulz.mx")
    expect(w.find("button").exists()).toBe(false)
  })

  it("to → RouterLink con href real (regresión: href indefinido lo borraba)", async () => {
    const router = createRouter({
      history: createMemoryHistory(),
      routes: [
        { path: "/", component: defineComponent({ render: () => h("div") }) },
        { path: "/e/:slug/equipo", component: defineComponent({ render: () => h("div") }) },
      ],
    })
    await router.push("/")
    const w = mount(Boton, {
      props: { to: "/e/cv/equipo" },
      slots: { default: "Equipo" },
      global: { plugins: [router] },
    })
    expect(w.get("a").attributes("href")).toBe("/e/cv/equipo")
  })

  it("deshabilitado o cargando: no emite click y explica el motivo", async () => {
    const w = mount(Boton, {
      props: { disabled: true, motivoDeshabilitado: "Para entrar necesitas señal." },
    })
    const b = w.get("button")
    expect(b.attributes("disabled")).toBeDefined()
    expect(b.attributes("aria-disabled")).toBe("true")
    const motivoId = b.attributes("aria-describedby")!
    expect(w.get(`[id="${motivoId}"]`).text()).toBe("Para entrar necesitas señal.")
    await b.trigger("click")
    expect(w.emitted("click")).toBeUndefined()

    const c = mount(Boton, { props: { loading: true } })
    expect(c.get("button").attributes("aria-busy")).toBe("true")
    await c.get("button").trigger("click")
    expect(c.emitted("click")).toBeUndefined()
  })
})

describe("CampoTexto (text-field)", () => {
  it("etiqueta visible ligada al control; ayuda y error por aria-describedby", async () => {
    const w = mount(CampoTexto, {
      props: { modelValue: "", etiqueta: "Usuario o correo", ayuda: "Tal cual te lo dieron." },
    })
    const input = w.get("input")
    expect(w.get("label").attributes("for")).toBe(input.attributes("id"))
    expect(w.get("label").text()).toBe("Usuario o correo")
    const ayudaId = input.attributes("aria-describedby")!
    expect(w.get(`[id="${ayudaId}"]`).text()).toBe("Tal cual te lo dieron.")
    expect(input.attributes("aria-invalid")).toBeUndefined()

    await w.setProps({ error: "Ese usuario ya existe en la empresa" })
    expect(w.get("input").attributes("aria-invalid")).toBe("true")
    const ids = w.get("input").attributes("aria-describedby")!.split(" ")
    expect(ids.some((id) => w.get(`[id="${id}"]`).text().includes("ya existe"))).toBe(true)
  })

  it("v-model: emite lo escrito", async () => {
    const w = mount(CampoTexto, { props: { modelValue: "", etiqueta: "Nombre" } })
    await w.get("input").setValue("Ana")
    expect(w.emitted("update:modelValue")?.[0]).toEqual(["Ana"])
  })
})

describe("CampoContrasena (password-field)", () => {
  it("mostrar/ocultar es un botón con texto y aria-pressed; no cambia el valor", async () => {
    const w = mount(CampoContrasena, { props: { modelValue: "secreta1", etiqueta: "Contraseña" } })
    const input = w.get("input")
    expect(input.attributes("type")).toBe("password")
    const toggle = w.get("button")
    expect(toggle.text()).toBe("Mostrar")
    expect(toggle.attributes("aria-pressed")).toBe("false")
    await toggle.trigger("click")
    expect(w.get("input").attributes("type")).toBe("text")
    expect(w.get("button").text()).toBe("Ocultar")
    expect(w.get("button").attributes("aria-pressed")).toBe("true")
    expect((w.get("input").element as HTMLInputElement).value).toBe("secreta1")
  })
})

describe("SegmentoOpciones (segmented-choice)", () => {
  const opciones = [
    { valor: "admin", etiqueta: "Admin" },
    { valor: "productor", etiqueta: "Productor" },
    { valor: "operador", etiqueta: "Operador", ayuda: "Mediciones y corridas." },
  ] as const

  it("radiogroup con una sola opción marcada y ayuda de la elegida", () => {
    const w = mount(SegmentoOpciones, {
      props: { modelValue: "operador", opciones: [...opciones], etiqueta: "Rol" },
    })
    expect(w.get("[role=radiogroup]").attributes("aria-labelledby")).toBeDefined()
    const radios = w.findAll("[role=radio]")
    expect(radios).toHaveLength(3)
    expect(radios.map((r) => r.attributes("aria-checked"))).toEqual(["false", "false", "true"])
    expect(radios.map((r) => r.attributes("tabindex"))).toEqual(["-1", "-1", "0"])
    expect(w.text()).toContain("Mediciones y corridas.")
  })

  it("clic y flechas cambian la selección", async () => {
    const w = mount(SegmentoOpciones, {
      attachTo: document.body,
      props: { modelValue: "admin", opciones: [...opciones], etiqueta: "Rol" },
    })
    await w.findAll("[role=radio]")[1].trigger("click")
    expect(w.emitted("update:modelValue")?.[0]).toEqual(["productor"])
    await w.findAll("[role=radio]")[0].trigger("keydown", { key: "ArrowRight" })
    expect(w.emitted("update:modelValue")?.[1]).toEqual(["productor"])
    await w.findAll("[role=radio]")[0].trigger("keydown", { key: "ArrowLeft" })
    expect(w.emitted("update:modelValue")?.[2]).toEqual(["operador"]) // circular
    w.unmount()
  })
})

describe("ChipEstado, Aviso, BloqueEstado (estado nunca solo por color)", () => {
  it("el chip lleva texto y una variante de forma (::before) aparte del color", () => {
    const w = mount(ChipEstado, { props: { variante: "off" }, slots: { default: "suspendido" } })
    expect(w.text()).toContain("suspendido")
    expect(w.classes()).toContain("chip--off") // relleno / discontinuo / tachado / medio
  })

  it("el aviso es role=status con título en texto", () => {
    const w = mount(Aviso, {
      props: { variante: "readonly", titulo: "Solo lectura." },
      slots: { default: "La suscripción venció." },
    })
    expect(w.get("[role=status]").text()).toContain("Solo lectura.")
  })

  it("el bloque de estado muestra título, texto y la acción del consumidor", () => {
    const w = mount(BloqueEstado, {
      props: { variante: "error", titulo: "No pudimos conectar", texto: "Revisa tu señal." },
      slots: { default: "<button>Reintentar</button>" },
    })
    expect(w.text()).toContain("No pudimos conectar")
    expect(w.get("button").text()).toBe("Reintentar")
  })
})

describe("MenuFila (row-menu)", () => {
  it("botón con nombre por fila; abre un menú; el destructivo va marcado; Esc cierra y devuelve el foco", async () => {
    const w = mount(MenuFila, {
      attachTo: document.body,
      props: {
        nombre: "Tomás Hernández",
        acciones: [
          { id: "rol", etiqueta: "Cambiar rol…" },
          { id: "suspender", etiqueta: "Suspender…", intent: "danger" },
        ],
      },
    })
    const boton = w.get("button")
    expect(boton.attributes("aria-label")).toBe("Acciones para Tomás Hernández")
    expect(boton.attributes("aria-haspopup")).toBe("menu")
    expect(boton.attributes("aria-expanded")).toBe("false")
    await boton.trigger("click")
    await nextTick()
    expect(w.get("button").attributes("aria-expanded")).toBe("true")
    const items = w.findAll("[role=menuitem]")
    expect(items.map((i) => i.text())).toEqual(["Cambiar rol…", "Suspender…"])
    expect(items[1].classes()).toContain("menu__item--danger")
    expect(document.activeElement).toBe(items[0].element)

    await items[0].trigger("keydown", { key: "Escape" })
    expect(w.find("[role=menu]").exists()).toBe(false)
    expect(document.activeElement).toBe(w.get("button").element)

    await w.get("button").trigger("click")
    await nextTick()
    await w.findAll("[role=menuitem]")[1].trigger("click")
    expect(w.emitted("seleccionar")?.[0]).toEqual(["suspender"])
    w.unmount()
  })
})

describe("CapaTarea (task-layer)", () => {
  it("dialog modal con título, foco dentro, Esc y fondo emiten cerrar", async () => {
    const w = mount(CapaTarea, {
      attachTo: document.body,
      props: { abierta: false, titulo: "Agregar persona" },
      slots: { default: '<input id="n" aria-label="Nombre" />' },
    })
    expect(document.querySelector("[role=dialog]")).toBeNull()
    await w.setProps({ abierta: true })
    await nextTick()
    await nextTick()
    const dialog = document.querySelector("[role=dialog]")!
    expect(dialog.getAttribute("aria-modal")).toBe("true")
    const titulo = document.getElementById(dialog.getAttribute("aria-labelledby")!)
    expect(titulo?.textContent?.trim()).toBe("Agregar persona")
    expect(dialog.contains(document.activeElement)).toBe(true)

    document.activeElement!.dispatchEvent(
      new KeyboardEvent("keydown", { key: "Escape", bubbles: true }),
    )
    expect(w.emitted("cerrar")).toHaveLength(1)
    ;(document.querySelector(".capa__fondo") as HTMLElement).click()
    expect(w.emitted("cerrar")).toHaveLength(2)
    w.unmount()
  })

  it("al cerrar, el foco vuelve al disparador", async () => {
    const disparador = document.createElement("button")
    disparador.textContent = "Agregar persona"
    document.body.appendChild(disparador)
    disparador.focus()
    const back = vi.spyOn(history, "back").mockImplementation(() => {})
    const w = mount(CapaTarea, {
      attachTo: document.body,
      props: { abierta: true, titulo: "Agregar persona" },
      slots: { default: "<p>hola</p>" },
    })
    await nextTick()
    await nextTick()
    expect(document.activeElement).not.toBe(disparador)
    await w.setProps({ abierta: false })
    await nextTick()
    expect(document.activeElement).toBe(disparador)
    back.mockRestore()
    w.unmount()
  })
})
