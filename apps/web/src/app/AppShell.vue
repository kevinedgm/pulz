<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, watch } from "vue"
import { useRoute, useRouter } from "vue-router"
import {
  Aviso,
  Boton,
  BotonFlotante,
  CabeceraPagina,
  NavInferior,
  NavLateral,
  type IconoNombre,
} from "../shared/ui"
import { useConexion } from "../shared/utils/conexion"
import { useCola } from "../shared/offline/useCola"
import { useAcceso } from "../modules/acceso/store"
import { DESTINOS, destinoDeRuta, destinosVisibles, itemsNav } from "./destinos"
import { fabAccion } from "./fab"
import CapaCuenta from "./CapaCuenta.vue"
import CapaMas from "./CapaMas.vue"

// Contrato: registry "app-shell" (ronda shell/r01). Cabecera + banner +
// cuerpo (router-view) + navegación (lateral ≥600 / inferior <600) + hueco
// de FAB por destino + capas Más y Cuenta. Una sola lista de destinos con
// dos presentaciones; la ruta y el foco del contenido se conservan.
const acceso = useAcceso()
const route = useRoute()
const router = useRouter()
const { enLinea } = useConexion()
// Cola offline (§8.3): cuántas capturas esperan y cuáles fallaron, por empresa
const cola = useCola()
watch(
  () => acceso.membresiaActual?.organization_id ?? null,
  (org) => void cola.usarEmpresa(org),
  { immediate: true },
)
const pendientesTexto = computed(() => {
  const p = cola.pendientes.value
  const f = cola.fallos.value.length
  return `${p} captura${p === 1 ? "" : "s"} pendiente${p === 1 ? "" : "s"} de enviar${f ? ` · ${f} fall${f === 1 ? "ó" : "aron"}` : ""}.`
})

const slug = computed(() => String(route.params.slug ?? acceso.slug ?? ""))
const membresia = computed(() => acceso.membresiaActual)
const iniciales = (nombre: string) =>
  nombre
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((p) => p[0]!.toUpperCase())
    .join("")
const empresa = computed(() => ({
  nombre: membresia.value?.name ?? acceso.portal?.name ?? "",
  iniciales: iniciales(membresia.value?.name ?? acceso.portal?.name ?? "P"),
  subtitulo: `${membresia.value?.username ?? "titular"} · ${membresia.value?.role ?? ""}`,
  acento: membresia.value?.brand_color ?? acceso.portal?.brand_color ?? null,
}))
const cuenta = computed(() => ({
  nombre: membresia.value?.username ?? "titular",
  subtitulo: `${membresia.value?.role ?? ""} · cuenta`,
  iniciales: iniciales(membresia.value?.username ?? "titular"),
}))

const visibles = computed(() => destinosVisibles(acceso.esAdmin))
const items = computed(() => itemsNav(slug.value, visibles.value))
const fijos = computed(() =>
  items.value.filter((it) => DESTINOS.find((d) => d.id === it.id)?.fijoEnCompact),
)
const restantes = computed(() =>
  items.value.filter((it) => !DESTINOS.find((d) => d.id === it.id)?.fijoEnCompact),
)
const destinoActual = computed(() => destinoDeRuta(route.meta.destino ?? route.name))
const actualId = computed(() => destinoActual.value?.id ?? "")
const titulo = computed(
  () => (route.meta.titulo as string | undefined) ?? destinoActual.value?.titulo ?? "",
)

// Modo por espacio (misma instancia de contenido; solo cambia el chrome)
const ancho = ref(typeof window !== "undefined" ? window.innerWidth : 1440)
const modo = computed<"compact" | "medium" | "expanded">(() =>
  ancho.value < 600 ? "compact" : ancho.value < 1024 ? "medium" : "expanded",
)
const onResize = () => (ancho.value = window.innerWidth)

// Teclado virtual (compact): la barra inferior se oculta mientras un campo
// tiene el foco o el visualViewport se encoge (hallazgo de la ronda).
const campoConFoco = ref(false)
const viewportCorto = ref(false)
const tecladoAbierto = computed(
  () => modo.value === "compact" && (campoConFoco.value || viewportCorto.value),
)
const esCampo = (el: EventTarget | null) =>
  el instanceof HTMLElement && ["INPUT", "TEXTAREA", "SELECT"].includes(el.tagName)
const onFocusIn = (e: FocusEvent) => (campoConFoco.value = esCampo(e.target))
const onFocusOut = () => (campoConFoco.value = false)
const onViewport = () => {
  const vv = window.visualViewport
  viewportCorto.value = Boolean(vv && vv.height < window.innerHeight * 0.75)
}

