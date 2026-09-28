<script setup lang="ts">
import Icono from "./Icono.vue"
import type { IconoNombre } from "./tipos"

// Contrato: registry "fab". Solo compact. ES la primaria del destino: la
// pantalla no muestra otra mientras el FAB esté visible. 56px, pill, abajo
// a la derecha sobre la navegación inferior; el consumidor lo oculta con
// capas abiertas, solo lectura y en destinos sin acción.
defineProps<{ etiqueta: string; icono?: IconoNombre; disabled?: boolean }>()
const emit = defineEmits<{ click: [] }>()
</script>

<template>
  <button
    type="button"
    class="fab"
    :disabled="disabled"
    :aria-disabled="disabled ? 'true' : undefined"
    @click="emit('click')"
  >
    <Icono v-if="icono" :nombre="icono" :size="24" />
    <span>{{ etiqueta }}</span>
  </button>
</template>

<style scoped>
.fab {
  position: fixed;
  right: var(--sp-4);
  bottom: calc(72px + env(safe-area-inset-bottom));
  z-index: 21;
  display: inline-flex;
  align-items: center;
  gap: var(--sp-2);
  min-height: 56px;
  padding: 0 var(--sp-5);
  border: 0;
  border-radius: var(--r-pill);
  background: var(--ink-900);
  color: var(--surface);
  font: 700 1rem/1 var(--font);
  box-shadow: var(--shadow);
  cursor: pointer;
}
.fab:hover {
  background: var(--ink-700);
}
.fab:focus-visible {
  outline: 3px solid var(--ink-900);
  outline-offset: 3px;
}
.fab:disabled {
  opacity: 0.55;
  cursor: not-allowed;
}
@media (min-width: 600px) {
  .fab {
    display: none;
  }
}
</style>
