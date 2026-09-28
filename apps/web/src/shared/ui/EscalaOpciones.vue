<script setup lang="ts">
import { computed, useId } from "vue"

// Contrato: registry "scale-choice" (ronda fermentacion/r01). radiogroup de
// valores enteros consecutivos (min..max) con etiqueta por valor; botones
// iguales ≥44px en una fila; la etiqueta del valor elegido se lee en
// aria-live. Selección por forma (borde 3px + fondo), nunca solo color.
// Escala 1–6 de actividad, dulzor y acidez (§18 #1: el tope vive en el
// CHECK del esquema; aquí solo se pinta).
const props = withDefaults(
  defineProps<{
    modelValue: number | null
    etiqueta: string
    etiquetas: string[]
    min?: number
    max?: number
    disabled?: boolean
  }>(),
  { min: 1, max: 6, disabled: false },
)
const emit = defineEmits<{ "update:modelValue": [number | null] }>()
const id = useId()
const valores = computed(() =>
  Array.from({ length: props.max - props.min + 1 }, (_, i) => props.min + i),
)
const etiquetaDe = (v: number) => props.etiquetas[v - props.min] ?? ""
const leyenda = computed(() =>
  props.modelValue === null
    ? "Elige un valor"
    : `${props.modelValue} · ${etiquetaDe(props.modelValue)}`,
)
function mover(delta: number) {
  const actual = props.modelValue ?? props.min - 1
  const n = Math.min(props.max, Math.max(props.min, actual + delta))
  emit("update:modelValue", n)
  ;(document.getElementById(`${id}-${n}`) as HTMLElement | null)?.focus()
}
</script>

<template>
  <div class="escala" role="radiogroup" :aria-labelledby="`${id}-etiqueta`">
    <span :id="`${id}-etiqueta`" class="escala__etiqueta">{{ etiqueta }}</span>
    <div class="escala__valores" :style="{ '--n': valores.length }">
      <button
        v-for="v in valores"
        :id="`${id}-${v}`"
        :key="v"
        type="button"
        role="radio"
        class="escala__valor"
        :aria-checked="v === modelValue ? 'true' : 'false'"
        :aria-label="`${v} · ${etiquetaDe(v)}`"
        :tabindex="v === modelValue || (modelValue === null && v === min) ? 0 : -1"
        :disabled="disabled"
        @click="emit('update:modelValue', v)"
        @keydown.right.down.prevent="mover(1)"
        @keydown.left.up.prevent="mover(-1)"
      >
        {{ v }}
      </button>
    </div>
    <p class="escala__leyenda" aria-live="polite">{{ leyenda }}</p>
  </div>
</template>

<style scoped>
.escala {
  display: grid;
  gap: var(--sp-2);
}
.escala__etiqueta {
  font: 600 1rem/1.3 var(--font);
  color: var(--text);
}
.escala__valores {
  display: grid;
  grid-template-columns: repeat(var(--n, 6), minmax(0, 1fr));
  gap: var(--sp-1);
}
.escala__valor {
  min-height: 52px;
  min-width: 0;
  padding: 0;
  border: 1px solid var(--muted);
  border-radius: var(--r-md);
  background: var(--surface);
  color: var(--text);
  font: 600 1.25rem/1 var(--font);
  font-variant-numeric: tabular-nums;
  cursor: pointer;
}
.escala__valor[aria-checked="true"] {
  border: 3px solid var(--ink-900);
  background: var(--ink-100);
  font-weight: 800;
}
.escala__valor:focus-visible {
  outline: 3px solid var(--ink-900);
  outline-offset: 2px;
}
.escala__valor:disabled {
  opacity: 0.55;
  cursor: not-allowed;
}
.escala__leyenda {
  margin: 0;
  min-height: 1.4em;
  text-align: center;
  font: 500 0.9375rem/1.4 var(--font);
  color: var(--text);
}
</style>
