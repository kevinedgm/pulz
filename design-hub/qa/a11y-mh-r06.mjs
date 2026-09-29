// r06 Maguey/Horneado · checklist 14.03 y bloque 16 (16.02, 16.05, 16.06,
// 16.08, 16.09) con Playwright sobre el SHELL AUTENTICADO del dev server y el
// proyecto alojado. Escrituras reales, todas por teclado (16.02): recepción de
// 1 kg, horneada abierta con ese kilo, cierre con 0.5 kg y cocido previo de
// 0.25 kg en Cuatro Vientos; se retiran con `supabase db reset --linked`.
// Lo que NO es real y se declara: (a) en 16.09 se interceptan las lecturas
// REST de lots/solid_lot_balances/maguey_receptions para inyectar folios y
// notas largas, cantidades enormes y 120 lotes de paginación (solo render);
// (b) los errores largos y de forced-colors se provocan con una respuesta
// 400 P0001 interceptada (nada llega al servidor). El zoom 200 % se emula
// como lo hace el navegador (viewport CSS a la mitad + DPR 2), forced-colors
// y reduced-motion con la emulación de Chromium. Ningún lector de pantalla ni
// hardware táctil participa: 16.03, 16.04 y 16.07 siguen abiertos.
//   node design-hub/qa/a11y-mh-r06.mjs   (con `web` corriendo)
import { chromium } from "@playwright/test"
import { writeFileSync } from "node:fs"
import { mkdir } from "node:fs/promises"
import path from "node:path"
import { fileURLToPath } from "node:url"

const AQUI = path.dirname(fileURLToPath(import.meta.url))
const RAIZ = path.join(AQUI, "..", "..")
const WEB = process.env.WEB_URL ?? "http://localhost:5173"
const OUT = path.join(RAIZ, "design-hub", "lab", "maguey-horneado", "r06", "evidence")
const SLUG = "cuatro-vientos"
const RPC = "**/rest/v1/rpc/registrar_recepcion_maguey"
const checks = []
const ok = (c, m) => checks.push({ ok: Boolean(c), m })
const paso = (m) => console.log(`· ${m}`)
const evidencia = {}
const errores = []

await mkdir(OUT, { recursive: true })
const browser = await chromium.launch()

// ---------- utilidades ----------
const foto = (page, n) => page.screenshot({ path: path.join(OUT, `${n}.png`), fullPage: false })
async function entrar(page) {
  await page.goto(`${WEB}/e/${SLUG}`)
  await page.locator("input[name=usuario]").fill("aurelia")
  await page.locator("input[name=contrasena]").fill("aurelia-2026")
  await page.locator("button[type=submit]").click()
  await page.waitForURL("**/inicio", { timeout: 20000 })
}
async function destino(page, d) {
  await page.goto(`${WEB}/e/${SLUG}/${d}`)
  await page
    .getByRole("heading", { name: d === "maguey" ? "Maguey" : "Horneado", exact: true })
    .waitFor({ timeout: 20000 })
  await page.locator(".mh-loading").waitFor({ state: "detached", timeout: 20000 })
}
async function nuevoContexto(opciones = {}, estado) {
  const ctx = await browser.newContext({ viewport: { width: 1024, height: 800 }, ...opciones })
  const page = await ctx.newPage()
  page.on("pageerror", (e) => errores.push(String(e)))
  if (estado) {
    await ctx.addInitScript((s) => {
      for (const [k, v] of Object.entries(s)) localStorage.setItem(k, v)
    }, estado)
  } else await entrar(page)
  return { ctx, page }
}
// Elemento activo con su nombre accesible aproximado y si el foco es visible.
const activo = (page) =>
  page.evaluate(() => {
    const el = document.activeElement
    if (!el || el === document.body) return { tag: "body", nombre: "", visible: false }
    const label = el.labels?.[0]?.textContent ?? ""
    const byId = el.getAttribute("aria-labelledby")
    const nombre = (
      el.getAttribute("aria-label") ||
      (byId ? document.getElementById(byId)?.textContent : "") ||
      label ||
      el.textContent ||
      ""
    )
      .replace(/\s+/g, " ")
      .trim()
    const cs = getComputedStyle(el)
    const visible =
      (cs.outlineStyle !== "none" && parseFloat(cs.outlineWidth) > 0) || cs.boxShadow !== "none"
    return {
      tag: el.tagName.toLowerCase(),
      tipo: el.getAttribute("type") ?? el.getAttribute("role") ?? undefined,
      nombre: nombre.slice(0, 80),
      clase: nombre ? undefined : el.className,
      visible,
      enDialogo: !!el.closest("[role=dialog]"),
    }
  })
