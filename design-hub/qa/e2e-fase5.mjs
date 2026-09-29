// E2E del proceso completo (PULZ_MAESTRO.md §16 Fase 5, tarea 8): en
// **Palenque Prueba B** (vacío tras `db reset`) se rehace DESDE LA INTERFAZ
// la simulación de `supabase/seed.sql` con sus fechas —recursos por
// Configuración, carga inicial por el arranque, tina que ya fermentaba,
// recepción, horneada, formulación a dos tinas, ocho mediciones, tina lista,
// DES-001/002 de 1ª, DES-003 de 2ª con ordinario y colas (aviso → nota),
// transferencia a granel con folio nuevo, agua, puntas, unión, compra,
// muestra, autoconsumo, venta y regalo— y se comprueba que los saldos
// finales de Prueba B coinciden con §15.1 leyendo `resource_lot_balances`.
// Todo REAL contra el proyecto alojado; `db reset --linked` lo deshace.
// Lo que la interfaz no permite y se declara: folio de los cortes, de la
// formulación (F-001), de la tina que ya fermentaba (FER-T3-INI) y de la
// carga inicial (G-INI-01) → automáticos; la carga inicial del arranque no
// lleva fecha (hoy); el día del ciclo lo cuenta la app desde la formulación
// (el 8 de septiembre es día 2, no día 1 como en la semilla); el «regalo»
// se registra como «Muestra comercial» (Prueba B no tiene ese concepto).
//   node design-hub/qa/e2e-fase5.mjs   (con `web` corriendo)
import { chromium } from "@playwright/test"
import { execFileSync } from "node:child_process"
import { mkdir, writeFile } from "node:fs/promises"
import { rmSync, writeFileSync } from "node:fs"
import path from "node:path"
import { fileURLToPath } from "node:url"

const AQUI = path.dirname(fileURLToPath(import.meta.url))
const RAIZ = path.join(AQUI, "..", "..")
const WEB = process.env.WEB_URL ?? "http://localhost:5173"
const SLUG = "prueba-b"
const ORG = "b0000000-0000-4000-8000-0000000000b0"
const OUT = path.join(AQUI, "evidence", "fase5-e2e")
const fallos = []
const ok = (c, m) => {
  if (!c) fallos.push(m)
}
const paso = (m) => console.log(`· ${m}`)
function sql(q) {
  const f = path.join(AQUI, ".e2e-fase5.sql")
  writeFileSync(f, q)
  const out = execFileSync("supabase", ["db", "query", "--linked", "-f", f], {
    cwd: RAIZ,
    encoding: "utf8",
  })
  rmSync(f, { force: true })
  const m = /\[[\s\S]*\]/.exec(out)
  return m ? JSON.parse(m[0]) : []
}

await mkdir(OUT, { recursive: true })
const lotesAntes = Number(sql(`select count(*) as n from lots where organization_id = '${ORG}';`)[0]?.n)
if (lotesAntes !== 0) {
  console.log(`Prueba B no está vacía (${lotesAntes} lotes): corre \`supabase db reset --linked --yes\` primero.`)
  process.exit(2)
}

const browser = await chromium.launch()
const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 } })
const page = await ctx.newPage()
const errores = []
page.on("pageerror", (e) => errores.push(String(e)))
const foto = (n) => page.screenshot({ path: path.join(OUT, `${n}.png`), fullPage: true })

// ---------- utilidades de interfaz ----------
// «¿Cuándo pasó?»: «cambiar» abre el datetime-local nativo
async function cuando(scope, valor) {
  // Se acota al campo (.cuando): otras pantallas tienen su propio «cambiar»
  const campo = scope.locator(".cuando").first()
  await campo.getByRole("button", { name: "cambiar" }).click()
  const inp = campo.locator("input[type=datetime-local]")
  await inp.fill(valor)
  await inp.dispatchEvent("blur")
}
// select por etiqueta parcial (las opciones traen capacidad, folio, saldo…)
async function elegir(select, re) {
  const opciones = await select.locator("option").allTextContents()
  const etiqueta = opciones.find((o) => re.test(o))
  if (!etiqueta) throw new Error(`Sin opción ${re} entre: ${opciones.join(" | ")}`)
  await select.selectOption({ label: etiqueta })
}
async function notaSiPide(scope, texto) {
  const nota = scope.getByLabel("Nota (obligatoria por el aviso)")
  if (await nota.count()) await nota.fill(texto)
}
async function entrar() {
  await page.goto(`${WEB}/e/${SLUG}`)
  await page.locator("input[name=usuario]").fill("duena@pruebab.mx")
  await page.locator("input[name=contrasena]").fill("prueba-b-2026")
  await page.locator("button[type=submit]").click()
  await page.waitForURL("**/inicio", { timeout: 20000 })
}

