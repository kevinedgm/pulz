// Design Hub · navegación (registry: hub-shell). Sin dependencias.
// - Marca aria-current="page" en el enlace de la página actual (sidebar y drawer).
// - Botón «Menú» (<1024) abre el drawer: role=dialog, foco dentro, Esc y
//   scrim cierran, el foco vuelve al botón.
;(() => {
  const aqui = location.pathname.replace(/\/index\.html$/, "/")
  for (const a of document.querySelectorAll(".hub-side a, .hub-drawer a")) {
    const destino = new URL(a.getAttribute("href"), location.href).pathname.replace(/\/index\.html$/, "/")
    if (destino === aqui) a.setAttribute("aria-current", "page")
  }

  const boton = document.querySelector(".hub-menu")
  const drawer = document.querySelector(".hub-drawer")
  if (!boton || !drawer) return
  const panel = drawer.querySelector(".hub-drawer__panel")
  const cerrarBtn = drawer.querySelector(".hub-drawer__cerrar")
  const fondo = drawer.querySelector(".hub-drawer__fondo")
  const focusables = () =>
    Array.from(panel.querySelectorAll('a[href], button:not([disabled]), [tabindex]:not([tabindex="-1"])'))

  function abrir() {
    drawer.setAttribute("open", "")
    boton.setAttribute("aria-expanded", "true")
    document.addEventListener("keydown", onKey)
    ;(focusables()[0] || panel).focus()
  }
  function cerrar() {
    drawer.removeAttribute("open")
    boton.setAttribute("aria-expanded", "false")
    document.removeEventListener("keydown", onKey)
    boton.focus()
  }
  function onKey(e) {
    if (e.key === "Escape") {
      e.preventDefault()
      cerrar()
      return
    }
    if (e.key !== "Tab") return
    const f = focusables()
    if (!f.length) return
    const primero = f[0]
    const ultimo = f[f.length - 1]
    if (e.shiftKey && document.activeElement === primero) {
      e.preventDefault()
      ultimo.focus()
    } else if (!e.shiftKey && document.activeElement === ultimo) {
      e.preventDefault()
      primero.focus()
    }
  }
  boton.addEventListener("click", () => (drawer.hasAttribute("open") ? cerrar() : abrir()))
  cerrarBtn?.addEventListener("click", cerrar)
  fondo?.addEventListener("click", cerrar)
})()
