// Evidencia de la ronda inicio-hoy/r01 (coco, R3) contra el dev server y el
// proyecto alojado. Aurelia (productora) en Mezcal Cuatro Vientos: Hoy con
// la semilla (Tina 2 y Tina 3 por medir; Tina 1 en vaciado = «lista para
// destilar»), «Medir» desde Hoy (primera corrida: medición REAL por la cola,
// Brix 12.4 sin aviso) y vuelta a Hoy con la Tina 2 fuera de «Toca medir»;
// Tomás (operador): Medir y Cortar sí, sin «Pasar a granel»; sin señal:
// «Mostrando datos guardados el …» y Medir sigue activo. 4 anchos × 2 temas.
// `db reset --linked` deja Cuatro Vientos como la semilla.
//   node design-hub/qa/evidencia-inicio-hoy.mjs   (con `web` corriendo)
import { chromium } from "@playwright/test"
import { mkdir } from "node:fs/promises"
import path from "node:path"
import { fileURLToPath } from "node:url"

const WEB = process.env.WEB_URL ?? "http://localhost:5173"
const SLUG = "cuatro-vientos"
const OUT = path.join(path.dirname(fileURLToPath(import.meta.url)), "evidence", "inicio-hoy-r01")
const ANCHOS = [1440, 1024, 768, 390]
const TEMAS = ["light", "dark"]
const fallos = []
const ok = (c, m) => {
  if (!c) fallos.push(m)
}
async function entrar(page, usuario = "aurelia", contrasena = "aurelia-2026") {
  await page.goto(`${WEB}/e/${SLUG}`)
  await page.locator("input[name=usuario]").fill(usuario)
  await page.locator("input[name=contrasena]").fill(contrasena)
  await page.locator("button[type=submit]").click()
  await page.waitForURL(/\/(inicio|cambiar-contrasena)$/, { timeout: 20000 })
  if (page.url().endsWith("/cambiar-contrasena")) {
    // Tomás trae must_change_password en la semilla: se cambia (escritura real
    // que `db reset` deshace) para poder ver Hoy como operador.
    await page.getByLabel("Nueva contraseña").fill("tomas-2026-hoy")
    await page.getByLabel("Repítela").fill("tomas-2026-hoy")
    await page.locator("button[type=submit]").click()
    await page.waitForURL("**/inicio", { timeout: 20000 })
  }
}
const hoyCargado = (page) => page.getByRole("status").filter({ hasText: /por medir/ }).waitFor({ timeout: 20000 })