// ---------- 1. Configuración: recursos y proveedores ----------
async function recurso(kind, code, cap, politica, clase) {
  await page.getByRole("button", { name: "Agregar recurso" }).first().click()
  const capa = page.getByRole("dialog", { name: "Agregar recurso" })
  await capa.waitFor()
  await capa.getByLabel("Tipo de recurso").selectOption(kind)
  await capa.getByLabel("Código (como le dicen)").fill(code)
  if (cap != null) await capa.getByLabel("Capacidad", { exact: true }).fill(String(cap))
  // La política es un segmento (radiogroup), no un select
  if (politica)
    await capa
      .getByRole("radio", { name: new RegExp(`^${politica[0].toUpperCase()}${politica.slice(1)}`) })
      .click()
  if (clase) await capa.getByLabel("Clase de líquido").selectOption(clase)
  await page.getByRole("button", { name: "Guardar recurso" }).click()
  await page.getByRole("button", { name: `Acciones para ${code}` }).waitFor({ timeout: 20000 })
}
async function proveedor(nombre, tipo) {
  await page.getByRole("button", { name: "Agregar proveedor" }).first().click()
  const capa = page.getByRole("dialog", { name: "Agregar proveedor" })
  await capa.waitFor()
  await capa.getByLabel("Nombre", { exact: true }).fill(nombre)
  await elegir(capa.getByLabel("Tipo de proveedor"), new RegExp(tipo))
  await page.getByRole("button", { name: "Guardar", exact: true }).click()
  await page.getByRole("button", { name: `Acciones para ${nombre}` }).waitFor({ timeout: 20000 })
}

paso("Dueña entra a Prueba B (vacío)")
await entrar()
await page.getByRole("heading", { name: "¿Qué tienes hoy?" }).waitFor({ timeout: 20000 })

paso("1. Recursos: horno, molino, tinas, alambiques, colectores, tanques")
await page.goto(`${WEB}/e/${SLUG}/configuracion/recursos`)
await page.getByRole("button", { name: "Acciones para Tina B1" }).waitFor({ timeout: 20000 })
await recurso("horno", "Horno 1", 10000, "libre")
await recurso("molino", "Tahona", 1000, "libre")
for (const t of ["Tina 1", "Tina 2", "Tina 3"]) await recurso("tina", t, 1500, "flexible")
await recurso("alambique", "Alambique 1", 300, "estricta")
await recurso("alambique", "Alambique 2", 250, "estricta")
await recurso("colector", "Colector mezcal", 60, "flexible", "mezcal")
await recurso("colector", "Colector ordinario", 200, "flexible", "ordinario")
await recurso("colector", "Colector colas", 200, "flexible", "colas")
await recurso("tanque", "Tanque 1", 1000, "flexible")
await recurso("tanque", "Tanque 2", 1500, "flexible")
await foto("01-recursos")

paso("1b. Proveedores del catálogo")
await page.goto(`${WEB}/e/${SLUG}/configuracion/catalogos`)
await page.getByLabel("Catálogo").waitFor({ timeout: 20000 })
await page.getByLabel("Catálogo").selectOption("proveedor")
await page.getByRole("button", { name: "Agregar proveedor" }).first().waitFor()
await proveedor("Magueyes Don Pedro", "Maguey")
await proveedor("Destilados Hermanos Luna", "Granel")

