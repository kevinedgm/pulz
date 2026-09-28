// Estado reactivo de la cola para el shell e Inicio (§8.3: "la interfaz
// muestra cuántas capturas esperan envío y cuáles fallaron"). Un solo
// estado por app; se dispara al volver la señal, al arrancar y a mano.
import { computed, readonly, ref } from "vue"
import {
  corregir,
  descartar,
  enviar,
  listar,
  reintentar,
  type ElementoCola,
  type Llamador,
} from "./cola"

const elementos = ref<ElementoCola[]>([])
const enviando = ref(false)
const orgActual = ref<string | null>(null)
let escuchando = false

async function refrescar() {
  if (!orgActual.value) {
    elementos.value = []
    return
  }
  try {
    elementos.value = await listar(orgActual.value)
  } catch {
    elementos.value = []
  }
}

async function enviarAhora(llamador?: Llamador) {
  if (!orgActual.value || enviando.value) return
  if (typeof navigator !== "undefined" && navigator.onLine === false) {
    // Sin señal no se envía, pero la fila sí cambió (se acaba de encolar)
    await refrescar()
    return
  }
  enviando.value = true
  try {
    await enviar(orgActual.value, llamador)
  } finally {
    enviando.value = false
    await refrescar()
  }
}

export function useCola() {
  if (!escuchando && typeof window !== "undefined") {
    escuchando = true
    window.addEventListener("online", () => void enviarAhora())
  }
  return {
    elementos: readonly(elementos),
    enviando: readonly(enviando),
    pendientes: computed(() => elementos.value.filter((e) => e.estado !== "fallo").length),
    fallos: computed(() => elementos.value.filter((e) => e.estado === "fallo")),
    // La empresa activa cambia con la membresía: se recarga la fila y se
    // intenta enviar lo que haya quedado de la sesión anterior.
    async usarEmpresa(org: string | null) {
      orgActual.value = org
      await refrescar()
      if (org) void enviarAhora()
    },
    refrescar,
    enviarAhora,
    async reintentar(id: string) {
      await reintentar(id)
      await enviarAhora()
    },
    async corregir(id: string, params: Record<string, unknown>) {
      await corregir(id, params)
      await enviarAhora()
    },
    async descartar(id: string) {
      await descartar(id)
      await refrescar()
    },
  }
}
