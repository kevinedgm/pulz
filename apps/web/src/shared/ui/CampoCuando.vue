<script setup lang="ts">
import { computed, nextTick, ref, useId } from "vue"

// Contrato: registry "datetime-field" (ronda fermentacion/r01). «¿Cuándo
// pasó?»: por defecto «ahora» (null → la app pone la hora al guardar);
// «cambiar» abre un datetime-local nativo; nunca futuro (error al salir).
// Toda captura del proceso lo lleva: cuándo pasó ≠ cuándo se registró (§3).
const props = withDefaults(
  defineProps<{ modelValue: string | null; etiqueta?: string; disabled?: boolean }>(),
  { etiqueta: "¿Cuándo pasó?", disabled: false },
)
const emit = defineEmits<{ "update:modelValue": [string | null] }>()
const id = useId()
const editando = ref(false)
const error = ref<string | null>(null)
const control = ref<HTMLInputElement | null>(null)

const local = (d: Date) => {
  const p = (n: number) => String(n).padStart(2, "0")
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}T${p(d.getHours())}:${p(d.getMinutes())}`
}
const texto = computed(() => {
  if (!props.modelValue) return "ahora"
  const d = new Date(props.modelValue)
  return new Intl.DateTimeFormat("es-MX", { dateStyle: "medium", timeStyle: "short" }).format(d)
})
async function cambiar() {
  editando.value = true
  if (!props.modelValue) emit("update:modelValue", local(new Date()))
  await nextTick()
  control.value?.focus()
}
function ahora() {
  editando.value = false
  error.value = null
  emit("update:modelValue", null)
}
function onInput(e: Event) {
  emit("update:modelValue", (e.target as HTMLInputElement).value || null)
}
function onBlur() {
  if (props.modelValue && new Date(props.modelValue).getTime() > Date.now() + 60_000)
    error.value = "No puede ser en el futuro."
  else error.value = null
}
</script>

<template>
  <div class="cuando" :class="{ 'cuando--error': error }">
    <span :id="`${id}-etiqueta`" class="cuando__etiqueta">{{ etiqueta }}</span>
    <div v-if="!editando" class="cuando__fila">
      <b class="cuando__valor" :aria-describedby="`${id}-etiqueta`">{{ texto }}</b>
      <button type="button" class="cuando__boton" :disabled="disabled" @click="cambiar">
        cambiar
      </button>
    </div>
    <div v-else class="cuando__fila">
      <input
        :id="id"
        ref="control"
        class="cuando__control"
        type="datetime-local"
        :value="modelValue ?? ''"
        :max="local(new Date())"
        :aria-labelledby="`${id}-etiqueta`"
        :aria-invalid="error ? 'true' : undefined"
        :aria-describedby="error ? `${id}-error` : undefined"
        :disabled="disabled"
        @input="onInput"
        @blur="onBlur"
      />
      <button type="button" class="cuando__boton" :disabled="disabled" @click="ahora">ahora</button>
    </div>
    <p v-if="error" :id="`${id}-error`" class="cuando__error">{{ error }}</p>
  </div>
</template>

<style scoped>
.cuando {
  display: grid;
  gap: var(--sp-1);
}
.cuando__etiqueta {
  font: 600 0.9375rem/1.3 var(--font);
  color: var(--text);
}
.cuando__fila {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--sp-2);
}
.cuando__valor {
  font: 700 1rem/1.3 var(--font);
  color: var(--text);
}
.cuando__control {
  flex: 1 1 200px;
  min-width: 0;
  min-height: var(--tap);
  padding: 0 var(--sp-3);
  border: 1px solid var(--muted);
  border-radius: var(--r-md);
  background: var(--surface);
  color: var(--text);
  font: 400 1rem/1.2 var(--font);
}
.cuando__control:focus-visible {
  border-color: var(--ink-900);
  outline: 3px solid var(--ink-900);
  outline-offset: 1px;
}
.cuando--error .cuando__control {
  border-color: var(--late);
}
.cuando__boton {
  min-height: var(--tap);
  padding: 0 var(--sp-2);
  border: 0;
  background: none;
  color: var(--ink-900);
  font: 500 0.9375rem/1 var(--font);
  text-decoration: underline;
  text-underline-offset: 3px;
  cursor: pointer;
}
.cuando__boton:focus-visible {
  outline: 3px solid var(--ink-900);
  outline-offset: 2px;
  border-radius: var(--r-sm);
}
.cuando__boton:disabled {
  opacity: 0.55;
  cursor: not-allowed;
}
.cuando__error {
  margin: 0;
  font-size: 0.8125rem;
  color: var(--late);
  font-weight: 600;
}
</style>
