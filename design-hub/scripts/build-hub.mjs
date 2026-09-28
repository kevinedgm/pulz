// Design Hub · generador del sitio (registry: hub-shell, ronda hub/r01).
// Una sola fuente: README.md + fichas Markdown (mora) + system/registry.json
// (lima). Escribe design-hub/site/ con el shell (assets/hub-shell.css +
// hub-navigation.js). El HTML generado no se edita a mano.
//   node design-hub/scripts/build-hub.mjs   (o pnpm build:hub-site)
import { marked } from "marked"
import { copyFile, mkdir, readdir, readFile, rm, writeFile } from "node:fs/promises"
import path from "node:path"
import { fileURLToPath } from "node:url"

const AQUI = path.dirname(fileURLToPath(import.meta.url))
const HUB = path.join(AQUI, "..")
const RAIZ = path.join(HUB, "..")
const SITE = path.join(HUB, "site")
const REPO = "https://github.com/kevinedgm/pulz/blob/main/"
const GRUPOS = [
  { dir: "Foundations", titulo: "Foundations" },
  { dir: "Components", titulo: "Components" },
  { dir: "Patterns", titulo: "Patterns" },
  { dir: "Screens", titulo: "Screens" },
]
const NOMBRE = {
  Tokens: "Tokens",
  Icons: "Iconos",
}

const registry = JSON.parse(await readFile(path.join(HUB, "system", "registry.json"), "utf8"))
const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c])
const slug = (t) =>
  t
    .toLowerCase()
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/(^-|-$)/g, "")

