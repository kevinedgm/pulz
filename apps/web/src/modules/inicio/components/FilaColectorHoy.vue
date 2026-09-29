<script setup lang="ts">
import { Boton } from "../../../shared/ui"
import { CLASES, litros, type ColectorConSaldo } from "../../destilacion/api"

// Colector con contenido en Hoy (local de Inicio): colector · clase ·
// litros · % Alc. · «Pasar a granel» (mezcal, admin/productor con señal)
// o «Ver» (Destilación).
defineProps<{ colector: ColectorConSaldo; granelTo: string | null; verTo: string }>()
const clase = (c: ColectorConSaldo) =>
  CLASES.find((x) => x.valor === c.liquid_class)?.etiqueta ?? c.liquid_class
</script>

<template>
  <li class="colector">
    <div class="colector__texto">
      <h3 class="colector__nombre">{{ colector.colector }}</h3>
      <p class="colector__sub">{{ colector.folio }} · {{ clase(colector) }}</p>
      <p class="colector__dato">
        <b>{{ litros(colector.litros) }}</b
        ><template v-if="colector.abv !== null"> · {{ colector.abv }} % Alc.</template>
      </p>
    </div>
    <div class="colector__acciones">
      <Boton v-if="granelTo" :to="granelTo">Pasar a granel</Boton
      ><Boton v-else intent="quiet" :to="verTo">Ver</Boton>
    </div>
  </li>
</template>

<style scoped>
.colector {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  gap: var(--sp-1) var(--sp-3);
  align-items: center;
  padding: var(--sp-3) var(--sp-4);
  min-height: 64px;
  border-top: 1px solid var(--border);
}
.colector:first-child {
  border-top: 0;
}
.colector__texto {
  min-width: 0;
}
.colector__nombre {
  margin: 0;
  font: 700 1.0625rem/1.3 var(--font);
  overflow-wrap: anywhere;
}
.colector__sub {
  margin: 2px 0 0;
  font-size: 0.875rem;
  color: var(--muted);
  overflow-wrap: anywhere;
}
.colector__dato {
  margin: 2px 0 0;
  font-variant-numeric: tabular-nums;
}
.colector__acciones {
  display: flex;
  justify-content: flex-end;
}
@media (max-width: 599px) {
  .colector {
    grid-template-columns: 1fr;
  }
  .colector__acciones {
    display: grid;
  }
}
</style>
