import type { RouteRecordRaw } from "vue-router"

// Rutas del portal por empresa: pulz.mx/e/<slug>/… (§7.1). meta.publica =
// se puede ver sin sesión; meta.soloAdmin = Equipo (§11.1).
export const rutasAcceso: RouteRecordRaw[] = [
  {
    path: "/e/:slug",
    name: "portal",
    component: () => import("./pages/PortalPage.vue"),
    meta: { publica: true },
  },
  {
    path: "/e/:slug/bienvenida",
    name: "bienvenida",
    component: () => import("./pages/BienvenidaPage.vue"),
    meta: { publica: true },
  },
  {
    path: "/e/:slug/cambiar-contrasena",
    name: "cambiar-contrasena",
    component: () => import("./pages/CambiarContrasenaPage.vue"),
  },
  {
    path: "/e/:slug/no-encontrado",
    name: "no-encontrado",
    component: () => import("./pages/NoEncontradoPage.vue"),
    meta: { publica: true, noEncontrado: true },
  },
]
