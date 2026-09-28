<script setup lang="ts">
import { computed, onMounted, ref } from "vue"
import { useRoute } from "vue-router"
import { haceCuanto } from "../../../shared/offline/instantanea"
import { BloqueEstado, Boton, ListaApilada, Selector } from "../../../shared/ui"
import { useConexion } from "../../../shared/utils/conexion"
import { useAcceso } from "../../acceso/store"
import {
  cargarGranel,
  cargarHistorial,
  cuandoCorto,
  HISTORIA,
  litros,
  type DatosGranel,
  type Pata,
  type Tanque,
} from "../api"

// Tanque (ronda granel/r01): saldo, lotes con grado vigente, acciones y la
// bitácora (movement_log del recurso, §6) con filtros por lote y persona.
// Las patas de conciliación se leen como diferencia bajo su entrada.
const acceso = useAcceso()
const route = useRoute()
const { enLinea } = useConexion()
const org = computed(() => acceso.membresiaActual?.organization_id ?? "")
const slug = computed(() => String(route.params.slug))
const tanqueId = computed(() => String(route.params.tanque))
const rol = computed(() => acceso.membresiaActual?.role)
const puedeMover = computed(
  () => (rol.value === "admin" || rol.value === "productor") && !acceso.modoLectura,
)

const datos = ref<DatosGranel | null>(null)
const patas = ref<Pata[] | null>(null)
const instantanea = ref<string | null>(null)
const errorCarga = ref<string | null>(null)
const aviso = ref<string | null>(typeof route.query.aviso === "string" ? route.query.aviso : null)
const tanque = computed<Tanque | null>(
  () => datos.value?.tanques.find((t) => t.resource_id === tanqueId.value) ?? null,
)
const filtroLote = ref("")
const filtroQuien = ref("")

async function cargar() {
  errorCarga.value = null
  try {
    const [g, h] = await Promise.all([
      cargarGranel(org.value),
      cargarHistorial(org.value, tanqueId.value),
    ])
    datos.value = g.datos
    patas.value = h.datos
    instantanea.value = g.instantanea ?? h.instantanea
  } catch (e) {
    errorCarga.value = e instanceof Error ? e.message : String(e)
  }
}
onMounted(cargar)

// Conciliaciones agrupadas con su operación
const filas = computed(() => {
  const todas = patas.value ?? []
  const conc = new Map<string, number>()
  for (const p of todas)
    if (p.movement_type === "conciliacion")
      conc.set(p.operation_id, (p.destination ? 1 : -1) * p.volume_l)
  return todas
    .filter((p) => p.movement_type !== "conciliacion")
    .filter((p) => !filtroLote.value || p.folio === filtroLote.value)
    .filter((p) => !filtroQuien.value || p.recorded_by === filtroQuien.value)
    .map((p) => ({
      ...p,
      entra: Boolean(p.destination),
      conciliacion: conc.get(p.operation_id) ?? null,
    }))
})
const opLotes = computed(() => [
  { valor: "", etiqueta: "Todos los lotes" },
  ...[...new Set((patas.value ?? []).map((p) => p.folio))].map((f) => ({ valor: f, etiqueta: f })),
])
const opQuien = computed(() => [
  { valor: "", etiqueta: "Todas las personas" },
  ...[
    ...new Set(
      (patas.value ?? []).map((p) => p.recorded_by).filter((x): x is string => Boolean(x)),
    ),
  ].map((q) => ({ valor: q, etiqueta: q })),
])
const que = (p: Pata) =>
  p.concept ??
  (
    {
      transferencia: "Transferencia",
      consumo: "Unión (consumo)",
      carga_alambique: "Carga al alambique",
      corte: "Corte",
      entrada: "Entrada",
      salida: "Salida",
      correccion: "Corrección",
    } as Record<string, string>
  )[p.movement_type] ??
  p.kind
</script>

