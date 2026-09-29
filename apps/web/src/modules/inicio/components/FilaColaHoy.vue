<script setup lang="ts">
import { Boton, ChipEstado } from "../../../shared/ui"
import type { ElementoCola } from "../../../shared/offline/cola"
import { horaCorta } from "../api"

// Elemento de la cola en «Por enviar» (local de Inicio; candidata a pieza
// `queue-item` si un tercer módulo la necesita): resumen · hora · estado ·
// motivo del fallo · Reintentar · Corregir (si pide nota) o Descartar.
// Pendiente = espera señal: se envía sola (useCola); no hay botón.
defineProps<{ elemento: ElementoCola; corregirTo: string | null; enviando: boolean }>()
const emit = defineEmits<{ reintentar: []; descartar: [] }>()
</script>

<template>
  <li class="cola">
    <div class="cola__texto">
      <h3 class="cola__nombre">{{ elemento.resumen }}</h3>
      <p class="cola__sub">{{ horaCorta(elemento.occurred_at) }}</p>
      <p v-if="elemento.estado === 'fallo'" class="cola__motivo" role="status">
        Falló: {{ elemento.error ?? "sin motivo" }}
      </p>
    </div>
    <div class="cola__acciones">
      <template v-if="elemento.estado === 'fallo'">
        <Boton :loading="enviando" @click="emit('reintentar')">Reintentar</Boton
        ><Boton v-if="corregirTo" intent="quiet" :to="corregirTo">Corregir</Boton
        ><Boton v-else intent="quiet" @click="emit('descartar')">Descartar</Boton>
      </template>
      <ChipEstado v-else variante="pending">pendiente · espera señal</ChipEstado>
    </div>
  </li>
</template>

<style scoped>
.cola {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  gap: var(--sp-1) var(--sp-3);
  align-items: center;
  padding: var(--sp-3) var(--sp-4);
  min-height: 64px;
}
.cola + .cola {
  border-top: 1px solid var(--border);
}
.cola__texto {
  min-width: 0;
}
.cola__nombre {
  margin: 0;
  font: 700 1.0625rem/1.3 var(--font);
  overflow-wrap: anywhere;
}
.cola__sub {
  margin: 2px 0 0;
  font-size: 0.875rem;
  color: var(--muted);
}
.cola__motivo {
  margin: var(--sp-1) 0 0;
  padding: 2px var(--sp-2);
  border: 1px dashed var(--late);
  border-radius: var(--r-sm);
  font-size: 0.875rem;
  color: var(--color-danger-text);
  display: inline-block;
  overflow-wrap: anywhere;
}
.cola__acciones {
  display: flex;
  flex-wrap: wrap;
  gap: var(--sp-2);
  justify-content: flex-end;
  align-items: center;
}
@media (max-width: 599px) {
  .cola {
    grid-template-columns: 1fr;
  }
  .cola__acciones {
    justify-content: stretch;
  }
  .cola__acciones > :deep(button),
  .cola__acciones > :deep(a) {
    flex: 1 1 auto;
  }
}
</style>
