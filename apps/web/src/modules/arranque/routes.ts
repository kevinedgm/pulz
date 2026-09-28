import type { RouteRecordRaw } from "vue-router"

// Primer arranque (§13.2 #2; ronda arranque/r01): dentro del shell, cuelga
// de Inicio. Admin y productor (rpc_guard); el operador ve "sin permiso".
export const rutasArranque: RouteRecordRaw[] = [
  {
    path: "/e/:slug/arranque",
    name: "arranque",
    component: () => import("./pages/ArranquePage.vue"),
    meta: { shell: true, destino: "inicio", titulo: "¿Qué tienes hoy?" },
  },
]
