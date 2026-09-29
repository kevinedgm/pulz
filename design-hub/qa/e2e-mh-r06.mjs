// r06 Maguey/Horneado · checklist 15.12 (recuperación de señal) y 15.13
// (partición de intenciones), con Playwright contra el dev server y el
// proyecto alojado. Todo REAL salvo dos respuestas del servidor que se
// interceptan en el navegador para provocar (a) un resultado INCIERTO
// (la petición se aborta antes de salir: nada llega al servidor) y (b) un
// RECHAZO confirmado (400 P0001). La única escritura real es el reintento
// del envío original (recepción de 123 kg en Cuatro Vientos); queda hasta
// el `db reset`. Evidencia en design-hub/lab/maguey-horneado/r06/evidence/.
//   node design-hub/qa/e2e-mh-r06.mjs   (con `web` corriendo)
import { chromium } from "@playwright/test"
import { execFileSync } from "node:child_process"
import { rmSync, writeFileSync } from "node:fs"
import { mkdir } from "node:fs/promises"
import path from "node:path"
import { fileURLToPath } from "node:url"

const AQUI = path.dirname(fileURLToPath(import.meta.url))
const RAIZ = path.join(AQUI, "..", "..")
const WEB = process.env.WEB_URL ?? "http://localhost:5173"
const OUT = path.join(RAIZ, "design-hub", "lab", "maguey-horneado", "r06", "evidence")
const RPC = "**/rest/v1/rpc/registrar_recepcion_maguey"
const checks = []
const ok = (c, m) => checks.push({ ok: Boolean(c), m })
const paso = (m) => console.log(`· ${m}`)
function sql(q) {
  const f = path.join(AQUI, ".e2e-mh.sql")
  writeFileSync(f, q)
  const out = execFileSync("supabase", ["db", "query", "--linked", "-f", f], { cwd: RAIZ, encoding: "utf8" })
  rmSync(f, { force: true })
  return out
}
const recepciones = () =>
  Number(/"n":\s*(\d+)/.exec(sql("select count(*) as n from operations where kind = 'recepcion_maguey';"))?.[1])

await mkdir(OUT, { recursive: true })
const browser = await chromium.launch()
const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 } })
const page = await ctx.newPage()
const errores = []
page.on("pageerror", (e) => errores.push(String(e)))
const foto = (n) => page.screenshot({ path: path.join(OUT, `${n}.png`), fullPage: false })
async function entrar(slug, usuario, contrasena) {
  await page.goto(`${WEB}/e/${slug}`)
  await page.locator("input[name=usuario]").fill(usuario)
  await page.locator("input[name=contrasena]").fill(contrasena)
  await page.locator("button[type=submit]").click()
  await page.waitForURL("**/inicio", { timeout: 20000 })
}
async function salir(slug) {
  await page.getByRole("button", { name: /cuenta|Cuatro Vientos|Prueba B/ }).first().click()
  await page.getByRole("button", { name: "Cerrar sesión" }).click()
  await page.waitForURL(`**/e/${slug}`)
}
const maguey = async (slug) => {
  await page.goto(`${WEB}/e/${slug}/maguey`)
  await page.getByRole("heading", { name: "Maguey", exact: true }).waitFor({ timeout: 20000 })
  await page.locator(".mh-loading").waitFor({ state: "detached", timeout: 20000 })
}
const pendiente = () => page.getByRole("status").filter({ hasText: "Hay un envío sin confirmar" })
const primaria = () => page.getByRole("button", { name: "Registrar recepción" }).first()

const antes = recepciones()
paso("A. Aurelia · Cuatro Vientos · datos frescos habilitan escritura")
await entrar("cuatro-vientos", "aurelia", "aurelia-2026")
await maguey("cuatro-vientos")
ok(await primaria().isEnabled(), "A: con datos frescos la primaria está habilitada")
ok((await page.getByText(/Mostrando datos guardados/).count()) === 0, "A: sin etiqueta de instantánea con señal")

paso("B. resultado INCIERTO: la petición se aborta antes de salir → intención conservada")
await page.route(RPC, (r) => r.abort("connectionreset"))
await primaria().click()
await page.getByLabel("Kilos (obligatorio)").fill("123")
await page.getByRole("button", { name: /123 kg · Registrar recepción/ }).click()
await pendiente().waitFor({ timeout: 20000 })
ok(/123 kg/.test(await pendiente().textContent()), "B: la intención pendiente muestra los 123 kg")
ok((await page.getByRole("button", { name: "Reintentar envío original" }).count()) >= 1, "B: ofrece reintentar el original")
ok(recepciones() === antes, "B: nada llegó al servidor")
await foto("15-13-intencion-pendiente")
await page.unroute(RPC)

