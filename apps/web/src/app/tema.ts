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

export function aplicarTema(t: Tema) {
  tema.value = t
  const html = document.documentElement
  if (t === "sistema") delete html.dataset.theme
  else html.dataset.theme = t === "claro" ? "light" : "dark"
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