// Tab hasta llegar a un control cuyo nombre cumpla `re`; devuelve el rastro.
async function tabHasta(page, re, max = 60, shift = false) {
  const rastro = []
  for (let i = 0; i < max; i++) {
    await page.keyboard.press(shift ? "Shift+Tab" : "Tab")
    const a = await activo(page)
    rastro.push(a)
    if (re.test(a.nombre)) return { rastro, a }
  }
  throw new Error(`No se alcanzó ${re} por teclado; rastro: ${rastro.map((r) => r.nombre).join(" › ")}`)
}
const focoDelResultado = (page) =>
  page.waitForFunction(() => document.activeElement?.classList.contains("mh-result"), null, {
    timeout: 20000,
  })
const sinDesborde = (page) =>
  page.evaluate(() => {
    const d = document.scrollingElement
    return { scroll: d.scrollWidth, cliente: d.clientWidth, ok: d.scrollWidth <= d.clientWidth }
  })

// ---------- sesión base ----------
paso("Sesión de Aurelia en Cuatro Vientos")
const base = await nuevoContexto()
const estado = await base.page.evaluate(() => Object.fromEntries(Object.entries(localStorage)))

// ---------- 14.03 · etiqueta «Fermentación» en la navegación del shell ----------
paso("14.03 · «Fermentación» en la navegación real a 600/768/1023/1024/1440")
evidencia["14.03"] = []
for (const ancho of [600, 768, 1023, 1024, 1440]) {
  await base.page.setViewportSize({ width: ancho, height: 900 })
  await destino(base.page, "horneado")
  const m = await base.page.evaluate(() => {
    const a = document.querySelector('nav[aria-label="Navegación principal"] a[aria-label="Fermentación"]')
    const span = a?.querySelector("span")
    const nav = a?.closest("nav")
    const r = span?.getBoundingClientRect()
    const lineas = span ? Math.round(r.height / parseFloat(getComputedStyle(span).lineHeight)) : 0
    return {
      nav: nav?.className ?? null,
      rail: nav ? nav.getBoundingClientRect().width : null,
      texto: span?.textContent ?? null,
      lineas,
      recortado: span ? span.scrollWidth > span.clientWidth + 1 : null,
      overflow: a ? getComputedStyle(a).overflow : null,
      inset: nav ? getComputedStyle(nav).paddingInlineStart : null,
    }
  })
  const desborde = await sinDesborde(base.page)
  evidencia["14.03"].push({ ancho, ...m, pagina: desborde })
  ok(m.texto?.replaceAll("­", "") === "Fermentación", `14.03 @${ancho}: la etiqueta conserva el nombre completo`)
  ok(m.recortado === false, `14.03 @${ancho}: el texto no queda recortado en el rail`)
  ok(desborde.ok, `14.03 @${ancho}: sin desplazamiento horizontal del documento`)
  if ([600, 768, 1023].includes(ancho)) await foto(base.page, `14-03-fermentacion-${ancho}`)
}

// ---------- 16.02 · recorridos completos por teclado ----------
paso("16.02 · recepción por teclado")
const page = base.page
await page.setViewportSize({ width: 1024, height: 800 })
const kb = (evidencia["16.02"] = {})
await destino(page, "maguey")
let r = await tabHasta(page, /^Registrar recepción$/)
await page.keyboard.press("Enter")
let a = await activo(page)
kb.recepcion = { hastaPrimaria: r.rastro.map((x) => x.nombre), alEntrar: a }
ok(a.tag === "h1" && a.nombre === "Registrar recepción", "16.02 recepción: al entrar el foco va al título")
r = await tabHasta(page, /^Kilos \(obligatorio\)/)
kb.recepcion.desdeTitulo = r.rastro.map((x) => x.nombre)
ok(r.rastro.length <= 2, "16.02 recepción: desde el título, Kilos llega en ≤2 Tab (antes solo «Volver sin borrar» de la cabecera)")
await page.keyboard.type("1")
r = await tabHasta(page, /1 kg · Registrar recepción/)
kb.recepcion.orden = r.rastro.map((x) => `${x.tag}${x.tipo ? `[${x.tipo}]` : ""}: ${x.nombre}`)
kb.recepcion.focoVisible = r.rastro.every((x) => x.visible)
ok(kb.recepcion.focoVisible, "16.02 recepción: todas las paradas tienen foco visible")
await page.keyboard.press("Enter")
await focoDelResultado(page)
a = await activo(page)
kb.recepcion.resultado = a
ok(/^Recepción registrada · 1 kg/.test(a.nombre), "16.02 recepción: el foco aterriza en el resultado")
await foto(page, "16-02-recepcion-resultado")

