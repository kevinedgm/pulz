// Acción del botón flotante (registry "app-shell", extensión de
// fermentacion/r01). El shell pinta el FAB que declara la ruta (meta.fab) y
// la página le dice qué hacer al pulsarlo: fija la acción al montar y la
// limpia al salir. Sin bus de eventos ni store: un ref compartido.
import { onBeforeUnmount, onMounted, ref } from "vue"

export const fabAccion = ref<(() => void) | null>(null)

export function useFab(accion: () => void) {
  onMounted(() => (fabAccion.value = accion))
  onBeforeUnmount(() => {
    if (fabAccion.value === accion) fabAccion.value = null
  })
}
