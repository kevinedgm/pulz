// Evidencia del sitio del Design Hub (hub/r01): inicio, una ficha de
// componente (demo embebida), una de pantalla (galería) y QA en
// 1440/1024/768/390 × claro/oscuro; drawer con Esc; sin desborde; 0 errores.
//   node design-hub/qa/evidencia-hub.mjs   (con `hub` corriendo en 4321)
import { chromium } from "@playwright/test"
import { mkdir } from "node:fs/promises"
import path from "node:path"
import { fileURLToPath } from "node:url"

const BASE = process.env.HUB_URL ?? "http://localhost:4321/design-hub/site/"
const OUT = path.join(path.dirname(fileURLToPath(import.meta.url)), "evidence", "hub-r01")
const ANCHOS = [1440, 1024, 768, 390]
const TEMAS = ["light", "dark"]
const fallos = []
const ok = (c, m) => {
  if (!c) fallos.push(m)
}
await mkdir(OUT, { recursive: true })
const browser = await chromium.launch()
for (const tema of TEMAS) {
  for (const ancho of ANCHOS) {
    const movil = ancho < 600
    const ctx = await browser.newContext({ viewport: { width: ancho, height: movil ? 780 : 900 }, colorScheme: tema, isMobile: movil, hasTouch: movil, deviceScaleFactor: 1 })
    const page = await ctx.newPage()
    const errores = []
    page.on("pageerror", (e) => errores.push(String(e)))
    const foto = (n) => page.screenshot({ path: path.join(OUT, `${n}-${ancho}-${tema}.png`), fullPage: false })
    const sinScrollH = async (n) => {
      const [sw, cw] = await page.evaluate(() => [document.documentElement.scrollWidth, document.documentElement.clientWidth])
      ok(sw <= cw, `${n} ${ancho}/${tema}: scroll horizontal (${sw} > ${cw})`)
    }
    await page.goto(`${BASE}index.html`)
    await page.getByRole("heading", { level: 1 }).waitFor()
    await foto("inicio")
    await sinScrollH("inicio")
    // ≥1024: sidebar visible; <1024: la misma jerarquía vive en el drawer (botón Menú)
    const navs = await page.getByRole("navigation", { name: "Design Hub" }).all()
    const menu = await page.getByRole("button", { name: "Menú" }).count()
    ok(ancho >= 1024 ? navs.length >= 1 : menu === 1, `inicio ${ancho}/${tema}: sin navegación global`)

    // Ficha de componente con demo embebida
    await page.goto(`${BASE}Components/button.html`)
    await page.getByRole("heading", { level: 1, name: /Botón/ }).waitFor()
    await page.locator("iframe").first().waitFor()
    ok((await page.locator('a[aria-current="page"]').count()) >= 1 || ancho < 1024, `button ${ancho}/${tema}: sin aria-current`)
    await foto("componente")
    await sinScrollH("componente")
    ok((await page.locator("h2#facetas-de-qa-registry").count()) === 1, `button ${ancho}/${tema}: sin facetas`)

    // Ficha de pantalla con galería
    await page.goto(`${BASE}Screens/arranque.html`)
    await page.getByRole("heading", { level: 1, name: /arranque/ }).waitFor()
    await page.locator(".hub-gal img").first().waitFor()
    await foto("pantalla")
    await sinScrollH("pantalla")

    // Drawer (<1024): abrir, Esc cierra y devuelve el foco
    if (ancho < 1024) {
      await page.getByRole("button", { name: "Menú" }).click()
      await page.getByRole("dialog", { name: "Design Hub" }).waitFor()
      ok((await page.evaluate(() => document.getElementById("hub-drawer").contains(document.activeElement))), `drawer ${ancho}/${tema}: el foco no entró`)
      await foto("drawer")
      await page.keyboard.press("Escape")
      ok((await page.getByRole("dialog", { name: "Design Hub" }).count()) === 0 || !(await page.locator("#hub-drawer[open]").count()), `drawer ${ancho}/${tema}: Esc no cerró`)
      ok((await page.evaluate(() => document.activeElement?.classList.contains("hub-menu"))), `drawer ${ancho}/${tema}: el foco no volvió a Menú`)
    }

    await page.goto(`${BASE}qa.html`)
    await page.getByRole("heading", { level: 1, name: /QA/ }).waitFor()
    await foto("qa")
    await sinScrollH("qa")
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