paso("16.02 · apertura con revisión y vuelta por teclado")
await destino(page, "horneado")
r = await tabHasta(page, /^Abrir horneada$/)
await page.keyboard.press("Enter")
a = await activo(page)
kb.apertura = { alEntrar: a }
ok(a.tag === "h1" && a.nombre === "Abrir horneada", "16.02 apertura: el foco va al título")
r = await tabHasta(page, /^Horno$/)
await page.keyboard.type("Horno 1")
let horno = await page.evaluate(() => document.activeElement.value)
kb.apertura.hornoPorTeclado = !!horno
if (!horno) {
  await page.locator("select").first().selectOption({ label: "Horno 1" })
  kb.apertura.hornoMetodo = "selectOption (typeahead no aplicó)"
} else kb.apertura.hornoMetodo = "typeahead del select"
r = await tabHasta(page, /^Kilos de /)
await page.keyboard.type("1")
r = await tabHasta(page, /^Revisar Horno 1 con 1 kg$/)
kb.apertura.orden = r.rastro.map((x) => `${x.tag}${x.tipo ? `[${x.tipo}]` : ""}: ${x.nombre}`)
kb.apertura.focoVisible = r.rastro.every((x) => x.visible)
ok(kb.apertura.focoVisible, "16.02 apertura: foco visible en todas las paradas")
await page.keyboard.press("Enter")
await page.waitForFunction(() => document.activeElement?.tagName === "H2")
a = await activo(page)
kb.apertura.revision = a
ok(/^Revisar carga de Horno 1/.test(a.nombre), "16.02 apertura: la revisión enfoca su título")
r = await tabHasta(page, /^Volver a cantidades$/)
await page.keyboard.press("Enter")
await page.waitForFunction(() => document.activeElement?.tagName === "SELECT")
a = await activo(page)
kb.apertura.vuelta = a
ok(a.tag === "select", "16.02 apertura: al volver, el foco regresa al formulario (horno)")
r = await tabHasta(page, /^Revisar Horno 1 con 1 kg$/)
await page.keyboard.press("Enter")
r = await tabHasta(page, /^Abrir Horno 1 con 1 kg$/)
await page.keyboard.press("Enter")
await focoDelResultado(page)
a = await activo(page)
kb.apertura.resultado = a
ok(/^Horneada abierta · 1 kg/.test(a.nombre), "16.02 apertura: resultado enfocado")
await foto(page, "16-02-apertura-resultado")

paso("16.02 · cierre en capa: contención, Escape, retorno y envío")
await page.getByRole("button", { name: "Cerrar horneada" }).first().waitFor({ timeout: 20000 })
r = await tabHasta(page, /^Cerrar horneada$/)
const disparador = r.a
await page.keyboard.press("Enter")
await page.getByRole("dialog").waitFor()
a = await activo(page)
kb.cierre = { alAbrir: a }
ok(a.enDialogo && /^Kilos cocidos/.test(a.nombre), "16.02 cierre: el foco entra al primer campo de la capa")
const vuelta = []
for (let i = 0; i < 14; i++) {
  await page.keyboard.press("Tab")
  vuelta.push(await activo(page))
}
kb.cierre.cicloTab = vuelta.map((x) => `${x.tag}: ${x.nombre}`)
ok(vuelta.every((x) => x.enDialogo), "16.02 cierre: 14 Tab seguidos nunca salen de la capa (sin fuga)")
ok(vuelta.some((x) => /^Kilos cocidos/.test(x.nombre)), "16.02 cierre: el ciclo vuelve al primer campo (envuelve)")
await page.keyboard.press("Shift+Tab")
a = await activo(page)
ok(a.enDialogo, "16.02 cierre: Shift+Tab también queda contenido")
await page.keyboard.press("Escape")
await page.getByRole("dialog").waitFor({ state: "hidden" })
a = await activo(page)
kb.cierre.trasEscape = a
ok(a.nombre === disparador.nombre, "16.02 cierre: Escape devuelve el foco al disparador")
await page.keyboard.press("Enter")
await page.getByRole("dialog").waitFor()
await page.keyboard.type("0.5")
r = await tabHasta(page, /^Cerrar con 0.5 kg de cocido$/)
kb.cierre.orden = r.rastro.map((x) => `${x.tag}${x.tipo ? `[${x.tipo}]` : ""}: ${x.nombre}`)
ok(r.rastro.every((x) => x.visible), "16.02 cierre: foco visible en la capa")
await page.keyboard.press("Enter")
await focoDelResultado(page)
a = await activo(page)
kb.cierre.resultado = a
ok(/^Horneada cerrada · 0.5 kg/.test(a.nombre), "16.02 cierre: resultado enfocado tras cerrar la capa")
ok((await page.getByRole("dialog").count()) === 0, "16.02 cierre: la capa se cerró sola al confirmar")
await foto(page, "16-02-cierre-resultado")

paso("16.02 · cocido que ya tenía")
r = await tabHasta(page, /^Cocido que ya tenía$/)
await page.keyboard.press("Enter")
await page.getByRole("dialog").waitFor()
a = await activo(page)
ok(a.enDialogo && /^Kilos cocidos/.test(a.nombre), "16.02 cocido: foco inicial en Kilos cocidos")
await page.keyboard.type("0.25")
r = await tabHasta(page, /^Registrar 0.25 kg de cocido$/)
kb.cocido = { orden: r.rastro.map((x) => `${x.tag}: ${x.nombre}`) }
await page.keyboard.press("Enter")
await focoDelResultado(page)
a = await activo(page)
kb.cocido.resultado = a
ok(/^Cocido registrado · 0.25 kg/.test(a.nombre), "16.02 cocido: resultado enfocado")

