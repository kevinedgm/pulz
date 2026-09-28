<script setup lang="ts">
import { computed, onBeforeUnmount, shallowRef, watch } from "vue"
import { useRoute } from "vue-router"
import { supabase } from "../../../shared/supabase/client"
import { useAcceso } from "../../acceso/store"
import { useConexion } from "../../../shared/utils/conexion"
import { cargarMH, guardarMH } from "../api"
import type { CapturaMH, DatosMH } from "../modelo"
import SuperficieMH from "../components/SuperficieMH.vue"
const route = useRoute(),
  acceso = useAcceso(),
  { enLinea } = useConexion()
const org = computed(() => acceso.membresiaActual?.organization_id ?? "")
const actor = shallowRef("")
const identidadLista = shallowRef(false)
const puede = computed(
  () =>
    !!actor.value &&
    identidadLista.value &&
    ["admin", "productor"].includes(acceso.membresiaActual?.role ?? "") &&
    !acceso.modoLectura,
)
const destino = computed(() => (route.meta.destino === "maguey" ? "maguey" : "horneado"))
const datos = shallowRef<DatosMH | null>(null),
  error = shallowRef(""),
  instantanea = shallowRef<string | null>(null)
let request = 0
let cambioSesion = 0
let refresco: ReturnType<typeof setTimeout> | undefined
const { data: escucha } = supabase.auth.onAuthStateChange((_evento, session) => {
  const siguiente = session?.user.id ?? ""
  if (siguiente === actor.value) return
  const revision = ++cambioSesion
  request++
  actor.value = siguiente
  identidadLista.value = false
  datos.value = null
  instantanea.value = null
  clearTimeout(refresco)
  // Fuera del callback de Auth: no esperar otra operación Auth bajo su bloqueo.
  refresco = setTimeout(async () => {
    try {
      await acceso.cargarSesion(true)
      if (revision !== cambioSesion) return
      identidadLista.value = !!actor.value
      if (actor.value) await cargar()
    } catch {
      if (revision === cambioSesion)
        error.value = "No pudimos verificar la sesión. Vuelve a entrar."
    }
  }, 0)
})
onBeforeUnmount(() => {
  cambioSesion++
  request++
  clearTimeout(refresco)
  escucha.subscription.unsubscribe()
})
async function cargar() {
  const id = ++request,
    empresa = org.value
  if (!empresa) return
  error.value = ""
  try {
    const r = await cargarMH(empresa)
    if (id === request && org.value === empresa) {
      datos.value = r.datos
      instantanea.value = r.instantanea
    }
  } catch (e) {
    if (id === request) error.value = e instanceof Error ? e.message : String(e)
  }
}
watch(
  org,
  async () => {
    datos.value = null
    instantanea.value = null
    actor.value = ""
    identidadLista.value = false
    const revision = cambioSesion
    const empresa = org.value
    void cargar()
    try {
      // Sólo identifica la partición local; roles y autorización siguen en store/RLS/RPC.
      const { data } = await supabase.auth.getSession()
      if (org.value === empresa && revision === cambioSesion) {
        actor.value = data.session?.user.id ?? ""
        identidadLista.value = true
      }
    } catch {
      /* sin sesión identificable no habilitar escritura */
    }
  },
  { immediate: true },
)
watch(enLinea, (online) => {
  if (online) void cargar()
})
async function guardar(c: CapturaMH) {
  if (!puede.value || !enLinea.value) throw new Error("Necesitas permiso y señal para registrar.")
  return guardarMH(org.value, c)
}
</script>
<template>
  <div class="mh-page">
    <SuperficieMH
      :key="`${org}:${actor}:${destino}`"
      :datos="datos"
      :destino="destino"
      :puede="puede"
      :en-linea="enLinea"
      :error-carga="error"
      :instantanea="instantanea"
      :guardar="guardar"
      :contexto="actor ? `${org}:${actor}:${destino}` : ''"
      :formulacion="`/e/${route.params.slug}/fermentacion/formular`"
      @recargar="cargar"
    />
  </div>
</template>
