<script setup lang="ts">
import { computed, ref, useId } from "vue"
import type { CampoSize } from "./tipos"

// Contrato: registry "password-field" (compone text-field + button).
// Componente aparte porque cambia la anatomía: el control lleva al lado un
// botón "Mostrar/Ocultar" (aria-pressed, target 44px). El sprite no tiene
// icono de ojo: va con texto (docs/DECISIONES.md). Mínimo 8 lo valida el
// formulario, no el campo.
const props = withDefaults(
  defineProps<{
    modelValue: string
    etiqueta: string
    ayuda?: string
    error?: string
    size?: CampoSize
    autocomplete?: "current-password" | "new-password"
    disabled?: boolean
    required?: boolean
    name?: string
  }>(),
  { size: "md", autocomplete: "current-password", disabled: false, required: false },
)
const emit = defineEmits<{ "update:modelValue": [string]; blur: [FocusEvent] }>()

const id = useId()
const ayudaId = `${id}-ayuda`
const errorId = `${id}-error`
const visible = ref(false)
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
    <div class="campo__fila">
      <input
        :id="id"
        class="campo__control"
        :name="name"
        :type="visible ? 'text' : 'password'"
        :value="modelValue"
        :autocomplete="autocomplete"
        autocapitalize="none"
        spellcheck="false"
        :disabled="disabled"
        :required="required"
        :aria-invalid="error ? 'true' : undefined"
        :aria-describedby="describedby"
        @input="emit('update:modelValue', ($event.target as HTMLInputElement).value)"
        @blur="emit('blur', $event)"
      />
      <button
        type="button"
        class="campo__ver"
        :aria-pressed="visible ? 'true' : 'false'"
        :aria-controls="id"
        :disabled="disabled"
        @click="visible = !visible"
      >
        {{ visible ? "Ocultar" : "Mostrar" }}
      </button>
    </div>
    <p v-if="ayuda && !error" :id="ayudaId" class="campo__ayuda">{{ ayuda }}</p>
    <p v-if="error" :id="errorId" class="campo__error">{{ error }}</p>
  </div>
</template>

<style scoped>
.campo {
  display: grid;
  gap: var(--sp-1);
}
.campo__etiqueta {
  font: 600 0.9375rem/1.3 var(--font);
  color: var(--text);
}
.campo__fila {
  display: flex;
  gap: var(--sp-2);
}
.campo__control {
  flex: 1 1 auto;
  min-width: 0;
  min-height: var(--tap);
  padding: 0 var(--sp-3);
  border: 1px solid var(--border);
  border-radius: var(--r-md);
  background: var(--surface);
  color: var(--text);
  font: 400 1rem/1.2 var(--font);
}
.campo--lg .campo__control {
  min-height: calc(var(--tap) + var(--sp-2));
  font-size: 1.125rem;
}
.campo__control:focus-visible,
.campo__ver:focus-visible {
  outline: 3px solid var(--ink-900);
  outline-offset: 1px;
}
.campo__control:focus-visible {
  border-color: var(--ink-900);
}
.campo__ver {
  flex: none;
  min-width: var(--tap);
  min-height: var(--tap);
  padding: 0 var(--sp-3);
  border: 1px solid var(--border);
  border-radius: var(--r-md);
  background: var(--surface);
  color: var(--ink-900);
  font: 600 0.875rem/1 var(--font);
  cursor: pointer;
}
.campo__ver[aria-pressed="true"] {
  background: var(--ink-100);
}
.campo__control:disabled,
.campo__ver:disabled {
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