// ---------- 2. Carga inicial del Tanque 2 (arranque) ----------
paso("2. Arranque: Tanque 2 ya tenía 600 L a 44.2 %")
await page.goto(`${WEB}/e/${SLUG}/inicio`)
await page.getByRole("link", { name: "Empezar" }).click()
await page.waitForURL("**/arranque")
const tarjeta = page.getByRole("article", { name: "Tanque 2" })
await tarjeta.waitFor({ timeout: 20000 })
await tarjeta.getByRole("radio", { name: "Tiene algo" }).click()
await tarjeta.getByLabel("Litros").fill("600")
await tarjeta.getByLabel("% Alc.").fill("44.2")
await tarjeta.getByRole("button", { name: "Guardar 600 L en Tanque 2" }).click()
await tarjeta.getByText("guardado").waitFor({ timeout: 30000 })
await foto("02-arranque")

// ---------- 3. Tina 3 ya fermentaba ----------
paso("3. Fermentación: Tina 3 ya fermentaba con 1,300 L (1 sep)")
await page.goto(`${WEB}/e/${SLUG}/fermentacion`)
await page.getByRole("button", { name: "Tina que ya fermentaba" }).waitFor({ timeout: 20000 })
await page.getByRole("button", { name: "Tina que ya fermentaba" }).click()
const cf = page.getByRole("dialog", { name: "Tina que ya fermentaba" })
await cf.waitFor()
await elegir(cf.getByLabel("Tina (libre)"), /^Tina 3/)
await cf.getByLabel("Litros").fill("1300")
await cuando(cf, "2026-09-01T10:40")
await cf.getByRole("button", { name: /en Tina 3/ }).click()
await cf.waitFor({ state: "hidden", timeout: 30000 })
await page.getByRole("listitem", { name: "Tina 3" }).waitFor({ timeout: 20000 })

// ---------- 4. Maguey y horneado ----------
paso("4. Maguey: recepción MAG-001 de 8,000 kg (2 sep)")
await page.goto(`${WEB}/e/${SLUG}/maguey`)
await page.getByRole("heading", { name: "Maguey", exact: true }).waitFor({ timeout: 20000 })
await page.locator(".mh-loading").waitFor({ state: "detached", timeout: 20000 })
await page.getByRole("button", { name: "Registrar recepción" }).first().click()
await page.getByLabel("Kilos (obligatorio)").fill("8000")
await page.locator(".mh-form details summary").click()
await page.getByLabel("Piñas (opcional)").fill("132")
await elegir(page.getByLabel("Especie (opcional)"), /Espadín/)
await elegir(page.getByLabel("Predio (opcional)"), /Predio B/)
await elegir(page.getByLabel("Proveedor (opcional)"), /Don Pedro/)
await page.getByLabel("Nota de calidad (opcional)").fill("Piñas de 8 años, buen tamaño")
await cuando(page.locator(".mh-form"), "2026-09-02T07:30")
await page.getByLabel("Folio (opcional)").fill("MAG-001")
await page.getByRole("button", { name: /8,000 kg · Registrar recepción/ }).click()
await page.getByRole("status").filter({ hasText: "Recepción registrada" }).waitFor({ timeout: 30000 })
await foto("04-maguey")

paso("4b. Horneado: HOR-001 en Horno 1 con MAG-001 (2 sep) y cierre con 6,200 kg (6 sep)")
await page.goto(`${WEB}/e/${SLUG}/horneado`)
await page.getByRole("heading", { name: "Horneado", exact: true }).waitFor({ timeout: 20000 })
await page.locator(".mh-loading").waitFor({ state: "detached", timeout: 20000 })
await page.getByRole("button", { name: "Abrir horneada" }).first().click()
await elegir(page.getByLabel("Horno"), /Horno 1/)
await page.getByLabel("Kilos de MAG-001").fill("8000")
await cuando(page.locator(".mh-form"), "2026-09-02T12:00")
await page.getByLabel("Folio (opcional)").fill("HOR-001")
await page.getByRole("button", { name: /Revisar Horno 1/ }).click()
await page.getByRole("button", { name: /Abrir Horno 1/ }).click()
await page.getByRole("status").filter({ hasText: "Horneada abierta" }).waitFor({ timeout: 30000 })
await page.getByRole("button", { name: "Cerrar horneada" }).first().waitFor({ timeout: 20000 })
await page.getByRole("button", { name: "Cerrar horneada" }).first().click()
const dlgCierre = page.getByRole("dialog")
await dlgCierre.waitFor()
await dlgCierre.getByLabel("Kilos cocidos").fill("6200")
await dlgCierre.getByLabel("Combustible (opcional)").fill("Leña de encino")
await cuando(dlgCierre, "2026-09-06T08:00")
await dlgCierre.getByLabel("Folio del cocido (opcional)").fill("AC-001")
await dlgCierre.getByRole("button", { name: /Cerrar con .* de cocido/ }).click()
await page.getByRole("status").filter({ hasText: "Horneada cerrada" }).waitFor({ timeout: 30000 })
await foto("04b-horneado")

