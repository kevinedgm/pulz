import { test } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import { prepararFixture } from "./db-fixture.mjs"

const seed = readFileSync(new URL("../supabase/seed.sql", import.meta.url), "utf8")
const leer = (suite) =>
  readFileSync(new URL(`../supabase/tests/${suite}.test.sql`, import.meta.url), "utf8")
test("cada suite conserva sus aserciones y ejecuta RPC en empresas nuevas con rollback", () => {
  for (const suite of [
    "aislamiento",
    "rpc",
    "portal",
    "equipo_miembros",
    "configuracion",
    "proceso",
  ]) {
    const original = leer(suite)
    const f = prepararFixture(seed, original)
    assert.match(f.sql, /^begin;/)
    assert.match(f.sql, /rollback;\n$/)
    assert.doesNotMatch(f.sql, /^commit;/m)
    assert.doesNotMatch(
      f.sql,
      /b66cf468-47f7-51ee-a8f2-994d907440b9|b0000000-0000-4000-8000-0000000000b0/,
    )
    assert.doesNotMatch(f.sql, /^insert into (plans|plan_limits|plan_features|\w+_templates) /m)
    assert.match(f.sql, /seed_organization_catalogs/)
    assert.match(f.sql, /registrar_formulacion/)
    assert.match(f.sql, /pg_temp.seed_a/)
    assert.equal(
      (f.sql.match(/return next /g) ?? []).length,
      (original.match(/return next /g) ?? []).length,
    )
    assert.ok(f.empresas.every(Boolean))
  }
})
test("ejecuciones consecutivas no comparten identidades ni slugs", () => {
  const a = prepararFixture(seed, leer("rpc")),
    b = prepararFixture(seed, leer("rpc"))
  assert.notEqual(a.tag, b.tag)
  assert.notEqual(a.empresas[0], b.empresas[0])
  assert.equal(a.semillaSha256, b.semillaSha256)
})
test("rechaza cambios inesperados y commits adicionales", () => {
  assert.throws(() =>
    prepararFixture(seed.replace("insert into plans", "insert into otros"), leer("rpc")),
  )
  assert.throws(() => prepararFixture(seed, leer("rpc") + "\ncommit;"))
})
test("los slugs derivados conservan el límite de 40 y la prueba de mayúsculas", () => {
  const f = prepararFixture(seed, leer("configuracion"))
  const slugs = f.sql.match(/qa-[a-z0-9-]+/gi) ?? []
  assert.ok(slugs.length > 0)
  assert.ok(slugs.filter((s) => /vientos|prueba-b/i.test(s)).every((s) => s.length <= 40))
  const portal = prepararFixture(seed, leer("portal"))
  assert.match(portal.sql, /QA-[A-F0-9]+-CUATRO-VIENTOS/)
})
