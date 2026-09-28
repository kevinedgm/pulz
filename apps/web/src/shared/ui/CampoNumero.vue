<script setup lang="ts">
import { computed, useId } from "vue"

// Contrato: registry "number-field". Valor numérico o null; inputmode
// decimal|numeric; unidad opcional a la derecha (texto). Sin spinners. El
// formulario valida rangos al salir y pasa `error`.
const props = withDefaults(
  defineProps<{
    modelValue: number | null
    etiqueta: string
    unidad?: string
    ayuda?: string
    error?: string
    decimales?: boolean
    min?: number
    max?: number
    disabled?: boolean
    required?: boolean
  }>(),
  { decimales: true, disabled: false, required: false },
)
const emit = defineEmits<{ "update:modelValue": [number | null]; blur: [FocusEvent] }>()
const id = useId()
const ayudaId = `${id}-ayuda`
const errorId = `${id}-error`
const describedby = computed(
  () =>
    [props.ayuda && !props.error ? ayudaId : null, props.error ? errorId : null]
      .filter(Boolean)
      .join(" ") || undefined,
)
const texto = computed(() => (props.modelValue === null ? "" : String(props.modelValue)))
function onInput(e: Event) {
  const v = (e.target as HTMLInputElement).value.replace(",", ".").trim()
  if (v === "") return emit("update:modelValue", null)
  const n = Number(v)
  emit("update:modelValue", Number.isFinite(n) ? n : null)
}
</script>

<template>
  <div class="campo" :class="{ 'campo--error': error }">
    <label class="campo__etiqueta" :for="id">{{ etiqueta }}</label>
    <div class="campo__fila">
      <input
        :id="id"
        class="campo__control"
        type="text"
        :inputmode="decimales ? 'decimal' : 'numeric'"
        :value="texto"
        :min="min"
        :max="max"
        :disabled="disabled"
        :required="required"
        :aria-invalid="error ? 'true' : undefined"
        :aria-describedby="describedby"
        autocomplete="off"
        @input="onInput"
        @blur="emit('blur', $event)"
      />
      <span v-if="unidad" class="campo__unidad" aria-hidden="true">{{ unidad }}</span>
    </div>
    <p v-if="ayuda && !error" :id="ayudaId" class="campo__ayuda">{{ ayuda }}</p>
    <p v-if="error" :id="errorId" class="campo__error">{{ error }}</p>
  </div>
</template>

<style scoped>
.campo {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: var(--sp-1);
}
.campo__etiqueta {
  font: 600 0.9375rem/1.3 var(--font);
  color: var(--text);
}
.campo__fila {
  display: flex;
  align-items: center;
  gap: var(--sp-2);
}
.campo__control {
  flex: 1 1 0;
  min-width: 0;
  min-height: var(--tap);
  padding: 0 var(--sp-3);
  border: 1px solid var(--muted);
  border-radius: var(--r-md);
  background: var(--surface);
  color: var(--text);
  font: 400 1rem/1.2 var(--font);
  font-variant-numeric: tabular-nums;
}
.campo__control:focus-visible {
  border-color: var(--ink-900);
  outline: 3px solid var(--ink-900);
  outline-offset: 1px;
}
.campo__control:disabled {
  opacity: 0.55;
  cursor: not-allowed;
}
.campo--error .campo__control {
  border-color: var(--late);
}
.campo__unidad {
  flex: none;
  color: var(--muted);
  font: 500 0.9375rem/1 var(--font);
}
.campo__ayuda,
.campo__error {
  margin: 0;
  font-size: 0.8125rem;
  line-height: 1.35;
}
.campo__ayuda {
  color: var(--muted);
}
.campo__error {
  color: var(--color-danger-text);
  font-weight: 600;
}
</style>
