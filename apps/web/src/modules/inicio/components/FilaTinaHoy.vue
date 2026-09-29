<script setup lang="ts">
import { computed } from "vue"
import { Boton, ChipEstado } from "../../../shared/ui"
import { haceCuanto } from "../../../shared/offline/instantanea"
import { litros } from "../../fermentacion/dominio"
import type { UsoTina } from "../../fermentacion/api"

// Fila de «Toca medir» (local de Inicio, ronda inicio-hoy/r01): tina ·
// rótulo por la hora del recordatorio · día N de M · última medición ·
// litros · Medir. Solo la primera fila lleva la primaria (en compact la
// primaria es el FAB del shell).
const props = defineProps<{
  uso: UsoTina
  dia: number
  esperados: number
  rotulo: string
  medirTo: string | null
  primaria: boolean
}>()
const ultima = computed(() =>
  props.uso.ultima_medicion_at
    ? `última ${haceCuanto(props.uso.ultima_medicion_at)}`
    : "sin mediciones",
)
</script>

<template>
  <li class="tina">
    <div class="tina__texto">
      <h3 class="tina__nombre">
        {{ uso.tina }}
        <ChipEstado :variante="rotulo === 'toca medir' ? 'partial' : 'draft'">{{
          rotulo
        }}</ChipEstado>
      </h3>
      <p class="tina__sub">
        día {{ dia }} de {{ esperados }} · {{ ultima }} · {{ litros(uso.litros) }}
      </p>
    </div>
    <div v-if="medirTo" class="tina__accion" :class="{ 'tina__accion--primaria': primaria }">
      <Boton :intent="primaria ? 'primary' : 'secondary'" :to="medirTo">Medir</Boton>
    </div>
  </li>
</template>

<style scoped>
.tina {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  gap: var(--sp-1) var(--sp-3);
  align-items: center;
  padding: var(--sp-3) var(--sp-4);
  min-height: 64px;
}
.tina + .tina {
  border-top: 1px solid var(--border);
}
.tina__texto {
  min-width: 0;
}
.tina__nombre {
  margin: 0;
  font: 700 1.0625rem/1.3 var(--font);
  overflow-wrap: anywhere;
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--sp-2);
}
.tina__sub {
  margin: 2px 0 0;
  font-size: 0.875rem;
  color: var(--muted);
  overflow-wrap: anywhere;
  font-variant-numeric: tabular-nums;
}
@media (max-width: 599px) {
  .tina {
    grid-template-columns: 1fr;
  }
  .tina__accion {
    display: grid;
  }
  /* En compact la primaria vive en el FAB del shell: la fila no la repite */
  .tina__accion--primaria {
    display: none;
  }
}
</style>
