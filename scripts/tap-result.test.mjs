import { test } from "node:test"
import assert from "node:assert/strict"
import { evaluarTap } from "./tap-result.mjs"

const respuesta = (...lineas) => JSON.stringify({ rows: lineas.map((runtests) => ({ runtests })) })
test("PASS exige TAP, no solo código 0 del CLI", () => {
  assert.equal(
    evaluarTap(respuesta("    ok 1 - regla", "    1..1", "ok 1 - suite", "1..1")).estado,
    "PASS",
  )
})
test("un fallo interno no se oculta tras el éxito del proceso", () => {
  const r = evaluarTap(respuesta("    not ok 1 - regla", "    1..1", "not ok 1 - suite", "1..1"))
  assert.equal(r.estado, "FAIL")
  assert.equal(r.fallos.length, 2)
})
test("Test died se informa como fallo aunque no haya aserciones hoja", () => {
  assert.equal(
    evaluarTap(respuesta("    # Test died: error", "not ok 1 - suite", "1..1")).estado,
    "FAIL",
  )
})
test("SKIP y TODO no certifican un criterio", () => {
  assert.equal(
    evaluarTap(respuesta("    1..0 # SKIP sin fixture", "ok 1 - suite", "1..1")).estado,
    "PARTIAL",
  )
  for (const pendiente of ["SKIP sin credenciales", "TODO concurrencia"]) {
    assert.equal(
      evaluarTap(respuesta(`    ok 1 # ${pendiente}`, "    1..1", "ok 1 - suite", "1..1")).estado,
      "PARTIAL",
    )
  }
})
test("no acepta respuesta vacía, SQL sin TAP ni un plan sin sus resultados", () => {
  for (const s of [
    "",
    "{}",
    respuesta(),
    respuesta("ok 1 - regla"),
    respuesta("ok 1 - regla", "1..2"),
    respuesta("    ok 1 - regla", "    1..2", "ok 1 - suite", "1..1"),
    respuesta("ok 2 - regla", "1..1"),
    respuesta("ok 1 - regla", "1..1", "1..1"),
  ]) {
    assert.throws(() => evaluarTap(s))
  }
})
test("verifica por separado subtests hermanos y admite plan antes de resultados", () => {
  assert.equal(
    evaluarTap(
      respuesta(
        "1..2",
        "    1..1",
        "    ok 1 - a",
        "ok 1 - suite a",
        "    ok 1 - b",
        "    1..1",
        "ok 2 - suite b",
      ),
    ).estado,
    "PASS",
  )
})
