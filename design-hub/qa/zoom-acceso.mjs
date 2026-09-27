// lima · QA de ejecución aproximada para la compuerta: texto al 200 %
// (root font-size ×2, no el zoom nativo del navegador) en 1440 y 390 sobre
// las pantallas reales y el Hub. Reporta desborde horizontal y controles
// recortados. Nivel de evidencia en el registry: runtime-verified-approx.
//
//   node design-hub/qa/zoom-acceso.mjs   (con `web` y `hub` corriendo)
import { chromium } from "@playwright/test"

const WEB = process.env.WEB_URL ?? "http://localhost:5173"
const HUB = process.env.HUB_URL ?? "http://localhost:4321/design-hub/Components/demo/"
const SLUG = "cuatro-vientos"
const out = []
let fallos = 0
const browser = await chromium.launch()
for (const ancho of [1440, 390]) {
  const ctx = await browser.newContext({
    viewport: { width: ancho, height: ancho < 600 ? 780 : 900 },
  })
  const page = await ctx.newPage()
  const check = async (nombre) => {
    await page.evaluate(() => (document.documentElement.style.fontSize = "200%"))
    await page.waitForTimeout(150)
    const r = await page.evaluate(() => {
      const de = document.documentElement
      const clipped = [
        ...document.querySelectorAll("button, a, input, label, h1, h2, p, td"),
      ].filter((el) => {
        const cs = getComputedStyle(el)
        return cs.overflow === "hidden" && el.scrollWidth > el.clientWidth + 1
      }).length
      return { sw: de.scrollWidth, cw: de.clientWidth, clipped }
    })
    const ok = r.sw <= r.cw && r.clipped === 0
    if (!ok) fallos++
    out.push(
      `${nombre} ${ancho}: scrollW ${r.sw}/${r.cw} ${r.sw <= r.cw ? "OK" : "DESBORDE"} · recortados ${r.clipped}`,
    )
    await page.evaluate(() => (document.documentElement.style.fontSize = ""))
  }
  await page.goto(`${WEB}/e/${SLUG}`)
  await page.getByRole("heading", { name: "Mezcal Cuatro Vientos" }).waitFor()
  await check("portal")
  await page.locator("input[name=usuario]").fill("benito@cuatrovientos.mx")
  await page.locator("input[name=contrasena]").fill("benito-2026")
  await page.locator("button[type=submit]").click()
  await page.waitForURL("**/inicio")
  await check("inicio")
  await page.goto(`${WEB}/e/${SLUG}/equipo`)
  await page.getByRole("button", { name: "Acciones para Tomás Hernández" }).waitFor()
  await check("equipo")
  await page.getByRole("button", { name: "Agregar persona" }).click()
  await page.getByRole("dialog").waitFor()
  await check("equipo-alta")
  await page.keyboard.press("Escape")
  await page.goto(`${WEB}/e/${SLUG}/inicio`)
  await page.getByRole("button", { name: "Cerrar sesión" }).click()
  await page.waitForURL(`**/e/${SLUG}`)
  await page.goto(HUB)
  await page.getByRole("heading", { level: 2, name: /Botón/ }).waitFor()
  await check("hub")
  await ctx.close()
}
await browser.close()
console.log(out.join("\n"))
if (fallos) {
  console.error(`\n${fallos} comprobaciones con desborde o recorte`)
  process.exit(1)
}
