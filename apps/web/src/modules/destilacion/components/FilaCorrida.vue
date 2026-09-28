<script setup lang="ts">
import { computed } from "vue"
import { Boton, ChipEstado, MenuFila, type AccionFila } from "../../../shared/ui"
import { cuandoCorto, litros, resumenCortes, resumenOrigenes, type Corrida } from "../api"

// Fila de una corrida (local; ronda destilacion/r01): folio, alambique,
// pasada, cuándo y quién; cargado desde qué; cortado por clase; chip; en
// abiertas «Registrar corte» + menú (ver, cerrar).
const props = defineProps<{
  corrida: Corrida
  slug: string
  pendientes?: number
  fallo?: { texto: string; corregible: boolean } | null
  puedeCortar: boolean
  puedeCerrar: boolean
}>()
const emit = defineEmits<{ ver: []; cerrar: []; corregir: []; descartar: [] }>()
const abierta = computed(() => props.corrida.status === "abierta")
const acciones = computed<AccionFila[]>(() => {
  const a: AccionFila[] = [{ id: "ver", etiqueta: "Ver corrida" }]
  if (abierta.value && props.puedeCerrar)
    a.push({ id: "cerrar", etiqueta: "Cerrar corrida…", intent: "danger" })
  return a
})
const pasada = computed(() => (props.corrida.pass === "primera" ? "1ª pasada" : "2ª pasada"))
</script>

<template>
  <li class="fc" :aria-label="corrida.folio">
    <div class="fc__nombre">
      <h3 class="fc__folio">{{ corrida.folio }}</h3>
      <span class="fc__sub"
        >{{ corrida.alambique }} · {{ pasada }} · {{ abierta ? "abierta" : "cerrada" }}
        {{ cuandoCorto(abierta ? corrida.started_at : corrida.closed_at) }}
        <template v-if="corrida.started_by"> · {{ corrida.started_by }}</template></span
      >
    </div>
    <div class="fc__datos">
      <span
        ><b>Cargó {{ litros(corrida.litros_cargados) }}</b> ·
        {{ resumenOrigenes(corrida) || "—" }}</span
      >
      <span
        ><b>Cortó {{ litros(corrida.litros_cortados) }}</b
        ><template v-if="corrida.cortes.length"> · {{ resumenCortes(corrida) }}</template>
        <ChipEstado v-if="pendientes" variante="pending"
          >{{ pendientes }} corte{{ pendientes === 1 ? "" : "s" }} pendiente{{
            pendientes === 1 ? "" : "s"
          }}</ChipEstado
        >
        <template v-if="fallo">
          <ChipEstado variante="failed">corte falló</ChipEstado> <span>{{ fallo.texto }}</span>
          <Boton v-if="fallo.corregible" intent="quiet" @click="emit('corregir')">Corregir</Boton>
          <Boton v-else intent="quiet" @click="emit('descartar')">Descartar</Boton>
        </template>
      </span>
    </div>
    <ChipEstado class="fc__estado" :variante="abierta ? 'partial' : 'off'">{{
      abierta ? "abierta" : "cerrada"
    }}</ChipEstado>
    <div class="fc__acciones">
      <Boton
        v-if="abierta"
        intent="secondary"
        :to="`/e/${slug}/destilacion/${corrida.run_id}/corte`"
        :disabled="!puedeCortar"
        :aria-label="`Registrar corte en ${corrida.folio}`"
        >Registrar corte</Boton
      >
      <Boton v-else intent="quiet" :to="`/e/${slug}/destilacion/${corrida.run_id}`">Ver</Boton>
      <MenuFila
        v-if="abierta"
        :nombre="corrida.folio"
        :acciones="acciones"
        @seleccionar="$event === 'ver' ? emit('ver') : emit('cerrar')"
      />
    </div>
  </li>
</template>

<style scoped>
.fc {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  grid-template-areas:
    "nombre estado"
    "datos datos"
    "acciones acciones";
  gap: var(--sp-2) var(--sp-3);
  align-items: center;
  padding: var(--sp-3) var(--sp-4);
  border: 1px solid var(--border);
  border-top: 0;
  background: var(--surface);
}
.fc:first-child {
  border-top: 1px solid var(--border);
  border-radius: var(--r-lg) var(--r-lg) 0 0;
}
.fc:last-child {
  border-radius: 0 0 var(--r-lg) var(--r-lg);
}
.fc__nombre {
  grid-area: nombre;
  min-width: 0;
}
.fc__folio {
  margin: 0;
  font: 700 1.0625rem/1.3 var(--font);
  overflow-wrap: anywhere;
}
.fc__sub {
  font-size: 0.875rem;
  color: var(--muted);
  overflow-wrap: anywhere;
}
.fc__datos {
  grid-area: datos;
  display: grid;
  gap: 2px;
  font-size: 0.875rem;
  color: var(--muted);
  overflow-wrap: anywhere;
}
.fc__datos b {
  color: var(--text);
}
.fc__estado {
  grid-area: estado;
  justify-self: end;
}
.fc__acciones {
  grid-area: acciones;
  display: flex;
  align-items: center;
  gap: var(--sp-2);
}
@media (min-width: 1024px) {
  .fc {
    grid-template-columns: minmax(0, 1.2fr) minmax(0, 1.5fr) auto auto;
    grid-template-areas: "nombre datos estado acciones";
    min-height: 64px;
  }
  .fc__estado {
    justify-self: start;
  }
  .fc__acciones {
    justify-content: flex-end;
  }
}
</style>
