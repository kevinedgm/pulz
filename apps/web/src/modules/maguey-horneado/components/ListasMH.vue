<script setup lang="ts">
import { computed, shallowRef } from "vue"
import { Boton, ChipEstado, BloqueEstado } from "../../../shared/ui"
import { kilos, type DatosMH, type Horneada, type LoteSolido } from "../modelo"
const props = defineProps<{
  datos: DatosMH
  destino: "maguey" | "horneado"
  bloqueado: boolean
  formulacion: string
}>()
const emit = defineEmits<{
  cerrar: [Horneada]
  cocido: []
  recepcion: []
  abrir: []
  ver: [LoteSolido | Horneada]
}>()
const limite = shallowRef(50)
const activos = computed(() =>
  props.datos.lotes.filter(
    (l) => l.material === (props.destino === "maguey" ? "maguey" : "agave_cocido") && l.saldo > 0,
  ),
)
const agotados = computed(() =>
  props.datos.lotes.filter((l) => l.material === "maguey" && l.saldo <= 0).slice(0, 10),
)
const abiertas = computed(() => props.datos.horneadas.filter((h) => h.estado === "abierta"))
const cerradas = computed(() =>
  props.datos.horneadas.filter((h) => h.estado === "cerrada").slice(0, 10),
)
const total = computed(() => activos.value.reduce((n, l) => n + l.saldo, 0))
const fecha = (iso: string) =>
  iso
    ? new Intl.DateTimeFormat("es-MX", { dateStyle: "medium", timeStyle: "short" }).format(
        new Date(iso),
      )
    : ""
</script>
<template>
  <p role="status">
    {{
      destino === "maguey"
        ? `${activos.length} lotes con saldo`
        : `${abiertas.length} horneadas abiertas`
    }}
    · <b>{{ kilos(total) }} {{ destino === "maguey" ? "de maguey" : "de cocido con saldo" }}</b>
  </p>
  <section v-if="destino === 'horneado'" class="mh-group">
    <h2>Horneadas abiertas</h2>
    <p v-if="!abiertas.length">No hay horneadas abiertas.</p>
    <ul class="mh-list">
      <li v-for="h in abiertas" :key="h.id" class="mh-row">
        <div class="mh-identity">
          <h3>{{ h.folio }}</h3>
          <p>
            {{ h.horno }} · empezó {{ fecha(h.inicio)
            }}<template v-if="h.quien"> · {{ h.quien }}</template>
          </p>
        </div>
        <div class="mh-data">
          <b>Cargó {{ kilos(h.cargados) }}</b
          ><span>{{ h.origenes }}</span>
        </div>
        <ChipEstado class="mh-state" variante="partial">abierta</ChipEstado>
        <div class="mh-actions">
          <Boton :disabled="bloqueado" @click="emit('cerrar', h)">Cerrar horneada</Boton
          ><Boton intent="quiet" @click="emit('ver', h)">Ver detalle</Boton>
        </div>
      </li>
    </ul>
  </section>
  <section class="mh-group">
    <h2 v-if="destino === 'horneado'">Agave cocido con saldo</h2>
    <BloqueEstado
      v-if="!activos.length"
      variante="empty"
      :titulo="destino === 'maguey' ? 'Aún no hay maguey con saldo' : 'Sin cocido disponible'"
      :texto="
        destino === 'maguey'
          ? 'Registra los kilos que recibiste.'
          : 'Cierra una horneada o registra el cocido que ya tenías.'
      "
    />
    <ul class="mh-list">
      <li v-for="l in activos.slice(0, limite)" :key="l.id" class="mh-row">
        <div class="mh-identity">
          <h3>{{ l.folio }}</h3>
          <p>
            {{ l.contexto }}<template v-if="l.cuando"> · {{ fecha(l.cuando) }}</template
            ><template v-if="l.quien"> · {{ l.quien }}</template>
          </p>
        </div>
        <div class="mh-data">
          <b>{{ kilos(l.saldo) }}</b
          ><span
            >restantes de {{ kilos(l.inicial)
            }}<template v-if="l.nota"> · {{ l.nota }}</template></span
          >
        </div>
        <ChipEstado class="mh-state">con saldo</ChipEstado>
        <div class="mh-actions">
          <Boton v-if="destino === 'horneado'" :to="formulacion" :disabled="bloqueado"
            >Llenar tinas</Boton
          ><Boton v-else intent="quiet" @click="emit('ver', l)">Ver detalle</Boton>
        </div>
      </li>
    </ul>
    <Boton v-if="activos.length > limite" @click="limite += 50">Mostrar siguientes 50 lotes</Boton>
  </section>
  <details v-if="destino === 'maguey' && agotados.length" class="mh-details">
    <summary>Agotados (últimos 10)</summary>
    <ul class="mh-list">
      <li v-for="l in agotados" :key="l.id" class="mh-row">
        <div class="mh-identity">
          <h3>{{ l.folio }}</h3>
          <p>{{ l.contexto }}</p>
        </div>
        <div class="mh-data">
          <b>{{ kilos(l.saldo) }}</b
          ><span>de {{ kilos(l.inicial) }}</span>
        </div>
        <ChipEstado class="mh-state" variante="off">agotado</ChipEstado>
        <div class="mh-actions">
          <Boton intent="quiet" @click="emit('ver', l)">Ver detalle</Boton>
        </div>
      </li>
    </ul>
  </details>
  <section v-if="destino === 'horneado'" class="mh-group">
    <h2>Últimas horneadas</h2>
    <p v-if="!cerradas.length">Todavía no hay cierres registrados.</p>
    <ul class="mh-list">
      <li v-for="h in cerradas" :key="h.id" class="mh-row">
        <div class="mh-identity">
          <h3>{{ h.folio }}</h3>
          <p>{{ h.horno }} · {{ fecha(h.inicio) }} → {{ fecha(h.fin ?? "") }}</p>
        </div>
        <div class="mh-data">
          <span>{{ kilos(h.cargados) }} cargados →</span
          ><b>{{ h.cocidos === null ? "Sin cantidad declarada" : kilos(h.cocidos) + " cocidos" }}</b
          ><span>{{ h.combustible }}</span>
        </div>
        <ChipEstado class="mh-state" variante="off">cerrada</ChipEstado>
        <div class="mh-actions">
          <Boton intent="quiet" @click="emit('ver', h)">Ver detalle</Boton>
        </div>
      </li>
    </ul>
    <div class="mh-actions">
      <Boton :disabled="bloqueado" @click="emit('cocido')">Cocido que ya tenía</Boton>
    </div>
  </section>
</template>
