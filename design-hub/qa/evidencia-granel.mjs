// Evidencia de la ronda granel/r01 (coco, R3) con Aurelia en Mezcal Cuatro
// Vientos. En la primera corrida (1440/claro) hace escrituras REALES:
// transfiere 8 L del Colector mezcal al Tanque 1 conservando G-COMPRA-01;
// entra 2 L de agua al Tanque 2 declarando 343.6 L a 44.7 % (el ledger da
// 343.8 → diferencia −0.2 L conocida antes → nota → conciliación); saca 10 L
// del Tanque 2 como venta con contraparte y documento; y captura el
// historial del Tanque 2 con los tres. Las demás corridas capturan tanques,
// tanque, elegir concepto y transferir sin guardar. `db reset` al cerrar la fase.
//   node design-hub/qa/evidencia-granel.mjs   (con `web` corriendo)
import { chromium } from "@playwright/test"
import { mkdir } from "node:fs/promises"
import path from "node:path"
import { fileURLToPath } from "node:url"

const WEB = process.env.WEB_URL ?? "http://localhost:5173"
const SLUG = "cuatro-vientos"
const OUT = path.join(path.dirname(fileURLToPath(import.meta.url)), "evidence", "granel-r01")
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
let tanque2 = null
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
    await page.goto(`${WEB}/e/${SLUG}/granel`)
    await page.getByText(/de granel/).waitFor({ timeout: 20000 })
    await foto("tanques")
    await sinScrollH("tanques")
    ok((await page.locator(".fab").count()) === 0, `tanques ${ancho}/${tema}: no debe haber FAB`)
    const t2 = page.getByRole("article", { name: "Tanque 2" })
    await t2.waitFor()
    ok(
      /% Alc\. declarado/.test(await t2.textContent()),
      `tanques ${ancho}/${tema}: Tanque 2 sin grado declarado`,
    )
    tanque2 = (await t2.getByRole("link", { name: "Ver historial" }).getAttribute("href")).split(
      "/granel/",
    )[1]

    if (primera) {
      // 1) Pasar a granel: Colector mezcal → Tanque 1 (conservar G-COMPRA-01)
      await page.getByRole("link", { name: "Pasar a granel" }).first().click()
      await page.getByText("De dónde y a dónde").waitFor({ timeout: 20000 })
      const destino = page.getByLabel("Destino")
      const opt = (await destino.locator("option", { hasText: "Tanque 1" }).first().textContent()).trim()
      await destino.selectOption({ label: opt })
      await page.getByLabel("Litros", { exact: true }).fill("8")
      await page.getByRole("radio", { name: /Conservar G-COMPRA-01/ }).waitFor()
      await foto("transferir")
      await sinScrollH("transferir")
      await page.getByRole("button", { name: /Transferir 8 L a Tanque 1/ }).click()
      await page.getByText("Transferidos 8 L a Tanque 1.").waitFor({ timeout: 30000 })
      await page.getByRole("heading", { name: "Tanque 1", exact: true }).waitFor({ timeout: 20000 })
      ok(
        /G-COMPRA-01/.test(await page.locator("main").textContent()),
        "transferir: Tanque 1 no conserva G-COMPRA-01",
      )
      await foto("tanque1-transferido")

      // 2) Entrada de agua al Tanque 2 con diferencia conocida antes
      await page.goto(`${WEB}/e/${SLUG}/granel/${tanque2}/movimiento?direccion=entrada`)
      await page.getByRole("radio", { name: /Agua para bajar grado/ }).waitFor({ timeout: 20000 })
      await foto("concepto")
      await sinScrollH("concepto")
      await page.getByRole("radio", { name: /Agua para bajar grado/ }).click()
      await page.getByRole("button", { name: "Siguiente" }).click()
      await page.getByLabel("Litros", { exact: true }).fill("2")
      await page.getByLabel("Volumen resultante").fill("343.6")
      await page.getByLabel("% Alc. resultante").fill("44.7")
      await page
        .getByText(/diferencia de/)
        .first()
        .waitFor()
      await page.getByRole("alert").filter({ hasText: "no cuadra" }).waitFor()
      ok(
        await page.getByRole("button", { name: /Registrar 2 L de agua/ }).isDisabled(),
        "agua: Registrar no espera la nota",
      )
      await foto("agua-aviso")
      await sinScrollH("agua-aviso")
      await page
        .getByLabel("Nota (obligatoria por el aviso)")
        .fill("Prueba de evidencia: contracción al mezclar")
      await page.getByRole("button", { name: /Registrar 2 L de agua/ }).click()
      await page.getByText(/diferencia de -0\.2 L/).first().waitFor({ timeout: 30000 })
      await page.getByRole("heading", { name: "Tanque 2", exact: true }).waitFor({ timeout: 20000 })
      ok(
        /343\.6 L/.test(await page.locator("main").textContent()),
        "agua: el tanque no muestra 343.6 L",
      )
      await foto("tanque2-agua")

      // 3) Salida: venta con contraparte
      await page.goto(`${WEB}/e/${SLUG}/granel/${tanque2}/movimiento?direccion=salida`)
      await page.getByRole("radio", { name: /Venta a granel/ }).waitFor({ timeout: 20000 })
      await page.getByRole("radio", { name: /Venta a granel/ }).click()
      await page.getByRole("button", { name: "Siguiente" }).click()
      await page.getByLabel("Litros", { exact: true }).fill("10")
      ok(
        await page.getByRole("button", { name: /Sacar 10 L/ }).isDisabled(),
        "venta: Registrar no espera la contraparte",
      )
      await page.getByLabel("Contraparte").fill("Cliente de evidencia")
      await page.getByLabel(/Documento/).fill("Remisión QA-1")
      await foto("venta")
      await sinScrollH("venta")
      await page.getByRole("button", { name: /Sacar 10 L de Tanque 2/ }).click()
      await page.getByText(/Registrado: sacar 10 L/).waitFor({ timeout: 30000 })
      await page.getByRole("table").waitFor({ timeout: 20000 })
      ok(
        /333\.6 L/.test(await page.locator("main").textContent()),
        "venta: el tanque no muestra 333.6 L",
      )
      const hist = await page.locator("main").textContent()
      ok(
        /Venta a granel/.test(hist) &&
          /Agua para bajar grado/.test(hist) &&
          /Cliente de evidencia/.test(hist),
        "historial: faltan los movimientos reales",
      )
      await foto("tanque2")
      await sinScrollH("tanque2")
    } else {
      await page.goto(`${WEB}/e/${SLUG}/granel/${tanque2}`)
      await page.getByRole("table").waitFor({ timeout: 20000 })
      await foto("tanque2")
      await sinScrollH("tanque2")
      await page.goto(`${WEB}/e/${SLUG}/granel/${tanque2}/movimiento?direccion=entrada`)
      await page.getByRole("radio", { name: /Agua para bajar grado/ }).waitFor({ timeout: 20000 })
      await foto("concepto")
      await sinScrollH("concepto")
      await page.goto(`${WEB}/e/${SLUG}/granel/transferir`)
      await page.getByText("De dónde y a dónde").waitFor({ timeout: 20000 })
      await foto("transferir")
      await sinScrollH("transferir")
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