<template>
  <div class="tk">
    <div class="tk__cuerpo">
      <p class="tk__volver"><Boton intent="quiet" :to="`/e/${slug}/granel`">‹ Granel</Boton></p>
      <p v-if="instantanea" class="tk__instantanea">
        Datos de <b>{{ haceCuanto(instantanea) }}</b
        >.
      </p>
      <p v-if="aviso" class="tk__aviso" role="status">{{ aviso }}</p>
      <div v-if="!datos && !errorCarga" class="tk__esqueleto" aria-busy="true"></div>
      <BloqueEstado
        v-else-if="errorCarga"
        variante="error"
        titulo="No pudimos cargar el tanque"
        :texto="errorCarga"
      >
        <Boton intent="secondary" @click="cargar">Reintentar</Boton>
      </BloqueEstado>
      <BloqueEstado
        v-else-if="!tanque"
        variante="empty"
        titulo="Este tanque no existe"
        texto="El enlace no es de esta empresa o el tanque está inactivo."
      >
        <Boton intent="secondary" :to="`/e/${slug}/granel`">Ir a Granel</Boton>
      </BloqueEstado>
      <div v-else class="tk__det">
        <div>
          <h2 class="tk__titulo">{{ tanque.tanque }}</h2>
          <div class="tk__kpi">
            <div>
              <b>{{ litros(tanque.litros) }}</b
              ><span>en el tanque</span>
            </div>
            <div v-for="l in tanque.lotes" :key="l.lot_id">
              <b>{{ l.abv !== null ? `${l.abv} %` : "—" }}</b
              ><span
                >{{ l.folio }} · {{ litros(l.litros)
                }}<template v-if="l.abv_by">
                  · {{ l.abv_by }} · {{ cuandoCorto(l.abv_at) }}</template
                >
                · {{ HISTORIA[l.history] }}</span
              >
            </div>
          </div>
          <p class="tk__sub">
            <template v-if="tanque.capacidad_l">{{ litros(tanque.capacidad_l) }} · </template
            >política {{ tanque.capacity_policy
            }}<template v-if="tanque.location"> · {{ tanque.location }}</template>
          </p>
          <h3 class="tk__h3">Historial</h3>
          <div v-if="patas && patas.length" class="tk__filtros">
            <Selector v-model="filtroLote" etiqueta="Lote" :opciones="opLotes" />
            <Selector v-model="filtroQuien" etiqueta="Quién" :opciones="opQuien" />
          </div>
          <BloqueEstado
            v-if="patas && patas.length === 0"
            variante="empty"
            titulo="Aún sin movimientos"
            texto="Cada entrada, salida y transferencia queda aquí con quién y cuándo."
          />
          <ListaApilada
            v-else-if="patas"
            :resumen="`Historial de ${tanque.tanque}: cuándo, qué, lote, litros, % Alc. y quién`"
          >
            <template #cabecera>
              <tr>
                <th scope="col">Cuándo</th>
                <th scope="col">Qué</th>
                <th scope="col">Lote</th>
                <th scope="col">Litros</th>
                <th scope="col">% Alc.</th>
                <th scope="col">Quién</th>
              </tr>
            </template>
            <tr v-for="p in filas" :key="p.movement_id">
              <td data-label="Cuándo">{{ cuandoCorto(p.occurred_at) }}</td>
              <td data-label="Qué">
                {{ que(p) }}
                <span
                  v-if="p.movement_type === 'transferencia' || p.movement_type === 'consumo'"
                  class="tk__nota"
                  >·
                  {{
                    p.entra ? `desde ${p.source ?? "fuera"}` : `hacia ${p.destination ?? "fuera"}`
                  }}</span
                >
                <span v-if="p.counterparty || p.document_ref" class="tk__nota"
                  >· {{ [p.counterparty, p.document_ref].filter(Boolean).join(" · ") }}</span
                >
                <span v-if="p.note" class="tk__nota">· {{ p.note }}</span>
                <span v-if="p.conciliacion !== null" class="tk__nota"
                  >· el sistema registró una diferencia de {{ p.conciliacion > 0 ? "+" : ""
                  }}{{ litros(p.conciliacion) }}</span
                >
              </td>
              <td data-label="Lote">{{ p.folio }}</td>
              <td data-label="Litros">{{ p.entra ? "+" : "−" }}{{ litros(p.volume_l) }}</td>
              <td data-label="% Alc.">
                <template v-if="p.abv !== null"
                  ><b>{{ p.abv }}</b> declarado</template
                ><template v-else>—</template>
              </td>
              <td data-label="Quién">{{ p.recorded_by ?? "—" }}</td>
            </tr>
          </ListaApilada>
        </div>
        <aside class="tk__lado">
          <template v-if="puedeMover">
            <Boton
              intent="primary"
              adapt="page-primary"
              :to="`/e/${slug}/granel/${tanque.resource_id}/movimiento?direccion=entrada`"
              :disabled="!enLinea"
              :motivo-deshabilitado="!enLinea ? 'Necesitas señal.' : undefined"
              >Entrada</Boton
            >
            <Boton
              intent="secondary"
              :to="`/e/${slug}/granel/${tanque.resource_id}/movimiento?direccion=salida`"
              :disabled="!enLinea || tanque.lotes.length === 0"
              :motivo-deshabilitado="
                !enLinea
                  ? 'Necesitas señal.'
                  : tanque.lotes.length === 0
                    ? 'El tanque está vacío.'
                    : undefined
              "
              >Salida</Boton
            >
            <Boton
              intent="secondary"
              :to="`/e/${slug}/granel/transferir?${tanque.lotes.length ? `origen=${tanque.resource_id}` : `destino=${tanque.resource_id}`}`"
              :disabled="!enLinea"
              :motivo-deshabilitado="!enLinea ? 'Necesitas señal.' : undefined"
              >Transferir</Boton
            >
          </template>
          <p v-else class="tk__sub">Los movimientos los registra el productor.</p>
        </aside>
      </div>
    </div>
  </div>
