// Rasteriza los iconos del manifest desde public/favicon.svg con el Chromium
// de Playwright (mismo método que en Fase 4, sin librerías nuevas). Si cambia
// la marca, se edita el SVG y se corre:
//   node apps/web/scripts/iconos.mjs
// maskable: fondo a sangre (sin radio) y glifo al 72 % dentro de la zona segura.
import { chromium } from "@playwright/test"
import { readFileSync } from "node:fs"
import path from "node:path"
import { fileURLToPath } from "node:url"

const WEB = path.join(path.dirname(fileURLToPath(import.meta.url)), "..")
const svg = readFileSync(path.join(WEB, "public", "favicon.svg"), "utf8")
const maskable = svg
  .replace('rx="20"', 'rx="0"')
  .replace(
    'transform="translate(6 6) scale(0.875)"',
    'transform="translate(13.44 13.44) scale(0.72)"',
  )
const browser = await chromium.launch()
const page = await browser.newPage()
for (const [nombre, px, fuente] of [
  ["pwa-192x192.png", 192, svg],
  ["pwa-512x512.png", 512, svg],
  ["apple-touch-icon-180x180.png", 180, svg],
  ["maskable-512x512.png", 512, maskable],
]) {
  await page.setViewportSize({ width: px, height: px })
  await page.setContent(
    `<style>html,body{margin:0;background:transparent}svg{display:block;width:${px}px;height:${px}px}</style>${fuente}`,
  )
  await page.screenshot({ path: path.join(WEB, "public", "icons", nombre), omitBackground: true })
  console.log(nombre, px)
}
await browser.close()