paso("16.02 · detalle y retorno")
await destino(page, "maguey")
r = await tabHasta(page, /^Ver detalle$/)
await page.keyboard.press("Enter")
await page.getByRole("dialog").waitFor()
a = await activo(page)
kb.detalle = { alAbrir: a, titulo: await page.getByRole("dialog").getByRole("heading").first().textContent() }
ok(a.enDialogo, "16.02 detalle: el foco entra a la capa")
await page.keyboard.press("Escape")
await page.getByRole("dialog").waitFor({ state: "hidden" })
a = await activo(page)
kb.detalle.trasEscape = a
ok(a.nombre === "Ver detalle", "16.02 detalle: Escape regresa a «Ver detalle»")

paso("16.02 · Más (compact) y navegación desde la capa")
await page.setViewportSize({ width: 390, height: 780 })
await destino(page, "horneado")
r = await tabHasta(page, /^Más$/)
await page.keyboard.press("Enter")
await page.getByRole("dialog", { name: "Más" }).waitFor()
a = await activo(page)
kb.mas = { alAbrir: a, hastaMas: r.rastro.map((x) => x.nombre) }
ok(a.enDialogo, "16.02 Más: el foco entra a la capa")
await page.keyboard.press("Escape")
await page.getByRole("dialog").waitFor({ state: "hidden" })
a = await activo(page)
kb.mas.trasEscape = a
ok(a.nombre === "Más", "16.02 Más: Escape devuelve el foco a «Más»")
await page.keyboard.press("Enter")
await page.getByRole("dialog", { name: "Más" }).waitFor()
r = await tabHasta(page, /^Maguey$/)
await page.keyboard.press("Enter")
await page.waitForURL("**/maguey")
await page.getByRole("dialog").waitFor({ state: "hidden" })
kb.mas.navego = page.url()
ok(/\/maguey$/.test(page.url()), "16.02 Más: Enter en «Maguey» navega y cierra la capa")
await foto(page, "16-02-mas-compact")

// ---------- 16.08 · contraste (claro/oscuro) y movimiento ----------
paso("16.08 · contraste con colores computados, claro y oscuro")
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
  ["leyenda de formulario", ".mh-form legend", "texto"],
  ["etiqueta de campo", ".mh-form label", "texto"],
  ["error", ".mh-error", "texto"],
  ["botón primario", ".boton--primary", "texto"],
  ["botón secundario", ".mh-heading .boton:not(.boton--primary)", "texto"],
  ["botón quiet", ".boton--quiet", "texto"],
  ["chip de estado", ".mh-state", "texto"],
  ["ítem de navegación", 'nav[aria-label="Navegación principal"] a:not([aria-current])', "texto"],
  ["ítem activo de navegación", 'nav[aria-label="Navegación principal"] a[aria-current]', "texto"],
  ["borde de campo", ".mh-form input", "borde"],
  ["borde de botón", ".mh-heading .boton:not(.boton--primary)", "borde"],
  ["anillo de foco", ".boton--primary:focus-visible", "foco"],
]
const MUESTRAS_HORNEADO = [
  ["chip parcial (horneada abierta)", ".chip--partial", "texto"],
  ["chip apagado (cerrada)", ".chip--off", "texto"],
  ["borde de botón en fila", ".mh-row .boton--secondary", "borde"],
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
      return [255, 255, 255]
    }
    return muestras.map(([nombre, sel, tipo]) => {
      const el = document.querySelector(sel)
      if (!el) return { nombre, sel, ausente: true }
      const cs = getComputedStyle(el)
      const fg =
        tipo === "texto" ? parse(cs.color) : tipo === "borde" ? parse(cs.borderTopColor) : parse(cs.outlineColor)
      const bg = tipo === "foco" ? fondo(el.parentElement) : tipo === "borde" ? (parse(cs.backgroundColor)?.a ? parse(cs.backgroundColor).rgb : fondo(el)) : fondo(el)
      const px = parseFloat(cs.fontSize),
        w = parseInt(cs.fontWeight)
      const grande = px >= 24 || (px >= 18.66 && w >= 700)
      return {
        nombre,
        sel,
        tipo,
        fg: fg?.rgb,
        bg,
        fontSize: px,
        fontWeight: w,
        minimo: tipo === "texto" ? (grande ? 3 : 4.5) : 3,
        extra: tipo === "borde" ? `${cs.borderTopWidth} ${cs.borderTopStyle}` : tipo === "foco" ? `${cs.outlineWidth} ${cs.outlineStyle}` : undefined,
      }
    })
}
async function contraste(pg, tema) {
  await destino(pg, "maguey")
  await pg.route(RPC, (rt) =>
    rt.fulfill({ status: 400, contentType: "application/json", body: JSON.stringify({ code: "P0001", message: "NO_PERMITIDO: prueba de contraste" }) }),
  )
  await pg.getByRole("button", { name: "Registrar recepción" }).first().click()
  await pg.getByLabel("Kilos (obligatorio)").fill("2")
  await pg.getByRole("button", { name: /2 kg · Registrar recepción/ }).click()
  await pg.locator(".mh-error").waitFor()
  // El anillo de foco solo aparece con :focus-visible: se llega por teclado.
  await pg.locator(".mh-heading h1").focus()
  await tabHasta(pg, /Registrar recepción$/)
  const filas = await pg.evaluate(medir, MUESTRAS)
  for (const f of filas) {
    if (f.ausente) {
      f.nota = "no presente en esta vista"
      continue
    }
    f.ratio = ratio(f.fg, f.bg)
    f.pasa = f.ratio >= f.minimo
    ok(f.pasa, `16.08 ${tema} · ${f.nombre}: ${f.ratio}:1 ≥ ${f.minimo}:1`)
  }
  await pg.unroute(RPC)
  await foto(pg, `16-08-contraste-${tema}`)
  await destino(pg, "horneado")
  const extra = await pg.evaluate(medir, MUESTRAS_HORNEADO)
  for (const f of extra) {
    if (f.ausente) {
      f.nota = "no presente en esta vista"
      continue
    }
    f.ratio = ratio(f.fg, f.bg)
    f.pasa = f.ratio >= f.minimo
    ok(f.pasa, `16.08 ${tema} · ${f.nombre}: ${f.ratio}:1 ≥ ${f.minimo}:1`)
  }
  return [...filas, ...extra]
}
await page.setViewportSize({ width: 1024, height: 800 })
evidencia["16.08"] = { claro: await contraste(page, "claro") }
const oscuro = await nuevoContexto({ colorScheme: "dark" }, estado)
evidencia["16.08"].oscuro = await contraste(oscuro.page, "oscuro")
await oscuro.ctx.close()

