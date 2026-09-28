import { randomUUID, createHash } from "node:crypto"

const UUID = /\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b/gi
const GLOBALES = [
  "plans",
  "plan_limits",
  "plan_features",
  "catalog_item_templates",
  "movement_concept_templates",
  "species_templates",
]
const EMPRESAS = ["b66cf468-47f7-51ee-a8f2-994d907440b9", "b0000000-0000-4000-8000-0000000000b0"]

// Reproduce the canonical simulation through real RPCs in NEW tenants, inside
// the same rollback transaction as pgTAP. Never truncates or rewrites the demo.
export function prepararFixture(semilla, prueba) {
  const tag = `qa-${randomUUID().replaceAll("-", "").slice(0, 12)}`
  const globales = new Set(["00000000-0000-0000-0000-000000000000"])
  let seed = semilla
  for (const tabla of GLOBALES) {
    const patron = new RegExp(`^insert into ${tabla} \\([\\s\\S]*?;`, "gm")
    const bloques = [...seed.matchAll(patron)]
    if (bloques.length !== 1) throw new Error(`Semilla cambió: revisar bloque global ${tabla}`)
    for (const id of bloques[0][0].match(UUID) ?? []) globales.add(id)
    seed = seed.replace(patron, `-- Fixture: reutiliza ${tabla} canónica, sin modificarla.`)
  }
  const ids = new Map()
  const transformar = (sql) =>
    sql
      .replace(UUID, (id) => {
        if (globales.has(id)) return id
        if (!ids.has(id)) ids.set(id, randomUUID())
        return ids.get(id)
      })
      .replace(/cuatro-vientos-mezcal|mezcal-cuatro-vientos|cuatro-vientos|prueba-b/gi, (slug) =>
        slug === slug.toUpperCase() ? `${tag}-${slug}`.toUpperCase() : `${tag}-${slug}`,
      )
  seed = transformar(seed)
  // Emails and invitation hashes are globally unique; no outbound Auth call.
  seed = seed
    .replace(/'([^'\s]+@[^'\s]+)'/g, (_m, email) => `'${tag}-${email}'`)
    .replaceAll("sha256:SIMULADO", `${tag}:SIMULADO`)
    .replaceAll("pg_temp.", "pg_temp.seed_")
  const test = transformar(prueba)
  if (
    !/^begin;$/m.test(seed) ||
    !/^commit;\s*$/m.test(seed) ||
    !/^begin;$/m.test(test) ||
    !/^rollback;\s*$/m.test(test)
  )
    throw new Error("Fixture requiere transacciones explícitas de semilla y prueba")
  seed = seed.replace(/^begin;\s*$/m, "").replace(/^commit;\s*$/m, "")
  const cuerpo = test.replace(/^begin;\s*$/m, "").replace(/^rollback;\s*$/m, "")
  // Guard against accidentally introducing a persistent transaction boundary.
  if (/^\s*(commit|rollback|end transaction)\s*;/im.test(seed + cuerpo))
    throw new Error("Límite de transacción inesperado: fixture no ejecutado")
  return {
    tag,
    empresas: EMPRESAS.map((id) => ids.get(id)),
    sql: `begin;\nset local statement_timeout = '60s';\n${seed}\n${cuerpo}\nrollback;\n`,
    semillaSha256: createHash("sha256").update(semilla).digest("hex"),
    pruebaSha256: createHash("sha256").update(prueba).digest("hex"),
  }
}
