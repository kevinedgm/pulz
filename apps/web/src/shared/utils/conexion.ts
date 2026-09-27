// Estado de conexión reactivo (§8.3: entrar y los cambios de equipo
// requieren señal; la interfaz lo dice en vez de fallar en silencio).
import { onBeforeUnmount, onMounted, ref } from "vue"

export function useConexion() {
  const enLinea = ref(typeof navigator === "undefined" ? true : navigator.onLine)
  const on = () => (enLinea.value = true)
  const off = () => (enLinea.value = false)
  onMounted(() => {
    window.addEventListener("online", on)
    window.addEventListener("offline", off)
  })
  onBeforeUnmount(() => {
    window.removeEventListener("online", on)
    window.removeEventListener("offline", off)
  })
  return { enLinea }
}
