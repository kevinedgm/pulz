import type { RouteRecordRaw } from "vue-router"

// Granel (§13.1 destino; ronda granel/r01): tanques, tanque con historial,
// movimiento por concepto y transferir. Sin FAB: la acción depende del tanque.
export const rutasGranel: RouteRecordRaw[] = [
  {
    path: "/e/:slug/granel",
    name: "granel",
    component: () => import("./pages/GranelPage.vue"),
    meta: { shell: true, destino: "granel", titulo: "Granel" },
  },
  {
    path: "/e/:slug/granel/transferir",
    name: "granel-transferir",
    component: () => import("./pages/TransferirPage.vue"),
    meta: { shell: true, destino: "granel", titulo: "Transferir" },
  },
  {
    path: "/e/:slug/granel/:tanque",
    name: "granel-tanque",
    component: () => import("./pages/TanquePage.vue"),
    meta: { shell: true, destino: "granel", titulo: "Tanque" },
  },
  {
    path: "/e/:slug/granel/:tanque/movimiento",
    name: "granel-movimiento",
    component: () => import("./pages/MovimientoPage.vue"),
    meta: { shell: true, destino: "granel", titulo: "Movimiento" },
  },
]
