import type { RouteRecordRaw } from "vue-router"
export const rutasMagueyHorneado: RouteRecordRaw[] = ["maguey", "horneado"].map((destino) => ({
  path: `/e/:slug/${destino}`,
  name: destino,
  component: () => import("./pages/ProcesoSolidoPage.vue"),
  meta: { shell: true, destino, titulo: destino === "maguey" ? "Maguey" : "Horneado" },
}))
