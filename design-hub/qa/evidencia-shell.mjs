// Evidencia de la ronda shell/r01 (coco, R3). Recorre el shell real contra el
// dev server (5173) y el proyecto alojado, con los usuarios de la semilla, en
// 1440/1024/768/390 × claro/oscuro, y guarda capturas en
// evidence/shell-r01/<pantalla>-<ancho>-<tema>.png.
//   node design-hub/qa/evidencia-shell.mjs   (con `web` corriendo)
import { chromium } from "@playwright/test"
import { mkdir } from "node:fs/promises"
import path from "node:path"
import { fileURLToPath } from "node:url"

const WEB = process.env.WEB_URL ?? "http://localhost:5173"
const SLUG = "cuatro-vientos"
const OUT = path.join(path.dirname(fileURLToPath(import.meta.url)), "evidence", "shell-r01")
const ANCHOS = [1440, 1024, 768, 390]
const TEMAS = ["light", "dark"]
const fallos = []
const ok = (c, m) => {
  if (!c) fallos.push(m)
}

async function entrar(page, usuario, contrasena) {
  await page.goto(`${WEB}/e/${SLUG}`)
  await page.locator("input[name=usuario]").fill(usuario)
  await page.locator("input[name=contrasena]").fill(contrasena)
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
    const errores = []
    page.on("pageerror", (e) => errores.push(String(e)))
    const foto = (n) => page.screenshot({ path: path.join(OUT, `${n}-${ancho}-${tema}.png`), fullPage: false })
    const sinScrollH = async (n) => {
      const [sw, cw] = await page.evaluate(() => [
        document.documentElement.scrollWidth,
        document.documentElement.clientWidth,
      ])
      ok(sw <= cw, `${n} ${ancho}/${tema}: scroll horizontal (${sw} > ${cw})`)
    }

    // Admin: Inicio, navegación, Más (compact), Cuenta, Configuración, Equipo
    await entrar(page, "benito@cuatrovientos.mx", "benito-2026")
    await page.getByRole("heading", { level: 1, name: "Inicio" }).waitFor()
    await page.getByText(/Tinas que toca medir hoy|¿Qué tienes hoy\?/).waitFor()
    await foto("inicio")
    await sinScrollH("inicio")
    const navs = await page.getByRole("navigation", { name: "Navegación principal" }).all()
    ok(navs.length === 1, `inicio ${ancho}/${tema}: una sola navegación principal (hay ${navs.length})`)
    const enlaces = await page.getByRole("navigation", { name: "Navegación principal" }).getByRole("link").all()
    ok(enlaces.length === (movil ? 4 : 8), `nav ${ancho}/${tema}: ${enlaces.length} enlaces (admin)`)
    for (const a of enlaces) {
      const box = await a.boundingBox()
      ok(box && box.height >= 44, `nav ${ancho}/${tema}: target < 44 (${Math.round(box?.height ?? 0)})`)
    }
    if (movil) {
      await page.getByRole("button", { name: "Más" }).click()
      await page.getByRole("dialog", { name: "Más" }).waitFor()
      await foto("mas")
      await page.getByRole("link", { name: "Configuración" }).click()
    } else {
      await page.getByRole("link", { name: "Configuración" }).click()
    }
    await page.getByRole("heading", { level: 1, name: "Configuración" }).waitFor()
    await page.getByText("Equipo", { exact: true }).first().waitFor()
    await foto("configuracion")
    await sinScrollH("configuracion")
    await page.getByRole("link", { name: "Fermentación" }).click()
    await page.getByText("Próximamente en tu palenque").waitFor()
    await foto("fermentacion")
    // Cuenta
    await page.getByRole("button", { name: /Cuatro Vientos|titular/ }).first().click()
    await page.getByRole("dialog", { name: "Tu cuenta" }).waitFor()
    await foto("cuenta")
    await page.getByRole("radio", { name: "Oscuro" }).click()
    ok((await page.evaluate(() => document.documentElement.dataset.theme)) === "dark", `tema ${ancho}/${tema}: no aplicó oscuro`)
    ok((await page.evaluate(() => localStorage.getItem("pulz:tema"))) === "oscuro", `tema ${ancho}/${tema}: no guardó`)
    await page.getByRole("radio", { name: "Sistema" }).click()
    await page.keyboard.press("Escape")
    // Equipo dentro del shell
    await page.goto(`${WEB}/e/${SLUG}/equipo`)
    await page.getByRole("button", { name: "Acciones para Tomás Hernández" }).waitFor()
    await foto("equipo")
    await sinScrollH("equipo")
    await salir(page)

    // Productora (no admin): sin Configuración en el menú; por URL → sin permiso
    // (tomas.h no sirve aquí: debe cambiar la contraseña dictada antes de entrar)
    await entrar(page, "aurelia", "aurelia-2026")
    const navNoAdmin = await page.getByRole("navigation", { name: "Navegación principal" }).getByRole("link").all()
    ok(navNoAdmin.length === (movil ? 4 : 7), `nav no-admin ${ancho}/${tema}: ${navNoAdmin.length} enlaces`)
    ok((await page.getByRole("link", { name: "Configuración" }).count()) === 0, `no-admin ${ancho}/${tema}: ve Configuración`)
    await page.goto(`${WEB}/e/${SLUG}/configuracion`)
    await page.getByText("Solo el administrador puede ver la configuración").waitFor()
    await foto("configuracion-sin-permiso")
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
