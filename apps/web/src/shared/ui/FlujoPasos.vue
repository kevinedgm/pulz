<script setup lang="ts">
import { nextTick, ref, watch } from "vue"
import Boton from "./Boton.vue"

// Contrato: registry "step-flow" (pattern, ronda fermentacion/r01). Cabecera
// fija con contexto (slot) y «Paso n de N»; un paso visible (slot); barra
// Atrás / Siguiente que en compact es fija en la zona del pulgar y en ≥600
// va bajo el contenido, centrado a 520px. Una sola primaria. Atrás conserva
// valores (el consumidor guarda el estado). El foco va al primer control
// del paso al cambiar. Un concepto por paso.
const props = withDefaults(
  defineProps<{
    paso: number
    total: number
    etiquetaSiguiente?: string
    ocupado?: boolean
    siguienteDeshabilitado?: boolean
    motivoDeshabilitado?: string
    cancelarTo?: string
  }>(),
  { etiquetaSiguiente: "Siguiente", ocupado: false, siguienteDeshabilitado: false },
)
const emit = defineEmits<{ atras: []; siguiente: []; cancelar: [] }>()
const cuerpo = ref<HTMLElement | null>(null)

watch(
  () => props.paso,
  async () => {
    await nextTick()
    const primero = cuerpo.value?.querySelector<HTMLElement>(
      "input:not([disabled]), button[role=radio]:not([disabled]), select:not([disabled]), textarea:not([disabled])",
    )
    primero?.focus()
  },
)
</script>

<template>
  <section class="flujo" :aria-busy="ocupado ? 'true' : undefined">
    <header class="flujo__cab">
      <div class="flujo__contexto"><slot name="cabecera" /></div>
      <p class="flujo__paso" role="status">Paso {{ paso }} de {{ total }}</p>
    </header>
    <div ref="cuerpo" class="flujo__cuerpo">
      <slot />
    </div>
    <div class="flujo__barra">
      <Boton v-if="paso === 1 && cancelarTo" intent="quiet" :to="cancelarTo">Cancelar</Boton>
      <Boton v-else-if="paso === 1" intent="quiet" @click="emit('cancelar')">Cancelar</Boton>
      <Boton v-else intent="quiet" :disabled="ocupado" @click="emit('atras')">Atrás</Boton>
      <Boton
        intent="primary"
        class="flujo__siguiente"
        :loading="ocupado"
        :disabled="siguienteDeshabilitado"
        :motivo-deshabilitado="motivoDeshabilitado"
        @click="emit('siguiente')"
        >{{ etiquetaSiguiente }}</Boton
      >
    </div>
  </section>
</template>

<style scoped>
.flujo {
  max-width: 520px;
  margin: 0 auto;
  padding: var(--sp-4) var(--sp-4) var(--sp-6);
  display: grid;
  gap: var(--sp-4);
}
.flujo__cab {
  display: flex;
  flex-wrap: wrap;
  align-items: baseline;
  justify-content: space-between;
  gap: var(--sp-2) var(--sp-4);
  padding-bottom: var(--sp-3);
  border-bottom: 1px solid var(--border);
}
.flujo__contexto {
  display: flex;
  flex-wrap: wrap;
  align-items: baseline;
  gap: var(--sp-2) var(--sp-4);
  min-width: 0;
}
.flujo__paso {
  margin: 0;
  font-size: 0.875rem;
  color: var(--muted);
  white-space: nowrap;
}
.flujo__cuerpo {
  display: grid;
  gap: var(--sp-4);
}
.flujo__barra {
  display: flex;
  align-items: center;
  gap: var(--sp-3);
}
.flujo__barra :deep(.flujo__siguiente) {
  flex: 1 1 auto;
}
@media (max-width: 599px) {
  .flujo {
    padding-bottom: calc(var(--sp-6) + 80px);
  }
  .flujo__barra {
    /* zona del pulgar: fija sobre la navegación inferior del shell */
    position: fixed;
    left: 0;
    right: 0;
    bottom: calc(64px + env(safe-area-inset-bottom));
    z-index: 12;
    padding: var(--sp-3) var(--sp-4);
    background: var(--surface);
    border-top: 1px solid var(--border);
  }
}
</style>