onMounted(() => {
  window.addEventListener("resize", onResize)
  document.addEventListener("focusin", onFocusIn)
  document.addEventListener("focusout", onFocusOut)
  window.visualViewport?.addEventListener("resize", onViewport)
})
onBeforeUnmount(() => {
  window.removeEventListener("resize", onResize)
  document.removeEventListener("focusin", onFocusIn)
  document.removeEventListener("focusout", onFocusOut)
  window.visualViewport?.removeEventListener("resize", onViewport)
})

// Capas
const masAbierto = ref(false)
const cuentaAbierta = ref(false)

// FAB: hueco por destino. Cada ronda de etapa lo define; por ahora solo se
// publica el contrato (meta.fab) y no aparece en Inicio/Configuración.
const fab = computed(() => route.meta.fab as { etiqueta: string; icono?: IconoNombre } | undefined)
const fabVisible = computed(
  () =>
    Boolean(fab.value) &&
    modo.value === "compact" &&
    !masAbierto.value &&
    !cuentaAbierta.value &&
    !acceso.modoLectura,
)

async function irA(to: string) {
  // La capa (task-layer) deshace su entrada de historial con history.back()
  // al cerrarse; ese popstate llega DESPUÉS de un router.push inmediato y
  // devolvería a la ruta anterior. Se espera el popstate y luego se navega.
  const hayCapa = Boolean(history.state?.capa)
  masAbierto.value = false
  cuentaAbierta.value = false
  if (hayCapa) {
    await new Promise<void>((resolve) => {
      const listo = () => {
        window.removeEventListener("popstate", listo)
        resolve()
      }
      window.addEventListener("popstate", listo)
      setTimeout(listo, 400)
    })
  }
  await router.push(to)
}
</script>

<template>
  <div class="shell" :class="`shell--${modo}`">
    <NavLateral
      v-if="modo !== 'compact'"
      class="shell__lateral"
      :items="items"
      :actual="actualId"
      :empresa="modo === 'expanded' ? empresa : undefined"
      :cuenta="modo === 'expanded' ? cuenta : undefined"
      :ancho="modo"
      @cuenta="cuentaAbierta = true"
    />
    <div class="shell__columna">
      <CabeceraPagina
        :titulo="titulo"
        :empresa="modo === 'expanded' ? undefined : empresa"
        @cuenta="cuentaAbierta = true"
      />
      <Aviso v-if="!enLinea" variante="offline" titulo="Sin conexión."
        ><template v-if="cola.pendientes.value"
          >{{ pendientesTexto }} Se envían al volver la señal; puedes seguir midiendo.</template
        ><template v-else>Puedes medir; lo demás necesita señal.</template></Aviso
      >
      <Aviso
        v-else-if="cola.pendientes.value || cola.fallos.value.length"
        variante="cola"
        :titulo="pendientesTexto"
      >
        <template v-if="cola.fallos.value.length">Revisa las que fallaron en su pantalla.</template>
        <template #accion
          ><Boton intent="quiet" :loading="cola.enviando.value" @click="cola.enviarAhora()"
            >Reintentar</Boton
          ></template
        >
      </Aviso>
      <Aviso v-else-if="acceso.modoLectura" variante="readonly" titulo="Solo lectura."
        >La suscripción venció: puedes consultar y exportar, no registrar.</Aviso
      >
      <main id="contenido" class="shell__cuerpo" tabindex="-1">
        <router-view />
      </main>
    </div>

    <NavInferior
      v-if="modo === 'compact'"
      :items="fijos"
      :actual="actualId"
      :mas-abierto="masAbierto"
      :oculta="tecladoAbierto"
      @mas="masAbierto = true"
    />
    <BotonFlotante
      v-if="fabVisible && fab"
      :etiqueta="fab.etiqueta"
      :icono="fab.icono"
      :disabled="!fabAccion"
      @click="fabAccion?.()"
    />

    <CapaMas
      :abierta="masAbierto"
      :items="restantes"
      :actual="actualId"
      @cerrar="masAbierto = false"
      @ir="irA"
    />
    <CapaCuenta :abierta="cuentaAbierta" @cerrar="cuentaAbierta = false" @ir="irA" />
  </div>
</template>

<style scoped>
.shell {
  min-height: 100vh;
  display: flex;
  background: var(--canvas);
  color: var(--text);
}
.shell__lateral {
  flex: none;
  position: sticky;
  top: 0;
  height: 100vh;
}
.shell__columna {
  flex: 1 1 auto;
  min-width: 0;
  display: flex;
  flex-direction: column;
}
.shell__cuerpo {
  flex: 1 1 auto;
  min-width: 0;
  outline: none;
}
.shell--compact .shell__cuerpo {
  /* barra inferior + FAB + área segura: nada queda tapado */
  padding-bottom: calc(140px + env(safe-area-inset-bottom));
}
</style>
