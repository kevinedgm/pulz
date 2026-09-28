// Evidencia de la ronda destilacion/r01 (coco, R3) con Aurelia en Mezcal
// Cuatro Vientos. En la primera corrida (1440/claro) hace escrituras REALES:
// abre una corrida en Alambique 1 con 290 L de la Tina 1 (lista, FER-T1-001),
// registra tres cortes por la cola (mezcal 8 @ 51 → Colector mezcal;
// ordinario 40 @ 24 → Colector ordinario; colas 12 @ 9 → Colector colas) y
// captura la corrida con cortes. Las demás corridas capturan la lista (con
// la corrida abierta), la corrida, abrir corrida y el corte paso 1 sin
// guardar. La ÚLTIMA corrida cierra la corrida (diálogo destructivo real).
// Queda en Cuatro Vientos hasta el `db reset --linked` (los cortes no se anulan).
//   node design-hub/qa/evidencia-destilacion.mjs   (con `web` corriendo)
import { chromium } from "@playwright/test"
import { mkdir } from "node:fs/promises"
import path from "node:path"
import { fileURLToPath } from "node:url"

const WEB = process.env.WEB_URL ?? "http://localhost:5173"
const SLUG = "cuatro-vientos"
const OUT = path.join(path.dirname(fileURLToPath(import.meta.url)), "evidence", "destilacion-r01")
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
async function corte(page, clase, litros, abv, colector) {
  await page.getByRole("status").filter({ hasText: "Paso 1 de 4" }).waitFor({ timeout: 20000 })
  await page.getByRole("radio", { name: clase }).click()
  await page.getByRole("button", { name: "Siguiente" }).click()
  await page.getByLabel("Litros").fill(String(litros))
  await page.getByRole("button", { name: "Siguiente" }).click()
  await page.getByLabel("% Alc.").fill(String(abv))
  await page.getByRole("button", { name: "Revisar" }).click()
  await page.getByRole("status").filter({ hasText: "Paso 4 de 4" }).waitFor()
  ok(
    (await page.locator("main").textContent()).includes(colector),
    `revisar: no muestra ${colector}`,
  )
  await page.getByRole("button", { name: "Guardar corte" }).click()
  await page.getByText("Corte guardado · enviado").waitFor({ timeout: 30000 })
}

