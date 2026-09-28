<script setup lang="ts">
// Contrato: registry "page-header". Línea de acento de 4px con el color de
// la empresa (solo acento, nunca detrás de texto), botón de empresa
// (iniciales + nombre en una línea + persona · rol) que abre la Cuenta, y
// el h1 del destino. En expanded el consumidor no pasa `empresa` (vive en
// side-nav) y la cabecera solo dice dónde estás.
defineProps<{
  titulo: string
  empresa?: { nombre: string; subtitulo: string; iniciales: string; acento?: string | null }
}>()
const emit = defineEmits<{ cuenta: [] }>()
</script>

<template>
  <header class="cab" :style="empresa?.acento ? { '--acento': empresa.acento } : undefined">
    <button
      v-if="empresa"
      type="button"
      class="cab__empresa"
      aria-haspopup="dialog"
      :title="empresa.nombre"
      @click="emit('cuenta')"
    >
      <span class="cab__iniciales" aria-hidden="true">{{ empresa.iniciales }}</span>
      <span class="cab__texto">
        <b class="cab__nombre">{{ empresa.nombre }}</b>
        <small class="cab__sub">{{ empresa.subtitulo }}</small>
      </span>
    </button>
    <h1 v-if="titulo" class="cab__titulo">{{ titulo }}</h1>
  </header>
</template>

<style scoped>
.cab {
  --acento: var(--clay-300);
  position: relative;
  display: flex;
  align-items: center;
  gap: var(--sp-3);
  min-height: 56px;
  padding: 4px var(--sp-4) 0;
  border-bottom: 1px solid var(--border);
  background: var(--surface);
  color: var(--text);
}
.cab::before {
  content: "";
  position: absolute;
  inset: 0 0 auto 0;
  height: 4px;
  background: var(--acento);
}
.cab__empresa {
  display: flex;
  align-items: center;
  gap: var(--sp-2);
  min-width: 0;
  min-height: var(--tap);
  padding: 4px var(--sp-2);
  border: 0;
  border-radius: var(--r-md);
  background: transparent;
  color: inherit;
  font: inherit;
  text-align: left;
  cursor: pointer;
}
.cab__empresa:hover {
  background: var(--ink-100);
}
.cab__empresa:focus-visible {
  outline: 3px solid var(--ink-900);
  outline-offset: 2px;
}
.cab__iniciales {
  width: 32px;
  height: 32px;
  flex: none;
  display: grid;
  place-items: center;
  border-radius: var(--r-pill);
  background: var(--clay-100);
  color: var(--text);
  font: 700 0.75rem/1 var(--font);
}
.cab__texto {
  display: grid;
  min-width: 0;
}
.cab__nombre {
  font: 600 1rem/1.2 var(--font);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.cab__sub {
  font: 400 0.75rem/1.2 var(--font);
  color: var(--muted);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.cab__titulo {
  margin: 0 0 0 auto;
  font: 700 1.125rem/1.2 var(--font);
  white-space: nowrap;
}
.cab__empresa + .cab__titulo {
  flex: none;
}
.cab__titulo:only-child {
  margin-left: 0;
  font-size: 1.375rem;
}
</style>