paso("16.08 · movimiento: transiciones con y sin prefers-reduced-motion")
async function movimiento(pg) {
  await destino(pg, "maguey")
  await pg.getByRole("button", { name: "Ver detalle" }).first().click()
  await pg.getByRole("dialog").waitFor()
  await pg.waitForTimeout(400)
  return pg.evaluate(() => {
    const dlg = document.querySelector("[role=dialog]")
    const cand = [dlg, dlg?.parentElement, ...document.querySelectorAll(".boton, nav, .mh-row, .mh-state, input, select")]
    const con = []
    for (const el of cand) {
      if (!el) continue
      const cs = getComputedStyle(el)
      const t = cs.transitionDuration.split(",").map((x) => parseFloat(x)).filter((x) => x > 0)
      const an = parseFloat(cs.animationDuration)
      if (t.length || an > 0)
        con.push({ el: `${el.tagName.toLowerCase()}.${[...el.classList].slice(0, 2).join(".")}`, transition: cs.transitionDuration, property: cs.transitionProperty, animation: cs.animationDuration })
    }
    return { revisados: cand.filter(Boolean).length, conMovimiento: con, reduceMotion: matchMedia("(prefers-reduced-motion: reduce)").matches }
  })
}
const movNormal = await movimiento(page)
const reducido = await nuevoContexto({ reducedMotion: "reduce" }, estado)
const movReducido = await movimiento(reducido.page)
await reducido.ctx.close()
evidencia["16.08"].movimiento = { normal: movNormal, reducido: movReducido }
ok(movReducido.reduceMotion, "16.08 movimiento: la emulación reduced-motion está activa")
ok(movReducido.conMovimiento.length === 0, `16.08 movimiento: con reduced-motion ninguna transición/animación queda activa (normal tenía ${movNormal.conMovimiento.length})`)

