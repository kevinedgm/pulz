<script setup lang="ts">
import { computed, useId } from "vue"
import { Boton, ChipEstado, MenuFila, type AccionFila, type ChipVariante } from "../../../shared/ui"
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
  registrando?: boolean
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
  <li
    class="tina-fermentacion"
    :class="{ 'tina-fermentacion--atrasada': medicionAtrasada }"
    :aria-labelledby="tituloId"
  >
    <div class="fila__cuerpo">
      <section class="fila__contexto" aria-label="Identidad y antigüedad de la tina">
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
      </section>

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
          class="fila__cta"
          intent="primary"
          :to="`/e/${slug}/fermentacion/${uso.cycle_id}/medir`"
          :loading="registrando"
          :aria-label="`Registrar medición en ${uso.tina}`"
          >Registrar medición</Boton
        >
        <span v-else-if="medible" class="fila__permiso"
          >No tienes permiso para registrar mediciones.</span
        >
        <MenuFila :nombre="uso.tina" :acciones="acciones" @seleccionar="accion" />
      </div>
    </div>
  </li>
</template>

<style scoped>
.tina-fermentacion {
  container: tina / inline-size;
  padding: var(--space-4);
  border: 1px solid var(--color-border);
  border-top: 0;
  background: var(--color-surface);
  color: var(--color-text);
  font-family: var(--font-primary);
}
.fila__cuerpo {
  display: grid;
  gap: var(--space-3);
}
.fila__contexto {
  min-width: 0;
  display: grid;
  gap: var(--space-3);
}
.tina-fermentacion:first-child {
  border-top: 1px solid var(--color-border);
  border-radius: var(--radius-surface) var(--radius-surface) 0 0;
}
.tina-fermentacion:last-child {
  border-radius: 0 0 var(--radius-surface) var(--radius-surface);
}
.fila__cabecera {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  gap: var(--space-2) var(--space-4);
  align-items: start;
}
.fila__nombre {
  min-width: 0;
}
.fila__tina {
  margin: 0;
  font: 700 var(--font-size-lg) / var(--line-height-heading) var(--font-primary);
  overflow-wrap: anywhere;
}
.fila__sub {
  font-size: var(--font-size-sm);
  line-height: var(--line-height-body);
  color: var(--color-text-muted);
  overflow-wrap: anywhere;
}
.fila__antiguedad {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--space-1) var(--space-2);
  min-height: var(--space-8);
  margin: 0;
  color: var(--color-text-muted);
  font-size: var(--font-size-sm);
  line-height: var(--line-height-body);
  overflow-wrap: anywhere;
}
.tina-fermentacion--atrasada .fila__antiguedad {
  padding-inline-start: var(--space-3);
  border-inline-start: 1px solid var(--color-danger);
  color: var(--color-text);
}
.fila__alerta {
  color: var(--color-danger-text);
}
.fila__fallo {
  color: var(--color-text);
}
.fila__estado {
  justify-self: end;
}
.fila__metricas {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  margin: 0;
  border-block: 1px solid var(--color-border);
}
.fila__metrica {
  min-width: 0;
  padding: var(--space-3) var(--space-4);
}
.fila__metrica + .fila__metrica {
  border-inline-start: 1px solid var(--color-border);
}
.fila__metrica dt {
  color: var(--color-text-muted);
  font-size: var(--font-size-xs);
  line-height: var(--line-height-body);
}
.fila__metrica dd {
  margin: var(--space-1) 0 0;
  font: 700 var(--font-size-xl) / var(--line-height-heading) var(--font-primary);
  font-variant-numeric: tabular-nums;
  overflow-wrap: anywhere;
}
.fila__acciones {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  gap: var(--space-2);
  min-width: 0;
  padding-top: var(--space-3);
  border-top: 1px solid var(--color-border);
}
.fila__acciones :deep(.fila__cta) {
  border-radius: var(--radius-control);
  min-height: var(--size-control-height);
}
.fila__permiso {
  margin-inline-end: auto;
  color: var(--color-text-muted);
  font-size: var(--font-size-sm);
  line-height: var(--line-height-body);
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
    gap: var(--space-3);
    padding: var(--space-3) 0;
  }
  .fila__metrica + .fila__metrica {
    border-inline-start: 0;
    border-block-start: 1px solid var(--color-border);
  }
  .fila__metrica dd {
    text-align: end;
  }
  .fila__acciones {
    display: grid;
    grid-template-columns: minmax(0, 1fr);
    align-items: stretch;
  }
  .fila__acciones :deep(.fila__cta) {
    width: 100%;
  }
  .fila__acciones :deep(.menu) {
    justify-self: end;
  }
}
@container tina (min-width: 1024px) {
  .fila__cuerpo {
    grid-template-columns: minmax(280px, 1fr) minmax(480px, 1.7fr);
    column-gap: var(--space-6);
    align-items: start;
  }
  .fila__contexto,
  .fila__metricas,
  .fila__acciones {
    min-width: 0;
  }
  .fila__acciones {
    grid-column: 1 / -1;
  }
}
</style>