paso("C. 15.13 · otra persona y otra empresa no ven ni reenvían la intención ajena")
await salir("cuatro-vientos")
await entrar("prueba-b", "duena@pruebab.mx", "prueba-b-2026")
await maguey("prueba-b")
ok((await pendiente().count()) === 0, "C: Prueba B no ve la intención de Aurelia")
ok(recepciones() === antes, "C: no se reenvió nada al cambiar de persona")
await foto("15-13-otra-empresa-sin-intencion")
await salir("prueba-b")
await entrar("cuatro-vientos", "aurelia", "aurelia-2026")
await maguey("cuatro-vientos")
await pendiente().waitFor({ timeout: 20000 })
ok(/123 kg/.test(await pendiente().textContent()), "C: al volver, Aurelia recupera su intención original")
await page.reload()
await maguey("cuatro-vientos")
await pendiente().waitFor({ timeout: 20000 })
ok(recepciones() === antes, "C: recargar no reenvía solo")

paso("D. 15.12 · sin señal: instantánea con fecha, captura bloqueada; reconectar habilita solo con datos frescos")
// Maguey y Horneado comparten componente: ir de uno a otro no recarga. Se
// pasa por Fermentación (precargada con señal: el dev server no tiene SW)
// para que la página de Maguey se monte de nuevo sin señal.
await page.getByRole("link", { name: "Fermentación" }).first().click()
await page.getByText(/tinas en uso|No hay tinas en uso/).waitFor({ timeout: 20000 })
await page.getByRole("link", { name: "Maguey" }).first().click()
await page.getByRole("heading", { name: "Maguey", exact: true }).waitFor({ timeout: 20000 })
await page.locator(".mh-loading").waitFor({ state: "detached", timeout: 20000 })
await ctx.setOffline(true)
await page.evaluate(() => window.dispatchEvent(new Event("offline")))
await page.getByRole("link", { name: "Fermentación" }).first().click()
await page.getByText(/tinas en uso|No hay tinas en uso/).waitFor({ timeout: 20000 })
await page.getByRole("link", { name: "Maguey" }).first().click()
await page.getByRole("heading", { name: "Maguey", exact: true }).waitFor({ timeout: 20000 })
await page.getByText(/Mostrando datos guardados el/).waitFor({ timeout: 20000 })
ok((await page.locator("time[datetime]").count()) >= 1, "D: etiqueta de antigüedad con fecha y hora")
ok(await primaria().isDisabled(), "D: sin señal, la primaria está bloqueada")
ok(await page.getByRole("button", { name: "Reintentar envío original" }).first().isDisabled(), "D: sin señal no se puede reintentar")
await foto("15-12-sin-senal-instantanea")
await ctx.setOffline(false)
await page.evaluate(() => window.dispatchEvent(new Event("online")))
await page.getByText(/Mostrando datos guardados el/).waitFor({ state: "detached", timeout: 20000 })
await page.locator(".mh-loading").waitFor({ state: "detached", timeout: 20000 })
ok(await primaria().isEnabled(), "D: con señal y datos frescos la primaria vuelve a habilitarse")
ok(recepciones() === antes, "D: reconectar no reenvía solo")
await foto("15-12-senal-recuperada")

paso("E. reintento del envío original → escritura REAL")
await page.getByRole("button", { name: "Reintentar envío original" }).first().click()
await page.getByRole("status").filter({ hasText: "Recepción registrada · 123 kg" }).waitFor({ timeout: 30000 })
ok((await pendiente().count()) === 0, "E: la intención se libera al confirmar")
ok(recepciones() === antes + 1, "E: exactamente una recepción nueva en el servidor")
await foto("15-13-reintento-confirmado")

paso("F. rechazo CONFIRMADO (P0001) libera la intención sin escribir")
await page.route(RPC, (r) =>
  r.fulfill({ status: 400, contentType: "application/json", body: JSON.stringify({ code: "P0001", message: "NO_PERMITIDO: prueba de rechazo confirmado", details: null, hint: null }) }),
)
await primaria().click()
await page.getByLabel("Kilos (obligatorio)").fill("5")
await page.getByRole("button", { name: /5 kg · Registrar recepción/ }).click()
await page.getByText("prueba de rechazo confirmado").waitFor({ timeout: 20000 })
ok((await pendiente().count()) === 0, "F: un rechazo confirmado no deja intención pendiente")
ok(recepciones() === antes + 1, "F: el rechazo no escribió nada")
await foto("15-13-rechazo-confirmado")
await page.unroute(RPC)
ok(errores.length === 0, `errores JS: ${errores.join(" | ")}`)

await browser.close()
const fallos = checks.filter((c) => !c.ok)
writeFileSync(path.join(OUT, "ui-15-12-15-13.json"), JSON.stringify({ fecha: new Date().toISOString(), status: fallos.length ? "FAIL" : "PASS", recepcionesAntes: antes, recepcionesDespues: antes + 1, checks }, null, 2) + "\n")
console.log(JSON.stringify({ status: fallos.length ? "FAIL" : "PASS", checks: checks.length, fallos: fallos.map((f) => f.m) }))
if (fallos.length) process.exit(1)
