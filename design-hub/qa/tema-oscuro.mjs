// Tema oscuro (DUDAS #16, cerrado 2026-09-28): comprueba que tokens.css aplica
// el tema por preferencia del sistema y por data-theme, y mide el contraste
// de las mismas muestras que r06 en Maguey y Horneado. Sin escrituras: el
// error se provoca con una respuesta 400 interceptada.
//   node design-hub/qa/tema-oscuro.mjs   (con `web` corriendo)
import { chromium } from "@playwright/test"
import { writeFileSync } from "node:fs"
import { mkdir } from "node:fs/promises"
import path from "node:path"
import { fileURLToPath } from "node:url"

const AQUI = path.dirname(fileURLToPath(import.meta.url))
const RAIZ = path.join(AQUI, "..", "..")
const WEB = process.env.WEB_URL ?? "http://localhost:5173"
const OUT = path.join(RAIZ, "design-hub", "qa", "evidence", "tema-oscuro")
const SLUG = "cuatro-vientos"
const RPC = "**/rest/v1/rpc/registrar_recepcion_maguey"
const checks = []
const ok = (c, m) => checks.push({ ok: Boolean(c), m })
await mkdir(OUT, { recursive: true })
const browser = await chromium.launch()
const errores = []

const lum = (c) => {
  const [r, g, b] = c.map((v) => v / 255).map((v) => (v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4))
  return 0.2126 * r + 0.7152 * g + 0.0722 * b
}
const ratio = (a, b) => {
  const [l1, l2] = [lum(a), lum(b)].sort((x, y) => y - x)
  return Math.round(((l1 + 0.05) / (l2 + 0.05)) * 100) / 100
}
const MUESTRAS = [
  ["texto principal", ".mh-identity h3", "texto"],
  ["texto secundario", ".mh-identity p", "texto"],
  ["estado (status)", ".mh-surface [role=status]", "texto"],
  ["leyenda", ".mh-form legend", "texto"],
  ["etiqueta", ".mh-form label", "texto"],
  ["error", ".mh-error", "texto"],
  ["botón primario", ".boton--primary", "texto"],
  ["botón secundario", ".mh-heading .boton:not(.boton--primary)", "texto"],
  ["chip on", ".chip--on", "texto"],
  ["chip off", ".chip--off", "texto"],
  ["navegación", 'nav[aria-label="Navegación principal"] a:not([aria-current])', "texto"],
  ["navegación activa", 'nav[aria-label="Navegación principal"] a[aria-current]', "texto"],
  ["empresa (cabecera nav)", ".lat__nombre", "texto"],
  ["borde de campo", ".mh-form input", "borde"],
  ["borde de botón", ".mh-heading .boton:not(.boton--primary)", "borde"],
  ["anillo de foco", ".boton--primary:focus-visible", "foco"],
]
const MUESTRAS_HORNEADO = [
  ["chip partial", ".chip--partial", "texto"],
  ["botón quiet", ".boton--quiet", "texto"],
]
const medir = (muestras) => {
  const parse = (s) => {
    const m = /rgba?\(([^)]+)\)/.exec(s)
    if (!m) return null
    const p = m[1].split(",").map((x) => parseFloat(x))
    return { rgb: p.slice(0, 3), a: p[3] ?? 1 }
  }
  const fondo = (el) => {
    for (let n = el; n; n = n.parentElement) {
      const c = parse(getComputedStyle(n).backgroundColor)
      if (c && c.a > 0) return c.rgb
    }
    return parse(getComputedStyle(document.documentElement).backgroundColor)?.rgb ?? [255, 255, 255]
  }
  return muestras.map(([nombre, sel, tipo]) => {
    const el = document.querySelector(sel)
    if (!el) return { nombre, sel, ausente: true }
    const cs = getComputedStyle(el)
    const fg = tipo === "texto" ? parse(cs.color) : tipo === "borde" ? parse(cs.borderTopColor) : parse(cs.outlineColor)
    const bg = tipo === "foco" ? fondo(el.parentElement) : tipo === "borde" && parse(cs.backgroundColor)?.a ? parse(cs.backgroundColor).rgb : fondo(el)
    const px = parseFloat(cs.fontSize),
      w = parseInt(cs.fontWeight)
    const grande = px >= 24 || (px >= 18.66 && w >= 700)
    return { nombre, fg: fg?.rgb, bg, fontSize: px, minimo: tipo === "texto" ? (grande ? 3 : 4.5) : 3 }
  })
}
const evaluar = (filas, etiqueta) => {
  for (const f of filas) {
    if (f.ausente) continue
    f.ratio = ratio(f.fg, f.bg)
    ok(f.ratio >= f.minimo, `${etiqueta} · ${f.nombre}: ${f.ratio}:1 ≥ ${f.minimo}:1`)
  }
  return filas
}

async function sesion(opciones, extraStorage) {
  const ctx = await browser.newContext({ viewport: { width: 1024, height: 800 }, ...opciones })
  const page = await ctx.newPage()
  page.on("pageerror", (e) => errores.push(String(e)))
  if (extraStorage) await ctx.addInitScript((s) => Object.entries(s).forEach(([k, v]) => localStorage.setItem(k, v)), extraStorage)
  await page.goto(`${WEB}/e/${SLUG}`)
  await page.locator("input[name=usuario]").fill("aurelia")
  await page.locator("input[name=contrasena]").fill("aurelia-2026")
  await page.locator("button[type=submit]").click()
  await page.waitForURL("**/inicio", { timeout: 20000 })
  return { ctx, page }
}
const fondoHtml = (page) =>
  page.evaluate(() => ({
    scheme: getComputedStyle(document.documentElement).colorScheme,
    fondo: getComputedStyle(document.body).backgroundColor,
    superficie: getComputedStyle(document.documentElement).getPropertyValue("--surface").trim(),
    theme: document.documentElement.dataset.theme ?? null,
  }))
