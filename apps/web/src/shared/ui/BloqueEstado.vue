<script setup lang="ts">
import type { BloqueEstadoVariante } from "./tipos"

// Contrato: registry "state-block" (pattern). Título (qué pasa) + una frase
// (causa o quién puede) + a lo sumo una acción en el slot. Centrado, máx.
// 520px. error lleva role=alert; denied explica, no oculta ni inventa
// "solicitar acceso"; empty ofrece la siguiente acción útil.
withDefaults(defineProps<{ variante: BloqueEstadoVariante; titulo: string; texto?: string }>(), {
  texto: undefined,
})
</script>

<template>
  <section
    class="bloque"
    :class="`bloque--${variante}`"
    :role="variante === 'error' ? 'alert' : undefined"
    :aria-live="variante === 'error' ? undefined : 'polite'"
  >
    <h2 class="bloque__titulo">{{ titulo }}</h2>
    <p v-if="texto" class="bloque__texto">{{ texto }}</p>
    <div v-if="$slots.default" class="bloque__accion"><slot /></div>
  </section>
</template>

<style scoped>
.bloque {
  max-width: 520px;
  margin: var(--sp-8) auto;
  padding: var(--sp-6);
  border: 1px solid var(--border);
  border-radius: var(--r-xl);
  background: var(--surface);
  text-align: center;
}
.bloque--error {
  border-color: var(--late);
}
.bloque__titulo {
  margin: 0 0 var(--sp-2);
  font: 600 1.25rem/1.3 var(--font);
  color: var(--text);
}
.bloque__texto {
  margin: 0;
  color: var(--muted);
  line-height: 1.45;
}
.bloque__accion {
  margin-top: var(--sp-4);
  display: flex;
  justify-content: center;
}
</style>