// ---------- 16.06 · forced-colors ----------
paso("16.06 · forced-colors activo")
const fc = await nuevoContexto({ forcedColors: "active" }, estado)
await destino(fc.page, "maguey")
await fc.page.route(RPC, (rt) =>
  rt.fulfill({ status: 400, contentType: "application/json", body: JSON.stringify({ code: "P0001", message: "NO_PERMITIDO: prueba forced-colors" }) }),
)
await fc.page.keyboard.press("Tab")
await tabHasta(fc.page, /^Registrar recepción$/)
const fcFoco = await activo(fc.page)
const fcNav = await fc.page.evaluate(() => {
  const act = document.querySelector('nav[aria-label="Navegación principal"] a[aria-current]')
  const otro = document.querySelector('nav[aria-label="Navegación principal"] a:not([aria-current])')
  const st = (el) => {
    const cs = getComputedStyle(el)
    return { fontWeight: cs.fontWeight, borde: `${cs.borderInlineStartWidth || cs.borderLeftWidth} ${cs.borderLeftStyle} ${cs.borderLeftColor}`, bordeAbajo: `${cs.borderBottomWidth} ${cs.borderBottomStyle}`, color: cs.color, fondo: cs.backgroundColor, forced: cs.forcedColorAdjust }
  }
  return { activo: act && st(act), otro: otro && st(otro), forcedColors: matchMedia("(forced-colors: active)").matches }
})
await fc.page.keyboard.press("Enter")
await fc.page.getByLabel("Kilos (obligatorio)").fill("2")
const fcCampo = await fc.page.evaluate(() => {
  const i = document.querySelector(".mh-form input")
  const b = document.querySelector(".mh-heading .boton:not(.boton--primary)")
  const st = (el) => {
    const cs = getComputedStyle(el)
    return { borde: `${cs.borderTopWidth} ${cs.borderTopStyle} ${cs.borderTopColor}`, color: cs.color, fondo: cs.backgroundColor }
  }
  return { campo: st(i), boton: st(b) }
})
await fc.page.getByRole("button", { name: /2 kg · Registrar recepción/ }).click()
await fc.page.locator(".mh-error").waitFor()
const fcError = await fc.page.evaluate(() => {
  const e = document.querySelector(".mh-error")
  const cs = getComputedStyle(e)
  return { texto: e.textContent.trim().slice(0, 60), color: cs.color, fondo: cs.backgroundColor, role: e.getAttribute("role") }
})
await fc.page.locator(".mh-form input").first().focus()
const fcFocoCampo = await activo(fc.page)
evidencia["16.06"] = { foco: fcFoco, navegacion: fcNav, campo: fcCampo, error: fcError, focoCampo: fcFocoCampo }
ok(fcNav.forcedColors, "16.06: forced-colors reportado activo por el navegador")
ok(fcFoco.visible, "16.06: el foco del botón primario tiene contorno bajo forced-colors")
ok(fcFocoCampo.visible, "16.06: el foco del campo tiene contorno bajo forced-colors")
ok(parseFloat(fcCampo.campo.borde) > 0 && !/none/.test(fcCampo.campo.borde), "16.06: el campo conserva borde")
ok(parseFloat(fcCampo.boton.borde) > 0 && !/none/.test(fcCampo.boton.borde), "16.06: el botón secundario conserva borde")
ok(fcNav.activo && (parseFloat(fcNav.activo.borde) > 0 || parseFloat(fcNav.activo.bordeAbajo) > 0 || parseInt(fcNav.activo.fontWeight) >= 600), "16.06: el destino activo se distingue sin color (borde o peso)")
ok(fcError.role === "alert" && fcError.color !== fcError.fondo, "16.06: el error es un alert con texto visible")
await foto(fc.page, "16-06-forced-colors-error")
await fc.ctx.close()

// ---------- 16.05 · 200 % como lo hace el navegador (viewport/2 + DPR 2) ----------
paso("16.05 · texto al 200 %: 1440, 1024, 768 y 320 CSS px reales")
evidencia["16.05"] = []
for (const [fisico, css] of [
  [1440, 720],
  [1024, 512],
  [768, 384],
  [640, 320],
]) {
  const z = await nuevoContexto({ viewport: { width: css, height: Math.round(css * 0.7) }, deviceScaleFactor: 2 }, estado)
  const p = z.page
  const fila = { ventana: fisico, css, dpr: 2, vistas: {} }
  await destino(p, "maguey")
  fila.vistas.lista = await sinDesborde(p)
  fila.nav = await p.evaluate(() => document.querySelector('nav[aria-label="Navegación principal"]')?.className)
  await p.getByRole("button", { name: "Registrar recepción" }).first().click()
  await p.getByLabel("Kilos (obligatorio)").waitFor()
  fila.vistas.recepcion = await sinDesborde(p)
  await p.locator(".mh-form details summary").click()
  fila.campos = await p.evaluate(() =>
    [...document.querySelectorAll(".mh-form input, .mh-form select, .mh-form button, .mh-form summary")].map((el) => {
      el.scrollIntoView({ block: "center" })
      const r = el.getBoundingClientRect()
      return { nombre: (el.labels?.[0]?.textContent ?? el.textContent ?? "").trim().slice(0, 40), dentro: r.left >= 0 && r.right <= innerWidth + 0.5, alto: Math.round(r.height) }
    }),
  )
  ok(fila.campos.every((c) => c.dentro), `16.05 @${css}css×2: todos los controles del formulario caben en el ancho`)
  ok(fila.campos.every((c) => c.alto >= 44), `16.05 @${css}css×2: controles ≥44 px de alto`)
  await foto(p, `16-05-recepcion-${css}x2`)
  await p.getByRole("button", { name: "Volver sin borrar" }).first().click()
  await p.getByRole("button", { name: "Ver detalle" }).first().click()
  await p.getByRole("dialog").waitFor()
  fila.capa = await p.evaluate(() => {
    const d = document.querySelector("[role=dialog]")
    const r = d.getBoundingClientRect()
    return { ancho: Math.round(r.width), alto: Math.round(r.height), cabe: r.left >= 0 && r.right <= innerWidth + 0.5 && r.top >= 0 && r.bottom <= innerHeight + 0.5, desplazable: d.scrollHeight > d.clientHeight ? getComputedStyle(d).overflowY : "no hace falta" }
  })
  ok(fila.capa.cabe, `16.05 @${css}css×2: la capa de detalle cabe en el viewport`)
  await foto(p, `16-05-capa-${css}x2`)
  await p.keyboard.press("Escape")
  await destino(p, "horneado")
  fila.vistas.horneado = await sinDesborde(p)
  await p.getByRole("button", { name: "Cocido que ya tenía" }).click()
  await p.getByRole("dialog").waitFor()
  fila.capaCocido = await p.evaluate(() => {
    const d = document.querySelector("[role=dialog]")
    const r = d.getBoundingClientRect()
    const btn = d.querySelector("button[type=submit]")
    btn?.scrollIntoView({ block: "center" })
    const b = btn?.getBoundingClientRect()
    return { cabe: r.right <= innerWidth + 0.5 && r.left >= 0, envioVisible: !!b && b.bottom <= innerHeight && b.top >= 0 }
  })
  ok(fila.capaCocido.cabe && fila.capaCocido.envioVisible, `16.05 @${css}css×2: la capa de cocido cabe y su envío es alcanzable`)
  await foto(p, `16-05-cocido-${css}x2`)
  for (const v of Object.values(fila.vistas)) ok(v.ok, `16.05 @${css}css×2: sin desplazamiento horizontal (${v.scroll}/${v.cliente})`)
  evidencia["16.05"].push(fila)
  await z.ctx.close()
}

