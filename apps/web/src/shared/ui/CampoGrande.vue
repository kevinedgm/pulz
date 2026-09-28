<script setup lang="ts">
import { computed, onMounted, ref, useId } from "vue"

// Contrato: registry "big-number-field" (ronda fermentacion/r01). Un solo
// número por pantalla, con una mano (§13.2 #4): control 2.75rem centrado y
// tabular, teclado numérico del teléfono, unidad y rango como texto. Hereda
// number-field: valor number | null, sin spinners, valida al salir.
const props = withDefaults(
  defineProps<{
    modelValue: number | null
    etiqueta: string
    unidad?: string
    rango?: string
    error?: string
    decimales?: boolean
    min?: number
    max?: number
    disabled?: boolean
    autofocus?: boolean
    placeholder?: string
  }>(),
  { decimales: true, disabled: false, autofocus: false },
)
const emit = defineEmits<{ "update:modelValue": [number | null]; blur: [FocusEvent] }>()
const id = useId()
const rangoId = `${id}-rango`
const errorId = `${id}-error`
const control = ref<HTMLInputElement | null>(null)
const describedby = computed(
  () =>
    [props.rango && !props.error ? rangoId : null, props.error ? errorId : null]
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
onMounted(() => {
  if (props.autofocus) control.value?.focus()
})
defineExpose({ enfocar: () => control.value?.focus() })
</script>

<template>
  <div class="grande" :class="{ 'grande--error': error }">
    <label class="grande__etiqueta" :for="id">{{ etiqueta }}</label>
    <input
      :id="id"
      ref="control"
      class="grande__control"
      type="text"
      :inputmode="decimales ? 'decimal' : 'numeric'"
      :value="texto"
      :placeholder="placeholder"
      :min="min"
      :max="max"
      :disabled="disabled"
      :aria-invalid="error ? 'true' : undefined"
      :aria-describedby="describedby"
      autocomplete="off"
      @input="onInput"
      @blur="emit('blur', $event)"
    />
    <p v-if="(unidad || rango) && !error" :id="rangoId" class="grande__rango">
      <span v-if="unidad">{{ unidad }}</span
      ><span v-if="unidad && rango"> · </span><span v-if="rango">{{ rango }}</span>
    </p>
    <p v-if="error" :id="errorId" class="grande__error">{{ error }}</p>
  </div>
</template>

<style scoped>
.grande {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: var(--sp-2);
}
.grande__etiqueta {
  font: 600 1rem/1.3 var(--font);
  color: var(--text);
}
.grande__control {
  min-width: 0;
  width: 100%;
  min-height: 4.5rem;
  padding: 0 var(--sp-3);
  border: 1px solid var(--muted);
  border-radius: var(--r-lg);
  background: var(--surface);
  color: var(--text);
  font: 700 2.75rem/1.1 var(--font);
  font-variant-numeric: tabular-nums;
  text-align: center;
}
.grande__control::placeholder {
  color: var(--muted);
  opacity: 0.6;
  font-weight: 500;
}
.grande__control:focus-visible {
  border-color: var(--ink-900);
  outline: 3px solid var(--ink-900);
  outline-offset: 1px;
}
.grande__control:disabled {
  opacity: 0.55;
  cursor: not-allowed;
}
.grande--error .grande__control {
  border-color: var(--late);
}
.grande__rango,
.grande__error {
  margin: 0;
  text-align: center;
  font-size: 0.875rem;
  line-height: 1.35;
}
.grande__rango {
  color: var(--muted);
}
.grande__error {
  color: var(--late);
  font-weight: 600;
}
</style>