// ---------- 5. Formulación a Tina 1 y Tina 2 ----------
paso("5. Formulación: 6,200 kg de AC-001 + 1,900 L de agua → Tina 1 y Tina 2 con 1,400 L (7 sep)")
await page.goto(`${WEB}/e/${SLUG}/fermentacion/formular`)
await page.getByText("Agave cocido").waitFor({ timeout: 20000 })
await elegir(page.getByLabel("Molino"), /Tahona/)
await page.locator(".asig__fila", { hasText: "AC-001" }).getByLabel(/Kilos/).fill("6200")
await page.getByLabel("Agua").fill("1900")
for (const t of ["Tina 1", "Tina 2"]) {
  await page.locator(".asig__fila", { hasText: t }).getByLabel(/Litros/).fill("1400")
  await page.getByLabel(`Folio para ${t} (opcional)`).fill(t === "Tina 1" ? "FER-T1-001" : "FER-T2-001")
}
await cuando(page, "2026-09-07T09:00")
await page.getByLabel("Método (opcional)").fill("Tahona con mula")
await page.getByRole("button", { name: "Registrar formulación" }).click()
await page.waitForURL("**/fermentacion?aviso=formulacion", { timeout: 30000 })
await page.getByRole("listitem", { name: "Tina 1" }).waitFor({ timeout: 20000 })
await foto("05-formulacion")

// ---------- 6. Mediciones diarias ----------
const ACT = ["quieta", "apenas", "poca", "media", "mucha", "muy activa"]
async function medir(tina, fecha, temp, brix, act) {
  await page.goto(`${WEB}/e/${SLUG}/fermentacion`)
  await page.getByText(/tinas en uso/).waitFor({ timeout: 20000 })
  const fila = page.getByRole("listitem", { name: tina })
  // Sin mediciones el enlace dice «Registrar medición»; después, «Medir Tina N»
  const href = await fila
    .getByRole("link", { name: new RegExp(`^(Registrar medición|Medir ${tina})`) })
    .first()
    .getAttribute("href")
  await page.goto(`${WEB}${href}`)
  await page.getByRole("status").filter({ hasText: "Paso 1 de 4" }).waitFor({ timeout: 20000 })
  await cuando(page, fecha)
  await page.getByLabel("Temperatura").fill(String(temp))
  await page.getByRole("button", { name: "Siguiente" }).click()
  await page.getByRole("status").filter({ hasText: "Paso 2 de 4" }).waitFor()
  await page.getByLabel("Brix").fill(String(brix))
  await page.getByRole("button", { name: "Siguiente" }).click()
  await page.getByRole("status").filter({ hasText: "Paso 3 de 4" }).waitFor()
  await page.getByRole("radio", { name: `${act} · ${ACT[act - 1]}` }).click()
  await page.getByRole("button", { name: "Revisar" }).click()
  await page.getByRole("status").filter({ hasText: "Paso 4 de 4" }).waitFor()
  await notaSiPide(page, "Simulación §15.1: Brix fuera del rango habitual")
  await page.getByRole("button", { name: "Guardar medición" }).click()
  await page.getByRole("status").filter({ hasText: "Medición guardada · enviada" }).waitFor({ timeout: 30000 })
}
paso("6. Ocho mediciones (Tina 1 del 8 al 12 sep, Tina 2 del 8 al 10 sep)")
await medir("Tina 1", "2026-09-08T08:30", 27.5, 12.0, 4)
await medir("Tina 1", "2026-09-09T08:30", 29.0, 9.5, 6)
await medir("Tina 1", "2026-09-10T08:30", 30.5, 6.0, 6)
await medir("Tina 1", "2026-09-11T08:30", 29.5, 3.5, 6)
await medir("Tina 1", "2026-09-12T08:30", 28.0, 1.5, 3)
await medir("Tina 2", "2026-09-08T08:30", 27.0, 12.2, 3)
await medir("Tina 2", "2026-09-09T08:30", 28.5, 10.1, 6)
await medir("Tina 2", "2026-09-10T08:30", 30.0, 7.4, 6)
await foto("06-mediciones")

