// Evidencia de la ronda acceso/r01 (coco, R3). No es una suite de pruebas:
// recorre las pantallas reales contra el dev server (5173) y el Hub (4321)
// y guarda capturas en evidence/acceso-r01/<pantalla>-<ancho>-<tema>.png
// en los cuatro anchos del perfil, claro y oscuro. Entra con los usuarios de
// supabase/seed.sql contra el proyecto de desarrollo alojado.
//
//   node design-hub/qa/evidencia-acceso.mjs
//
// Requiere: `pnpm --filter @pulz/web dev --port 5173` y
// `python3 -m http.server 4321` (raíz del repo) corriendo.
import { chromium } from "@playwright/test"
import { mkdir } from "node:fs/promises"
import path from "node:path"
import { fileURLToPath } from "node:url"

const WEB = process.env.WEB_URL ?? "http://localhost:5173"
const HUB = process.env.HUB_URL ?? "http://localhost:4321/design-hub/Components/demo/"
const SLUG = "cuatro-vientos"
const OUT = path.join(path.dirname(fileURLToPath(import.meta.url)), "evidence", "acceso-r01")
const ANCHOS = [1440, 1024, 768, 390]
const TEMAS = ["light", "dark"]

const fallos = []
const ok = (cond, msg) => {
  if (!cond) fallos.push(msg)
}

async function entrar(page, usuario, contrasena) {
  await page.goto(`${WEB}/e/${SLUG}`)
  await page.locator("input[name=usuario]").fill(usuario)
  await page.locator("input[name=contrasena]").fill(contrasena)
  await page.locator("button[type=submit]").click()
  await page.waitForURL((u) => !u.pathname.endsWith(`/e/${SLUG}`), { timeout: 15000 })
}

