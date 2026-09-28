// Evidencia inmutable de .fruti/tests/r01 sobre la demo F3 real compilada desde Vue.
//   node design-hub/qa/evidencia-fermentation-vat.mjs
import { chromium } from "@playwright/test"
import { mkdir, writeFile } from "node:fs/promises"
import path from "node:path"
import { fileURLToPath } from "node:url"

const HUB = process.env.HUB_URL ?? "http://localhost:4321"
const URL = `${HUB}/design-hub/Components/demo/index.html?pieza=fermentation-vat&solo=1`
const OUT = path.join(
  path.dirname(fileURLToPath(import.meta.url)),
  "evidence",
  "fermentation-vat-immutable-r01",
)
const viewports = [1440, 1024, 768, 390]
const failures = []
const observations = []
const check = (condition, message) => {
  if (!condition) failures.push(message)
}

await mkdir(OUT, { recursive: true })
const browser = await chromium.launch()
for (const width of viewports) {
  const context = await browser.newContext({
    viewport: { width, height: width < 600 ? 780 : 900 },
    hasTouch: width < 600,
    isMobile: width < 600,
    colorScheme: "light",
  })
  const page = await context.newPage()
  const errors = []
  page.on("pageerror", (error) => errors.push(String(error)))
  await page.goto(URL, { waitUntil: "networkidle" })
  const component = page.locator("#fermentation-vat")
  await component.waitFor()

  const text = await component.textContent()
  for (const expected of [
    "Tina 2",
    "día 6",
    "Hace 28 h",
    "Medición atrasada",
    "28.5 °C",
    "10.1 °Bx",
    "Media · 4/6",
    "Registrar medición",
  ]) {
    check(text?.includes(expected), `${width}: falta «${expected}»`)
  }
  const overflow = await page.evaluate(
    () => document.documentElement.scrollWidth > document.documentElement.clientWidth,
  )
  check(!overflow, `${width}: overflow horizontal`)
  const action = page.getByRole("link", { name: "Registrar medición en Tina 2" })
  const box = await action.boundingBox()
  check(Boolean(box && box.height >= 44), `${width}: acción menor a 44 CSS px`)

  const geometry = await component.evaluate((node) => {
    const box = (selector) => {
      const rect = node.querySelector(selector)?.getBoundingClientRect()
      return rect
        ? {
            x: rect.x,
            y: rect.y,
            width: rect.width,
            height: rect.height,
            right: rect.right,
            bottom: rect.bottom,
          }
        : null
    }
    const css = (selector, property) => {
      const target = node.querySelector(selector)
      return target ? getComputedStyle(target)[property] : null
    }
    return {
      component: box(".tina-fermentacion"),
      context: box(".fila__contexto"),
      metrics: box(".fila__metricas"),
      actions: box(".fila__acciones"),
      cta: box(".fila__cta"),
      bodyColumns: css(".fila__cuerpo", "gridTemplateColumns"),
      metricColumns: css(".fila__metricas", "gridTemplateColumns"),
      font: css(".tina-fermentacion", "fontFamily"),
    }
  })
  check(
    geometry.actions &&
      geometry.context &&
      geometry.metrics &&
      geometry.actions.y >= Math.max(geometry.context.bottom, geometry.metrics.bottom),
    `${width}: el CTA dejó de vivir en un footer separado`,
  )
  if (width === 390) {
    check(
      geometry.cta && geometry.actions && Math.abs(geometry.cta.width - geometry.actions.width) < 1,
      `${width}: el CTA no ocupa el ancho completo`,
    )
  }
  if (width === 1440) {
    check(
      geometry.context &&
        geometry.metrics &&
        geometry.context.right <= geometry.metrics.x &&
        geometry.context.width >= 280 &&
        geometry.metrics.width >= 480,
      `${width}: las regiones expanded colisionan o incumplen sus mínimos`,
    )
  }
  for (let step = 0; step < 20; step += 1) {
    if (await action.evaluate((node) => node === document.activeElement)) break
    await page.keyboard.press("Tab")
  }
  check(
    await action.evaluate((node) => node === document.activeElement && node.matches(":focus-visible")),
    `${width}: sin foco visible o no alcanzable por teclado`,
  )
  await page.screenshot({
    path: path.join(OUT, `fermentation-vat-${width}-light.png`),
    fullPage: true,
  })
  observations.push({
    width,
    overflow,
    actionHeight: box?.height ?? null,
    geometry,
    pageErrors: errors,
  })
  check(errors.length === 0, `${width}: errores JS ${errors.join(" | ")}`)
  await context.close()
}

const zoomContext = await browser.newContext({ viewport: { width: 390, height: 780 } })
const zoomPage = await zoomContext.newPage()
await zoomPage.goto(URL, { waitUntil: "networkidle" })
await zoomPage.evaluate(() => {
  document.documentElement.style.fontSize = "200%"
})
const zoomOverflow = await zoomPage.evaluate(
  () => document.documentElement.scrollWidth > document.documentElement.clientWidth,
)
check(!zoomOverflow, "390 a texto 200%: overflow horizontal")
await zoomPage.screenshot({
  path: path.join(OUT, "fermentation-vat-390-zoom200-approx.png"),
  fullPage: true,
})
await zoomContext.close()
await browser.close()

await writeFile(
  path.join(OUT, "resultado.json"),
  `${JSON.stringify({ url: URL, observations, zoom200ApproxOverflow: zoomOverflow, failures }, null, 2)}\n`,
)
if (failures.length) {
  console.error(failures.join("\n"))
  process.exit(1)
}
console.log(`PASS · ${viewports.join(" / ")} · evidencia ${OUT}`)