</template>

<style scoped>
.tk__cuerpo {
  padding: var(--sp-4) var(--sp-5) var(--sp-6);
  max-width: 1100px;
}
.tk__volver {
  margin: 0 0 var(--sp-2);
}
.tk__instantanea {
  margin: 0 0 var(--sp-3);
  padding: var(--sp-2) var(--sp-3);
  border: 1px dashed var(--muted);
  border-radius: var(--r-md);
  font-size: 0.9375rem;
}
.tk__aviso {
  margin: 0 0 var(--sp-3);
  padding: var(--sp-2) var(--sp-3);
  border-radius: var(--r-md);
  background: var(--ok-bg);
}
.tk__esqueleto {
  height: 200px;
  border-radius: var(--r-lg);
  background: var(--ink-100);
}
.tk__det {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: var(--sp-5);
}
@media (min-width: 1024px) {
  .tk__det {
    grid-template-columns: minmax(0, 2fr) minmax(0, 1fr);
  }
}
.tk__titulo {
  margin: 0 0 var(--sp-3);
  font: 700 1.5rem/1.2 var(--font);
}
.tk__kpi {
  display: flex;
  flex-wrap: wrap;
  gap: var(--sp-2) var(--sp-5);
  margin: 0 0 var(--sp-3);
}
.tk__kpi b {
  display: block;
  font: 700 1.375rem/1.2 var(--font);
  font-variant-numeric: tabular-nums;
}
.tk__kpi span {
  font-size: 0.75rem;
  color: var(--muted);
}
.tk__sub {
  margin: 0 0 var(--sp-4);
  font-size: 0.875rem;
  color: var(--muted);
}
.tk__h3 {
  margin: var(--sp-3) 0 var(--sp-2);
  font: 700 1.0625rem/1.3 var(--font);
}
.tk__filtros {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: var(--sp-3);
  margin: 0 0 var(--sp-3);
  max-width: 520px;
}
.tk__nota {
  display: block;
  font-size: 0.8125rem;
  color: var(--muted);
}
.tk__lado {
  display: grid;
  gap: var(--sp-2);
  align-content: start;
}
</style>
