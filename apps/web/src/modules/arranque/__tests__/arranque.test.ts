// Contrato de la tarjeta de recipiente (ronda arranque/r01) y de la api local.
import { describe, expect, it } from "vitest"
import { mount } from "@vue/test-utils"
import TarjetaRecipiente from "../components/TarjetaRecipiente.vue"
import { guardarEstado, leerEstado, materialDe, mensajeDeCarga } from "../api"
import type { Recurso } from "../../configuracion/api"

const tanque: Recurso = {
  id: "r1",
  organization_id: "o",
  kind: "tanque",
  code: "Tanque B1",
  type_item_id: null,
  capacity: 500,
  capacity_unit: "L",
  capacity_policy: "estricta",
  liquid_class: null,
  location: null,
  active: true,
}
const base = {
  tipoNombre: "acero",
  vacio: false,
  puedeEscribir: true,
  enLinea: true,
  ocupado: false,
}

describe("TarjetaRecipiente", () => {
  it("pendiente: segmento vacío / tiene algo; 'tiene algo' pide litros y % Alc. en tanque; el botón dice cantidad y recipiente", async () => {
    const w = mount(TarjetaRecipiente, { props: { recurso: tanque, ...base } })
    expect(w.findAll("[role=radio]").map((r) => r.text())).toEqual(["Vacío", "Tiene algo"])
    await w.findAll("[role=radio]")[1].trigger("click")
    expect(w.findAll("input")).toHaveLength(2)
    await w.findAll("input")[0].setValue("300")
    await w.findAll("input")[1].setValue("47")
    expect(w.get("button.boton--primary").text()).toBe("Guardar 300 L en Tanque B1")
    await w.get("button.boton--primary").trigger("click")
    expect(w.emitted("guardar")?.[0]).toEqual([300, 47])
  })
  it("tina: solo litros (fermentado); 'vacío' emite vacio=true; guardado se muestra colapsado", async () => {
    const tina = {
      ...tanque,
      id: "r2",
      kind: "tina" as const,
      code: "Tina B1",
      capacity_policy: "flexible" as const,
    }
    const w = mount(TarjetaRecipiente, { props: { recurso: tina, ...base } })
    await w.findAll("[role=radio]")[1].trigger("click")
    expect(w.findAll("input")).toHaveLength(1)
    await w.findAll("[role=radio]")[0].trigger("click")
    expect(w.emitted("vacio")?.[0]).toEqual([true])
    const g = mount(TarjetaRecipiente, {
      props: {
        recurso: tina,
        ...base,
        uso: { resource_id: "r2", saldo_l: 900, ciclos_abiertos: 1 },
      },
    })
    expect(g.text()).toContain("guardado")
    expect(g.text()).toContain("900 L")
    expect(g.find("[role=radio]").exists()).toBe(false)
  })
  it("avisa cuando los litros superan la capacidad (estricta: no se podrá guardar) y deshabilita sin señal", async () => {
    const w = mount(TarjetaRecipiente, { props: { recurso: tanque, ...base, enLinea: false } })
    await w.findAll("[role=radio]")[1].trigger("click")
    await w.findAll("input")[0].setValue("600")
    expect(w.text()).toContain("política es estricta")
    expect(w.get("button.boton--primary").attributes("disabled")).toBeDefined()
  })
})

describe("api local", () => {
  it("material por tipo y traducción de errores", () => {
    expect(materialDe("tanque")).toBe("granel")
    expect(materialDe("tina")).toBe("fermentado")
    expect(materialDe("colector")).toBe("destilado")
    expect(mensajeDeCarga(new Error("CAPACIDAD: Tanque B1 500"), "Tanque B1")).toContain("estricta")
    expect(
      mensajeDeCarga(
        new Error("NO_PERMITIDO: la tina Tina B1 ya tiene un ciclo abierto"),
        "Tina B1",
      ),
    ).toContain("ciclo abierto")
    expect(mensajeDeCarga(new TypeError("Failed to fetch"), "x")).toContain("conectar")
  })
  it("estado local por empresa en localStorage", () => {
    localStorage.clear()
    guardarEstado("org1", { r1: { idem: "k", vacio: true } })
    expect(leerEstado("org1").r1).toEqual({ idem: "k", vacio: true })
    expect(leerEstado("org2")).toEqual({})
  })
})