paso("6b. Tina 1 declarada lista (12 sep)")
await page.goto(`${WEB}/e/${SLUG}/fermentacion`)
await page.getByText(/tinas en uso/).waitFor({ timeout: 20000 })
const hrefT1 = await page.getByRole("listitem", { name: "Tina 1" }).getByRole("link", { name: /^(Registrar medición|Medir Tina 1)/ }).first().getAttribute("href")
const cicloT1 = hrefT1.split("/fermentacion/")[1].split("/")[0]
await page.goto(`${WEB}/e/${SLUG}/fermentacion/${cicloT1}`)
await page.getByRole("button", { name: "Declarar lista" }).waitFor({ timeout: 20000 })
await page.getByRole("button", { name: "Declarar lista" }).click()
const dlgLista = page.getByRole("dialog")
await dlgLista.waitFor()
await cuando(dlgLista, "2026-09-12T17:00")
await dlgLista.getByLabel("Nota (opcional)").fill("Día 5: ya no burbujea, sabor seco")
await dlgLista.getByRole("button", { name: "Declarar lista" }).click()
await dlgLista.waitFor({ state: "hidden", timeout: 30000 })

// ---------- 7. Destilación ----------
async function abrirCorrida({ alambique, pasada, origenes, fecha, folio, nota }) {
  await page.goto(`${WEB}/e/${SLUG}/destilacion/abrir`)
  await page.getByText("Alambique y pasada").waitFor({ timeout: 20000 })
  await elegir(page.getByLabel("Alambique"), new RegExp(`^${alambique}`))
  await page.getByRole("radio", { name: pasada === "segunda" ? "2ª pasada" : "1ª pasada" }).click()
  for (const [nombre, litros] of origenes)
    await page.locator(".asig__fila", { hasText: nombre }).getByLabel(/Litros/).fill(String(litros))
  await cuando(page, fecha)
  await page.getByLabel("Folio (opcional)").fill(folio)
  if (nota) await notaSiPide(page, nota)
  await page.getByRole("button", { name: /Abrir corrida con/ }).click()
  await page.waitForURL(/\/destilacion\/[^/?]+\?aviso=abierta/, { timeout: 30000 })
  return page.url().split("/destilacion/")[1].split("?")[0]
}
async function corte(runId, clase, litros, abv, fecha) {
  await page.goto(`${WEB}/e/${SLUG}/destilacion/${runId}/corte`)
  await page.getByRole("status").filter({ hasText: "Paso 1 de 4" }).waitFor({ timeout: 20000 })
  await page.getByRole("radio", { name: clase }).click()
  await cuando(page, fecha)
  await page.getByRole("button", { name: "Siguiente" }).click()
  await page.getByLabel("Litros").fill(String(litros))
  await page.getByRole("button", { name: "Siguiente" }).click()
  await page.getByLabel("% Alc.").fill(String(abv))
  await page.getByRole("button", { name: "Revisar" }).click()
  await page.getByRole("status").filter({ hasText: "Paso 4 de 4" }).waitFor()
  await notaSiPide(page, "Simulación §15.1: % Alc. fuera del rango habitual")
  await page.getByRole("button", { name: "Guardar corte" }).click()
  await page.getByText("Corte guardado · enviado").waitFor({ timeout: 30000 })
}
async function cerrarCorrida(runId, fecha) {
  await page.goto(`${WEB}/e/${SLUG}/destilacion/${runId}`)
  await page.getByRole("button", { name: "Cerrar corrida" }).waitFor({ timeout: 20000 })
  await page.getByRole("button", { name: "Cerrar corrida" }).click()
  const dlg = page.getByRole("dialog", { name: /Cerrar la corrida/ })
  await dlg.waitFor()
  await cuando(dlg, fecha)
  await notaSiPide(dlg, "Simulación §15.1")
  await dlg.getByRole("button", { name: "Cerrar corrida" }).click()
  await page.waitForURL("**/destilacion?aviso=cerrada", { timeout: 30000 })
}
paso("7. DES-001 y DES-002 (1ª pasada desde la Tina 1, 13 sep)")
const des1 = await abrirCorrida({ alambique: "Alambique 1", pasada: "primera", origenes: [["Tina 1", 290]], fecha: "2026-09-13T06:00", folio: "DES-001" })
await corte(des1, "Mezcal", 8, 51.0, "2026-09-13T08:00")
await corte(des1, "Ordinario", 40, 24.0, "2026-09-13T10:00")
await corte(des1, "Colas", 12, 9.0, "2026-09-13T12:00")
await cerrarCorrida(des1, "2026-09-13T14:00")
const des2 = await abrirCorrida({ alambique: "Alambique 2", pasada: "primera", origenes: [["Tina 1", 240]], fecha: "2026-09-13T06:00", folio: "DES-002" })
await corte(des2, "Mezcal", 6, 50.0, "2026-09-13T08:00")
await corte(des2, "Ordinario", 34, 23.0, "2026-09-13T10:00")
await corte(des2, "Colas", 10, 8.0, "2026-09-13T12:00")
await cerrarCorrida(des2, "2026-09-13T14:00")
paso("7b. DES-003 (2ª pasada con ordinario y colas juntos → aviso y nota, 15 sep)")
const des3 = await abrirCorrida({
  alambique: "Alambique 1",
  pasada: "segunda",
  origenes: [
    ["Colector ordinario", 74],
    ["Colector colas", 22],
  ],
  fecha: "2026-09-15T06:00",
  folio: "DES-003",
  nota: "Había olla libre y poca cola; se juntó con el ordinario",
})
await corte(des3, "Mezcal", 26, 52.5, "2026-09-15T08:00")
await corte(des3, "Colas", 16, 10.0, "2026-09-15T10:00")
await cerrarCorrida(des3, "2026-09-15T14:00")
await page.goto(`${WEB}/e/${SLUG}/destilacion`)
await page.getByRole("heading", { name: "Últimas corridas" }).waitFor({ timeout: 20000 })
await foto("07-destilacion")

