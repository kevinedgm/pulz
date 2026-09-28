<script setup lang="ts">
import { RouterLink } from "vue-router"
import Icono from "./Icono.vue"
import { etiquetaNav } from "./etiquetaNav"
import type { ItemNav } from "./tipos"

// Contrato: registry "side-nav". 200px en medium, 240px en expanded (lo
// decide el consumidor con `ancho`). Bloque de empresa arriba (iniciales +
// nombre en dos líneas, completo en title), lista de destinos (icono +
// texto, 44px, aria-current por borde + negrita) y, si el consumidor lo
// pasa, el bloque de cuenta al pie (solo expanded). El filtro por rol lo
// hace el consumidor: aquí solo llegan los ítems visibles.
defineProps<{
  items: ItemNav[]
  actual: string
  empresa?: { nombre: string; iniciales: string } // solo expanded: en medium la cabecera ya la muestra
  cuenta?: { nombre: string; subtitulo: string; iniciales: string }
  ancho?: "medium" | "expanded"
}>()
const emit = defineEmits<{ cuenta: [] }>()
</script>

<template>
  <nav class="lat" :class="`lat--${ancho ?? 'expanded'}`" aria-label="Navegación principal">
    <div v-if="empresa" class="lat__empresa" :title="empresa.nombre">
      <span class="lat__iniciales" aria-hidden="true">{{ empresa.iniciales }}</span>
      <b class="lat__nombre">{{ empresa.nombre }}</b>
    </div>
    <ul class="lat__lista">
      <li v-for="it in items" :key="it.id">
        <RouterLink
          class="lat__item"
          :to="it.to"
          :aria-label="it.etiqueta"
          :aria-current="it.id === actual ? 'page' : undefined"
        >
          <Icono :nombre="it.icono" :size="24" />
          <span>{{ etiquetaNav(it.etiqueta) }}</span>
        </RouterLink>
      </li>
    </ul>
    <button
      v-if="cuenta"
      type="button"
      class="lat__cuenta"
      aria-haspopup="dialog"
      @click="emit('cuenta')"
    >
      <span class="lat__iniciales" aria-hidden="true">{{ cuenta.iniciales }}</span>
      <span class="lat__texto">
        <b>{{ cuenta.nombre }}</b>
        <small>{{ cuenta.subtitulo }}</small>
      </span>
    </button>
  </nav>
</template>

<style scoped>
.lat {
  display: flex;
  flex-direction: column;
  gap: var(--sp-3);
  width: 240px;
  height: 100%;
  padding: var(--sp-4) var(--sp-3);
  border-right: 1px solid var(--border);
  background: var(--canvas);
  color: var(--text);
  overflow: auto;
}
.lat--medium {
  width: 200px;
}
.lat__empresa {
  display: flex;
  align-items: center;
  gap: var(--sp-2);
  min-width: 0;
  padding: 0 var(--sp-2);
}
.lat__iniciales {
  width: 32px;
  height: 32px;
  flex: none;
  display: grid;
  place-items: center;
  border-radius: var(--r-pill);
  background: var(--clay-100);
  font: 700 0.75rem/1 var(--font);
}
.lat__nombre {
  font: 600 0.9375rem/1.25 var(--font);
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
.lat__lista {
  list-style: none;
  margin: 0;
  padding: 0;
  display: grid;
  gap: 2px;
}
.lat__item {
  display: flex;
  align-items: center;
  gap: var(--sp-2);
  min-height: var(--tap);
  padding: 0 var(--sp-3);
  border: 2px solid transparent;
  border-radius: var(--r-md);
  color: var(--text);
  text-decoration: none;
  font: 500 0.9375rem/1.2 var(--font);
}
.lat__item:hover {
  background: var(--ink-100);
}
.lat__item > span {
  min-width: 0;
  hyphens: manual;
}
.lat__item:focus-visible {
  outline: 3px solid var(--ink-900);
  outline-offset: 2px;
}
.lat__item[aria-current="page"] {
  border-color: var(--ink-900);
  background: var(--surface);
  font-weight: 700;
}
.lat__cuenta {
  margin-top: auto;
  display: flex;
  align-items: center;
  gap: var(--sp-2);
  min-height: var(--tap);
  padding: var(--sp-3) var(--sp-2) 0;
  border: 0;
  border-top: 1px solid var(--border);
  background: transparent;
  color: inherit;
  font: inherit;
  text-align: left;
  cursor: pointer;
}
.lat__cuenta:focus-visible {
  outline: 3px solid var(--ink-900);
  outline-offset: 2px;
}
.lat__texto {
  display: grid;
  min-width: 0;
}
.lat__texto b {
  font: 600 0.9375rem/1.2 var(--font);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.lat__texto small {
  font-size: 0.75rem;
  color: var(--muted);
}
</style>
