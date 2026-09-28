import type { RouteRecordRaw } from "vue-router"

// Destilación (§13.1 destino; ronda destilacion/r01): corridas, abrir,
// corrida y corte por pasos. Todo dentro del shell. El FAB «Abrir corrida»
// solo existe en la lista.
export const rutasDestilacion: RouteRecordRaw[] = [
  {
    path: "/e/:slug/destilacion",
    name: "destilacion",
    component: () => import("./pages/DestilacionPage.vue"),
    meta: {
      shell: true,
      destino: "destilacion",
      titulo: "Destilación",
      fab: { etiqueta: "Abrir corrida", icono: "i-destila" },
    },
  },
  {
    path: "/e/:slug/destilacion/abrir",
    name: "destilacion-abrir",
    component: () => import("./pages/AbrirCorridaPage.vue"),
    meta: { shell: true, destino: "destilacion", titulo: "Abrir corrida" },
  },
  {
    path: "/e/:slug/destilacion/:corrida",
    name: "destilacion-corrida",
    component: () => import("./pages/CorridaPage.vue"),
    meta: { shell: true, destino: "destilacion", titulo: "Corrida" },
  },
  {
    path: "/e/:slug/destilacion/:corrida/corte",
    name: "destilacion-corte",
    component: () => import("./pages/CortePage.vue"),
    meta: { shell: true, destino: "destilacion", titulo: "Corte" },
  },
]
