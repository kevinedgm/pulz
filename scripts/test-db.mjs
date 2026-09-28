import { spawnSync } from "node:child_process"
import { readFileSync, mkdirSync, writeFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { resolve } from "node:path"
import { evaluarTap } from "./tap-result.mjs"
import { prepararFixture } from "./db-fixture.mjs"

const raiz = fileURLToPath(new URL("../", import.meta.url))
const proyecto = "ypgeiyorgktshgbzhgfh"
const enlazado = readFileSync(resolve(raiz, "supabase/.temp/project-ref"), "utf8").trim()
if (enlazado !== proyecto)
  throw new Error("Proyecto enlazado distinto de PULZ desarrollo. No se ejecutó SQL.")
const suites = ["aislamiento", "rpc", "portal", "equipo_miembros", "configuracion", "proceso"]
const candidato = process.argv.includes("--candidate-view")
const seleccion = process.argv.slice(2).filter((arg) => arg !== "--candidate-view")
const vista = candidato
  ? readFileSync(resolve(raiz, "supabase/migrations/20260927000011_vistas.sql"), "utf8")
      .match(/create view lot_declared_abv[\s\S]*?;/)?.[0]
      ?.replace("create view", "create or replace view")
  : null
if (candidato && !vista) throw new Error("No se encontró la vista candidata")
if (seleccion.some((s) => !suites.includes(s)))
  throw new Error(`Suites permitidas: ${suites.join(", ")}`)

// La prueba de dos sesiones usa su propio tenant efímero y limpieza explícita:
// pnpm test:db:concurrency. No comparte el rollback de las suites pgTAP.
const resultados = []
const ahora = new Date().toISOString()
const carpeta = resolve(raiz, "docs/plan/evidence", ahora.replaceAll(":", "-"))
mkdirSync(carpeta, { recursive: true })
const semilla = readFileSync(resolve(raiz, "supabase/seed.sql"), "utf8")
for (const suite of seleccion.length ? seleccion : suites) {
  const { sql, ...fixture } = prepararFixture(
    semilla,
    readFileSync(resolve(raiz, `supabase/tests/${suite}.test.sql`), "utf8"),
  )
  const entrada = resolve(carpeta, `${suite}.sql`)
  writeFileSync(entrada, vista ? sql.replace(/^begin;/, `begin;\n${vista}`) : sql)
  const comando = ["db", "query", "--linked", "-f", entrada]
  const r = spawnSync("supabase", comando, { cwd: raiz, encoding: "utf8", timeout: 120_000 })
  let resultado
  try {
    if (r.error || r.status !== 0)
      throw new Error(
        r.error?.message ?? `CLI terminó con código ${r.status}: ${r.stderr.slice(-2000)}`,
      )
    resultado = evaluarTap(r.stdout)
  } catch (error) {
    resultado = { estado: "ERROR", motivo: error.message }
  }
  resultados.push({ suite, fixture, comando: `supabase ${comando.join(" ")}`, ...resultado })
  console.log(`${suite}: ${resultado.estado}`)
  for (const fallo of resultado.fallos ?? []) console.log(fallo.trim())
  if (resultado.motivo) console.log(resultado.motivo)
}
const archivo = resolve(carpeta, "database.json")
writeFileSync(
  archivo,
  JSON.stringify(
    {
      fecha: ahora,
      proyecto,
      resetEjecutado: false,
      vistaCandidataEnRollback: candidato,
      resultados,
      noEjecutado: ["Concurrencia con dos sesiones: no cubierta por estas suites"],
    },
    null,
    2,
  ) + "\n",
)
console.log(`Evidencia nueva: ${archivo}`)
process.exitCode = resultados.some((r) => r.estado !== "PASS") ? 1 : 0
