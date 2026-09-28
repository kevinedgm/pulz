<script setup lang="ts">
import { computed } from "vue"
import { useRoute } from "vue-router"
import { BloqueEstado, Boton } from "../../../shared/ui"
import { destinoDeRuta } from "../../../app/destinos"

// Destino vacío hasta la Fase 5 (shell/r01): explica qué habrá, no finge
// datos. El FAB de la etapa lo define la ronda de esa pantalla.
const route = useRoute()
const destino = computed(() => destinoDeRuta(route.meta.destino))
const slug = computed(() => String(route.params.slug))
</script>

<template>
  <div class="prox">
    <BloqueEstado
      variante="empty"
      titulo="Próximamente en tu palenque"
      :texto="`Aquí vas a ${destino?.proximamente ?? 'trabajar'}.`"
    >
      <Boton intent="secondary" :to="`/e/${slug}/inicio`">Volver a Inicio</Boton>
    </BloqueEstado>
  </div>
</template>

<style scoped>
.prox {
  padding: var(--sp-5);
}
</style>