await mkdir(OUT, { recursive: true })
const browser = await chromium.launch()
let primera = true
let runId = null
const total = ANCHOS.length * TEMAS.length
let n = 0
for (const tema of TEMAS) {
  for (const ancho of ANCHOS) {
    n += 1
    const ultima = n === total
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
    const foto = (nm) =>
      page.screenshot({ path: path.join(OUT, `${nm}-${ancho}-${tema}.png`), fullPage: false })
    const sinScrollH = async (nm) => {
      const [sw, cw] = await page.evaluate(() => [
        document.documentElement.scrollWidth,
        document.documentElement.clientWidth,
      ])
      ok(sw <= cw, `${nm} ${ancho}/${tema}: scroll horizontal (${sw} > ${cw})`)
    }

    await entrar(page)
    if (primera) {
      // Abrir corrida REAL: Alambique 1 (300 L, estricta), 1ª, 290 L de Tina 1
      await page.goto(`${WEB}/e/${SLUG}/destilacion/abrir`)
      await page.getByText("Alambique y pasada").waitFor({ timeout: 20000 })
      await foto("abrir")
      await sinScrollH("abrir")
      await page.getByLabel("Alambique").selectOption({ label: "Alambique 1 · 300 L · estricta" })
      const fila = page.locator(".asig__fila", { hasText: "Tina 1" })
      await fila.getByLabel("Litros").fill("290")
      await page.getByText("Total 290 L de 300 L").waitFor()
      await foto("abrir-lleno")
      await page.getByRole("button", { name: "Abrir corrida con 290 L" }).click()
      await page.waitForURL("**/destilacion/*?aviso=abierta", { timeout: 30000 })
      runId = page.url().split("/destilacion/")[1].split("?")[0]
      await page.getByText("Corrida abierta.").waitFor()
      await page.getByText("Aún sin cortes").waitFor()
      await foto("corrida-sin-cortes")
      // Tres cortes reales por la cola
      await page.getByRole("link", { name: "Registrar corte" }).click()
      await foto("corte-1")
      await sinScrollH("corte-1")
      await corte(page, "Mezcal", 8, 51, "Colector mezcal")
      await foto("corte-guardado")
      await page.getByRole("button", { name: "Registrar otro corte" }).click()
      await corte(page, "Ordinario", 40, 24, "Colector ordinario")
      await page.getByRole("button", { name: "Registrar otro corte" }).click()
      await corte(page, "Colas", 12, 9, "Colector colas")
      await page.getByRole("link", { name: "Volver a la corrida" }).click()
      await page.getByText("Corte guardado.").waitFor({ timeout: 20000 })
      await page.getByRole("table").waitFor()
      const txt = await page.locator("main").textContent()
      ok(
        /60 L/.test(txt) &&
          /mezcal 8/.test(txt) &&
          /ordinario 40/.test(txt) &&
          /colas 12/.test(txt),
        "corrida: no suma 60 L con los tres cortes",
      )
      await foto("corrida")
      await sinScrollH("corrida")
    }

    // Lista con la corrida abierta
    await page.goto(`${WEB}/e/${SLUG}/destilacion`)
    await page.getByRole("heading", { name: "Corridas abiertas" }).waitFor({ timeout: 20000 })
    await foto("lista")
    await sinScrollH("lista")
    const fab = page.locator(".fab", { hasText: "Abrir corrida" })
    ok(
      movil ? (await fab.count()) === 1 : (await fab.count()) === 0,
      `lista ${ancho}/${tema}: FAB ${movil ? "ausente" : "presente"}`,
    )
    ok(
      (await page.getByRole("heading", { name: "Colectores con contenido" }).count()) === 1,
      `lista ${ancho}/${tema}: sin colectores con contenido`,
    )
    ok(
      (await page.getByRole("link", { name: "Pasar a granel" }).count()) >= 1,
      `lista ${ancho}/${tema}: sin «Pasar a granel» para el mezcal`,
    )

    if (!primera) {
      await page.goto(`${WEB}/e/${SLUG}/destilacion/${runId}`)
      await page.getByRole("table").waitFor({ timeout: 20000 })
      await foto("corrida")
      await sinScrollH("corrida")
      await page.goto(`${WEB}/e/${SLUG}/destilacion/${runId}/corte`)
      await page.getByRole("status").filter({ hasText: "Paso 1 de 4" }).waitFor({ timeout: 20000 })
      await foto("corte-1")
      await sinScrollH("corte-1")
      await page.goto(`${WEB}/e/${SLUG}/destilacion/abrir`)
      await page.getByText("Alambique y pasada").waitFor({ timeout: 20000 })
      await foto("abrir")
      await sinScrollH("abrir")
    }
    if (ultima) {
      // Cerrar la corrida: diálogo destructivo real
      await page.goto(`${WEB}/e/${SLUG}/destilacion/${runId}`)
      await page.getByRole("button", { name: "Cerrar corrida" }).waitFor({ timeout: 20000 })
      await page.getByRole("button", { name: "Cerrar corrida" }).click()
      const dlg = page.getByRole("dialog", { name: /Cerrar la corrida/ })
      await dlg.waitFor()
      await foto("cerrar-dialogo")
      await dlg.getByRole("button", { name: "Cerrar corrida" }).click()
      await page.waitForURL("**/destilacion?aviso=cerrada", { timeout: 30000 })
      await page.getByText("Últimas corridas").waitFor()
      ok(
        (await page.getByText("No hay corridas abiertas").count()) === 1,
        "cerrar: la corrida sigue abierta",
      )
      await foto("lista-cerrada")
    }

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
