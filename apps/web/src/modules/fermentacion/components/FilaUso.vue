<script setup lang="ts">
import { computed, useId } from "vue"
import {
  Boton,
  ChipEstado,
  Icono,
  MenuFila,
  type AccionFila,
  type ChipVariante,
} from "../../../shared/ui"
import type { UsoTina } from "../api"
import { ETIQUETAS_ACTIVIDAD, litros } from "../dominio"

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
  ahoraMs?: number
}>()
const emit = defineEmits<{ ver: []; lista: []; cerrar: []; corregir: [] }>()
const tituloId = useId()

const chip = computed<{ v: ChipVariante; t: string }>(() =>
  props.uso.status === "fermentando"
    ? { v: "partial", t: "fermentando" }
    : props.uso.status === "lista"
      ? { v: "on", t: "lista" }
      : { v: "draft", t: "en vaciado" },
)
const transcurridoMs = computed(() => {
  if (!props.uso.ultima_medicion_at) return null
  return Math.max(
    0,
    (props.ahoraMs ?? Date.now()) - new Date(props.uso.ultima_medicion_at).getTime(),
  )
})
const medicionAtrasada = computed(
  () => transcurridoMs.value === null || transcurridoMs.value > 24 * 60 * 60 * 1000,
)
const haceCuanto = computed(() => {
  if (transcurridoMs.value === null) return "Sin mediciones"
  const minutos = Math.floor(transcurridoMs.value / 60_000)
  if (minutos < 60) return `Hace ${Math.max(1, minutos)} min`
  const horas = Math.floor(minutos / 60)
  if (horas < 48) return `Hace ${horas} h`
  const dias = Math.floor(horas / 24)
  return `Hace ${dias} día${dias === 1 ? "" : "s"}`
})
const actividad = computed(() => {
  const valor = props.uso.ultima_actividad
  if (valor === null) return "—"
  const etiqueta = ETIQUETAS_ACTIVIDAD[valor - 1]
  return etiqueta ? `${etiqueta[0].toUpperCase()}${etiqueta.slice(1)} · ${valor}/6` : `${valor}/6`
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
  <li class="fila" :class="{ 'fila--atrasada': medicionAtrasada }" :aria-labelledby="tituloId">
    <div class="fila__layout">
      <header class="fila__cabecera">
        <div class="fila__nombre">
          <h3 :id="tituloId" class="fila__tina">{{ uso.tina }}</h3>
          <span class="fila__sub">
            {{ uso.folio }} · {{ litros(uso.litros) }} · <b>día {{ dia }}</b
            ><template v-if="uso.status === 'fermentando'"> de ~{{ esperados }}</template
            ><template v-if="!uso.formulation_id"> · sin formulación</template>
          </span>
        </div>
        <ChipEstado class="fila__estado" :variante="chip.v">{{ chip.t }}</ChipEstado>
      </header>

      <p class="fila__antiguedad" :role="medicionAtrasada ? 'status' : undefined">
        <Icono nombre="i-clock" :size="20" />
        <span><b>Última medición:</b> {{ haceCuanto }}</span>
        <strong v-if="medicionAtrasada" class="fila__alerta">
          {{ uso.ultima_medicion_at ? "Medición atrasada" : "Registra la primera medición" }}
        </strong>
        <ChipEstado v-if="pendiente" variante="pending">pendiente de enviar</ChipEstado>
        <template v-if="fallo">
          <ChipEstado variante="failed">falló</ChipEstado>
          <span class="fila__fallo">{{ fallo }}</span>
          <Boton intent="quiet" @click="emit('corregir')">Corregir</Boton>
        </template>
      </p>

      <dl class="fila__metricas" aria-label="Valores de la última medición">
        <div class="fila__metrica">
          <dt>Temperatura</dt>
          <dd>{{ uso.ultima_temperatura === null ? "—" : `${uso.ultima_temperatura} °C` }}</dd>
        </div>
        <div class="fila__metrica">
          <dt>Brix</dt>
          <dd>{{ uso.ultimo_brix === null ? "—" : `${uso.ultimo_brix} °Bx` }}</dd>
        </div>
        <div class="fila__metrica">
          <dt>Actividad</dt>
          <dd>{{ actividad }}</dd>
        </div>
      </dl>

      <div class="fila__acciones">
        <Boton
          v-if="medible && puedeMedir"
          intent="secondary"
          :to="`/e/${slug}/fermentacion/${uso.cycle_id}/medir`"
          :aria-label="`Medir ${uso.tina}`"
          >Registrar medición</Boton
        >
        <MenuFila :nombre="uso.tina" :acciones="acciones" @seleccionar="accion" />
      </div>
    </div>
  </li>
</template>

<style scoped>
.fila {
  container: tina / inline-size;
  padding: var(--sp-4);
  border: 1px solid var(--border);
  border-top: 0;
  background: var(--surface);
}
.fila__layout {
  display: grid;
  gap: var(--sp-3);
}
.fila:first-child {
  border-top: 1px solid var(--border);
  border-radius: var(--r-lg) var(--r-lg) 0 0;
}
.fila:last-child {
  border-radius: 0 0 var(--r-lg) var(--r-lg);
}
.fila__cabecera {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  gap: var(--sp-2) var(--sp-4);
  align-items: start;
}
.fila__nombre {
  min-width: 0;
}
.fila__tina {
  margin: 0;
  font: 700 1.0625rem/1.3 var(--font);
  overflow-wrap: anywhere;
}
.fila__sub {
  font-size: 0.875rem;
  color: var(--muted);
  overflow-wrap: anywhere;
}
.fila__antiguedad {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--sp-1) var(--sp-2);
  min-height: var(--sp-8);
  margin: 0;
  color: var(--muted);
  overflow-wrap: anywhere;
}
.fila--atrasada .fila__antiguedad {
  padding-inline-start: var(--sp-3);
  border-inline-start: 4px solid var(--late);
  color: var(--text);
}
.fila__alerta {
  color: var(--late);
}
.fila__fallo {
  color: var(--text);
}
.fila__estado {
  justify-self: end;
}
.fila__metricas {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  margin: 0;
  border-block: 1px solid var(--border);
}
.fila__metrica {
  min-width: 0;
  padding: var(--sp-3) var(--sp-4);
}
.fila__metrica + .fila__metrica {
  border-inline-start: 1px solid var(--border);
}
.fila__metrica dt {
  color: var(--muted);
  font-size: 0.75rem;
}
.fila__metrica dd {
  margin: var(--sp-1) 0 0;
  font: 700 1.25rem/1.25 var(--font);
  font-variant-numeric: tabular-nums;
  overflow-wrap: anywhere;
}
.fila__acciones {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  gap: var(--sp-2);
}
@container tina (max-width: 599px) {
  .fila__cabecera {
    grid-template-columns: 1fr;
  }
  .fila__estado {
    justify-self: start;
  }
  .fila__metricas {
    grid-template-columns: 1fr;
  }
  .fila__metrica {
    display: grid;
    grid-template-columns: minmax(0, 1fr) auto;
    align-items: baseline;
    gap: var(--sp-3);
    padding: var(--sp-3) 0;
  }
  .fila__metrica + .fila__metrica {
    border-inline-start: 0;
    border-block-start: 1px solid var(--border);
  }
  .fila__metrica dd {
    text-align: end;
  }
  .fila__acciones {
    align-items: stretch;
  }
  .fila__acciones > :first-child {
    flex: 1;
  }
}
@container tina (min-width: 900px) {
  .fila__layout {
    grid-template-columns: minmax(220px, 1.15fr) minmax(220px, 1fr) minmax(360px, 1.45fr) auto;
    align-items: center;
  }
  .fila__antiguedad,
  .fila__metricas,
  .fila__acciones {
    min-width: 0;
  }
}
</style>
