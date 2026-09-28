// Prueba de aceptación de la Fase 4 (PULZ_MAESTRO.md §16): "un dueño nuevo,
// desde cero, configura su palenque y registra una carga inicial en un
// tanque sin ayuda". Todo REAL contra el proyecto alojado y el dev server:
//   1. signup-company crea empresa + titular (Edge Function desplegada)
//   2. confirmación del correo: si Auth la exige, se simula por SQL con el
//      CLI (en producción llega por correo) y se declara
//   3. la titular entra, Inicio ofrece "¿Qué tienes hoy?", crea Tanque 1 en
//      el arranque, guarda 300 L @ 47, Listo → Inicio "Hoy"
//   4. sube el logo en Portal y marca; Recursos muestra 300 L dentro; el
//      portal público muestra el logo
// La empresa creada se borra con `supabase db reset --linked` al cerrar la fase.
//   node design-hub/qa/e2e-fase4.mjs   (con `web` corriendo)
import { chromium } from "@playwright/test"
import { execFileSync } from "node:child_process"
import { mkdir, readFile, writeFile } from "node:fs/promises"
import path from "node:path"
import { fileURLToPath } from "node:url"

const AQUI = path.dirname(fileURLToPath(import.meta.url))
const RAIZ = path.join(AQUI, "..", "..")
const WEB = process.env.WEB_URL ?? "http://localhost:5173"
const env = Object.fromEntries(
  (await readFile(path.join(RAIZ, "apps", "web", ".env.local"), "utf8"))
    .split("\n")
    .filter((l) => l.includes("="))
    .map((l) => l.split("=").map((x) => x.trim())),
)
const U = env.VITE_SUPABASE_URL
const K = env.VITE_SUPABASE_PUBLISHABLE_KEY
const SUF = Math.random().toString(36).slice(2, 7)
const SLUG = `prueba-d-${SUF}`
const CORREO = `duena-d-${SUF}@pulz-qa.mx`
const PASS = `prueba-d-${SUF}-2026`
const OUT = path.join(AQUI, "evidence", "fase4-e2e")
const LOGO = path.join(RAIZ, "apps", "web", "public", "icons", "pwa-192x192.png")
const fallos = []
const ok = (c, m) => {
  if (!c) fallos.push(m)
}
const paso = (m) => console.log(`· ${m}`)

await mkdir(OUT, { recursive: true })

// 1) signup-company
paso(`signup-company → ${SLUG}`)
const r = await fetch(`${U}/functions/v1/signup-company`, {
  method: "POST",
  headers: { apikey: K, "content-type": "application/json" },
  body: JSON.stringify({
    nombre: "Palenque Prueba D",
    slug: SLUG,
    correo: CORREO,
    contrasena: PASS,
    nombre_titular: "Dueña Prueba D",
    estado: "Oaxaca",
    mensaje: "Empresa de prueba de la Fase 4",
  }),
})
const cuerpo = await r.json().catch(() => ({}))
ok(r.ok, `signup-company respondió ${r.status}: ${JSON.stringify(cuerpo)}`)
if (!r.ok) {
  console.error(fallos.join("\n"))
  process.exit(1)
}

// 2) ¿hace falta confirmar el correo?
let tok = await fetch(`${U}/auth/v1/token?grant_type=password`, {
  method: "POST",
  headers: { apikey: K, "content-type": "application/json" },
  body: JSON.stringify({ email: CORREO, password: PASS }),
})
let confirmacionSimulada = false
if (!tok.ok) {
  const e = await tok.json().catch(() => ({}))
  if (/not confirmed/i.test(JSON.stringify(e))) {
    paso("Auth exige confirmar el correo: se simula por SQL (en producción llega por correo)")
    const sql = path.join(AQUI, "..", "..", "supabase", ".temp", `confirmar-${SUF}.sql`)
    await mkdir(path.dirname(sql), { recursive: true })
    await writeFile(sql, `update auth.users set email_confirmed_at = now() where email = '${CORREO}';\n`)
    execFileSync("supabase", ["db", "query", "--linked", "-f", sql], { cwd: RAIZ, stdio: "pipe" })
    confirmacionSimulada = true
    tok = await fetch(`${U}/auth/v1/token?grant_type=password`, {
      method: "POST",
      headers: { apikey: K, "content-type": "application/json" },
      body: JSON.stringify({ email: CORREO, password: PASS }),
    })
  }
}
ok(tok.ok, `la titular no pudo iniciar sesión por API (${tok.status})`)

// 3) La titular en la app
const browser = await chromium.launch()
const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 }, deviceScaleFactor: 1 })
const page = await ctx.newPage()
page.on("dialog", (d) => d.accept())
const errores = []
page.on("pageerror", (e) => errores.push(String(e)))
const foto = (n) => page.screenshot({ path: path.join(OUT, `${n}.png`), fullPage: false })

