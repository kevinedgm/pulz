<script setup lang="ts">
import { computed, useId } from "vue"
import type { OpcionSelect } from "./tipos"

// Contrato: registry "select". Para 4+ opciones (≤3 → segmented-choice).
// Select nativo (la hoja del sistema en el teléfono), 44px, borde --muted,
// etiqueta visible, ayuda/error con aria-describedby: mismo contrato que
// text-field.
const props = withDefaults(
  defineProps<{
    modelValue: string
    etiqueta: string
    opciones: OpcionSelect[]
    ayuda?: string
    error?: string
    placeholder?: string
    disabled?: boolean
    required?: boolean
  }>(),
  { disabled: false, required: false },
)
const emit = defineEmits<{ "update:modelValue": [string]; blur: [FocusEvent] }>()
const id = useId()
const ayudaId = `${id}-ayuda`
const errorId = `${id}-error`
const describedby = computed(
  () =>
    [props.ayuda && !props.error ? ayudaId : null, props.error ? errorId : null]
      .filter(Boolean)
      .join(" ") || undefined,
)
</script>

<template>
  <div class="campo" :class="{ 'campo--error': error }">
    <label class="campo__etiqueta" :for="id">{{ etiqueta }}</label>
    <select
      :id="id"
      class="campo__control"
      :value="modelValue"
      :disabled="disabled"
      :required="required"
      :aria-invalid="error ? 'true' : undefined"
      :aria-describedby="describedby"
      @change="emit('update:modelValue', ($event.target as HTMLSelectElement).value)"
      @blur="emit('blur', $event)"
    >
      <option v-if="placeholder" value="" disabled>{{ placeholder }}</option>
      <option v-for="o in opciones" :key="o.valor" :value="o.valor" :disabled="o.disabled">
        {{ o.etiqueta }}
      </option>
    </select>
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
.campo__control {
  width: 100%;
  min-width: 0;
  min-height: var(--tap);
  padding: 0 var(--sp-3);
  border: 1px solid var(--muted);
  border-radius: var(--r-md);
  background: var(--surface);
  color: var(--text);
  font: 400 1rem/1.2 var(--font);
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
  color: var(--late);
  font-weight: 600;
}
</style>
