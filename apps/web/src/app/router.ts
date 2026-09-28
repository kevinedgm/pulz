import { createRouter, createWebHistory, type RouteLocationRaw } from "vue-router"
import { rutasAcceso } from "../modules/acceso/routes"
import { useAcceso } from "../modules/acceso/store"
import { rutasEquipo } from "../modules/equipo/routes"
import { rutasArranque } from "../modules/arranque/routes"
import { rutasConfiguracion } from "../modules/configuracion/routes"
import { rutasProceso } from "../modules/proceso/routes"
import { rutasFermentacion } from "../modules/fermentacion/routes"
import { rutasDestilacion } from "../modules/destilacion/routes"
import { rutasGranel } from "../modules/granel/routes"
import { rutasMagueyHorneado } from "../modules/maguey-horneado/routes"
import type { IconoNombre } from "../shared/ui"

declare module "vue-router" {
  interface RouteMeta {
    publica?: boolean
    noEncontrado?: boolean
    // shell/r01: layout con navegación; destino de §13.1; título; hueco de FAB
    shell?: boolean
    destino?: string
    titulo?: string
    fab?: { etiqueta: string; icono?: IconoNombre }
  }
}

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: "/",
      name: "inicio-generico",
      component: () => import("../modules/inicio/pages/InicioPage.vue"),
    },
    ...rutasAcceso,
    {
      path: "/e/:slug/inicio",
      name: "inicio",
      component: () => import("../modules/inicio/pages/InicioEmpresaPage.vue"),
      meta: { shell: true, destino: "inicio", titulo: "Inicio" },
    },
    ...rutasFermentacion,
    ...rutasDestilacion,
    ...rutasGranel,
    ...rutasMagueyHorneado,
    ...rutasProceso,
    ...rutasConfiguracion,
    ...rutasArranque,
    ...rutasEquipo,
    // Cualquier otra ruta: el mismo 404 genérico (§7.4)
    {
      path: "/:pathMatch(.*)*",
      name: "no-encontrado-global",
      component: () => import("../modules/acceso/pages/NoEncontradoPage.vue"),
      meta: { publica: true, noEncontrado: true },
    },
  ],
})

// Guardias (PULZ_MAESTRO.md §7.4–§7.5, ronda acceso/r01):
//   sin fila de portal_branding      → 404 idéntico (inexistente o cancelada)
//   slug viejo (redirect_to)         → al slug actual (la Pages Function ya dio 301)
//   sin sesión en ruta privada       → portal del slug
//   sesión que no pertenece al slug  → el mismo 404
//   must_change_password             → cambio obligatorio antes que nada
//   read_only                        → la app entra; las pantallas esconden la escritura
//   Equipo                           → la pantalla explica si no es admin (no se oculta)
router.beforeEach(async (to): Promise<true | RouteLocationRaw> => {
  const slug = typeof to.params.slug === "string" ? to.params.slug : null
  if (!slug) return true
  const acceso = useAcceso()

  try {
    await acceso.cargarPortal(slug)
  } catch {
    return true // sin red: la pantalla muestra el error y conserva lo escrito
  }
  const portal = acceso.portal
  if (!portal) {
    return to.meta.noEncontrado ? true : { name: "no-encontrado", params: { slug } }
  }
  if (portal.redirect_to) {
    return {
      path: to.path.replace(`/e/${slug}`, `/e/${portal.redirect_to}`),
      query: to.query,
      hash: to.hash,
    }
  }

  try {
    await acceso.cargarSesion()
  } catch {
    return to.meta.publica ? true : { name: "portal", params: { slug } }
  }
  const m = acceso.membresiaActual

  if (to.meta.publica) {
    if (to.name === "portal" && m && m.status === "activo") {
      return { name: m.must_change_password ? "cambiar-contrasena" : "inicio", params: { slug } }
    }
    return true
  }
  if (!acceso.sesion) return { name: "portal", params: { slug } }
  if (!m || m.status !== "activo") return { name: "no-encontrado", params: { slug } }
  if (m.must_change_password && to.name !== "cambiar-contrasena")
    return { name: "cambiar-contrasena", params: { slug } }
  return true
})

export default router
