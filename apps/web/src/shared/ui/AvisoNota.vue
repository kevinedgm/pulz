<script setup lang="ts">
import { computed } from "vue"
import { AVISOS } from "../supabase/errores"
import CampoTexto from "./CampoTexto.vue"

// Contrato: registry "soft-warning-note" (pattern, ronda fermentacion/r01).
// Un aviso blando (§2.1) no bloquea: con una nota, la misma captura pasa.
// Se conoce ANTES de enviar cuando la interfaz tiene los rangos; si el
// servidor responde REQUIERE_NOTA:<código>, la misma pieza aparece con ese
// código (rama «Corregir» de la cola). El consumidor bloquea su primaria
// mientras `codigo` exista y la nota esté vacía.
const props = withDefaults(
  defineProps<{
    codigo: string | null
    modelValue: string
    detalle?: string
    disabled?: boolean
  }>(),
  { disabled: false },
)
const emit = defineEmits<{ "update:modelValue": [string] }>()
const texto = computed(() =>
  props.codigo ? (AVISOS[props.codigo] ?? "Esta captura necesita una nota para guardarse.") : "",
)
const [titulo, resto] = [
  computed(() => texto.value.split(". ")[0] + (texto.value.includes(". ") ? "." : "")),
  computed(() => texto.value.split(". ").slice(1).join(". ")),
]
</script>

<template>
  <div v-if="codigo" class="aviso-nota">
    <p class="aviso-nota__aviso" role="alert">
      <b>{{ titulo }}</b>
      <span v-if="detalle"> {{ detalle }}</span>
      <span v-else-if="resto"> {{ resto }}</span>
    </p>
    <CampoTexto
      :model-value="modelValue"
      etiqueta="Nota (obligatoria por el aviso)"
      placeholder="Ej. calor de mediodía, tina al sol"
      autocapitalize="sentences"
      :disabled="disabled"
      required
      @update:model-value="emit('update:modelValue', $event)"
    />
  </div>
</template>

<style scoped>
.aviso-nota {
  display: grid;
  gap: var(--sp-3);
}
.aviso-nota__aviso {
  margin: 0;
  padding: var(--sp-3) var(--sp-4);
  border: 2px solid var(--pend);
  border-radius: var(--r-md);
  background: var(--pend-bg);
  color: var(--text);
  font: 400 0.9375rem/1.4 var(--font);
}
.aviso-nota__aviso b {
  display: block;
  font-weight: 700;
}
</style>