// ---------- 8. Granel ----------
paso("8. Granel: el mezcal del colector pasa al Tanque 1 con folio nuevo G-2609-01 (16 sep)")
await page.goto(`${WEB}/e/${SLUG}/granel/transferir`)
await page.getByText("De dónde y a dónde").waitFor({ timeout: 20000 })
await elegir(page.getByLabel("Origen"), /^Colector mezcal/)
await elegir(page.getByLabel("Destino"), /^Tanque 1/)
await page.getByLabel("Litros", { exact: true }).fill("40")
await page.getByLabel("% Alc.", { exact: true }).fill("51.6")
await page.getByLabel("Folio nuevo (opcional)").fill("G-2609-01")
await cuando(page, "2026-09-16T09:00")
await page.getByRole("button", { name: /Transferir 40 L/ }).click()
await page.getByText(/Transferidos 40 L a Tanque 1/).waitFor({ timeout: 30000 })

await page.goto(`${WEB}/e/${SLUG}/granel`)
await page.getByText(/de granel/).waitFor({ timeout: 20000 })
const idTanque = async (code) =>
  (await page.getByRole("article", { name: code }).getByRole("link", { name: "Ver historial" }).getAttribute("href"))
    .split("/granel/")[1]
    .split("/")[0]
const tq1 = await idTanque("Tanque 1")
const tq2 = await idTanque("Tanque 2")

