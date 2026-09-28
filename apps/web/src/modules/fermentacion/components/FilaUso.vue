<script setup lang="ts">
import { computed } from "vue"
import { Boton, ChipEstado, MenuFila, type AccionFila, type ChipVariante } from "../../../shared/ui"
import { cuandoCorto, litros, type UsoTina } from "../api"

// Fila de un uso de tina (local del módulo; ronda fermentacion/r01): tina,
// folio, litros, día N; última medición; chip de estado; Medir + menú.
// En compact se apila (tarjeta); en expanded es una línea.
const props = defineProps<{
  uso: UsoTina
  dia: number
  esperados: number
  slug: string
  pendiente?: boolean
  fallo?: string | null
  puedeMedir: boolean
  puedeGestionar: boolean
}>()
const emit = defineEmits<{ ver: []; lista: []; cerrar: []; corregir: [] }>()

const chip = computed<{ v: ChipVariante; t: string }>(() =>
  props.uso.status === "fermentando"
    ? { v: "partial", t: "fermentando" }
    : props.uso.status === "lista"
      ? { v: "on", t: "lista" }
      : { v: "draft", t: "en vaciado" },
)
const ultima = computed(() => {
  const u = props.uso
  if (!u.ultima_medicion_at) return "nunca medida"
  const partes = [cuandoCorto(u.ultima_medicion_at)]
  if (u.ultima_temperatura !== null) partes.push(`${u.ultima_temperatura} °C`)
  if (u.ultimo_brix !== null) partes.push(`${u.ultimo_brix} Brix`)
  if (u.ultima_actividad !== null) partes.push(`actividad ${u.ultima_actividad}`)
  return partes.join(" · ")
})
const acciones = computed<AccionFila[]>(() => {
  const a: AccionFila[] = [{ id: "ver", etiqueta: "Ver mediciones" }]
  if (props.puedeGestionar && props.uso.status === "fermentando")
    a.push({ id: "lista", etiqueta: "Declarar lista" })
  if (props.puedeGestionar)
    a.push({ id: "cerrar", etiqueta: "Cerrar ciclo (tina vaciada)…", intent: "danger" })
  return a
})
function accion(id: string) {
  if (id === "ver") emit("ver")
  else if (id === "lista") emit("lista")
  else if (id === "cerrar") emit("cerrar")
}
const medible = computed(() => props.uso.status === "fermentando" || props.uso.status === "lista")
</script>

<template>
  <li class="fila" :aria-label="uso.tina">
    <div class="fila__nombre">
      <h3 class="fila__tina">{{ uso.tina }}</h3>
      <span class="fila__sub">
        {{ uso.folio }} · {{ litros(uso.litros) }} · <b>día {{ dia }}</b
        ><template v-if="uso.status === 'fermentando'"> de ~{{ esperados }}</template
        ><template v-if="!uso.formulation_id"> · sin formulación</template>
      </span>
    </div>
    <div class="fila__ultima">
      Última: {{ ultima }}
      <ChipEstado v-if="pendiente" variante="pending">pendiente de enviar</ChipEstado>
      <template v-if="fallo">
        <ChipEstado variante="failed">falló</ChipEstado>
        <span class="fila__fallo">{{ fallo }}</span>
        <Boton intent="quiet" @click="emit('corregir')">Corregir</Boton>
      </template>
    </div>
    <ChipEstado class="fila__estado" :variante="chip.v">{{ chip.t }}</ChipEstado>
    <div class="fila__acciones">
      <Boton
        v-if="medible"
        intent="secondary"
        :to="`/e/${slug}/fermentacion/${uso.cycle_id}/medir`"
        :disabled="!puedeMedir"
        :aria-label="`Medir ${uso.tina}`"
        >Medir</Boton
      >
      <MenuFila :nombre="uso.tina" :acciones="acciones" @seleccionar="accion" />
    </div>
  </li>
</template>

<style scoped>
.fila {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  grid-template-areas:
    "nombre estado"
    "ultima ultima"
    "acciones acciones";
  gap: var(--sp-2) var(--sp-3);
  align-items: center;
  padding: var(--sp-3) var(--sp-4);
  border: 1px solid var(--border);
  border-top: 0;
  background: var(--surface);
}
.fila:first-child {
  border-top: 1px solid var(--border);
  border-radius: var(--r-lg) var(--r-lg) 0 0;
}
.fila:last-child {
  border-radius: 0 0 var(--r-lg) var(--r-lg);
}
.fila__nombre {
  grid-area: nombre;
  min-width: 0;
}
.fila__tina {
  margin: 0;
  font: 700 1.0625rem/1.3 var(--font);
  overflow-wrap: anywhere;
}
.fila__sub,
.fila__ultima {
  font-size: 0.875rem;
  color: var(--muted);
  overflow-wrap: anywhere;
}
.fila__ultima {
  grid-area: ultima;
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--sp-1) var(--sp-2);
}
.fila__fallo {
  color: var(--text);
}
.fila__estado {
  grid-area: estado;
  justify-self: end;
}
.fila__acciones {
  grid-area: acciones;
  display: flex;
  align-items: center;
  gap: var(--sp-2);
}
@media (min-width: 1024px) {
  .fila {
    grid-template-columns: minmax(0, 1.3fr) minmax(0, 1.4fr) auto auto;
    grid-template-areas: "nombre ultima estado acciones";
    min-height: 64px;
  }
  .fila__estado {
    justify-self: start;
  }
  .fila__acciones {
    justify-content: flex-end;
  }
}
</style>
