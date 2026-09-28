<script setup lang="ts">
import { computed } from "vue"
import { useRoute } from "vue-router"
import { Aviso, BloqueEstado, Boton } from "../../../shared/ui"
import { useConexion } from "../../../shared/utils/conexion"
import { useAcceso } from "../../acceso/store"

// Envoltura de cada página de Configuración: solo admin (por URL sin admin →
// "sin permiso", mismo patrón que Equipo), ruta "Configuración / Sección",
// banners de sin conexión / solo lectura. Expone `puedeEscribir` al slot.
defineProps<{ seccion?: string }>()
const acceso = useAcceso()
const route = useRoute()
const { enLinea } = useConexion()
const slug = computed(() => String(route.params.slug))
const puedeEscribir = computed(() => enLinea.value && !acceso.modoLectura)
</script>

<template>
  <div class="cfg">
    <Aviso v-if="!enLinea" variante="offline" titulo="Sin conexión."
      >Puedes ver lo último cargado; para cambiar algo necesitas señal.</Aviso
    >
    <Aviso v-else-if="acceso.modoLectura" variante="readonly" titulo="Solo lectura."
      >La suscripción venció: puedes consultar, no cambiar.</Aviso
    >
    <div class="cfg__cuerpo">
      <BloqueEstado
        v-if="!acceso.esAdmin"
        variante="denied"
        titulo="Solo el administrador puede ver la configuración"
        :texto="`Pídele a quien administra ${acceso.membresiaActual?.name ?? 'la empresa'} lo que necesites cambiar.`"
      >
        <Boton intent="secondary" :to="`/e/${slug}/inicio`">Volver a Inicio</Boton>
      </BloqueEstado>
      <template v-else>
        <nav v-if="seccion" class="cfg__ruta" aria-label="Ruta">
          <RouterLink :to="`/e/${slug}/configuracion`">Configuración</RouterLink> /
          <strong>{{ seccion }}</strong>
        </nav>
        <slot :puede-escribir="puedeEscribir" :en-linea="enLinea" :slug="slug" />
      </template>
    </div>
  </div>
</template>

<style scoped>
.cfg__cuerpo {
  padding: var(--sp-5);
  max-width: 960px;
}
.cfg__ruta {
  margin: 0 0 var(--sp-3);
  font-size: 0.875rem;
  color: var(--muted);
}
.cfg__ruta a {
  color: var(--ink-900);
}
</style>
