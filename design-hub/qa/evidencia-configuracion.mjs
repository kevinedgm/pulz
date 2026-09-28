// Evidencia de la ronda configuracion/r01 (coco, R3). Recorre las cuatro
// secciones reales como admin (Benito) contra el dev server y el proyecto
// alojado en 1440/1024/768/390 × claro/oscuro. En 1440/light además ejecuta
// escrituras REALES y las deshace: alta de TANQUE y su desactivación,
// especie propia y su ocultado, guardado de ajustes (sin cambios de valor),
// logo real a Storage y su retiro, cambio de enlace y vuelta al original.
//   node design-hub/qa/evidencia-configuracion.mjs   (con `web` corriendo)
import { chromium } from "@playwright/test"
import { mkdir } from "node:fs/promises"
import path from "node:path"
import { fileURLToPath } from "node:url"

const WEB = process.env.WEB_URL ?? "http://localhost:5173"
const SLUG = "cuatro-vientos"
const AQUI = path.dirname(fileURLToPath(import.meta.url))
const OUT = path.join(AQUI, "evidence", "configuracion-r01")
const LOGO = path.join(AQUI, "..", "..", "apps", "web", "public", "icons", "pwa-192x192.png")
// Códigos únicos por corrida: la semilla conserva los de corridas previas hasta el db reset
const SUF = Math.random().toString(36).slice(2, 6)
const TANQUE = `Tanque QA ${SUF}`
const ESPECIE = `Especie QA ${SUF}`
const ANCHOS = [1440, 1024, 768, 390]
const TEMAS = ["light", "dark"]
const fallos = []
const ok = (c, m) => {
  if (!c) fallos.push(m)
}

async function entrar(page) {
  await page.goto(`${WEB}/e/${SLUG}`)
  await page.locator("input[name=usuario]").fill("benito@cuatrovientos.mx")
  await page.locator("input[name=contrasena]").fill("benito-2026")
  await page.locator("button[type=submit]").click()
  await page.waitForURL("**/inicio", { timeout: 15000 })
}
async function salir(page) {
  await page.getByRole("button", { name: /cuenta|Cuatro Vientos/ }).first().click()
  await page.getByRole("button", { name: "Cerrar sesión" }).click()
  await page.waitForURL(`**/e/${SLUG}`)
}

