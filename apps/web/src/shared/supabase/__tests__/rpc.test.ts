// §12.1: prefijos estables de las RPC → un solo traductor para todas las
// pantallas de captura y la cola offline.
import { describe, expect, it } from "vitest"
import { AVISOS, MENSAJE_RED, traducirErrorRpc } from "../errores"

describe("traducirErrorRpc", () => {
  it.each([
    [
      "SALDO_INSUFICIENTE: la Tina 1 tiene 870 L y se quieren 900 L",
      "SALDO",
      "No alcanza: la Tina 1 tiene 870 L y se quieren 900 L",
    ],
    [
      "CAPACIDAD_EXCEDIDA: Alambique 1 admite 300 L y se quieren cargar 320 L",
      "CAPACIDAD",
      "No cabe: Alambique 1 admite 300 L y se quieren cargar 320 L",
    ],
    ["NO_PERMITIDO: el ciclo ya estaba cerrado", "PERMISO", "el ciclo ya estaba cerrado"],
    ["LIMITE_PLAN: el plan Gratis permite 3 tinas", "PLAN", "el plan Gratis permite 3 tinas"],
    ["permission denied for table lots", "PERMISO", "No tienes permiso para registrar esto."],
    [
      "new row violates row-level security policy",
      "PERMISO",
      "No tienes permiso para registrar esto.",
    ],
    ["algo raro", "SERVIDOR", "algo raro"],
  ])("%s → %s", (msg, codigo, mensaje) => {
    expect(traducirErrorRpc({ message: msg, code: "P0001" })).toEqual({ codigo, mensaje })
  })

  it("REQUIERE_NOTA:<código> → NOTA con el texto del aviso y el código", () => {
    expect(traducirErrorRpc(new Error("REQUIERE_NOTA:mezcla_clases_2a"))).toEqual({
      codigo: "NOTA",
      requiereNota: "mezcla_clases_2a",
      mensaje: AVISOS.mezcla_clases_2a,
    })
    expect(traducirErrorRpc({ message: "REQUIERE_NOTA:algo_nuevo" }).mensaje).toMatch(
      /necesita una nota/,
    )
  })

  it("todos los avisos de rpc_warn tienen texto", () => {
    for (const c of [
      "brix_fuera_rango",
      "abv_fuera_rango",
      "mezcla_clases_2a",
      "excede_capacidad",
      "cierre_con_saldo",
      "diferencia_volumen",
    ])
      expect(AVISOS[c]).toMatch(/nota/)
  })

  it("sin red → RED, sin importar el mensaje", () => {
    expect(traducirErrorRpc(new TypeError("Failed to fetch"))).toEqual({
      codigo: "RED",
      mensaje: MENSAJE_RED,
    })
  })
})
