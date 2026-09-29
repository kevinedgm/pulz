<script setup lang="ts">
import { Boton } from "../../../shared/ui"
import { haceCuanto } from "../../../shared/offline/instantanea"
import { litros, type Corrida } from "../../destilacion/api"

// Corrida abierta en Hoy (local de Inicio): folio · alambique · pasada ·
// empezó · L cargados / L cortados · Cortar (cola) · Ver corrida.
defineProps<{ corrida: Corrida; cortarTo: string | null; verTo: string }>()
</script>

<template>
  <li class="corrida">
    <div class="corrida__texto">
      <h3 class="corrida__nombre">{{ corrida.folio }}</h3>
      <p class="corrida__sub">
        {{ corrida.alambique }} · {{ corrida.pass === "primera" ? "1ª" : "2ª" }} pasada · empezó
        {{ haceCuanto(corrida.started_at)
        }}<template v-if="corrida.started_by"> · {{ corrida.started_by }}</template>
      </p>
      <p class="corrida__dato">
        <b>{{ litros(corrida.litros_cargados) }}</b> cargados ·
        <b>{{ litros(corrida.litros_cortados) }}</b> cortados
      </p>
    </div>
    <div class="corrida__acciones">
      <Boton v-if="cortarTo" :to="cortarTo">Cortar</Boton
      ><Boton intent="quiet" :to="verTo">Ver corrida</Boton>
    </div>
  </li>
</template>

<style scoped>
.corrida {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  gap: var(--sp-1) var(--sp-3);
  align-items: center;
  padding: var(--sp-3) var(--sp-4);
  min-height: 64px;
}
.corrida + .corrida,
.corrida + :deep(li) {
  border-top: 1px solid var(--border);
}
.corrida__texto {
  min-width: 0;
}
.corrida__nombre {
  margin: 0;
  font: 700 1.0625rem/1.3 var(--font);
  overflow-wrap: anywhere;
}
.corrida__sub {
  margin: 2px 0 0;
  font-size: 0.875rem;
  color: var(--muted);
  overflow-wrap: anywhere;
}
.corrida__dato {
  margin: 2px 0 0;
  font-variant-numeric: tabular-nums;
}
.corrida__acciones {
  display: flex;
  flex-wrap: wrap;
  gap: var(--sp-2);
  justify-content: flex-end;
}
@media (max-width: 599px) {
  .corrida {
    grid-template-columns: 1fr;
  }
  .corrida__acciones {
    justify-content: stretch;
  }
  .corrida__acciones > :deep(*) {
    flex: 1 1 auto;
  }
}
</style>
