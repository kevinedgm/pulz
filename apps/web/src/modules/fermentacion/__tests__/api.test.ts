// Funciones puras de Fermentación (ronda fermentacion/r01): el día del
// ciclo y «hoy» se deciden en el navegador; el aviso de Brix se conoce
// antes de enviar; las lecturas van como arreglos paralelos (0017).
import { describe, expect, it, vi } from "vitest"
import type { UsoTina } from "../api"
import {
  agrupar,
  avisoBrix,
  cuandoCorto,
  diaDelCiclo,
  esHoy,
  lecturasParaRpc,
  promedio,
  tocaMedirHoy,
} from "../api"

vi.mock("../../../shared/supabase/client", () => ({ supabase: {} }))

const HOY = new Date(2026, 8, 27, 10, 0) // 27 sep 2026, 10:00 local
const uso = (p: Partial<UsoTina>): UsoTina => ({
  organization_id: "o",
  cycle_id: "c",
  tina_id: "t",
  tina: "Tina 2",
  capacidad_l: 1500,
  capacity_policy: "flexible",
  lot_id: "l",
  folio: "FER-T2-001",
  status: "fermentando",
  formulation_id: "f",
  formulacion: "F-001",
  started_at: new Date(2026, 8, 25, 9, 0).toISOString(),
  started_by: "Aurelia",
  litros: 1400,
  mediciones: 0,
  ultima_medicion_at: null,
  ultima_medicion_dia: null,
  ultima_actividad: null,
  ultima_temperatura: null,
  ultimo_brix: null,
  ...p,
})

describe("diaDelCiclo", () => {
  it("cuenta días naturales desde started_at + 1, en la zona del navegador", () => {
    expect(diaDelCiclo(new Date(2026, 8, 27, 1, 0).toISOString(), HOY)).toBe(1)
    expect(diaDelCiclo(new Date(2026, 8, 26, 23, 59).toISOString(), HOY)).toBe(2)
    expect(diaDelCiclo(new Date(2026, 8, 25, 9, 0).toISOString(), HOY)).toBe(3)
    expect(diaDelCiclo(new Date(2026, 8, 1, 10, 40).toISOString(), HOY)).toBe(27)
  })
  it("nunca menos de 1 aunque el reloj vaya atrás", () => {
    expect(diaDelCiclo(new Date(2026, 8, 28, 9, 0).toISOString(), HOY)).toBe(1)
  })
})

describe("esHoy / tocaMedirHoy / agrupar", () => {
  it("hoy es hoy por fecha local, no por 24 h", () => {
    expect(esHoy(new Date(2026, 8, 27, 0, 5).toISOString(), HOY)).toBe(true)
    expect(esHoy(new Date(2026, 8, 26, 23, 55).toISOString(), HOY)).toBe(false)
    expect(esHoy(null, HOY)).toBe(false)
  })
  it("toca medir: fermentando y sin medición válida hoy", () => {
    expect(tocaMedirHoy(uso({}), HOY)).toBe(true)
    expect(
      tocaMedirHoy(uso({ ultima_medicion_at: new Date(2026, 8, 26, 8, 30).toISOString() }), HOY),
    ).toBe(true)
    expect(
      tocaMedirHoy(uso({ ultima_medicion_at: new Date(2026, 8, 27, 7, 10).toISOString() }), HOY),
    ).toBe(false)
    expect(tocaMedirHoy(uso({ status: "lista" }), HOY)).toBe(false)
    expect(tocaMedirHoy(uso({ status: "en_vaciado" }), HOY)).toBe(false)
  })
  it("agrupa por lo que hay que hacer y ordena por más días sin medir", () => {
    const g = agrupar(
      [
        uso({ tina: "Tina 4", ultima_medicion_at: new Date(2026, 8, 27, 7, 10).toISOString() }),
        uso({ tina: "Tina 2", ultima_medicion_at: new Date(2026, 8, 26, 8, 30).toISOString() }),
        uso({ tina: "Tina 3", ultima_medicion_at: null }),
        uso({ tina: "Tina 1", status: "en_vaciado" }),
      ],
      HOY,
    )
    expect(g.porMedir.map((u) => u.tina)).toEqual(["Tina 3", "Tina 2"])
    expect(g.medidas.map((u) => u.tina)).toEqual(["Tina 4"])
    expect(g.listas.map((u) => u.tina)).toEqual(["Tina 1"])
  })
})

describe("promedio / avisoBrix / lecturasParaRpc", () => {
  it("promedio al vuelo con dos decimales; ignora vacíos", () => {
    expect(promedio([27.5, 27.8, null])).toBe(27.65)
    expect(promedio([null, null])).toBeNull()
  })
  it("aviso de Brix con los rangos de la empresa", () => {
    const a = { brix_warn_min: 12, brix_warn_max: 14 }
    expect(avisoBrix(12.4, a)).toBeNull()
    expect(avisoBrix(19, a)).toBe("brix_fuera_rango")
    expect(avisoBrix(11.9, a)).toBe("brix_fuera_rango")
    expect(avisoBrix(null, a)).toBeNull()
    expect(avisoBrix(19, null)).toBeNull()
  })
  it("arreglos paralelos para registrar_medicion", () => {
    expect(
      lecturasParaRpc([
        { variable: "temperatura", zona: "unica", numero: 1, valor: 27.5 },
        { variable: "brix", zona: "unica", numero: 1, valor: 12.4 },
      ]),
    ).toEqual({
      p_variables: ["temperatura", "brix"],
      p_zonas: ["unica", "unica"],
      p_numeros: [1, 1],
      p_valores: [27.5, 12.4],
    })
  })
})

describe("cuandoCorto", () => {
  it("hoy / ayer con hora; antes, día y mes", () => {
    expect(cuandoCorto(new Date(2026, 8, 27, 7, 10).toISOString(), HOY)).toMatch(/^hoy 07:10/)
    expect(cuandoCorto(new Date(2026, 8, 26, 8, 30).toISOString(), HOY)).toMatch(/^ayer 08:30/)
    expect(cuandoCorto(new Date(2026, 8, 12, 8, 30).toISOString(), HOY)).toMatch(/12 sep/)
    expect(cuandoCorto(null, HOY)).toBe("nunca")
  })
})