// ---------- 16.09 · contenido extremo (lecturas interceptadas, sin escrituras) ----------
paso("16.09 · folios/contextos largos, 120 lotes paginados, cantidades enormes, error largo")
const FOLIO = "MAG-2026-09-28-TOBALÁ-SILVESTRE-LOMA-DEL-TORO-SAN-BALTAZAR-GUELAVILA-0001-REPOSICIÓN"
const NOTA = "Piñas de ocho a diez años, cosechadas en luna llena en la loma alta del predio, con capón de un año y transporte en camioneta cerrada; " .repeat(2) + "revisar humedad antes de hornear."
const ERROR_LARGO = "NO_PERMITIDO: " + "el lote indicado pertenece a otra empresa o no tiene saldo suficiente para la operación solicitada; verifica el folio, la fecha de recepción y el proveedor antes de volver a intentar. ".repeat(3)
async function extremos(opciones, etiqueta) {
  const x = await nuevoContexto(opciones, estado)
  const p = x.page
  const fakes = Array.from({ length: 120 }, (_, i) => `00000000-0000-4000-8000-${String(i).padStart(12, "0")}`)
  await p.route(/\/rest\/v1\/(lots|solid_lot_balances|maguey_receptions)\?/, async (rt) => {
    const res = await rt.fetch()
    const json = await res.json()
    const tabla = /rest\/v1\/(\w+)\?/.exec(rt.request().url())[1]
    const i0 = json.findIndex((l) => l.material === "maguey")
    if (tabla === "lots" && i0 >= 0) {
      json[i0] = { ...json[i0], folio: FOLIO, notes: NOTA }
      const op = json[i0].operation_id
      json.push(...fakes.map((id, i) => ({ id, folio: `MAG-PAG-${String(i + 1).padStart(3, "0")}`, material: "maguey", origin: "recepcion", initial_quantity: 123456789.125, notes: "", operation_id: op })))
    } else if (tabla === "solid_lot_balances") json.push(...fakes.map((id) => ({ lot_id: id, remaining_kg: 98765432.5 })))
    else if (tabla === "maguey_receptions") json.push(...fakes.map((id) => ({ lot_id: id, species_id: null, predio_id: null, supplier_id: null, pina_count: 999999, quality_note: "" })))
    await rt.fulfill({ status: 200, contentType: "application/json", body: JSON.stringify(json) })
  })
  await p.route(RPC, (rt) => rt.fulfill({ status: 400, contentType: "application/json", body: JSON.stringify({ code: "P0001", message: ERROR_LARGO }) }))
  await destino(p, "maguey")
  const fila = { etiqueta }
  fila.status = await p.locator(".mh-surface [role=status]").first().textContent()
  const filas = () => p.evaluate(() => [...document.querySelectorAll(".mh-group .mh-list .mh-row")].map((r) => ({ folio: r.querySelector("h3")?.textContent, desborda: r.scrollWidth > r.clientWidth + 1, identidadCabe: r.querySelector(".mh-identity").getBoundingClientRect().right <= r.getBoundingClientRect().right + 0.5, orden: [...r.children].map((c) => ["mh-identity", "mh-data", "mh-state", "mh-actions"].find((k) => c.classList.contains(k)) ?? c.className).join(">") })))
  let lista = await filas()
  fila.visibles = lista.length
  ok(lista.length === 50, `16.09 ${etiqueta}: la lista muestra 50 lotes y pagina el resto`)
  ok(lista.every((r) => !r.desborda && r.identidadCabe), `16.09 ${etiqueta}: ninguna fila desborda ni pierde su bloque de identidad`)
  ok(lista.every((r) => r.orden === "mh-identity>mh-data>mh-state>mh-actions"), `16.09 ${etiqueta}: cada fila conserva identidad › datos › estado › acciones`)
  fila.largo = lista.find((r) => r.folio === FOLIO)
  ok(!!fila.largo, `16.09 ${etiqueta}: el folio de ${FOLIO.length} caracteres se muestra completo`)
  fila.grande = await p.evaluate(() => [...document.querySelectorAll(".mh-data > b")].map((b) => b.textContent).find((t) => /98,765,432\.5 kg/.test(t)))
  ok(!!fila.grande, `16.09 ${etiqueta}: 98,765,432.5 kg se formatea con separadores y decimal`)
  fila.pagina = await sinDesborde(p)
  ok(fila.pagina.ok, `16.09 ${etiqueta}: sin desplazamiento horizontal con 50 filas`)
  await p.locator(".mh-row").first().scrollIntoViewIfNeeded()
  await foto(p, `16-09-folio-largo-${etiqueta}`)
  await p.getByRole("button", { name: "Mostrar siguientes 50 lotes" }).click()
  lista = await filas()
  fila.trasPaginar = lista.length
  ok(lista.length === 100, `16.09 ${etiqueta}: «Mostrar siguientes 50» pasa a 100 filas`)
  await p.getByRole("button", { name: "Registrar recepción" }).first().click()
  await p.getByLabel("Kilos (obligatorio)").fill("123456.789")
  fila.botonGrande = await p.getByRole("button", { name: /Registrar recepción/ }).last().textContent()
  ok(/123,456\.789 kg · Registrar recepción/.test(fila.botonGrande), `16.09 ${etiqueta}: el botón refleja 123,456.789 kg`)
  await p.getByRole("button", { name: /123,456\.789 kg · Registrar recepción/ }).click()
  await p.locator(".mh-error").waitFor()
  fila.error = await p.evaluate(() => {
    const e = document.querySelector(".mh-error")
    e.scrollIntoView({ block: "center" })
    return { caracteres: e.textContent.trim().length, desborda: e.scrollWidth > e.clientWidth + 1, role: e.getAttribute("role") }
  })
  ok(fila.error.caracteres >= ERROR_LARGO.length && !fila.error.desborda, `16.09 ${etiqueta}: el error de ${fila.error.caracteres} caracteres se lee completo y envuelve`)
  fila.paginaError = await sinDesborde(p)
  ok(fila.paginaError.ok, `16.09 ${etiqueta}: sin desplazamiento horizontal con el error largo`)
  await foto(p, `16-09-error-largo-${etiqueta}`)
  await x.ctx.close()
  return fila
}
evidencia["16.09"] = [
  await extremos({ viewport: { width: 1024, height: 800 } }, "1024"),
  await extremos({ viewport: { width: 384, height: 540 }, deviceScaleFactor: 2 }, "384x2"),
]

