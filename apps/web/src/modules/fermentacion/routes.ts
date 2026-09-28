import type { RouteRecordRaw } from "vue-router"

// Fermentación (§13.1 destino; ronda fermentacion/r01): usos de tinas,
// uso de una tina, medición por pasos y formulación. Todo dentro del shell.
// El FAB «Medir» solo existe en la lista (la página fija su acción).
export const rutasFermentacion: RouteRecordRaw[] = [
  {
    path: "/e/:slug/fermentacion",
    name: "fermentacion",
    component: () => import("./pages/FermentacionPage.vue"),
    meta: {
      shell: true,
      destino: "fermentacion",
      titulo: "Fermentación",
      fab: { etiqueta: "Medir", icono: "i-medir" },
    },
  },
  {
    path: "/e/:slug/fermentacion/formular",
    name: "fermentacion-formular",
    component: () => import("./pages/FormularPage.vue"),
    meta: { shell: true, destino: "fermentacion", titulo: "Llenar tinas" },
  },
  {
    path: "/e/:slug/fermentacion/:ciclo",
    name: "fermentacion-uso",
    component: () => import("./pages/UsoTinaPage.vue"),
    meta: { shell: true, destino: "fermentacion", titulo: "Uso de tina" },
  },
  {
    path: "/e/:slug/fermentacion/:ciclo/medir",
    name: "fermentacion-medir",
    component: () => import("./pages/MedirPage.vue"),
    meta: { shell: true, destino: "fermentacion", titulo: "Medir" },
  },
]
