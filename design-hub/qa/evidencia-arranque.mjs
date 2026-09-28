// Evidencia de la ronda arranque/r01 (coco, R3) con la dueña de Palenque
// Prueba B (semilla: solo Tina B1, sin lotes). En 1440/claro hace escrituras
// REALES: crea "Tanque B1" (capa de Recursos), guarda 300 L @ 47 (carga
// inicial), marca Tina B1 vacía y llega a "Listo". Después, Inicio deja de
// ofrecer "¿Qué tienes hoy?". `db reset --linked` limpia Prueba B.
//   node design-hub/qa/evidencia-arranque.mjs   (con `web` corriendo)
import { chromium } from "@playwright/test"
import { mkdir } from "node:fs/promises"
import path from "node:path"
import { fileURLToPath } from "node:url"

const WEB = process.env.WEB_URL ?? "http://localhost:5173"
const SLUG = "prueba-b"
const OUT = path.join(path.dirname(fileURLToPath(import.meta.url)), "evidence", "arranque-r01")
const ANCHOS = [1440, 1024, 768, 390]
const TEMAS = ["light", "dark"]
const fallos = []
const ok = (c, m) => {
  if (!c) fallos.push(m)
}
async function entrar(page) {
  await page.goto(`${WEB}/e/${SLUG}`)
  await page.locator("input[name=usuario]").fill("duena@pruebab.mx")
  await page.locator("input[name=contrasena]").fill("prueba-b-2026")
  await page.locator("button[type=submit]").click()
  await page.waitForURL("**/inicio", { timeout: 15000 })
}
async function salir(page) {
  await page.getByRole("button", { name: /cuenta|Prueba B/ }).first().click()
  await page.getByRole("button", { name: "Cerrar sesión" }).click()
  await page.waitForURL(`**/e/${SLUG}`)
}

await mkdir(OUT, { recursive: true })
const browser = await chromium.launch()
let primera = true
for (const tema of TEMAS) {
  for (const ancho of ANCHOS) {
    const movil = ancho < 600
    const ctx = await browser.newContext({ viewport: { width: ancho, height: movil ? 780 : 900 }, colorScheme: tema, isMobile: movil, hasTouch: movil, deviceScaleFactor: 1 })
    const page = await ctx.newPage()
    page.on("dialog", (d) => d.accept())
    const errores = []
    page.on("pageerror", (e) => errores.push(String(e)))
    const foto = (n) => page.screenshot({ path: path.join(OUT, `${n}-${ancho}-${tema}.png`), fullPage: false })
    const sinScrollH = async (n) => {
      const [sw, cw] = await page.evaluate(() => [document.documentElement.scrollWidth, document.documentElement.clientWidth])
      ok(sw <= cw, `${n} ${ancho}/${tema}: scroll horizontal (${sw} > ${cw})`)
    }

    await entrar(page)
    if (primera) {
      // Inicio sin lotes → ¿Qué tienes hoy? → Empezar
      await page.getByRole("heading", { name: "¿Qué tienes hoy?" }).waitFor()
      await foto("inicio-sin-lotes")
      await page.getByRole("link", { name: "Empezar" }).click()
      await page.waitForURL("**/arranque")
    } else {
      await page.goto(`${WEB}/e/${SLUG}/arranque`)
    }
    await page.getByText(/recipientes decididos|Aún no tienes recipientes/).waitFor()
    await foto("arranque")
    await sinScrollH("arranque")

    if (primera) {
      // Agregar Tanque B1 con la capa de Recursos
      await page.getByRole("button", { name: "Agregar recipiente" }).click()
      const capa = page.getByRole("dialog", { name: "Agregar recurso" })
      await capa.waitFor()
      await foto("arranque-agregar")
      await capa.getByLabel("Tipo de recurso").selectOption("tanque")
      await capa.getByLabel("Código (como le dicen)").fill("Tanque B1")
      await capa.getByLabel("Capacidad", { exact: true }).fill("1000")
      await page.getByRole("button", { name: "Guardar recurso" }).click()
      await page.getByText("Tanque B1 quedó dado de alta").waitFor({ timeout: 15000 })
      // Tanque B1: tiene algo → 300 L @ 47 → Guardar
      const tarjeta = page.getByRole("article", { name: "Tanque B1" })
      await tarjeta.getByRole("radio", { name: "Tiene algo" }).click()
      await tarjeta.getByLabel("Litros").fill("300")
      await tarjeta.getByLabel("% Alc.").fill("47")
      await foto("arranque-datos")
      await tarjeta.getByRole("button", { name: "Guardar 300 L en Tanque B1" }).click()
      await tarjeta.getByText("guardado").waitFor({ timeout: 20000 })
      ok((await tarjeta.textContent())?.includes("300 L"), "Tanque B1 no muestra 300 L guardados")
      // Tina B1: vacía
      const tina = page.getByRole("article", { name: "Tina B1" })
      await tina.getByRole("radio", { name: "Vacío" }).click()
      await page.getByText("2 de 2 recipientes decididos").waitFor()
      await page.getByRole("link", { name: "Listo, ir a Inicio" }).waitFor()
      await foto("arranque-listo")
      await sinScrollH("arranque-listo")
      // Reanudación: recargar conserva vacío y guardado
      await page.reload()
      await page.getByText("2 de 2 recipientes decididos").waitFor({ timeout: 15000 })
      await page.getByRole("link", { name: "Listo, ir a Inicio" }).click()
      await page.waitForURL("**/inicio")
      await page.getByText("Tinas que toca medir hoy").waitFor({ timeout: 15000 })
      await foto("inicio-con-lotes")
      primera = false
    } else {
      // Ya arrancó: aviso + estado derivado de recurso_en_uso
      await page.getByText("Ya tienes registros").waitFor()
      ok((await page.getByRole("article", { name: "Tanque B1" }).textContent())?.includes("guardado"), `${ancho}/${tema}: Tanque B1 no aparece guardado`)
    }
    await salir(page)
    ok(errores.length === 0, `${ancho}/${tema}: errores JS: ${errores.join(" | ")}`)
    await ctx.close()
    console.log(`✔ ${ancho} ${tema}`)
  }
}
await browser.close()
if (fallos.length) {
  console.error("\nFALLOS:\n- " + fallos.join("\n- "))
  process.exit(1)
}
console.log(`\nEvidencia en ${OUT}`)
