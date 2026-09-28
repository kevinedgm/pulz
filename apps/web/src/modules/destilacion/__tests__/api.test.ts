// Reglas que la interfaz conoce antes de enviar (ronda destilacion/r01):
// colector por clase, puntas solo con record_puntas, capacidad del destino,
// ordinario + colas en 2ª, resumen de cortes.
import { describe, expect, it, vi } from "vitest"
import {
  avisoCapacidad,
  avisosApertura,
  clasesDisponibles,
  colectoresDeClase,
  resumenCortes,
  saldoDe,
  type ColectorConSaldo,
  type RecursoActivo,
} from "../api"

vi.mock("../../../shared/supabase/client", () => ({ supabase: {} }))

const activos: RecursoActivo[] = [
  {
    id: "cm",
    code: "Colector mezcal",
    capacity: 60,
    capacity_policy: "flexible",
    liquid_class: "mezcal",
  },
  {
    id: "co",
    code: "Colector ordinario",
    capacity: 200,
    capacity_policy: "flexible",
    liquid_class: "ordinario",
  },
  {
    id: "cc",
    code: "Colector colas",
    capacity: 200,
    capacity_policy: "estricta",
    liquid_class: "colas",
  },
]
const conSaldo: ColectorConSaldo[] = [
  {
    resource_id: "cc",
    colector: "Colector colas",
    liquid_class: "colas",
    capacidad_l: 200,
    lot_id: "l",
    folio: "COL-002",
    litros: 16,
    abv: 10,
    abv_at: null,
    abv_by: null,
  },
]

describe("clases y colectores", () => {
  it("puntas solo con record_puntas", () => {
    expect(clasesDisponibles({ record_puntas: false }).map((c) => c.valor)).toEqual([
      "mezcal",
      "ordinario",
      "colas",
    ])
    expect(clasesDisponibles({ record_puntas: true }).map((c) => c.valor)).toContain("puntas")
  })
  it("colector por clase; sin colector de la clase → lista vacía", () => {
    expect(colectoresDeClase("mezcal", activos).map((c) => c.id)).toEqual(["cm"])
    expect(colectoresDeClase("puntas", activos)).toEqual([])
  })
  it("saldo del colector desde colectores_con_saldo", () => {
    expect(saldoDe("cc", conSaldo)).toBe(16)
    expect(saldoDe("cm", conSaldo)).toBe(0)
  })
})

describe("avisoCapacidad", () => {
  it("libre o sin capacidad → nada; flexible → excede_capacidad; estricta → bloqueo", () => {
    expect(avisoCapacidad(0, 500, null, "estricta")).toBeNull()
    expect(avisoCapacidad(0, 500, 300, "libre")).toBeNull()
    expect(avisoCapacidad(40, 160, 200, "flexible")).toBeNull()
    expect(avisoCapacidad(40, 180, 200, "flexible")).toBe("excede_capacidad")
    expect(avisoCapacidad(0, 320, 300, "estricta")).toBe("bloqueo")
  })
})

describe("avisosApertura", () => {
  it("ordinario y colas juntos solo en 2ª y solo si el ajuste avisa", () => {
    expect(
      avisosApertura("segunda", ["ordinario", "colas"], { warn_mixed_second_pass: true }),
    ).toEqual(["mezcla_clases_2a"])
    expect(
      avisosApertura("segunda", ["ordinario", "colas"], { warn_mixed_second_pass: false }),
    ).toEqual([])
    expect(
      avisosApertura("primera", ["ordinario", "colas"], { warn_mixed_second_pass: true }),
    ).toEqual([])
    expect(
      avisosApertura("segunda", [null, "ordinario"], { warn_mixed_second_pass: true }),
    ).toEqual([])
  })
})

describe("resumenCortes", () => {
  it("suma por clase en el orden del proceso", () => {
    expect(
      resumenCortes({
        cortes: [
          {
            movement_id: "1",
            clase: "colas",
            litros: 12,
            abv: 9,
            resource_id: null,
            destino: null,
            lot_id: "a",
            folio: "COL-001",
            occurred_at: "",
          },
          {
            movement_id: "2",
            clase: "mezcal",
            litros: 8,
            abv: 51,
            resource_id: null,
            destino: null,
            lot_id: "b",
            folio: "MEZ-001",
            occurred_at: "",
          },
          {
            movement_id: "3",
            clase: "mezcal",
            litros: 6,
            abv: 50,
            resource_id: null,
            destino: null,
            lot_id: "b",
            folio: "MEZ-001",
            occurred_at: "",
          },
        ],
      }),
    ).toBe("mezcal 14 · colas 12")
    expect(resumenCortes({ cortes: [] })).toBe("")
  })
})