// ── Fichas ────────────────────────────────────────────────────────────────
async function leerFichas() {
  const fichas = []
  for (const g of GRUPOS) {
    const dir = path.join(HUB, g.dir)
    let files = []
    try {
      files = (await readdir(dir)).filter((f) => f.endsWith(".md"))
    } catch {
      continue
    }
    for (const f of files.sort()) {
      const id = f.replace(/\.md$/, "")
      const md = await readFile(path.join(dir, f), "utf8")
      const titulo = (md.match(/^#\s+(.+)$/m)?.[1] ?? id).replace(/\s*·\s*`[^`]+`\s*$/, "")
      const reg = registry[id]
      fichas.push({ grupo: g, id, md, titulo: NOMBRE[id] ?? titulo, reg })
    }
  }
  return fichas
}

// Enlaces del Markdown → sitio: .md → .html; rutas del repo → GitHub; evidencia/demo relativas
function reescribirEnlace(href, ficha) {
  if (/^https?:/.test(href)) return href
  if (href.startsWith("#")) return href
  const limpio = href.replace(/^\.\.\//, "")
  if (limpio.endsWith(".md")) {
    // ../Screens/equipo.md, Components/button.md, lab/acceso/r01/…
    const rel = limpio.replace(/\.md$/, ".html")
    if (/^(Foundations|Components|Patterns|Screens)\//.test(rel)) return (ficha ? "../" : "") + rel
    return (ficha ? "../../" : "../") + limpio // docs del laboratorio: al repo en local
  }
  if (/^(qa\/evidence|Components\/demo|lab\/)/.test(limpio)) return (ficha ? "../../" : "../") + limpio
  if (/^(system\/registry\.json)/.test(limpio)) return (ficha ? "../../" : "../") + limpio
  return REPO + limpio.replace(/^\.\.\//, "")
}

function render(md, ficha) {
  const renderer = new marked.Renderer()
  const link = renderer.link.bind(renderer)
  renderer.link = (t) => link({ ...t, href: reescribirEnlace(t.href, ficha) })
  const heading = renderer.heading.bind(renderer)
  renderer.heading = (t) => {
    if (t.depth === 2) return `<h2 id="${slug(t.text)}">${marked.parseInline(t.text)}</h2>\n`
    return heading(t)
  }
  return marked.parse(md, { renderer })
}

const mad = (m) => `<span class="hub-mad hub-mad--${esc(m)}">${esc(m)}</span>`
function metaDe(reg) {
  if (!reg) return ""
  return `<p class="hub-meta"><span>Tipo <b>${esc(reg.kind)}</b></span><span>Estado ${mad(reg.status)}</span><span>Versión <b>${esc(reg.version)}</b></span><span>Owner <b>${esc(reg.owner ?? "—")}</b></span><span>Ronda <b>${esc(reg.sourceRound ?? "—")}</b></span><span>Actualizado <b>${esc(reg.updated)}</b></span></p>`
}
const nivel = (v) => (typeof v === "string" ? v : `${v.status}${v.caveat ? ` · ${v.caveat}` : ""}`)
function facetas(reg) {
  if (!reg?.qa) return ""
  const filas = Object.entries(reg.qa)
    .filter(([k]) => !["candidate", "stable"].includes(k))
    .map(([k, v]) => `<tr><td>${esc(k)}</td><td>${esc(nivel(v))}</td></tr>`)
    .join("")
  return `<h2 id="facetas-de-qa-registry">Facetas de QA (registry)</h2><table><thead><tr><th>Faceta</th><th>Nivel de evidencia</th></tr></thead><tbody>${filas}</tbody></table><p>Candidate: <b>${reg.qa.candidate ? "sí" : "no"}</b> · Stable: <b>${reg.qa.stable ? "sí" : "no"}</b></p>`
}
async function galeria(reg) {
  const carpeta = reg?.evidence?.replace(/^\.\.\//, "")
  if (!carpeta) return ""
  let files = []
  try {
    files = (await readdir(path.join(HUB, carpeta))).filter((f) => f.endsWith(".png")).sort()
  } catch {
    return ""
  }
  const pantallas = [...new Set(files.map((f) => f.replace(/-\d+-(light|dark)\.png$/, "")))]
  const bloques = pantallas
    .map((p) => {
      const figs = files
        .filter((f) => f.startsWith(p + "-"))
        .map((f) => {
          const m = f.match(/-(\d+)-(light|dark)\.png$/)
          return `<figure><a href="../../${carpeta}${f}"><img loading="lazy" src="../../${carpeta}${f}" alt="${esc(p)} a ${m?.[1]} px, tema ${m?.[2] === "dark" ? "oscuro" : "claro"}"></a><figcaption>${m?.[1]} · ${m?.[2] === "dark" ? "oscuro" : "claro"}</figcaption></figure>`
        })
        .join("")
      return `<h3>${esc(p)}</h3><div class="hub-gal">${figs}</div>`
    })
    .join("")
  return `<h2 id="preview-capturas">Preview (capturas)</h2><p>Evidencia real de <a href="../../${carpeta}">${esc(carpeta)}</a>, 1440 / 1024 / 768 / 390 × claro / oscuro.</p>${bloques}`
}
function previewDemo(reg) {
  const demo = reg?.demo?.replace(/^\.\.\//, "")
  if (!demo) return ""
  const id = demo.split("#")[1]
  const src = `../../Components/demo/index.html?pieza=${id}&solo=1`
  return `<h2 id="preview">Preview</h2><div class="hub-preview"><div class="hub-preview__bar"><span>Demo real · construida desde el código con <code>build:hub</code></span><a href="${src}" target="_blank" rel="noopener">Abrir aparte ↗</a></div><iframe src="${src}" title="Demo real de la pieza" loading="lazy"></iframe></div><p>Si la demo no carga, sirve el Hub con <code>python3 -m http.server 4321</code> en la raíz del repo y ábrela aparte.</p>`
}
function toc(html) {
  const secs = [...html.matchAll(/<h2 id="([^"]+)">(.*?)<\/h2>/g)].map((m) => ({ id: m[1], t: m[2].replace(/<[^>]+>/g, "") }))
  if (!secs.length) return ""
  return `<aside class="hub-toc" aria-label="En esta página"><h2>En esta página</h2><ol>${secs.map((s) => `<li><a href="#${s.id}">${s.t}</a></li>`).join("")}</ol></aside>`
}

function sidebar(fichas, prefijo, actualId) {
  const grupos = GRUPOS.map((g) => {
    const items = fichas.filter((f) => f.grupo.dir === g.dir && f.reg?.status !== "deprecated")
    if (!items.length) return ""
    return `<h2>${esc(g.titulo)}</h2><ul>${items
      .map(
        (f) =>
          `<li><a href="${prefijo}${g.dir}/${f.id}.html"${f.id === actualId ? ' aria-current="page"' : ""}>${esc(f.titulo)}${f.reg ? mad(f.reg.status) : ""}</a></li>`,
      )
      .join("")}</ul>`
  }).join("")
  return `<a class="hub-side__marca" href="${prefijo}index.html">Design Hub · PULZ</a>${grupos}<h2>QA</h2><ul><li><a href="${prefijo}qa.html"${actualId === "__qa" ? ' aria-current="page"' : ""}>Evidencia y facetas</a></li></ul>`
}
function pagina({ titulo, crumb, cuerpo, tocHtml, fichas, prefijo, actualId }) {
  const nav = sidebar(fichas, prefijo, actualId)
  return `<!doctype html>
<html lang="es-MX">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(titulo)} · Design Hub PULZ</title>
<meta name="color-scheme" content="light dark">
<link rel="stylesheet" href="${prefijo}assets/hub-shell.css">
<link rel="icon" href="${prefijo}assets/favicon.svg" type="image/svg+xml">
</head>
<body>
<div class="hub">
  <nav class="hub-side" aria-label="Design Hub">${nav}</nav>
  <div class="hub-col">
    <header class="hub-top">
      <button class="hub-menu" type="button" aria-haspopup="dialog" aria-expanded="false" aria-controls="hub-drawer">Menú</button>
      <nav class="hub-crumb" aria-label="Ruta">${crumb}</nav>
    </header>
    <main class="hub-body" id="contenido" tabindex="-1">
      <article class="hub-main">${cuerpo}</article>
      ${tocHtml}
    </main>
  </div>
</div>
<div class="hub-drawer" id="hub-drawer" role="dialog" aria-modal="true" aria-label="Design Hub">
  <button class="hub-drawer__fondo" type="button" aria-label="Cerrar menú" tabindex="-1"></button>
  <div class="hub-drawer__panel"><div style="display:flex;justify-content:flex-end"><button class="hub-drawer__cerrar" type="button">Cerrar</button></div>${nav}</div>
</div>
<script src="${prefijo}assets/hub-navigation.js"></script>
</body>
</html>
`
}

// ── Build ─────────────────────────────────────────────────────────────────
const fichas = await leerFichas()
await rm(SITE, { recursive: true, force: true })
await mkdir(path.join(SITE, "assets"), { recursive: true })
await copyFile(path.join(RAIZ, "apps", "web", "src", "shared", "ui", "tokens.css"), path.join(SITE, "assets", "tokens.css"))
await copyFile(path.join(HUB, "assets", "hub-shell.css"), path.join(SITE, "assets", "hub-shell.css"))
await copyFile(path.join(HUB, "assets", "hub-navigation.js"), path.join(SITE, "assets", "hub-navigation.js"))
await copyFile(path.join(RAIZ, "apps", "web", "public", "favicon.svg"), path.join(SITE, "assets", "favicon.svg"))

// Inicio: README.md + mapa de piezas del registry
const readme = await readFile(path.join(HUB, "README.md"), "utf8")
let inicio = render(readme.replace(/^# .*\n/, "# Design Hub · PULZ\n"), null)
const mapa = GRUPOS.map((g) => {
  const items = fichas.filter((f) => f.grupo.dir === g.dir)
  return `<div class="hub-card"><h3>${esc(g.titulo)}</h3><ul>${items.map((f) => `<li><a href="${g.dir}/${f.id}.html">${esc(f.titulo)}</a>${f.reg ? `<span>${mad(f.reg.status)} <small>${esc(f.reg.version)}</small></span>` : ""}</li>`).join("")}</ul></div>`
}).join("")
inicio = inicio.replace(/<h2 id="foundations">[\s\S]*?(?=<h2 id="lo-que-no)/, `<h2 id="piezas">Piezas (estado y versión del registry)</h2><div class="hub-mapa">${mapa}</div>\n`)
await writeFile(
  path.join(SITE, "index.html"),
  pagina({ titulo: "Inicio", crumb: "Inicio", cuerpo: inicio, tocHtml: toc(inicio), fichas, prefijo: "", actualId: "__inicio" }),
)

// Fichas
for (const f of fichas) {
  await mkdir(path.join(SITE, f.grupo.dir), { recursive: true })
  let html = render(f.md.replace(/^# .*\n/, ""), f)
  const banner =
    f.reg?.status === "deprecated"
      ? `<div class="hub-aviso"><b>Reemplazada por</b> ${f.reg.replacedBy ? `<a href="../${GRUPOS.find((g) => registry[f.reg.replacedBy] && true)?.dir ?? "Components"}/${esc(f.reg.replacedBy)}.html">${esc(f.reg.replacedBy)}</a>` : "(pendiente)"} · la demo sigue disponible.</div>`
      : ""
  const preview = f.reg?.demo ? previewDemo(f.reg) : f.grupo.dir === "Screens" ? await galeria(f.reg) : ""
  // Preview tras la primera sección (Para qué / Propósito)
  const idx = html.search(/<h2 id="(?!para-que|proposito)[^"]+">/)
  const primera = html.search(/<h2 id="(para-que|proposito)">/)
  if (html.includes("<!-- hub-preview -->")) html = html.replace("<!-- hub-preview -->", preview)
  else if (preview && primera >= 0 && idx > primera) html = html.slice(0, idx) + preview + html.slice(idx)
  else if (preview) html = preview + html
  const cuerpo = `<h1>${esc(f.titulo)} <code>${esc(f.id)}</code></h1>${metaDe(f.reg)}${banner}${html}${facetas(f.reg)}`
  await writeFile(
    path.join(SITE, f.grupo.dir, `${f.id}.html`),
    pagina({
      titulo: f.titulo,
      crumb: `<a href="../index.html">Inicio</a> / ${esc(f.grupo.titulo)} / <b>${esc(f.titulo)}</b>`,
      cuerpo,
      tocHtml: toc(cuerpo),
      fichas,
      prefijo: "../",
      actualId: f.id,
    }),
  )
}

// QA
const rondas = (await readdir(path.join(HUB, "qa", "evidence"))).filter((d) => !d.startsWith("."))
const filasRondas = []
for (const r of rondas) {
  const n = (await readdir(path.join(HUB, "qa", "evidence", r))).filter((f) => f.endsWith(".png")).length
  filasRondas.push(`<tr><td><a href="../qa/evidence/${r}/">${esc(r)}</a></td><td>${n}</td></tr>`)
}
const filasFacetas = Object.entries(registry)
  .filter(([, v]) => v.qa)
  .map(([k, v]) => `<tr><td>${esc(k)}</td><td>${mad(v.status)}</td>${["viewports", "keyboard", "touch", "zoom200", "contrast", "states"].map((f) => `<td>${esc(v.qa[f] ? nivel(v.qa[f]) : "—")}</td>`).join("")}</tr>`)
  .join("")
const qa = `<h1>QA · evidencia y facetas</h1><p>Capturas reales por ronda (Playwright, 1440 / 1024 / 768 / 390 × claro / oscuro) y el nivel de evidencia de cada faceta según <a href="../system/registry.json">el registry</a>. Los niveles se muestran con su caveat; nunca como ✓ plano.</p><h2 id="rondas">Rondas de evidencia</h2><table><thead><tr><th>Carpeta</th><th>Capturas</th></tr></thead><tbody>${filasRondas.join("")}</tbody></table><p>Scripts: <code>qa/evidencia-*.mjs</code>, <code>qa/zoom-acceso.mjs</code>, <code>qa/e2e-fase4.mjs</code>.</p><h2 id="facetas">Facetas del registry</h2><table><thead><tr><th>Pieza</th><th>Estado</th><th>viewports</th><th>keyboard</th><th>touch</th><th>zoom200</th><th>contrast</th><th>states</th></tr></thead><tbody>${filasFacetas}</tbody></table>`
await writeFile(path.join(SITE, "qa.html"), pagina({ titulo: "QA", crumb: `<a href="index.html">Inicio</a> / <b>QA</b>`, cuerpo: qa, tocHtml: toc(qa), fichas, prefijo: "", actualId: "__qa" }))

// 404
await writeFile(
  path.join(SITE, "404.html"),
  pagina({ titulo: "No encontrada", crumb: "Inicio", cuerpo: `<div class="hub-404"><h1>No encontramos esta página</h1><p>El enlace cambió o la pieza ya no está.</p><a class="hub-boton" href="index.html">Ir al inicio del Hub</a></div>`, tocHtml: "", fichas, prefijo: "", actualId: "" }),
)
console.log(`Hub generado: ${fichas.length} fichas + inicio + qa + 404 → design-hub/site/`)
