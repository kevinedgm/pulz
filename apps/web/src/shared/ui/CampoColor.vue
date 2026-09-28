<script setup lang="ts">
import { computed, useId } from "vue"

// Contrato: registry "color-field". Solo para el color de acento de la
// empresa (nunca detrás de texto). input type=color (44px) + hex visible y
// editable; valida ^#[0-9A-Fa-f]{6}$ al salir.
const HEX_RE = /^#[0-9A-Fa-f]{6}$/
const props = withDefaults(
  defineProps<{
    modelValue: string
    etiqueta: string
    ayuda?: string
    error?: string
    disabled?: boolean
  }>(),
  { disabled: false },
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
const valido = computed(() => HEX_RE.test(props.modelValue))
function desdeTexto(e: Event) {
  let v = (e.target as HTMLInputElement).value.trim().toUpperCase()
  if (v && !v.startsWith("#")) v = `#${v}`
  emit("update:modelValue", v)
}
</script>

<template>
  <div class="campo" :class="{ 'campo--error': error }">
    <label class="campo__etiqueta" :for="`${id}-hex`">{{ etiqueta }}</label>
    <div class="campo__fila">
      <input
        :id="id"
        class="campo__muestra"
        type="color"
        :value="valido ? modelValue : '#173F87'"
        :disabled="disabled"
        :aria-label="`Elegir ${etiqueta.toLowerCase()}`"
        @input="emit('update:modelValue', ($event.target as HTMLInputElement).value.toUpperCase())"
      />
      <input
        :id="`${id}-hex`"
        class="campo__control"
        type="text"
        :value="modelValue"
        inputmode="text"
        autocapitalize="characters"
        autocomplete="off"
        maxlength="7"
        placeholder="#RRGGBB"
        :disabled="disabled"
        :aria-invalid="error ? 'true' : undefined"
        :aria-describedby="describedby"
        @input="desdeTexto"
        @blur="emit('blur', $event)"
      />
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
.campo__muestra {
  flex: none;
  width: 56px;
  height: var(--tap);
  padding: 2px;
  border: 1px solid var(--muted);
  border-radius: var(--r-md);
  background: var(--surface);
  cursor: pointer;
}
.campo__muestra:focus-visible,
.campo__control:focus-visible {
  outline: 3px solid var(--ink-900);
  outline-offset: 1px;
}
.campo__control {
  flex: 1 1 0;
  min-width: 0;
  max-width: 10rem;
  min-height: var(--tap);
  padding: 0 var(--sp-3);
  border: 1px solid var(--muted);
  border-radius: var(--r-md);
  background: var(--surface);
  color: var(--text);
  font: 400 1rem/1.2 var(--font);
  font-family: ui-monospace, Menlo, Consolas, var(--font);
}
.campo--error .campo__control {
  border-color: var(--late);
}
.campo__control:disabled,
.campo__muestra:disabled {
  opacity: 0.55;
  cursor: not-allowed;
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