paso("portal de la empresa nueva")
await page.goto(`${WEB}/e/${SLUG}`)
await page.getByRole("heading", { name: "Palenque Prueba D" }).waitFor({ timeout: 15000 })
await foto("01-portal")
await page.locator("input[name=usuario]").fill(CORREO)
await page.locator("input[name=contrasena]").fill(PASS)
await page.locator("button[type=submit]").click()
await page.waitForURL("**/inicio", { timeout: 20000 })
await page.getByRole("heading", { name: "¿Qué tienes hoy?" }).waitFor({ timeout: 15000 })
await foto("02-inicio-sin-lotes")

paso("arranque: sin recipientes → crear Tanque 1 → 300 L @ 47")
await page.getByRole("link", { name: "Empezar" }).click()
await page.waitForURL("**/arranque")
await page.getByText("Aún no tienes recipientes").waitFor({ timeout: 15000 })
await foto("03-arranque-vacio")
await page.getByRole("button", { name: "Agregar recipiente" }).click()
const capa = page.getByRole("dialog", { name: "Agregar recurso" })
await capa.waitFor()
await capa.getByLabel("Tipo de recurso").selectOption("tanque")
await capa.getByLabel("Código (como le dicen)").fill("Tanque 1")
await capa.getByLabel("Tipo (catálogo)").selectOption({ label: "Tanque de acero inoxidable" })
await capa.getByLabel("Capacidad", { exact: true }).fill("1000")
await foto("04-arranque-agregar-tanque")
await page.getByRole("button", { name: "Guardar recurso" }).click()
await page.getByText("Tanque 1 quedó dado de alta").waitFor({ timeout: 15000 })
const tarjeta = page.getByRole("article", { name: "Tanque 1" })
await tarjeta.getByRole("radio", { name: "Tiene algo" }).click()
await tarjeta.getByLabel("Litros").fill("300")
await tarjeta.getByLabel("% Alc.").fill("47")
await tarjeta.getByRole("button", { name: "Guardar 300 L en Tanque 1" }).click()
await tarjeta.getByText("guardado").waitFor({ timeout: 20000 })
ok((await tarjeta.textContent())?.includes("300 L"), "Tanque 1 no muestra 300 L")
await page.getByText("1 de 1 recipientes decididos").waitFor()
await foto("05-arranque-guardado")
await page.getByRole("link", { name: "Listo, ir a Inicio" }).click()
await page.waitForURL("**/inicio")
await page.getByText("Tinas que toca medir hoy").waitFor({ timeout: 15000 })
await foto("06-inicio-hoy")

paso("configuración: logo y recursos")
await page.goto(`${WEB}/e/${SLUG}/configuracion/portal`)
await page.getByRole("button", { name: "Cambiar enlace…" }).waitFor()
await page.setInputFiles('input[type="file"]', LOGO)
await page.getByRole("dialog", { name: "Recortar el logo" }).waitFor()
await page.getByRole("button", { name: "Usar este logo" }).click()
await page.getByRole("dialog", { name: "Recortar el logo" }).waitFor({ state: "detached", timeout: 20000 })
await page.waitForFunction(
  () => {
    const i = document.querySelector(".arch__previa img")
    return i && i.complete && i.naturalWidth > 0
  },
  null,
  { timeout: 20000 },
)
await foto("07-portal-y-marca-con-logo")
await page.goto(`${WEB}/e/${SLUG}/configuracion/recursos`)
await page.getByRole("button", { name: "Acciones para Tanque 1" }).waitFor({ timeout: 15000 })
ok((await page.locator("main").textContent())?.includes("300 L dentro"), "Recursos no muestra 300 L dentro")
await foto("08-recursos-con-saldo")

paso("cerrar sesión: el portal público muestra el logo")
await page.getByRole("button", { name: /cuenta/ }).first().click()
await page.getByRole("button", { name: "Cerrar sesión" }).click()
await page.waitForURL(`**/e/${SLUG}`)
await page.getByRole("heading", { name: "Palenque Prueba D" }).waitFor()
await page.waitForFunction(
  () => {
    const i = document.querySelector("img.marca__logo")
    return i && i.complete && i.naturalWidth > 0
  },
  null,
  { timeout: 20000 },
)
await foto("09-portal-con-logo")
ok(errores.length === 0, `errores JS: ${errores.join(" | ")}`)
await browser.close()

const resumen = {
  fecha: new Date().toISOString(),
  slug: SLUG,
  correo: CORREO,
  confirmacionSimuladaPorSQL: confirmacionSimulada,
  pasos: ["signup-company", "portal", "inicio sin lotes", "arranque: Tanque 1 creado", "300 L @ 47 guardados", "Listo → Inicio Hoy", "logo a Storage", "Recursos 300 L dentro", "portal público con logo"],
  fallos,
}
await writeFile(path.join(OUT, "resumen.json"), JSON.stringify(resumen, null, 2))
if (fallos.length) {
  console.error("\nFALLOS:\n- " + fallos.join("\n- "))
  process.exit(1)
}
console.log(`\n✔ Fase 4 de punta a punta OK · ${SLUG} · confirmación simulada por SQL: ${confirmacionSimulada}`)