await base.ctx.close()
await browser.close()

const fallos = checks.filter((c) => !c.ok).map((c) => c.m)
const resumen = {
  fecha: new Date().toISOString(),
  web: WEB,
  proyecto: "ypgeiyorgktshgbzhgfh",
  empresa: SLUG,
  status: fallos.length || errores.length ? "FAIL" : "PASS",
  checks: checks.length,
  fallos,
  erroresDePagina: errores,
  escriturasReales: ["recepción 1 kg", "horneada abierta 1 kg (Horno 1)", "horneada cerrada 0.5 kg", "cocido previo 0.25 kg"],
  noReal: ["16.09: lecturas REST interceptadas (folios/notas largos, 120 lotes, cantidades enormes)", "16.06/16.08/16.09: error 400 P0001 interceptado", "16.05: zoom 200 % = viewport/2 + DPR 2", "16.06 forced-colors y 16.08 reduced-motion: emulación de Chromium"],
  abiertos: ["16.03 touch físico", "16.04 teclado virtual", "16.07 lector de pantalla"],
  checksDetalle: checks,
  evidencia,
}
writeFileSync(path.join(OUT, "a11y-14-03-16.json"), JSON.stringify(resumen, null, 2))
console.log(JSON.stringify({ status: resumen.status, checks: checks.length, fallos, erroresDePagina: errores }, null, 2))
process.exit(fallos.length || errores.length ? 1 : 0)
