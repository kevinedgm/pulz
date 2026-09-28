// Evidencia de la ronda fermentacion/r01 (coco, R3) con Aurelia
// (productora) en Mezcal Cuatro Vientos. En la primera corrida (1440/claro)
// hace escrituras REALES: mide la Tina 2 (modo mínimo, Brix fuera de rango
// → aviso con nota → registrar_medicion por la cola → «enviada»), la ve en
// «Ya medidas hoy», abre el detalle y ANULA esa medición con motivo (la
// Tina 2 vuelve a «toca medir hoy» para las demás corridas). Captura lista,
// detalle, pasos, revisar, guardada, formulación (estado vacío real: no hay
// cocido con saldo) y la capa «tina que ya fermentaba». `db reset --linked`
// deja Cuatro Vientos como la semilla (queda una medición anulada).
//   node design-hub/qa/evidencia-fermentacion.mjs   (con `web` corriendo)
import { chromium } from "@playwright/test"
import { mkdir } from "node:fs/promises"
import path from "node:path"
import { fileURLToPath } from "node:url"

const WEB = process.env.WEB_URL ?? "http://localhost:5173"
const SLUG = "cuatro-vientos"
const OUT = path.join(path.dirname(fileURLToPath(import.meta.url)), "evidence", "fermentacion-r01")
const ANCHOS = [1440, 1024, 768, 390]
const TEMAS = ["light", "dark"]
const fallos = []
const ok = (c, m) => {
  if (!c) fallos.push(m)
}
async function entrar(page) {
  await page.goto(`${WEB}/e/${SLUG}`)
  await page.locator("input[name=usuario]").fill("aurelia")
  await page.locator("input[name=contrasena]").fill("aurelia-2026")
  await page.locator("button[type=submit]").click()
  await page.waitForURL("**/inicio", { timeout: 20000 })
}
async function salir(page) {
  await page
    .getByRole("button", { name: /cuenta|Cuatro Vientos/ })
    .first()
    .click()
  await page.getByRole("button", { name: "Cerrar sesión" }).click()
  await page.waitForURL(`**/e/${SLUG}`)
}

