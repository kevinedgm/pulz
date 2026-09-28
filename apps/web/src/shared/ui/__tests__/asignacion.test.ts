// Contrato de origin-allocation (ronda destilacion/r01): cantidad por
// origen, total en vivo, error por encima del saldo, bloqueo estricta,
// aviso flexible.
import { describe, expect, it } from "vitest"
import { mount } from "@vue/test-utils"
import AsignacionOrigenes from "../AsignacionOrigenes.vue"

const origenes = [
  {
    id: "t1",
    titulo: "Tina 1",
    sub: "FER-T1-001 · 870 L · lista",
    saldo: 870,
    unidad: "L" as const,
  },
  {
    id: "c1",
    titulo: "Colector ordinario",
    sub: "ORD-002 · 40 L",
    saldo: 40,
    unidad: "L" as const,
  },
]

describe("AsignacionOrigenes", () => {
  it("emite el mapa de cantidades y muestra el total con el destino", async () => {
    const w = mount(AsignacionOrigenes, {
      props: {
        modelValue: {},
        origenes,
        capacidad: 300,
        politica: "estricta",
        destino: "Alambique 1",
      },
    })
    expect(w.findAll("input")).toHaveLength(2)
    await w.findAll("input")[0].setValue("290")
    expect(w.emitted("update:modelValue")?.[0]).toEqual([{ t1: 290 }])
    await w.setProps({ modelValue: { t1: 290 } })
    expect(w.get(".asig__total").text()).toContain("Total 290 L de 300 L (Alambique 1)")
  })
  it("estricta: bloquea con motivo; flexible: aviso excede_capacidad; por encima del saldo: error en la fila", async () => {
    const w = mount(AsignacionOrigenes, {
      props: {
        modelValue: { t1: 290, c1: 40 },
        origenes,
        capacidad: 300,
        politica: "estricta",
        destino: "Alambique 1",
      },
    })
    expect(w.get(".asig__total").text()).toContain("no cabe")
    expect((w.vm as unknown as { bloqueo: boolean }).bloqueo).toBe(true)
    await w.setProps({ politica: "flexible" })
    expect((w.vm as unknown as { aviso: string | null }).aviso).toBe("excede_capacidad")
    expect(w.get(".asig__total").text()).not.toContain("no cabe")
    await w.setProps({ modelValue: { t1: 900 }, politica: "libre" })
    expect(w.text()).toContain("Solo hay 870 L.")
    expect((w.vm as unknown as { conError: boolean }).conError).toBe(true)
  })
})