await mkdir(OUT, { recursive: true })
const browser = await chromium.launch()
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
    page.on("dialog", (d) => d.accept())
    const errores = []
    page.on("pageerror", (e) => errores.push(String(e)))
    const foto = (n) => page.screenshot({ path: path.join(OUT, `${n}-${ancho}-${tema}.png`), fullPage: false })
    const sinScrollH = async (n) => {
      const [sw, cw] = await page.evaluate(() => [document.documentElement.scrollWidth, document.documentElement.clientWidth])
      ok(sw <= cw, `${n} ${ancho}/${tema}: scroll horizontal (${sw} > ${cw})`)
    }
    const escribe = ancho === 1440 && tema === "light"

    await entrar(page)
    // Índice
    await page.goto(`${WEB}/e/${SLUG}/configuracion`)
    await page.getByRole("link", { name: /Recursos/ }).waitFor()
    await foto("indice")

    // 1. Recursos
    await page.goto(`${WEB}/e/${SLUG}/configuracion/recursos`)
    await page.getByRole("button", { name: "Acciones para Tanque 1" }).waitFor()
    await foto("recursos")
    await sinScrollH("recursos")
    await page.getByRole("button", { name: "Agregar recurso" }).first().click()
    await page.getByRole("dialog", { name: "Agregar recurso" }).waitFor()
    await foto("recursos-alta")
    await sinScrollH("recursos-alta")
    if (escribe) {
      const capaAlta = page.getByRole("dialog", { name: "Agregar recurso" })
      await capaAlta.getByLabel("Tipo de recurso").selectOption("tanque")
      await capaAlta.getByLabel("Código (como le dicen)").fill(TANQUE)
      await capaAlta.getByLabel("Capacidad", { exact: true }).fill("250")
      await page.getByRole("button", { name: "Guardar recurso" }).click()
      await page.getByRole("button", { name: `Acciones para ${TANQUE}` }).waitFor({ timeout: 15000 })
      await foto("recursos-creado")
      await page.getByRole("button", { name: `Acciones para ${TANQUE}` }).click()
      await page.getByRole("menuitem", { name: "Desactivar…" }).click()
      await page.getByRole("dialog", { name: `¿Desactivar ${TANQUE}?` }).waitFor()
      await foto("recursos-desactivar")
      await page.getByRole("button", { name: "Desactivar", exact: true }).click()
      await page.getByText(`${TANQUE} ya no aparece`).waitFor({ timeout: 15000 })
      // Tanque 2 tiene saldo real (carga inicial de la semilla): la confirmación avisa
      await page.getByRole("button", { name: "Acciones para Tanque 2" }).click()
      await page.getByRole("menuitem", { name: "Desactivar…" }).click()
      await page.getByText(/tiene .* L dentro/).waitFor()
      await foto("recursos-en-uso")
      await page.keyboard.press("Escape")
    } else {
      await page.keyboard.press("Escape")
    }

    // 2. Catálogos
    await page.goto(`${WEB}/e/${SLUG}/configuracion/catalogos`)
    await page.getByRole("button", { name: "Acciones para Tina de sabino" }).waitFor()
    await foto("catalogos")
    await sinScrollH("catalogos")
    await page.getByLabel("Catálogo").selectOption("concepto")
    await page.getByRole("button", { name: /Acciones para Muestra/ }).first().waitFor()
    await foto("catalogos-conceptos")
    if (escribe) {
      await page.getByLabel("Catálogo").selectOption("especie")
      await page.getByRole("button", { name: "Agregar especie" }).first().click()
      await page.getByRole("dialog", { name: "Agregar especie" }).waitFor()
      const capaEsp = page.getByRole("dialog", { name: "Agregar especie" })
      await capaEsp.getByLabel("Nombre", { exact: true }).fill(ESPECIE)
      await capaEsp.getByLabel("Nombre científico (opcional)").fill("Agave qa")
      await foto("catalogos-alta")
      await page.getByRole("button", { name: "Guardar", exact: true }).click()
      await page.getByRole("button", { name: `Acciones para ${ESPECIE}` }).waitFor({ timeout: 15000 })
      await page.getByRole("button", { name: `Acciones para ${ESPECIE}` }).click()
      await page.getByRole("menuitem", { name: "Ocultar…" }).click()
      await page.getByRole("button", { name: "Ocultar", exact: true }).click()
      await page.getByText(`${ESPECIE} ya no se ofrece`).waitFor({ timeout: 15000 })
      await foto("catalogos-oculto")
    }

    // 3. Ajustes
    await page.goto(`${WEB}/e/${SLUG}/configuracion/ajustes`)
    await page.getByRole("switch", { name: "¿Capturan puntas?" }).waitFor()
    await foto("ajustes")
    await sinScrollH("ajustes")
    if (escribe) {
      await page.getByLabel("Brix inicial habitual · mínimo").fill("20")
      await page.getByLabel("Brix inicial habitual · mínimo").blur()
      await page.getByText("El mínimo debe ser menor que el máximo.").waitFor()
      await foto("ajustes-error")
      await page.getByLabel("Brix inicial habitual · mínimo").fill("12")
      await page.getByRole("switch", { name: "¿Capturan puntas?" }).click()
      await page.getByRole("button", { name: "Guardar ajustes" }).click()
      await page.getByText("Ajustes guardados.").waitFor({ timeout: 15000 })
      await page.getByRole("switch", { name: "¿Capturan puntas?" }).click()
      await page.getByRole("button", { name: "Guardar ajustes" }).click()
      await page.getByText("Ajustes guardados.").waitFor({ timeout: 15000 })
      await foto("ajustes-guardado")
    }

    // 4. Portal y marca
    await page.goto(`${WEB}/e/${SLUG}/configuracion/portal`)
    await page.getByRole("button", { name: "Cambiar enlace…" }).waitFor()
    await foto("portal")
    await sinScrollH("portal")
    if (escribe) {
      await page.setInputFiles('input[type="file"]', LOGO)
      await page.getByRole("dialog", { name: "Recortar el logo" }).waitFor()
      await foto("portal-logo")
      await page.getByRole("button", { name: "Usar este logo" }).click()
      await page.getByRole("dialog", { name: "Recortar el logo" }).waitFor({ state: "detached", timeout: 20000 })
      await page.locator(".arch__previa img").waitFor({ timeout: 15000 })
      await page.waitForFunction(() => {
        const i = document.querySelector(".arch__previa img")
        return i && i.complete && i.naturalWidth > 0
      }, null, { timeout: 15000 })
      await foto("portal-con-logo")
      await page.getByRole("button", { name: "Quitar" }).click()
      await page.locator(".arch__previa img").waitFor({ state: "detached", timeout: 15000 })
      // enlace: cambiar y volver
      await page.getByRole("button", { name: "Cambiar enlace…" }).click()
      await page.getByLabel(/Nuevo enlace/).fill("cuatro-vientos-qa")
      await foto("portal-slug")
      await page.getByRole("button", { name: "Cambiar enlace", exact: true }).click()
      await page.waitForURL("**/e/cuatro-vientos-qa/configuracion/portal", { timeout: 20000 })
      await page.getByText("pulz.mx/e/cuatro-vientos-qa").waitFor()
      await page.getByRole("button", { name: "Cambiar enlace…" }).click()
      await page.getByLabel(/Nuevo enlace/).fill("cuatro-vientos")
      await page.getByRole("button", { name: "Cambiar enlace", exact: true }).click()
      await page.waitForURL("**/e/cuatro-vientos/configuracion/portal", { timeout: 20000 })
      await page.getByText("pulz.mx/e/cuatro-vientos", { exact: false }).first().waitFor()
      await foto("portal-slug-vuelto")
    }
    await salir(page)

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
