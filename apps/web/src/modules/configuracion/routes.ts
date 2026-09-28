import type { RouteRecordRaw } from "vue-router"

// Configuración (§13.2 #8; ronda configuracion/r01): índice + cuatro
// secciones dentro del shell (destino "configuracion", solo admin: por URL
// sin admin cada página muestra "sin permiso"). Equipo vive en su módulo.
const meta = (titulo: string) => ({ shell: true, destino: "configuracion", titulo })

export const rutasConfiguracion: RouteRecordRaw[] = [
  {
    path: "/e/:slug/configuracion",
    name: "configuracion",
    component: () => import("./pages/ConfiguracionIndicePage.vue"),
    meta: meta("Configuración"),
  },
  {
    path: "/e/:slug/configuracion/recursos",
    name: "configuracion-recursos",
    component: () => import("./pages/RecursosPage.vue"),
    meta: meta("Recursos"),
  },
  {
    path: "/e/:slug/configuracion/catalogos",
    name: "configuracion-catalogos",
    component: () => import("./pages/CatalogosPage.vue"),
    meta: meta("Catálogos"),
  },
  {
    path: "/e/:slug/configuracion/ajustes",
    name: "configuracion-ajustes",
    component: () => import("./pages/AjustesPage.vue"),
    meta: meta("Ajustes"),
  },
  {
    path: "/e/:slug/configuracion/portal",
    name: "configuracion-portal",
    component: () => import("./pages/PortalMarcaPage.vue"),
    meta: meta("Portal y marca"),
  },
]