await mkdir(OUT, { recursive: true })
const browser = await chromium.launch()
let primera = true
for (const tema of TEMAS) {
  for (const ancho of ANCHOS) {
    const movil = ancho < 600
    const ctx = await browser.newContext({
      viewport: { width: ancho, height: movil ? 780 : 900 },
      colorScheme: tema,
      isMobile: movil,
      hasTouch: movil,
      deviceScaleFactor: 1,
    })
    const page = await ctx.newPage()
    const errores = []
    page.on("pageerror", (e) => errores.push(String(e)))
    const foto = (n) =>
      page.screenshot({ path: path.join(OUT, `${n}-${ancho}-${tema}.png`), fullPage: false })
    const sinScrollH = async (n) => {
      const [sw, cw] = await page.evaluate(() => [
        document.documentElement.scrollWidth,
        document.documentElement.clientWidth,
      ])
      ok(sw <= cw, `${n} ${ancho}/${tema}: scroll horizontal (${sw} > ${cw})`)
    }

    await entrar(page)
    await page.goto(`${WEB}/e/${SLUG}/fermentacion`)
    await page.getByText(/tinas en uso/).waitFor({ timeout: 20000 })
    await page.getByText("Toca medir hoy").waitFor()
    await foto("lista")
    await sinScrollH("lista")
    // Primaria «Medir»: FAB en compact, botón en la cabecera en ≥600
    const fab = page.locator(".fab", { hasText: "Medir" })
    ok(
      movil ? (await fab.count()) === 1 : (await fab.count()) === 0,
      `lista ${ancho}/${tema}: FAB Medir ${movil ? "ausente" : "presente"}`,
    )
    const tina2 = page.getByRole("listitem", { name: "Tina 2" })
    await tina2.waitFor()
    ok(
      /toca medir hoy/i.test(await page.locator("section", { has: tina2 }).first().textContent()),
      `lista ${ancho}/${tema}: Tina 2 no está en «toca medir hoy»`,
    )
    const hrefMedir = await tina2.getByRole("link", { name: "Medir Tina 2" }).getAttribute("href")
    const ciclo = hrefMedir.split("/fermentacion/")[1].split("/")[0]

    // Medir (paso 1) en todas las corridas; guardar solo en la primera
    await tina2.getByRole("link", { name: "Medir Tina 2" }).click()
    await page.getByRole("status").filter({ hasText: "Paso 1 de 4" }).waitFor()
    await foto("medir-1")
    await sinScrollH("medir-1")
    await page.getByLabel("Temperatura").fill("27.5")
    await page.getByRole("button", { name: "Siguiente" }).click()
    await page.getByRole("status").filter({ hasText: "Paso 2 de 4" }).waitFor()
    await page.getByLabel("Brix").fill(primera ? "19" : "12.4")
    await page.getByRole("button", { name: "Siguiente" }).click()
    await page.getByRole("status").filter({ hasText: "Paso 3 de 4" }).waitFor()
    await foto("medir-3")
    await page.getByRole("radio", { name: "6 · muy activa" }).click()
    await page.getByRole("button", { name: "Revisar" }).click()
    await page.getByRole("status").filter({ hasText: "Paso 4 de 4" }).waitFor()
    if (primera) {
      // Brix 19 → aviso conocido antes de enviar; la primaria espera la nota
      await page.getByRole("alert").filter({ hasText: "Brix está fuera del rango" }).waitFor()
      ok(
        await page.getByRole("button", { name: "Guardar medición" }).isDisabled(),
        "revisar: Guardar no espera la nota",
      )
      await foto("revisar-aviso")
      await sinScrollH("revisar-aviso")
      await page
        .getByLabel("Nota (obligatoria por el aviso)")
        .fill("Prueba de evidencia: calor de mediodía")
      await page.getByRole("button", { name: "Guardar medición" }).click()
      await page
        .getByRole("status")
        .filter({ hasText: "Medición guardada · enviada" })
        .waitFor({ timeout: 30000 })
      await foto("guardada")
      await page.getByRole("link", { name: "Volver a Fermentación" }).click()
      await page.getByText("Medición guardada.").waitFor()
      const t2 = page.getByRole("listitem", { name: "Tina 2" })
      await t2.waitFor()
      ok(
        /ya medidas hoy/i.test(await page.locator("section", { has: t2 }).first().textContent()),
        "tras guardar: Tina 2 no pasó a «ya medidas hoy»",
      )
      ok(
        /hoy \d\d:\d\d.*27\.5 °C.*19 Brix.*actividad 6/.test(await t2.textContent()),
        "tras guardar: la fila no muestra la última medición",
      )
      await foto("lista-medida")
    } else {
      await foto("revisar")
      // En «Revisar» la barra trae Atrás (Cancelar solo en el primer paso): se sale por navegación
      await page.goto(`${WEB}/e/${SLUG}/fermentacion`)
      await page.getByText(/tinas en uso/).waitFor({ timeout: 20000 })
    }

    // Detalle del uso
    await page.goto(`${WEB}/e/${SLUG}/fermentacion/${ciclo}`)
    await page.getByRole("heading", { name: "Tina 2" }).waitFor({ timeout: 20000 })
    await page.getByRole("table").waitFor()
    await foto("detalle")
    await sinScrollH("detalle")
    if (primera) {
      // Anular la medición recién guardada (motivo obligatorio)
      const fila = page.getByRole("row").filter({ hasText: "Prueba de evidencia" })
      await fila.getByRole("button", { name: /Acciones/ }).click()
      await page.getByRole("menuitem", { name: "Anular…" }).click()
      const capa = page.getByRole("dialog", { name: /Anular la medición/ })
      await capa.waitFor()
      await foto("anular")
      await capa.getByLabel("Motivo").fill("Evidencia de la ronda; se anula")
      await capa.getByRole("button", { name: "Anular medición" }).click()
      await page.getByText(/anulada\./).waitFor({ timeout: 20000 })
      ok(
        (await page.getByRole("row").filter({ hasText: "Evidencia de la ronda" }).count()) >= 1,
        "anular: la fila anulada no muestra el motivo",
      )
      await foto("detalle-anulada")
      // Cerrar ciclo: solo el diálogo (destructiva; Cancelar es la primaria)
      await page.getByRole("button", { name: "Cerrar ciclo (tina vaciada)" }).click()
      const dlg = page.getByRole("dialog", { name: /Cerrar el ciclo/ })
      await dlg.waitFor()
      await foto("cerrar-dialogo")
      await dlg.getByRole("button", { name: "Cancelar" }).first().click()
    }

    // Formulación (Cuatro Vientos: sin cocido con saldo → estado vacío real)
    await page.goto(`${WEB}/e/${SLUG}/fermentacion/formular`)
    await page.getByText(/No hay agave cocido con saldo|Agave cocido/).waitFor({ timeout: 20000 })
    await foto("formular")
    await sinScrollH("formular")

    // Tina que ya fermentaba (capa) — sin tinas libres en la semilla: lo dice
    await page.goto(`${WEB}/e/${SLUG}/fermentacion`)
    await page.getByRole("button", { name: "Tina que ya fermentaba" }).waitFor({ timeout: 20000 })
    await page.getByRole("button", { name: "Tina que ya fermentaba" }).click()
    const cf = page.getByRole("dialog", { name: "Tina que ya fermentaba" })
    await cf.waitFor()
    await foto("fermentaba")
    ok(
      /No hay tinas libres/.test(await cf.textContent()),
      `${ancho}/${tema}: la capa no dice que no hay tinas libres`,
    )
    await page.keyboard.press("Escape")

    await salir(page)
    ok(errores.length === 0, `${ancho}/${tema}: errores JS: ${errores.join(" | ")}`)
    await ctx.close()
    primera = false
    console.log(`✔ ${ancho} ${tema}`)
  }
}
await browser.close()
if (fallos.length) {
  console.error("\nFALLOS:\n- " + fallos.join("\n- "))
  process.exit(1)
}
console.log(`\nEvidencia en ${OUT}`)
