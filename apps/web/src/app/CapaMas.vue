<script setup lang="ts">
import { CapaTarea, Icono, type ItemNav } from "../shared/ui"

// "Más" (compact): los destinos que no caben en la barra. Reutiliza
// task-layer (hoja inferior en compact). Esc/atrás/scrim cierran y el foco
// vuelve al botón "Más".
defineProps<{ abierta: boolean; items: ItemNav[]; actual: string }>()
const emit = defineEmits<{ cerrar: []; ir: [to: string] }>()
</script>

<template>
  <CapaTarea :abierta="abierta" titulo="Más" @cerrar="emit('cerrar')">
    <nav aria-label="Más destinos">
      <ul class="mas">
        <li v-for="it in items" :key="it.id">
          <a
            class="mas__item"
            :href="it.to"
            :aria-current="it.id === actual ? 'page' : undefined"
            @click.prevent="emit('ir', it.to)"
          >
            <Icono :nombre="it.icono" :size="24" />
            <span>{{ it.etiqueta }}</span>
          </a>
        </li>
      </ul>
    </nav>
  </CapaTarea>
</template>

<style scoped>
.mas {
  list-style: none;
  margin: 0;
  padding: 0;
  display: grid;
  gap: 2px;
}
.mas__item {
  display: flex;
  align-items: center;
  gap: var(--sp-3);
  min-height: 48px;
  padding: 0 var(--sp-3);
  border: 2px solid transparent;
  border-radius: var(--r-md);
  color: var(--text);
  text-decoration: none;
  font: 500 1rem/1.2 var(--font);
}
.mas__item:hover {
  background: var(--ink-100);
}
.mas__item:focus-visible {
  outline: 3px solid var(--ink-900);
  outline-offset: 2px;
}
.mas__item[aria-current="page"] {
  border-color: var(--ink-900);
  font-weight: 700;
}
</style>
