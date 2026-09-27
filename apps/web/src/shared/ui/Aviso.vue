<script setup lang="ts">
import type { AvisoVariante } from "./tipos"

// Contrato: registry "banner" (pattern). Franja persistente arriba del
// contenido mientras dure la condición; role=status; sin botón de cerrar;
// nunca más de un aviso a la vez. Fondo semántico + texto de tinta (nunca
// color solo): el título en negrita dice qué pasa.
withDefaults(defineProps<{ variante: AvisoVariante; titulo: string }>(), {})
</script>

<template>
  <p class="aviso" :class="`aviso--${variante}`" role="status">
    <strong class="aviso__titulo">{{ titulo }}</strong>
    <span class="aviso__texto"><slot /></span>
  </p>
</template>

<style scoped>
.aviso {
  margin: 0;
  padding: var(--sp-2) var(--sp-4);
  border-bottom: 1px solid var(--border);
  font: 400 0.9375rem/1.4 var(--font);
  color: var(--text);
}
.aviso--offline {
  background: var(--pend-bg);
}
.aviso--readonly {
  background: var(--info-bg);
}
.aviso__titulo {
  font-weight: 700;
  margin-right: var(--sp-1);
}
</style>
