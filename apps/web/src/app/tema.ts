// Tema claro/oscuro (shell/r01): sigue al sistema por defecto
// (prefers-color-scheme en tokens.css); la elección manual se guarda en
// este navegador y se aplica con data-theme en <html>. Se aplica ANTES de
// montar la app (main.ts) para no parpadear.
import { ref } from "vue"

export type Tema = "sistema" | "claro" | "oscuro"
const CLAVE = "pulz:tema"
const tema = ref<Tema>("sistema")

function leer(): Tema {
  try {
    const v = localStorage.getItem(CLAVE)
    return v === "claro" || v === "oscuro" ? v : "sistema"
  } catch {
    return "sistema"
  }
}

// theme-color de la barra del navegador/PWA = --ink-900 de cada tema. Con
// elección manual las dos <meta media=…> del index.html dejan de valer y se
// fuerzan al color elegido; con «sistema» recuperan su valor original.
const COLOR_TEMA = { light: "#6D4AFF", dark: "#A590FD" } as const
function sincronizarMeta(theme: "light" | "dark" | null) {
  for (const m of document.querySelectorAll<HTMLMetaElement>('meta[name="theme-color"]')) {
    m.dataset.original ??= m.content
    m.content = theme ? COLOR_TEMA[theme] : m.dataset.original
  }
}

export function aplicarTema(t: Tema) {
  tema.value = t
  const html = document.documentElement
  const theme = t === "sistema" ? null : t === "claro" ? "light" : "dark"
  if (theme) html.dataset.theme = theme
  else delete html.dataset.theme
  sincronizarMeta(theme)
  try {
    if (t === "sistema") localStorage.removeItem(CLAVE)
    else localStorage.setItem(CLAVE, t)
  } catch {
    /* almacenamiento no disponible: aplica solo en esta sesión */
  }
}

export function aplicarTemaGuardado() {
  aplicarTema(leer())
}

export function useTema() {
  return { tema, aplicarTema }
}
