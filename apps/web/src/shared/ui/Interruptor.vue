<script setup lang="ts">
import { useId } from "vue"

// Contrato: registry "switch". Booleano que se aplica al guardar. Toda la
// fila es clicable (≥44px); estado por forma (punto relleno / vacío) + texto
// "Sí / No", nunca solo color. role=switch + aria-checked.
withDefaults(
  defineProps<{ modelValue: boolean; etiqueta: string; ayuda?: string; disabled?: boolean }>(),
  { disabled: false },
)
const emit = defineEmits<{ "update:modelValue": [boolean] }>()
const id = useId()
</script>

<template>
  <div class="sw">
    <div class="sw__texto">
      <span :id="`${id}-e`" class="sw__etiqueta">{{ etiqueta }}</span>
      <span v-if="ayuda" :id="`${id}-a`" class="sw__ayuda">{{ ayuda }}</span>
    </div>
    <button
      type="button"
      class="sw__control"
      role="switch"
      :aria-checked="modelValue ? 'true' : 'false'"
      :aria-labelledby="`${id}-e`"
      :aria-describedby="ayuda ? `${id}-a` : undefined"
      :disabled="disabled"
      @click="emit('update:modelValue', !modelValue)"
    >
      <span class="sw__pista" aria-hidden="true"><span class="sw__punto"></span></span>
      <span class="sw__estado">{{ modelValue ? "Sí" : "No" }}</span>
    </button>
  </div>
</template>

<style scoped>
.sw {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--sp-3);
  min-height: var(--tap);
}
.sw__texto {
  display: grid;
  gap: 2px;
  min-width: 0;
}
.sw__etiqueta {
  font: 600 0.9375rem/1.3 var(--font);
  color: var(--text);
}
.sw__ayuda {
  font-size: 0.8125rem;
  line-height: 1.35;
  color: var(--muted);
}
.sw__control {
  flex: none;
  display: inline-flex;
  align-items: center;
  gap: var(--sp-2);
  min-height: var(--tap);
  padding: 0 var(--sp-2);
  border: 0;
  border-radius: var(--r-md);
  background: transparent;
  color: var(--text);
  font: 600 0.9375rem/1 var(--font);
  cursor: pointer;
}
.sw__control:focus-visible {
  outline: 3px solid var(--ink-900);
  outline-offset: 2px;
}
.sw__control:disabled {
  opacity: 0.55;
  cursor: not-allowed;
}
.sw__pista {
  position: relative;
  width: 44px;
  height: 24px;
  border: 2px solid var(--ink-900);
  border-radius: var(--r-pill);
  background: var(--surface);
}
.sw__punto {
  position: absolute;
  top: 2px;
  right: 2px;
  width: 16px;
  height: 16px;
  border: 2px solid var(--ink-900);
  border-radius: 50%;
  background: transparent;
  transition: transform var(--dur, 120ms);
}
.sw__control[aria-checked="true"] .sw__pista {
  background: var(--ink-900);
}
.sw__control[aria-checked="true"] .sw__punto {
  transform: translateX(-20px);
  background: var(--surface);
  border-color: var(--surface);
}
.sw__estado {
  min-width: 1.5em;
  text-align: left;
}
@media (prefers-reduced-motion: reduce) {
  .sw__punto {
    transition: none;
  }
}
</style>