async function destino(page, d) {
  await page.goto(`${WEB}/e/${SLUG}/${d}`)
  await page.getByRole("heading", { name: d === "maguey" ? "Maguey" : "Horneado", exact: true }).waitFor({ timeout: 20000 })
  await page.locator(".mh-loading").waitFor({ state: "detached", timeout: 20000 })
}
const evidencia = {}

// 1. Preferencia del sistema: oscuro
const osc = await sesion({ colorScheme: "dark" })
evidencia.sistemaOscuro = await fondoHtml(osc.page)
ok(evidencia.sistemaOscuro.scheme === "dark" && evidencia.sistemaOscuro.superficie === "#1c1b23", "sistema oscuro: color-scheme dark y --surface oscura")
await destino(osc.page, "maguey")
await osc.page.route(RPC, (rt) => rt.fulfill({ status: 400, contentType: "application/json", body: JSON.stringify({ code: "P0001", message: "NO_PERMITIDO: prueba de contraste" }) }))
await osc.page.getByRole("button", { name: "Registrar recepción" }).first().click()
await osc.page.getByLabel("Kilos (obligatorio)").fill("2")
await osc.page.getByRole("button", { name: /2 kg · Registrar recepción/ }).click()
await osc.page.locator(".mh-error").waitFor()
await osc.page.locator(".mh-heading h1").focus()
for (let i = 0; i < 12; i++) {
  await osc.page.keyboard.press("Tab")
  if (await osc.page.evaluate(() => document.activeElement?.classList.contains("boton--primary"))) break
}
evidencia.contrasteMaguey = evaluar(await osc.page.evaluate(medir, MUESTRAS), "oscuro maguey")
await osc.page.screenshot({ path: path.join(OUT, "oscuro-maguey-error-1024.png") })
await osc.page.getByRole("button", { name: "Volver sin borrar" }).first().click()
await osc.page.screenshot({ path: path.join(OUT, "oscuro-maguey-lista-1024.png") })
await destino(osc.page, "horneado")
evidencia.contrasteHorneado = evaluar(await osc.page.evaluate(medir, MUESTRAS_HORNEADO), "oscuro horneado")
await osc.page.screenshot({ path: path.join(OUT, "oscuro-horneado-1024.png") })
await osc.page.getByRole("button", { name: "Ver detalle" }).first().click()
await osc.page.getByRole("dialog").waitFor()
await osc.page.screenshot({ path: path.join(OUT, "oscuro-capa-1024.png") })
await osc.page.keyboard.press("Escape")
await osc.page.setViewportSize({ width: 390, height: 780 })
await destino(osc.page, "horneado")
await osc.page.screenshot({ path: path.join(OUT, "oscuro-horneado-390.png") })
await osc.page.goto(`${WEB}/e/${SLUG}/inicio`)
await osc.page.getByRole("heading").first().waitFor()
await osc.page.screenshot({ path: path.join(OUT, "oscuro-inicio-390.png") })
// 1b. Sistema oscuro pero elección manual «claro»
const claroManual = await sesion({ colorScheme: "dark" }, { "pulz:tema": "claro" })
evidencia.sistemaOscuroManualClaro = await fondoHtml(claroManual.page)
ok(evidencia.sistemaOscuroManualClaro.theme === "light" && evidencia.sistemaOscuroManualClaro.superficie === "#f8f8fa", "sistema oscuro + manual claro: data-theme=light gana y la superficie es clara")
await claroManual.ctx.close()
await osc.ctx.close()

// 2. Sistema claro, elección manual «oscuro»
const oscManual = await sesion({ colorScheme: "light" }, { "pulz:tema": "oscuro" })
evidencia.sistemaClaroManualOscuro = await fondoHtml(oscManual.page)
ok(evidencia.sistemaClaroManualOscuro.theme === "dark" && evidencia.sistemaClaroManualOscuro.superficie === "#1c1b23", "sistema claro + manual oscuro: data-theme=dark aplica la superficie oscura")
await destino(oscManual.page, "maguey")
await oscManual.page.screenshot({ path: path.join(OUT, "manual-oscuro-maguey-1024.png") })
await oscManual.ctx.close()
// 3. Sistema claro sin elección: sigue claro
const claro = await sesion({ colorScheme: "light" })
evidencia.sistemaClaro = await fondoHtml(claro.page)
ok(evidencia.sistemaClaro.scheme === "light" && evidencia.sistemaClaro.superficie === "#f8f8fa", "sistema claro: sin cambios")
await claro.ctx.close()
await browser.close()

const fallos = checks.filter((c) => !c.ok).map((c) => c.m)
const resumen = { fecha: new Date().toISOString(), status: fallos.length || errores.length ? "FAIL" : "PASS", checks: checks.length, fallos, erroresDePagina: errores, evidencia }
writeFileSync(path.join(OUT, "tema-oscuro.json"), JSON.stringify(resumen, null, 2))
console.log(JSON.stringify({ status: resumen.status, checks: checks.length, fallos, errores }, null, 2))
process.exit(fallos.length || errores.length ? 1 : 0)
