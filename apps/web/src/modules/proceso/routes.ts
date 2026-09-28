import type { RouteRecordRaw } from "vue-router"
import { DESTINOS } from "../../app/destinos"

// Destinos de proceso (§13.1) como páginas vacías "próximamente" hasta la
// Fase 5, dentro del shell. Configuración: índice provisional para el
// admin (ronda configuracion/r01 lo reemplaza); sin admin → sin permiso.
export const rutasProceso: RouteRecordRaw[] = DESTINOS.filter(
  (d) => d.id !== "inicio" && d.id !== "configuracion",
).map((d) => ({
  path: `/e/:slug/${d.id}`,
  name: d.id,
  component: () => import("./pages/ProximamentePage.vue"),
  meta: { shell: true, destino: d.id, titulo: d.titulo },
}))

export const rutaConfiguracion: RouteRecordRaw = {
  path: "/e/:slug/configuracion",
  name: "configuracion",
  component: () => import("./pages/ConfiguracionIndicePage.vue"),
  meta: { shell: true, destino: "configuracion", titulo: "Configuración" },
}