async function movimiento(tanque, code, direccion, concepto, llenar, verbo, fecha, nota) {
  await page.goto(`${WEB}/e/${SLUG}/granel/${tanque}/movimiento?direccion=${direccion}`)
  await page.getByRole("radio", { name: concepto }).waitFor({ timeout: 20000 })
  await page.getByRole("radio", { name: concepto }).click()
  await page.getByRole("button", { name: "Siguiente" }).click()
  await llenar()
  await cuando(page, fecha)
  if (nota) {
    const obligatoria = page.getByLabel("Nota (obligatoria por el aviso)")
    if (await obligatoria.count()) await obligatoria.fill(nota)
    else await page.getByLabel("Nota (opcional)").fill(nota)
  }
  await page.getByRole("button", { name: verbo }).click()
  await page.getByRole("heading", { name: code, exact: true }).waitFor({ timeout: 30000 })
}
paso("8b. Agua 4 L en Tanque 1 → declara 43.8 L a 47.0 % (diferencia −0.2 L, 16 sep)")
await movimiento(tq1, "Tanque 1", "entrada", /Agua para bajar grado/, async () => {
  await page.getByLabel("Litros", { exact: true }).fill("4")
  await page.getByLabel("Volumen resultante").fill("43.8")
  await page.getByLabel("% Alc. resultante").fill("47.0")
}, /Registrar 4 L de agua/, "2026-09-16T11:00", "Contracción al mezclar")
paso("8c. Puntas sin lote 2 L al Tanque 2 (17 sep)")
await movimiento(tq2, "Tanque 2", "entrada", /Puntas para subir grado/, async () => {
  // Con «pide resultado» la app no captura el % Alc. de lo que entra (la
  // semilla traía 68 %): solo el resultado declarado
  await page.getByLabel("Litros", { exact: true }).fill("2")
  await page.getByLabel("Volumen resultante").fill("602")
  await page.getByLabel("% Alc. resultante").fill("44.6")
}, /Registrar 2 L/, "2026-09-17T10:00", "Puntas guardadas de corridas de agosto, sin lote")
paso("8d. Unión: G-2609-01 (Tanque 1) al Tanque 2 conservando el folio (18 sep)")
await movimiento(tq2, "Tanque 2", "entrada", /Unión con otro lote/, async () => {
  await elegir(page.getByLabel("Lote de origen (y dónde está)"), /Tanque 1 · G-2609-01/)
  await page.getByLabel("Litros", { exact: true }).fill("43.8")
  await page.getByLabel("% Alc. del que entra").fill("47.0")
  await page.getByRole("radio", { name: /^Conservar/ }).click()
  await page.getByLabel("Volumen resultante").fill("645.8")
  await page.getByLabel("% Alc. resultante").fill("44.9")
}, /Unir 43.8 L/, "2026-09-18T09:30", "Se conserva el folio del lote mayor")
paso("8e. Compra de 250 L al Tanque 1 (G-COMPRA-01, 19 sep)")
await movimiento(tq1, "Tanque 1", "entrada", /Compra de granel/, async () => {
  await page.getByLabel("Litros", { exact: true }).fill("250")
  await page.getByLabel("Volumen resultante").fill("250")
  await page.getByLabel("% Alc. resultante").fill("46.0")
  await page.getByLabel("Folio del lote (opcional)").fill("G-COMPRA-01")
  await elegir(page.getByLabel("Proveedor del catálogo"), /Hermanos Luna/)
  await page.getByLabel("Documento (remisión, factura)").fill("Remisión 0452")
  await elegir(page.getByLabel("Especie declarada"), /Espadín/)
  await page.getByLabel("Predio declarado").fill("Sola de Vega")
}, /Registrar compra de granel de 250 L/, "2026-09-19T12:00")
paso("8f. Salidas del Tanque 2: muestra 1 L, autoconsumo 2 L, venta 300 L, regalo 1 L (19–22 sep)")
await movimiento(tq2, "Tanque 2", "salida", /Muestra de laboratorio/, async () => {
  await page.getByLabel("Litros", { exact: true }).fill("1")
  await page.getByLabel("Contraparte").fill("Laboratorio ficticio de Oaxaca")
  await page.getByLabel(/Documento/).fill("Análisis 2026-311")
}, /Sacar 1 L/, "2026-09-19T13:00")
await movimiento(tq2, "Tanque 2", "salida", /Autoconsumo/, async () => {
  await page.getByLabel("Litros", { exact: true }).fill("2")
}, /Sacar 2 L/, "2026-09-20T13:00")
await movimiento(tq2, "Tanque 2", "salida", /Venta a granel/, async () => {
  await page.getByLabel("Litros", { exact: true }).fill("300")
  await page.getByLabel("Contraparte").fill("Cliente ficticio S.A.")
  await page.getByLabel(/Documento/).fill("Remisión 118")
}, /Sacar 300 L/, "2026-09-22T13:00")
await movimiento(tq2, "Tanque 2", "salida", /Muestra comercial/, async () => {
  await page.getByLabel("Litros", { exact: true }).fill("1")
  await page.getByLabel("Contraparte").fill("Cliente ficticio S.A.")
}, /Sacar 1 L/, "2026-09-22T13:00", "Regalo a cliente (Prueba B no tiene ese concepto)")
await page.goto(`${WEB}/e/${SLUG}/granel`)
await page.getByText(/de granel/).waitFor({ timeout: 20000 })
await foto("08-granel")
await page.goto(`${WEB}/e/${SLUG}/granel/${tq2}`)
await page.getByRole("table").waitFor({ timeout: 20000 })
await foto("08-tanque2-historial")

