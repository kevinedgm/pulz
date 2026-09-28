import type { RouteRecordRaw } from "vue-router"

// Equipo vive en Configuración (§13.1) y es solo para el administrador (§11.1).
// El "solo admin" no es un guardia: la página muestra el estado "Sin permiso"
// de la ronda acceso/r01 (y la función equipo_miembros rechaza igual).
export const rutasEquipo: RouteRecordRaw[] = [
  {
    path: "/e/:slug/equipo",
    name: "equipo",
    component: () => import("./pages/EquipoPage.vue"),
    meta: { shell: true, destino: "configuracion", titulo: "Configuración" },
  },
]
