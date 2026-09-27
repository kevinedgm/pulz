// Pages Function del portal (PULZ_MAESTRO.md §7.4, §7.7, §16 Fase 3), de
// punta a punta: `wrangler pages dev` (Miniflare, sin Docker) sirve dist/ +
// la función, y la función llama a portal_branding del proyecto Supabase
// alojado (bindings tomados de apps/web/.env.local). Requiere `pnpm build`.
//
// Casos: título y marca reescritos, manifiesto por empresa, 301 del slug
// viejo (mezcal-cuatro-vientos → cuatro-vientos, viene de la semilla), 404
// para inexistente, y que sin Supabase la app genérica sigue sirviendo.
// "Cancelada da el mismo 404" se prueba en supabase/tests/portal.test.sql
// (portal_branding no devuelve fila en ambos casos; la función no distingue).

import { spawn, type ChildProcess } from "node:child_process"
import { readFileSync } from "node:fs"
import { resolve } from "node:path"
import { afterAll, beforeAll, describe, expect, it } from "vitest"

const RAIZ = resolve(__dirname, "../..")
const PUERTO = 8788
const BASE = `http://127.0.0.1:${PUERTO}`

function leerEnvLocal(): Record<string, string> {
  const out: Record<string, string> = {}
  for (const linea of readFileSync(resolve(RAIZ, ".env.local"), "utf8").split("\n")) {
    const m = linea.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*?)\s*$/)
    if (m) out[m[1]] = m[2]
  }
  return out
}

async function esperarListo(ms = 60_000) {
  const fin = Date.now() + ms
  while (Date.now() < fin) {
    try {
      const r = await fetch(`${BASE}/`)
      if (r.ok) return
    } catch {
      /* aún no */
    }
    await new Promise((r) => setTimeout(r, 500))
  }
  throw new Error("wrangler pages dev no levantó a tiempo")
}

let proc: ChildProcess

beforeAll(async () => {
  const env = leerEnvLocal()
  proc = spawn(
    "pnpm",
    [
      "exec",
      "wrangler",
      "pages",
      "dev",
      "dist",
      "--port",
      String(PUERTO),
      "--ip",
      "127.0.0.1",
      "--compatibility-date",
      "2026-09-01",
      "--binding",
      `SUPABASE_URL=${env.VITE_SUPABASE_URL}`,
      "--binding",
      `SUPABASE_ANON_KEY=${env.VITE_SUPABASE_PUBLISHABLE_KEY}`,
    ],
    {
      cwd: RAIZ,
      stdio: ["ignore", "pipe", "pipe"],
      env: { ...process.env, CI: "1", WRANGLER_SEND_METRICS: "false" },
    },
  )
  proc.stderr?.on("data", (d) => {
    if (/error/i.test(String(d))) console.error(String(d))
  })
  await esperarListo()
})

afterAll(() => {
  proc?.kill("SIGTERM")
})

describe("Pages Function del portal contra el proyecto alojado", () => {
  it("reescribe título, marca y manifiesto de Cuatro Vientos", async () => {
    const res = await fetch(`${BASE}/e/cuatro-vientos`)
    const html = await res.text()
    expect(res.status).toBe(200)
    expect(html).toContain("<title>Mezcal Cuatro Vientos · PULZ</title>")
    expect(html).toContain('name="theme-color" content="#7A3E1D"')
    expect(html).toContain('name="apple-mobile-web-app-title" content="Mezcal Cuat…"')
    expect(html).toContain(
      'property="og:description" content="Registro de producción del palenque"',
    )
    expect(html).toContain('rel="manifest" href="/e/cuatro-vientos/manifest.webmanifest"')
    expect(html).toContain('data-portal="cuatro-vientos"')
    expect(res.headers.get("x-robots-tag")).toBe("noindex")
  })

  it("sirve un manifiesto propio por empresa", async () => {
    const res = await fetch(`${BASE}/e/cuatro-vientos/manifest.webmanifest`)
    expect(res.headers.get("content-type")).toContain("application/manifest+json")
    const m = (await res.json()) as Record<string, unknown>
    expect(m.id).toBe("/e/cuatro-vientos/")
    expect(m.scope).toBe("/e/cuatro-vientos/")
    expect(m.start_url).toBe("/e/cuatro-vientos/")
    expect(m.name).toBe("Mezcal Cuatro Vientos · PULZ")
    expect(m.theme_color).toBe("#7A3E1D")
    expect(m.lang).toBe("es-MX")
  })

  it("redirige el slug viejo con 301 conservando la ruta", async () => {
    const res = await fetch(`${BASE}/e/mezcal-cuatro-vientos/fermentacion`, { redirect: "manual" })
    expect(res.status).toBe(301)
    expect(res.headers.get("location")).toBe(`${BASE}/e/cuatro-vientos/fermentacion`)
  })

  it("una empresa que no existe recibe 404 con la app genérica", async () => {
    const res = await fetch(`${BASE}/e/no-existe-esta`)
    expect(res.status).toBe(404)
    expect(await res.text()).toContain("<title>PULZ</title>")
  })

  it("la empresa B (gratis) también entra con su marca", async () => {
    const res = await fetch(`${BASE}/e/prueba-b`)
    expect(res.status).toBe(200)
    expect(await res.text()).toContain("<title>Palenque Prueba B · PULZ</title>")
  })
})