// ---------- 9. Saldos finales = §15.1 ----------
paso("9. Saldos de Prueba B contra §15.1")
const saldos = sql(
  `select r.code, l.folio, b.volume_l::float as volumen from resource_lot_balances b
     join resources r on r.id = b.resource_id join lots l on l.id = b.lot_id
    where b.organization_id = '${ORG}' and b.volume_l <> 0 order by r.code, l.folio;`,
)
const ESPERADO = {
  "Colector colas": { volumen: 16, folio: "auto (semilla COL-002)" },
  "Tanque 1": { volumen: 250, folio: "G-COMPRA-01" },
  "Tanque 2": { volumen: 341.8, folio: "auto (semilla G-INI-01)" },
  "Tina 1": { volumen: 870, folio: "FER-T1-001" },
  "Tina 2": { volumen: 1400, folio: "FER-T2-001" },
  "Tina 3": { volumen: 1300, folio: "auto (semilla FER-T3-INI)" },
}
const tabla = []
for (const [code, e] of Object.entries(ESPERADO)) {
  const filas = saldos.filter((s) => s.code === code)
  const total = filas.reduce((a, s) => a + s.volumen, 0)
  const folios = filas.map((s) => s.folio).join(" + ")
  tabla.push({ recurso: code, esperado: e.volumen, real: total, folioEsperado: e.folio, folioReal: folios })
  ok(Math.abs(total - e.volumen) < 0.01, `${code}: ${total} L (esperado ${e.volumen})`)
  ok(filas.length === 1, `${code}: un solo lote (hay ${filas.length}: ${folios})`)
  if (!e.folio.startsWith("auto")) ok(folios === e.folio, `${code}: folio ${folios} (esperado ${e.folio})`)
}
const sobrantes = saldos.filter((s) => !ESPERADO[s.code])
ok(sobrantes.length === 0, `recursos con saldo fuera de §15.1: ${JSON.stringify(sobrantes)}`)
const operaciones = Number(sql(`select count(*) as n from operations where organization_id = '${ORG}';`)[0]?.n)
const avisos = sql(`select w.code, w.note from operation_warnings w join operations o on o.id = w.operation_id where o.organization_id = '${ORG}' order by o.occurred_at;`)
ok(avisos.some((a) => a.code === "mezcla_clases_2a"), "aviso mezcla_clases_2a registrado con nota")
ok(avisos.some((a) => a.code === "diferencia_volumen"), "aviso diferencia_volumen registrado con nota")
ok(errores.length === 0, `errores de página: ${errores.join(" | ")}`)
console.table(tabla)
await browser.close()
const resumen = {
  fecha: new Date().toISOString(),
  empresa: SLUG,
  status: fallos.length ? "FAIL" : "PASS",
  operaciones,
  saldos,
  tabla,
  avisos,
  fallos,
  declarado: [
    "folios automáticos donde la interfaz no los pide: cortes, formulación (F-001), tina que ya fermentaba (FER-T3-INI), carga inicial (G-INI-01)",
    "la carga inicial del arranque se registra con la fecha de hoy",
    "el día del ciclo lo cuenta la app desde la formulación (8 sep = día 2)",
    "«Regalo a cliente» → «Muestra comercial» (concepto con contraparte de Prueba B)",
    "con «pide resultado» la app no captura el % Alc. de lo que entra (puntas 68 %, compra 46 %): solo el resultado declarado",
    "Brix < 12 y % Alc. < 35 piden nota en la app (la semilla no la traía): se escribe «Simulación §15.1»",
  ],
}
await writeFile(path.join(OUT, "e2e-fase5.json"), JSON.stringify(resumen, null, 2))
console.log(JSON.stringify({ status: resumen.status, operaciones, fallos }, null, 2))
process.exit(fallos.length ? 1 : 0)
