// Comprueba que ningún enlace ni recurso interno del sitio generado
// (design-hub/site/) apunte a algo que no existe. Sin navegador.
//   node design-hub/qa/enlaces-hub.mjs
import { readdir, readFile, stat } from "node:fs/promises"
import path from "node:path"
import { fileURLToPath } from "node:url"

const SITE = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..", "site")
const paginas = []
async function recorrer(dir) {
  for (const e of await readdir(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name)
    if (e.isDirectory()) await recorrer(p)
    else if (e.name.endsWith(".html")) paginas.push(p)
  }
}
await recorrer(SITE)
const rotos = []
const existe = async (p) => stat(p).then(() => true).catch(() => false)
for (const pagina of paginas) {
  const html = await readFile(pagina, "utf8")
  for (const m of html.matchAll(/(?:href|src)="([^"#?]+)(?:[#?][^"]*)?"/g)) {
    const ref = m[1]
    if (/^(https?:|mailto:|data:|\/\/)/.test(ref)) continue
    const destino = path.resolve(path.dirname(pagina), decodeURI(ref))
    if (!(await existe(destino))) rotos.push(`${path.relative(SITE, pagina)} → ${ref}`)
  }
}
console.log(`páginas ${paginas.length} | enlaces/recursos rotos: ${rotos.length}`)
if (rotos.length) {
  console.error("- " + rotos.join("\n- "))
  process.exit(1)
}
