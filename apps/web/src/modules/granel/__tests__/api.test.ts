// Reglas del granel que la interfaz conoce antes de enviar (ronda
// granel/r01): qué pide cada concepto, ledger esperado y diferencia,
// avisos de entrada, folio sugerido al juntar.
import { describe, expect, it, vi } from "vitest"
import {
  avisosEntrada,
  bloqueaCapacidad,
  camposDe,
  diferencia,
  folioSugerido,
  ledgerEsperado,
  type Concepto,
  type LoteEnTanque,
} from "../api"

vi.mock("../../../shared/supabase/client", () => ({ supabase: {} }))

const c = (p: Partial<Concepto>): Concepto => ({
  id: "x",
  direction: "entrada",
  name: "x",
  source_lot: "no_aplica",
  creates_lot: false,
  asks_result: false,
  asks_counterparty: false,
  template_id: null,
  sort_order: 1,
  ...p,
})
const lote = (p: Partial<LoteEnTanque>): LoteEnTanque => ({
  lot_id: "l",
  folio: "G-INI-01",
  litros: 341.8,
  history: "sin_historia",
  origin: "carga_inicial",
  abv: 44.9,
  abv_at: null,
  abv_by: null,
  ...p,
})

describe("camposDe: el formulario se arma con el concepto (§5.2)", () => {
  it("agua: solo litros + resultado", () => {
    expect(camposDe(c({ name: "Agua", asks_result: true }), 1)).toMatchObject({
      origen: "no",
      decision: false,
      resultado: true,
      contraparte: false,
      certificado: false,
      folioNuevo: false,
      loteAfectado: false,
    })
  })
  it("unión: lote de origen requerido + decisión de folio si el tanque tiene lote", () => {
    const u = c({ name: "Unión", source_lot: "requerido", asks_result: true })
    expect(camposDe(u, 1)).toMatchObject({ origen: "requerido", decision: true, resultado: true })
    expect(camposDe(u, 0)).toMatchObject({ origen: "requerido", decision: false })
  })
  it("compra: crea lote, proveedor, certificado, folio nuevo; sin lote afectado", () => {
    expect(
      camposDe(
        c({ name: "Compra", creates_lot: true, asks_result: true, asks_counterparty: true }),
        2,
      ),
    ).toMatchObject({
      origen: "no",
      resultado: true,
      contraparte: true,
      certificado: true,
      folioNuevo: true,
      loteAfectado: false,
    })
  })
  it("venta: salida con contraparte; elige lote si hay varios", () => {
    expect(
      camposDe(c({ name: "Venta", direction: "salida", asks_counterparty: true }), 2),
    ).toMatchObject({
      resultado: false,
      contraparte: true,
      loteAfectado: true,
    })
  })
})

describe("ledger y diferencia", () => {
  it("ledger esperado = saldo + litros; la diferencia se redondea a milésimas y 0 si cuadra", () => {
    expect(ledgerEsperado(341.8, 4)).toBe(345.8)
    expect(diferencia(345.6, 345.8)).toBe(-0.2)
    expect(diferencia(345.8, 345.8)).toBe(0)
    expect(diferencia(null, 345.8)).toBeNull()
  })
  it("renombrar suma el saldo del lote que se une", () => {
    expect(ledgerEsperado(341.8, 250, true, 0)).toBe(591.8)
  })
})

describe("avisosEntrada / bloqueaCapacidad", () => {
  const aj = { abv_warn_min: 35, abv_warn_max: 55 }
  it("diferencia ≠ 0 → diferencia_volumen; % Alc. fuera → abv_fuera_rango; flexible excedida → excede_capacidad", () => {
    expect(avisosEntrada(-0.2, 44.4, aj, null)).toEqual(["diferencia_volumen"])
    expect(avisosEntrada(0, 60, aj, null)).toEqual(["abv_fuera_rango"])
    expect(
      avisosEntrada(0, 44, aj, { saldo: 1490, litros: 20, capacidad: 1500, politica: "flexible" }),
    ).toEqual(["excede_capacidad"])
    expect(
      avisosEntrada(0, 44, aj, { saldo: 1490, litros: 20, capacidad: 1500, politica: "libre" }),
    ).toEqual([])
    expect(avisosEntrada(null, null, aj, null)).toEqual([])
  })
  it("estricta excedida bloquea", () => {
    expect(bloqueaCapacidad(250, 300, { capacidad_l: 500, capacity_policy: "estricta" })).toBe(true)
    expect(bloqueaCapacidad(250, 200, { capacidad_l: 500, capacity_policy: "estricta" })).toBe(
      false,
    )
    expect(bloqueaCapacidad(250, 300, { capacidad_l: 500, capacity_policy: "flexible" })).toBe(
      false,
    )
  })
})

describe("folioSugerido", () => {
  it("el lote mayor del destino", () => {
    expect(
      folioSugerido([lote({ folio: "G-A", litros: 10 }), lote({ folio: "G-B", litros: 300 })])
        ?.folio,
    ).toBe("G-B")
    expect(folioSugerido([])).toBeNull()
  })
})
