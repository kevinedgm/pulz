<script setup lang="ts">
import { RouterLink } from "vue-router"
import Icono from "./Icono.vue"
import type { ItemNav } from "./tipos"

// Contrato: registry "bottom-nav". Solo compact (<600). Hasta 4 destinos
// fijos + "Más" (botón, aria-haspopup=dialog). Ítems ≥48px, ancho 1/5,
// icono + etiqueta corta (dos líneas permitidas, nunca oculta), destino
// actual por borde + negrita, área segura inferior. Con teclado virtual el
// consumidor la oculta (`oculta`).
defineProps<{ items: ItemNav[]; actual: string; masAbierto?: boolean; oculta?: boolean }>()
const emit = defineEmits<{ mas: [] }>()
</script>

<template>
  <nav class="inf" :class="{ 'inf--oculta': oculta }" aria-label="Navegación principal">
    <RouterLink
      v-for="it in items.slice(0, 4)"
      :key="it.id"
      class="inf__item"
      :to="it.to"
      :aria-current="it.id === actual ? 'page' : undefined"
    >
      <Icono :nombre="it.icono" :size="22" />
      <span>{{ it.etiqueta }}</span>
    </RouterLink>
    <button
      type="button"
      class="inf__item"
      aria-haspopup="dialog"
      :aria-expanded="masAbierto ? 'true' : 'false'"
      @click="emit('mas')"
    >
      <Icono nombre="i-menu" :size="22" />
      <span>Más</span>
    </button>
  </nav>
</template>

<style scoped>
.inf {
  position: fixed;
  inset: auto 0 0 0;
  z-index: 20;
  display: grid;
  grid-template-columns: repeat(5, minmax(0, 1fr));
  padding: 4px 4px calc(4px + env(safe-area-inset-bottom));
  border-top: 1px solid var(--border);
  background: var(--surface);
  color: var(--text);
}
.inf--oculta {
  display: none;
}
.inf__item {
  display: grid;
  justify-items: center;
  align-content: center;
  gap: 2px;
  min-height: 48px;
  padding: 4px 0; /* sin padding lateral: "Fermentación" cabe en 1/5 de 390 sin partirse */
  border: 0;
  border-radius: var(--r-md);
  background: transparent;
  color: var(--text);
  font: 500 0.6875rem/1.15 var(--font);
  letter-spacing: -0.01em;
  text-align: center;
  text-decoration: none;
  cursor: pointer;
  overflow-wrap: anywhere; /* solo como último recurso (texto al 200 %) */
  hyphens: manual;
}
.inf__item:focus-visible {
  outline: 3px solid var(--ink-900);
  outline-offset: -3px;
}
.inf__item[aria-current="page"] {
  box-shadow: inset 0 0 0 2px var(--ink-900); /* borde sin restar ancho a la etiqueta */
  font-weight: 700;
}
</style>