async function salir(page) {
  // Pantallas de acceso (sin shell): "Cerrar sesión" directo. Dentro del shell
  // (shell/r01) vive en la Cuenta: botón de empresa (compact/medium) o bloque
  // de cuenta al pie del menú lateral (expanded).
  const directo = page.getByRole("button", { name: "Cerrar sesión" })
  if ((await directo.count()) === 0) {
    await page.getByRole("button", { name: /cuenta|Cuatro Vientos/ }).first().click()
  }
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
    const foto = (nombre) =>
      page.screenshot({ path: path.join(OUT, `${nombre}-${ancho}-${tema}.png`), fullPage: true })
    const sinScrollH = async (nombre) => {
      const w = await page.evaluate(() => [
        document.documentElement.scrollWidth,
        document.documentElement.clientWidth,
      ])
      ok(w[0] <= w[1], `${nombre} ${ancho}/${tema}: scroll horizontal (${w[0]} > ${w[1]})`)
    }

    // 1. Portal
    await page.goto(`${WEB}/e/${SLUG}`)
    await page.getByRole("heading", { name: "Mezcal Cuatro Vientos" }).waitFor()
    await foto("portal")
    await sinScrollH("portal")

    // 1b. Rechazo: mismo texto para usuario inexistente
    await page.locator("input[name=usuario]").fill("nadie")
    await page.locator("input[name=contrasena]").fill("malaclave")
    await page.locator("button[type=submit]").click()
    const alerta = page.getByRole("alert")
    await alerta.waitFor({ timeout: 15000 })
    ok(
      (await alerta.textContent())?.trim() === "Usuario o contraseña incorrectos",
      `rechazo ${ancho}/${tema}: texto distinto`,
    )
    ok(
      (await page.locator("input[name=contrasena]").inputValue()) === "",
      `rechazo ${ancho}/${tema}: no limpió la contraseña`,
    )
    await foto("portal-rechazo")

    // 1c. Ayuda "¿No puedes entrar?" para colaborador
    await page.getByRole("button", { name: "¿No puedes entrar?" }).click()
    await foto("portal-ayuda")

    // 2. Slug viejo → slug actual (redirect_to)
    await page.goto(`${WEB}/e/mezcal-cuatro-vientos`)
    await page.waitForURL(`**/e/${SLUG}`)

    // 3. 404 genérico
    await page.goto(`${WEB}/e/no-existe`)
    await page.waitForURL("**/e/no-existe/no-encontrado")
    await foto("no-encontrado")
    await sinScrollH("no-encontrado")

    // 4. Guardia: ruta privada sin sesión → portal
    await page.goto(`${WEB}/e/${SLUG}/equipo`)
    await page.waitForURL(`**/e/${SLUG}`)

    // 5. Bienvenida (formulario con token de ejemplo; no se canjea)
    await page.goto(`${WEB}/e/${SLUG}/bienvenida#token-de-ejemplo`)
    await page.getByRole("heading", { name: /Te dieron acceso/ }).waitFor()
    await foto("bienvenida")
    await sinScrollH("bienvenida")
    // 5b. Sin token → enlace inválido
    await page.goto(`${WEB}/e/${SLUG}/bienvenida`)
    await page.getByText("El enlace no es válido o ya se usó").waitFor()
    await foto("bienvenida-invalido")

    // 6. Contraseña dictada → cambio obligatorio
    await entrar(page, "tomas.h", "tomas-2026")
    ok(page.url().endsWith("/cambiar-contrasena"), `tomas ${ancho}/${tema}: no obligó el cambio`)
    await page.goto(`${WEB}/e/${SLUG}/inicio`)
    await page.waitForURL("**/cambiar-contrasena")
    await foto("cambiar-contrasena")
    await sinScrollH("cambiar-contrasena")
    await salir(page)

    // 7. Titular → inicio → equipo
    await entrar(page, "benito@cuatrovientos.mx", "benito-2026")
    ok(page.url().endsWith("/inicio"), `benito ${ancho}/${tema}: no llegó a inicio`)
    await foto("inicio")
    // shell/r01: Equipo se llega desde la Cuenta (admin) o desde Configuración
    await page.getByRole("button", { name: /cuenta|Cuatro Vientos/ }).first().click()
    await page.getByRole("dialog", { name: "Tu cuenta" }).waitFor()
    await page.getByRole("link", { name: "Equipo" }).click()
    await page.getByRole("heading", { name: "Equipo" }).waitFor()
    await page.getByRole("button", { name: "Acciones para Tomás Hernández" }).waitFor()
    await foto("equipo")
    await sinScrollH("equipo")
    // 7b. Menú por fila (popover en ≥600, hoja en compact)
    await page.getByRole("button", { name: "Acciones para Tomás Hernández" }).click()
    await page.getByRole("menu").waitFor()
    await foto("equipo-menu")
    await page.keyboard.press("Escape")
    // 7c. Alta (drawer en ≥600, hoja en compact) — no se envía
    await page.getByRole("button", { name: "Agregar persona" }).click()
    await page.getByRole("dialog", { name: "Agregar persona" }).waitFor()
    await page.getByLabel("Nombre").fill("Ana López")
    await page.getByLabel("Usuario para entrar").fill("ana.lopez")
    await foto("equipo-alta")
    await sinScrollH("equipo-alta")
    // Cerrar ≠ Cancelar: con datos escritos, Esc pide confirmar el descarte
    let confirmo = null
    page.once("dialog", (d) => {
      confirmo = d.message()
      d.accept()
    })
    await page.keyboard.press("Escape")
    await page.getByRole("dialog").waitFor({ state: "detached", timeout: 5000 })
    ok(confirmo === "¿Descartar lo que escribiste?", `alta ${ancho}/${tema}: Esc no pidió confirmar`)
    await page.goto(`${WEB}/e/${SLUG}/inicio`)
    await salir(page)

    // 8. Colaboradora productora: en Inicio no ve "Equipo"; por URL, estado "Sin permiso"
    await entrar(page, "aurelia", "aurelia-2026")
    await page.getByRole("button", { name: /cuenta|Cuatro Vientos/ }).first().click()
    await page.getByRole("dialog", { name: "Tu cuenta" }).waitFor()
    ok(
      (await page.getByRole("link", { name: "Equipo" }).count()) === 0,
      `aurelia ${ancho}/${tema}: ve el enlace Equipo en su cuenta`,
    )
    await page.keyboard.press("Escape")
    await page.goto(`${WEB}/e/${SLUG}/equipo`)
    await page.getByText("Solo el administrador puede ver el equipo").waitFor()
    await foto("equipo-sin-permiso")
    await page.goto(`${WEB}/e/${SLUG}/inicio`)
    await salir(page)

    // 9. Hub (componentes con tokens reales: incluye solo lectura y estados)
    await page.goto(HUB)
    await page.getByRole("heading", { level: 2, name: "Botón button" }).waitFor()
    await foto("hub")
    await sinScrollH("hub")

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
