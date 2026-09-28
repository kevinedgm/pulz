import type { RouteRecordRaw } from "vue-router"
import { DESTINOS } from "../../app/destinos"

// Destinos de proceso (§13.1) como páginas vacías "próximamente" hasta la
// Fase 5, dentro del shell. Configuración vive en modules/configuracion.
export const rutasProceso: RouteRecordRaw[] = DESTINOS.filter((d) => d.proximamente).map((d) => ({
  path: `/e/:slug/${d.id}`,
  name: d.id,
  component: () => import("./pages/ProximamentePage.vue"),
  meta: { shell: true, destino: d.id, titulo: d.titulo },
}))
