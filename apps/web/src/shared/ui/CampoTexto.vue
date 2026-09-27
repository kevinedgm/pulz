<script setup lang="ts">
import { computed, useId } from "vue"
import type { CampoSize } from "./tipos"

// Contrato: registry "text-field". Etiqueta visible siempre (el placeholder
// solo ejemplifica), ayuda y error debajo con aria-describedby; lg (52px)
// para los campos de acceso en compact (una mano, sol).
const props = withDefaults(
  defineProps<{
    modelValue: string
    etiqueta: string
    ayuda?: string
    error?: string
    size?: CampoSize
    type?: "text" | "email" | "search" | "password"
    inputmode?: "text" | "email" | "search" | "none"
    autocomplete?: string
    autocapitalize?: "none" | "sentences" | "words"
    placeholder?: string
    disabled?: boolean
    required?: boolean
    name?: string
  }>(),
  { size: "md", type: "text", disabled: false, required: false, autocapitalize: "none" },
)
const emit = defineEmits<{ "update:modelValue": [string]; blur: [FocusEvent] }>()

const id = useId()
const ayudaId = `${id}-ayuda`
const errorId = `${id}-error`
const describedby = computed(
  () =>
    // solo ids que existen en el DOM: la ayuda se oculta cuando hay error
    [props.ayuda && !props.error ? ayudaId : null, props.error ? errorId : null]
      .filter(Boolean)
      .join(" ") || undefined,
)
</script>

<template>
  <div class="campo" :class="[`campo--${size}`, { 'campo--error': error }]">
    <label class="campo__etiqueta" :for="id">{{ etiqueta }}</label>
    <input
      :id="id"
      class="campo__control"
      :name="name"
      :type="type"
      :value="modelValue"
      :inputmode="inputmode"
      :autocomplete="autocomplete"
      :autocapitalize="autocapitalize"
      :placeholder="placeholder"
      :disabled="disabled"
      :required="required"
      :aria-invalid="error ? 'true' : undefined"
      :aria-describedby="describedby"
      @input="emit('update:modelValue', ($event.target as HTMLInputElement).value)"
      @blur="emit('blur', $event)"
    />
    <p v-if="ayuda && !error" :id="ayudaId" class="campo__ayuda">{{ ayuda }}</p>
    <p v-if="error" :id="errorId" class="campo__error">{{ error }}</p>
  </div>
</template>

<style scoped>
.campo {
  display: grid;
  grid-template-columns: minmax(0, 1fr); /* la columna no crece al ancho intrínseco del input */
  gap: var(--sp-1);
}
.campo__etiqueta {
  font: 600 0.9375rem/1.3 var(--font);
  color: var(--text);
}
.campo__control {
  width: 100%;
  min-width: 0; /* sin ancho intrínseco: con texto al 200 % no desborda */
  min-height: var(--tap);
  padding: 0 var(--sp-3);
  /* --muted, no --border: el borde es el límite del control (3:1 no-texto, sol) */
  border: 1px solid var(--muted);
  border-radius: var(--r-md);
  background: var(--surface);
  color: var(--text);
  font: 400 1rem/1.2 var(--font);
}
.campo--lg .campo__control {
  min-height: calc(var(--tap) + var(--sp-2));
  font-size: 1.125rem;
}
.campo__control::placeholder {
  color: var(--muted);
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
