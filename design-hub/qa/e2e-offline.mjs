// Prueba de aceptación offline (PULZ_MAESTRO.md §16 Fase 5): "registrar 3
// mediciones (…) en modo avión, reconectar, que lleguen una sola vez y en
// orden". REAL contra el proyecto alojado, en 390 px (una mano), con Aurelia
// en Cuatro Vientos:
//   1. entra con señal, abre Fermentación (queda la instantánea)
//   2. modo avión (context.setOffline) → mide Tina 2, Tina 3 y Tina 2 otra
//      vez (día corregido) → «pendiente de enviar» ×3, banner «3 capturas»
//   3. vuelve la señal → Reintentar → el banner desaparece
//   4. por SQL (CLI): 3 operaciones 'medicion' nuevas, claves únicas,
//      recorded_at en el mismo orden que occurred_at; reenviar no duplica
// Los cortes offline se agregan en la ronda de destilación. Las 3
// mediciones quedan en Cuatro Vientos hasta el `db reset --linked`.
//   node design-hub/qa/e2e-offline.mjs   (con `web` corriendo)
import { chromium } from "@playwright/test"
import { execFileSync } from "node:child_process"
import { rmSync, writeFileSync } from "node:fs"
import { mkdir, writeFile } from "node:fs/promises"
import path from "node:path"
import { fileURLToPath } from "node:url"

const AQUI = path.dirname(fileURLToPath(import.meta.url))
const RAIZ = path.join(AQUI, "..", "..")
const WEB = process.env.WEB_URL ?? "http://localhost:5173"
const SLUG = "cuatro-vientos"
const OUT = path.join(AQUI, "evidence", "fase5-offline")
const fallos = []
const ok = (c, m) => {
  if (!c) fallos.push(m)
}
const paso = (m) => console.log(`· ${m}`)
function sql(q) {
  const f = path.join(AQUI, ".e2e-offline.sql")
  writeFileSync(f, q)
  const out = execFileSync("supabase", ["db", "query", "--linked", "-f", f], {
    cwd: RAIZ,
    encoding: "utf8",
  })
  rmSync(f, { force: true })
  return out
}

await mkdir(OUT, { recursive: true })
const browser = await chromium.launch()
const ctx = await browser.newContext({
  viewport: { width: 390, height: 780 },
  isMobile: true,
  hasTouch: true,
  deviceScaleFactor: 1,
})
const page = await ctx.newPage()
const errores = []
page.on("pageerror", (e) => errores.push(String(e)))
const foto = (n) => page.screenshot({ path: path.join(OUT, `${n}.png`), fullPage: false })

const antes = Number(
  /"n":\s*(\d+)/.exec(sql("select count(*) as n from operations where kind = 'medicion';"))?.[1] ??
    "0",
)

paso("1. entrar y abrir Fermentación con señal")
await page.goto(`${WEB}/e/${SLUG}`)
await page.locator("input[name=usuario]").fill("aurelia")
await page.locator("input[name=contrasena]").fill("aurelia-2026")
await page.locator("button[type=submit]").click()
await page.waitForURL("**/inicio", { timeout: 20000 })
await page.goto(`${WEB}/e/${SLUG}/fermentacion`)
await page.getByText("Toca medir hoy").waitFor({ timeout: 20000 })
// En dev server (Vite) los módulos se piden bajo demanda: se abre una vez la
// medición con señal para tenerla cargada (en producción la precachea el SW).
await page.getByRole("link", { name: "Medir Tina 2" }).click()
await page.getByRole("status").filter({ hasText: "Paso 1 de 4" }).waitFor({ timeout: 20000 })
await page.getByRole("link", { name: "Cancelar" }).click()
await page.getByText("Toca medir hoy").waitFor({ timeout: 20000 })

paso("2. modo avión")
await ctx.setOffline(true)
await page.evaluate(() => window.dispatchEvent(new Event("offline")))
await page.getByRole("status").filter({ hasText: "Sin conexión" }).waitFor()
await foto("1-sin-conexion")

