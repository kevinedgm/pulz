<script setup lang="ts" generic="T extends string">
import { useId } from "vue"
import type { OpcionSegmento } from "./tipos"

// Contrato: registry "segmented-choice". 2–3 opciones excluyentes con texto
// (más → select nativo). radiogroup semántico: flechas mueven la selección;
// selección por forma y peso, no solo color. Ancho completo en compact.
const props = withDefaults(
  defineProps<{
    modelValue: T
    opciones: OpcionSegmento<T>[]
    etiqueta: string
    disabled?: boolean
  }>(),
  { disabled: false },
)
const emit = defineEmits<{ "update:modelValue": [T] }>()
const id = useId()

function mover(delta: number) {
  const i = props.opciones.findIndex((o) => o.valor === props.modelValue)
  const n = (i + delta + props.opciones.length) % props.opciones.length
  emit("update:modelValue", props.opciones[n].valor)
  ;(document.getElementById(`${id}-${n}`) as HTMLElement | null)?.focus()
}
</script>

<template>
  <div class="segmento" role="radiogroup" :aria-labelledby="`${id}-etiqueta`">
    <span :id="`${id}-etiqueta`" class="segmento__etiqueta">{{ etiqueta }}</span>
    <div class="segmento__opciones" :style="{ '--n': opciones.length }">
      <button
        v-for="(o, i) in opciones"
        :id="`${id}-${i}`"
        :key="o.valor"
        type="button"
        role="radio"
        class="segmento__opcion"
        :aria-checked="o.valor === modelValue ? 'true' : 'false'"
        :tabindex="o.valor === modelValue ? 0 : -1"
        :disabled="disabled"
        @click="emit('update:modelValue', o.valor)"
        @keydown.right.down.prevent="mover(1)"
        @keydown.left.up.prevent="mover(-1)"
      >
        {{ o.etiqueta }}
      </button>
    </div>
    <p v-if="opciones.find((o) => o.valor === modelValue)?.ayuda" class="segmento__ayuda">
      {{ opciones.find((o) => o.valor === modelValue)?.ayuda }}
    </p>
  </div>
</template>

<style scoped>
.segmento {
  display: grid;
  gap: var(--sp-1);
}
.segmento__etiqueta {
  font: 600 0.9375rem/1.3 var(--font);
  color: var(--text);
}
.segmento__opciones {
  /* n columnas iguales; si una etiqueta no cabe (texto al 200 % en compact),
     la opción baja de fila en vez de recortarse (compuerta de lima) */
  display: flex;
  flex-wrap: wrap;
  gap: var(--sp-2);
}
.segmento__opcion {
  flex: 1 1 calc((100% - var(--sp-2) * (var(--n, 2) - 1)) / var(--n, 2));
  min-width: max-content;
  min-height: var(--tap);
  padding: 0 var(--sp-3);
  border: 1px solid var(--muted); /* límite del control ≥ 3:1 (compuerta de lima) */
  border-radius: var(--r-md);
  background: var(--surface);
  color: var(--text);
  font: 500 0.9375rem/1.2 var(--font);
  cursor: pointer;
}
.segmento__opcion[aria-checked="true"] {
  border: 2px solid var(--ink-900);
  background: var(--ink-100);
  font-weight: 700;
}
.segmento__opcion:focus-visible {
  outline: 3px solid var(--ink-900);
  outline-offset: 2px;
}
.segmento__opcion:disabled {
  opacity: 0.55;
  cursor: not-allowed;
}
.segmento__ayuda {
  margin: 0;
  font-size: 0.8125rem;
  line-height: 1.35;
  color: var(--muted);
}
</style>