await mkdir(OUT, { recursive: true })
const browser = await chromium.launch()
let primera = true
let corridas = 0
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
    await hoyCargado(page)
    await foto("hoy")
    await sinScrollH("hoy")
    const resumen = await page.getByRole("status").filter({ hasText: /por medir/ }).textContent()
    if (primera)
      ok(/^2 tinas por medir · sin corridas · nada por enviar$/.test(resumen.trim()), `hoy: resumen inesperado «${resumen}»`)
    // Una sola primaria: Medir de la tina más atrasada; en compact es el FAB
    const primarias = page.locator(".boton--primary:visible")
    const fab = page.locator(".fab", { hasText: "Medir" })
    ok(
      movil ? (await fab.count()) === 1 && (await primarias.count()) === 0 : (await primarias.count()) === 1 && (await fab.count()) === 0,
      `hoy ${ancho}/${tema}: primaria (FAB en compact, botón en ≥600)`,
    )
    const filas = await page.locator("section[aria-labelledby=hoy-medir] li h3").allTextContents()
    if (primera) {
      ok(filas.length === 2 && /Tina 3/.test(filas[0]) && /Tina 2/.test(filas[1]), `hoy: Toca medir = ${JSON.stringify(filas)} (esperaba Tina 3, Tina 2)`)
      ok(/1 lista para destilar/.test(await page.textContent("main, body")), "hoy: contexto «1 lista para destilar» (Tina 1 en vaciado)")
      // Semilla: sin corridas abiertas; el Colector colas guarda 16 L (COL-002)
      const colector = page.locator("section[aria-labelledby=hoy-dest] li", { hasText: "Colector colas" })
      ok((await colector.count()) === 1 && /16 L/.test(await colector.textContent()), "hoy: Destilación muestra el Colector colas con 16 L")
      ok((await colector.getByRole("link", { name: "Ver" }).count()) === 1 && (await page.getByRole("link", { name: "Pasar a granel" }).count()) === 0, "hoy: colas no ofrece «Pasar a granel» (solo mezcal)")
    }

    if (primera) {
      // Medir desde Hoy (segunda fila: Tina 2) → medición real por la cola → vuelve a Hoy
      const tina2 = page.locator("section[aria-labelledby=hoy-medir] li", { hasText: "Tina 2" })
      await tina2.getByRole("link", { name: "Medir" }).click()
      await page.waitForURL(/\/fermentacion\/[^/]+\/medir\?volver=inicio/)
      await page.getByRole("status").filter({ hasText: "Paso 1 de 4" }).waitFor()
      await page.getByLabel("Temperatura").fill("27.5")
      await page.getByRole("button", { name: "Siguiente" }).click()
      await page.getByRole("status").filter({ hasText: "Paso 2 de 4" }).waitFor()
      await page.getByLabel("Brix").fill("12.4")
      await page.getByRole("button", { name: "Siguiente" }).click()
      await page.getByRole("status").filter({ hasText: "Paso 3 de 4" }).waitFor()
      await page.getByRole("radio", { name: "6 · muy activa" }).click()
      await page.getByRole("button", { name: "Revisar" }).click()
      await page.getByRole("status").filter({ hasText: "Paso 4 de 4" }).waitFor()
      await page.getByRole("button", { name: "Guardar medición" }).click()
      await page.getByRole("status").filter({ hasText: "Medición guardada · enviada" }).waitFor({ timeout: 30000 })
      await foto("medida-guardada")
      await page.getByRole("link", { name: "Volver a Inicio" }).click()
      await page.waitForURL("**/inicio?aviso=medida")
      await hoyCargado(page)
      ok(/Medición guardada\./.test(await page.textContent("body")), "vuelta: aviso «Medición guardada.»")
      const despues = await page.locator("section[aria-labelledby=hoy-medir] li h3").allTextContents()
      ok(despues.length === 1 && /Tina 3/.test(despues[0]), `vuelta: Toca medir = ${JSON.stringify(despues)} (esperaba solo Tina 3)`)
      ok(/1 tina ya medida hoy · 1 lista para destilar/.test(await page.textContent("body")), "vuelta: contexto «1 tina ya medida hoy · 1 lista para destilar»")
      ok(/^1 tina por medir/.test((await page.getByRole("status").filter({ hasText: /por medir/ }).textContent()).trim()), "vuelta: resumen «1 tina por medir»")
      await foto("hoy-tras-medir")
      // Sin señal: instantánea con fecha y Medir sigue activo. El dev server
      // no tiene SW: los módulos de Inicio y Fermentación se precargan
      // navegando dentro de la app antes de cortar la red.
      await page.goto(`${WEB}/e/${SLUG}/fermentacion`)
      await page.getByText(/tinas en uso/).waitFor({ timeout: 20000 })
      await page.getByRole("link", { name: "Inicio" }).first().click()
      await hoyCargado(page)
      await page.getByRole("link", { name: "Fermentación" }).first().click()
      await page.getByText(/tinas en uso/).waitFor({ timeout: 20000 })
      await ctx.setOffline(true)
      await page.getByRole("link", { name: "Inicio" }).first().click()
      await page.getByText(/Mostrando datos guardados el/).waitFor({ timeout: 20000 })
      ok((await page.locator("section[aria-labelledby=hoy-medir] li").getByRole("link", { name: "Medir" }).count()) >= 1, "sin señal: Medir sigue activo desde la instantánea")
      ok(/Sin señal puedes medir y cortar/.test(await page.textContent("body")), "sin señal: aviso de que Medir/Cortar siguen")
      await foto("hoy-sin-senal")
      await sinScrollH("hoy-sin-senal")
      await ctx.setOffline(false)
      primera = false
    }
    ok(errores.length === 0, `${ancho}/${tema}: errores de página ${errores.join(" | ")}`)
    await ctx.close()
    corridas++
  }
}

// Tomás (operador) en 1024/claro: Medir sí; sin «Abrir corrida» ni «Pasar a granel»
{
  const ctx = await browser.newContext({ viewport: { width: 1024, height: 900 } })
  const page = await ctx.newPage()
  await entrar(page, "tomas.h", "tomas-2026")
  await hoyCargado(page)
  ok((await page.locator("section[aria-labelledby=hoy-medir] li").getByRole("link", { name: "Medir" }).count()) === 1, "operador: ve Medir (Tina 3)")
  ok((await page.getByRole("link", { name: "Abrir corrida" }).count()) === 0, "operador: sin «Abrir corrida»")
  ok((await page.getByRole("link", { name: "Pasar a granel" }).count()) === 0, "operador: sin «Pasar a granel»")
  await page.screenshot({ path: path.join(OUT, "hoy-operador-1024-light.png") })
  await ctx.close()
}
await browser.close()
console.log(JSON.stringify({ status: fallos.length ? "FAIL" : "PASS", corridas, fallos }, null, 2))
process.exit(fallos.length ? 1 : 0)