async function medir(tina, temp, brix, act, dia = null) {
  await page.getByRole("link", { name: `Medir ${tina}` }).click()
  await page.getByRole("status").filter({ hasText: "Paso 1 de 4" }).waitFor()
  if (dia) {
    await page.getByRole("button", { name: "cambiar" }).first().click()
    await page.getByLabel("Día del ciclo").fill(String(dia))
    await page.getByLabel("Día del ciclo").blur()
  }
  await page.getByLabel("Temperatura").fill(temp)
  await page.getByRole("button", { name: "Siguiente" }).click()
  await page.getByLabel("Brix").fill(brix)
  await page.getByRole("button", { name: "Siguiente" }).click()
  await page.getByRole("radio", { name: new RegExp(`^${act} ·`) }).click()
  await page.getByRole("button", { name: "Revisar" }).click()
  await page.getByRole("button", { name: "Guardar medición" }).click()
  // La caja de resultado (no el banner del shell, que también dice «pendiente»)
  await page.getByText("Medición guardada · pendiente de enviar").waitFor({ timeout: 15000 })
}
await medir("Tina 2", "27", "12.5", "5")
await foto("2-guardada-pendiente")
await page.getByRole("link", { name: "Volver a Fermentación" }).click()
await page.getByText("Toca medir hoy").waitFor()
await medir("Tina 3", "26", "13", "4")
await page.getByRole("link", { name: "Volver a Fermentación" }).click()
await page.getByText(/tinas en uso/).waitFor()
// Tercera: Tina 2 otra vez desde «Ya medidas hoy» (día corregido a 22)
await medir("Tina 2", "27.5", "12.2", "5", 22)
await page.getByRole("link", { name: "Volver a Fermentación" }).click()
await page.getByRole("status").filter({ hasText: "3 capturas pendientes de enviar" }).waitFor()
// La lista sin señal sale de la instantánea: esperar a que pinte antes de contar chips
await page.getByText("Toca medir hoy").waitFor({ timeout: 20000 })
ok(
  (await page.locator(".chip--pending").count()) >= 2,
  "la lista no marca las tinas con captura pendiente",
)
await foto("3-tres-pendientes")
ok(errores.length === 0, `errores JS sin señal: ${errores.join(" | ")}`)

paso("3. vuelve la señal → Reintentar")
await ctx.setOffline(false)
await page.evaluate(() => window.dispatchEvent(new Event("online")))
await page
  .getByRole("status")
  .filter({ hasText: /pendientes de enviar/ })
  .waitFor({ state: "detached", timeout: 30000 })
  .catch(async () => {
    await page.getByRole("button", { name: "Reintentar" }).click()
    await page
      .getByRole("status")
      .filter({ hasText: /pendientes de enviar/ })
      .waitFor({ state: "detached", timeout: 30000 })
  })
await page.reload()
await page.getByText(/tinas en uso/).waitFor({ timeout: 20000 })
await foto("4-enviadas")
ok((await page.locator(".chip--pending").count()) === 0, "tras reconectar siguen chips pendientes")

paso("4. comprobar en la base")
const r = sql(`select count(*) as n, count(distinct idempotency_key) as claves,
  (array_agg(occurred_at order by recorded_at) = array_agg(occurred_at order by occurred_at)) as en_orden
  from (select * from operations where kind = 'medicion' order by recorded_at desc limit ${3}) x;`)
const n = Number(/"n":\s*(\d+)/.exec(r)?.[1])
const claves = Number(/"claves":\s*(\d+)/.exec(r)?.[1])
const enOrden = /"en_orden":\s*true/.test(r)
const despues = Number(
  /"n":\s*(\d+)/.exec(sql("select count(*) as n from operations where kind = 'medicion';"))?.[1] ??
    "0",
)
ok(despues - antes === 3, `llegaron ${despues - antes} mediciones, no 3 (una sola vez)`)
ok(n === 3 && claves === 3, "las 3 últimas no tienen claves únicas")
ok(enOrden, "las mediciones no llegaron en orden")
// Reenviar (recargar dispara la cola): no duplica
await page.reload()
await page.getByText(/tinas en uso/).waitFor({ timeout: 20000 })
const final = Number(
  /"n":\s*(\d+)/.exec(sql("select count(*) as n from operations where kind = 'medicion';"))?.[1] ??
    "0",
)
ok(final === despues, `reenviar duplicó: ${final - despues} de más`)
await writeFile(
  path.join(OUT, "resultado.txt"),
  `antes ${antes} · después ${despues} · final ${final}\n${r}\n`,
)

paso(
  "5. limpiar: las 3 mediciones quedan anuladas (por SQL, declarado) para no alterar otras evidencias",
)
sql(`update fermentation_measurements m set voided_at = now(), voided_by = o.recorded_by, void_reason = 'e2e offline: prueba de aceptación'
  from operations o where o.id = m.operation_id and m.id in (
    select m2.id from fermentation_measurements m2 join operations o2 on o2.id = m2.operation_id
    where o2.kind = 'medicion' and m2.voided_at is null order by o2.recorded_at desc limit 3);`)

await browser.close()
if (fallos.length) {
  console.error("\nFALLOS:\n- " + fallos.join("\n- "))
  process.exit(1)
}
console.log(`\nE2E offline OK · evidencia en ${OUT}`)
