<script setup lang="ts">
import type { ChipVariante } from "./tipos"

// Contrato: registry "status-chip". Punto de forma + texto; el color
// semántico solo refuerza (uso bajo el sol: nunca color solo).
// on = relleno · draft = discontinuo · off = tachado · partial = medio
withDefaults(defineProps<{ variante?: ChipVariante }>(), { variante: "on" })
</script>

<template>
  <span class="chip" :class="`chip--${variante}`"><slot /></span>
</template>

<style scoped>
.chip {
  display: inline-flex;
  align-items: center;
  gap: var(--sp-2);
  min-height: 24px;
  padding: 0 var(--sp-2) 0 var(--sp-2);
  border: 1px solid currentColor;
  border-radius: var(--r-pill);
  font: 600 0.8125rem/1 var(--font);
  white-space: nowrap;
}
.chip::before {
  content: "";
  width: 8px;
  height: 8px;
  border-radius: 50%;
  border: 1.5px solid currentColor;
  flex: none;
}
.chip--on {
  color: var(--ok);
  background: var(--ok-bg);
}
.chip--on::before {
  background: currentColor;
}
.chip--draft {
  /* --pend sobre --pend-bg da 3.03:1 en claro (compuerta de lima, docs/DUDAS.md #12):
     el texto va en --text; el color de estado queda en borde y punto. */
  color: var(--text);
  background: var(--pend-bg);
  border-color: var(--pend);
  border-style: dashed;
}
.chip--draft::before {
  border-color: var(--pend);
}
.chip--off {
  color: var(--muted);
  background: var(--surface);
  text-decoration: line-through;
}
.chip--partial {
  color: var(--info);
  background: var(--info-bg);
}
.chip--partial::before {
  background: linear-gradient(90deg, currentColor 50%, transparent 50%);
}
</style>
