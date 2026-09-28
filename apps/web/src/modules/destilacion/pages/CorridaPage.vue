<script setup lang="ts">
import { computed, onMounted, ref } from "vue"
import { useRoute, useRouter } from "vue-router"
import { descartar } from "../../../shared/offline/cola"
import { haceCuanto } from "../../../shared/offline/instantanea"
import { useCola } from "../../../shared/offline/useCola"
import { ErrorAcceso } from "../../../shared/supabase/errores"
import { BloqueEstado, Boton, ChipEstado, ListaApilada } from "../../../shared/ui"
import { useConexion } from "../../../shared/utils/conexion"
import { useAcceso } from "../../acceso/store"
import {
  cargarDestilacion,
  cerrarCorrida,
  cuandoCorto,
  ErrorDestilacion,
  litros,
  resumenCortes,
  type Corrida,
  type DatosDestilacion,
} from "../api"
import ConfirmarCierre from "../components/ConfirmarCierre.vue"

// Corrida (ronda destilacion/r01): KPIs, orígenes, cortes (más los que
// esperan en la cola), «Registrar corte» como primaria y cerrar.
const acceso = useAcceso()
const route = useRoute()
const router = useRouter()
const { enLinea } = useConexion()
const cola = useCola()
const org = computed(() => acceso.membresiaActual?.organization_id ?? "")
const slug = computed(() => String(route.params.slug))
const runId = computed(() => String(route.params.corrida))
const puedeEscribir = computed(() => !acceso.modoLectura)

const datos = ref<DatosDestilacion | null>(null)
const instantanea = ref<string | null>(null)
const errorCarga = ref<string | null>(null)
const aviso = ref<string | null>(
  route.query.aviso === "abierta"
    ? "Corrida abierta."
    : route.query.aviso === "corte"
      ? "Corte guardado."
      : null,
)
const corrida = computed<Corrida | null>(
  () => datos.value?.corridas.find((c) => c.run_id === runId.value) ?? null,
)
const abierta = computed(() => corrida.value?.status === "abierta")
const cortes = computed(() =>
  [...(corrida.value?.cortes ?? [])].sort((a, b) => b.occurred_at.localeCompare(a.occurred_at)),
)
const enCola = computed(() =>
  cola.elementos.value.filter(
    (e) => e.rpc === "registrar_corte" && String(e.params.p_corrida) === runId.value,
  ),
)

async function cargar() {
  errorCarga.value = null
  try {
    const r = await cargarDestilacion(org.value)
    datos.value = r.datos
    instantanea.value = r.instantanea
  } catch (e) {
    errorCarga.value = e instanceof Error ? e.message : String(e)
  }
}
onMounted(cargar)

const cerrando = ref(false)
const ocupado = ref(false)
const errorCerrar = ref<string | null>(null)
async function cerrarConfirmado(nota: string | null, cuando: string | null) {
  if (!corrida.value) return
  ocupado.value = true
  errorCerrar.value = null
  try {
    await cerrarCorrida(org.value, corrida.value.run_id, nota, cuando)
    // La capa deshace su entrada de historial al cerrarse (popstate); navegar
    // antes de que llegue devuelve a esta ruta (DECISIONES shell/r01): se espera.
    cerrando.value = false
    await new Promise<void>((resolve) => {
      const listo = () => {
        window.removeEventListener("popstate", listo)
        resolve()
      }
      window.addEventListener("popstate", listo)
      setTimeout(listo, 400)
    })
    router.push(`/e/${slug.value}/destilacion?aviso=cerrada`)
  } catch (e) {
    errorCerrar.value =
      e instanceof ErrorDestilacion || e instanceof ErrorAcceso ? e.message : String(e)
  } finally {
    ocupado.value = false
  }
}
async function descartarFallo(id: string) {
  await descartar(id)
  await cola.refrescar()
}
</script>

<template>
  <div class="co">
    <div class="co__cuerpo">
      <p class="co__volver">
        <Boton intent="quiet" :to="`/e/${slug}/destilacion`">‹ Destilación</Boton>
      </p>
      <p v-if="instantanea" class="co__instantanea">
        Datos de <b>{{ haceCuanto(instantanea) }}</b
        >.
      </p>
      <p v-if="aviso" class="co__aviso" role="status">{{ aviso }}</p>
      <div v-if="!datos && !errorCarga" class="co__esqueleto" aria-busy="true"></div>
      <BloqueEstado
        v-else-if="errorCarga"
        variante="error"
        titulo="No pudimos cargar la corrida"
        :texto="errorCarga"
      >
        <Boton intent="secondary" @click="cargar">Reintentar</Boton>
      </BloqueEstado>
      <BloqueEstado
        v-else-if="!corrida"
        variante="empty"
        titulo="Esta corrida no existe"
        texto="El enlace no es de esta empresa o la corrida es muy antigua."
      >
        <Boton intent="secondary" :to="`/e/${slug}/destilacion`">Ir a Destilación</Boton>
      </BloqueEstado>
      <div v-else class="co__det">
        <div class="co__principal">
          <h2 class="co__folio">{{ corrida.folio }}</h2>
          <div class="co__kpi">
            <div>
              <b>{{ litros(corrida.litros_cargados) }}</b
              ><span>cargados</span>
            </div>
            <div>
              <b>{{ litros(corrida.litros_cortados) }}</b
              ><span>cortados</span>
            </div>
            <div v-if="corrida.cortes.length">
              <b>{{ resumenCortes(corrida) }}</b
              ><span>por clase</span>
            </div>
          </div>
          <p class="co__sub">
            {{ corrida.alambique
            }}<template v-if="corrida.capacidad_l"> ({{ litros(corrida.capacidad_l) }})</template> ·
            {{ corrida.pass === "primera" ? "1ª pasada" : "2ª pasada" }} · abierta
            {{ cuandoCorto(corrida.started_at)
            }}<template v-if="corrida.started_by"> · {{ corrida.started_by }}</template
            ><template v-if="corrida.closed_at">
              · cerrada {{ cuandoCorto(corrida.closed_at) }}</template
            >
            ·
            <ChipEstado :variante="abierta ? 'partial' : 'off'">{{
              abierta ? "abierta" : "cerrada"
            }}</ChipEstado>
          </p>
          <h3 class="co__h3">Orígenes</h3>
          <ul class="co__origenes">
            <li v-for="o in corrida.origenes" :key="o.lot_id + (o.resource_id ?? '')">
              <span>{{ o.recurso ?? "—" }} · {{ o.folio }}</span
              ><b>{{ litros(o.litros) }}</b>
            </li>
          </ul>
          <h3 class="co__h3">Cortes</h3>
          <BloqueEstado
            v-if="cortes.length === 0 && enCola.length === 0"
            variante="empty"
            titulo="Aún sin cortes"
            texto="Registra cada corte al salir del alambique."
          />
          <ListaApilada
            v-else
            :resumen="`Cortes de ${corrida.folio}: hora, clase, litros, % Alc., colector y lote`"
          >
            <template #cabecera>
              <tr>
                <th scope="col">Hora</th>
                <th scope="col">Clase</th>
                <th scope="col">Litros</th>
                <th scope="col">% Alc.</th>
                <th scope="col">Colector · lote</th>
              </tr>
            </template>
            <tr v-for="e in enCola" :key="e.id">
              <td data-label="Hora">{{ cuandoCorto(e.occurred_at) }}</td>
              <td data-label="Clase">{{ e.params.p_clase }}</td>
              <td data-label="Litros">{{ e.params.p_litros }}</td>
              <td data-label="% Alc.">{{ e.params.p_abv }}</td>
              <td data-label="Colector · lote">
                <ChipEstado v-if="e.estado !== 'fallo'" variante="pending"
                  >pendiente de enviar</ChipEstado
                >
                <template v-else>
                  <ChipEstado variante="failed">falló</ChipEstado>
                  <span class="co__nota">{{ e.error }}</span>
                  <Boton
                    v-if="e.requiereNota"
                    intent="quiet"
                    :to="`/e/${slug}/destilacion/${runId}/corte?corregir=${e.id}`"
                    >Corregir</Boton
                  >
                  <Boton v-else intent="quiet" @click="descartarFallo(e.id)">Descartar</Boton>
                </template>
              </td>
            </tr>
            <tr v-for="k in cortes" :key="k.movement_id">
              <td data-label="Hora">{{ cuandoCorto(k.occurred_at) }}</td>
              <td data-label="Clase">{{ k.clase }}</td>
              <td data-label="Litros">{{ k.litros }}</td>
              <td data-label="% Alc.">{{ k.abv ?? "—" }}</td>
              <td data-label="Colector · lote">{{ k.destino ?? "—" }} · {{ k.folio }}</td>
            </tr>
          </ListaApilada>
          <p class="co__nota">
            Un corte no se anula: se corrige con un ajuste en Granel. La diferencia entre cargado y
            cortado (vinazas, pérdida) no queda como lote.
          </p>
        </div>
        <aside class="co__lado">
          <template v-if="abierta && puedeEscribir">
            <Boton
              intent="primary"
              adapt="page-primary"
              :to="`/e/${slug}/destilacion/${corrida.run_id}/corte`"
              >Registrar corte</Boton
            >
            <h3 class="co__h3">Acciones</h3>
            <Boton
              intent="danger"
              :disabled="!enLinea"
              :motivo-deshabilitado="!enLinea ? 'Cerrar necesita señal.' : undefined"
              @click="cerrando = true"
              >Cerrar corrida</Boton
            >
          </template>
          <p v-else-if="!abierta" class="co__cerrada">
            Cerrada: solo lectura. Para mover lo cortado usa Granel.
          </p>
        </aside>
      </div>
    </div>
    <ConfirmarCierre
      :abierta="cerrando"
      :corrida="corrida"
      :ocupado="ocupado"
      :error="errorCerrar"
      @cerrar="cerrando = false"
      @confirmar="cerrarConfirmado"
    />
  </div>
</template>

<style scoped>
.co__cuerpo {
  padding: var(--sp-4) var(--sp-5) var(--sp-6);
  max-width: 1100px;
}
.co__volver {
  margin: 0 0 var(--sp-2);
}
.co__instantanea {
  margin: 0 0 var(--sp-3);
  padding: var(--sp-2) var(--sp-3);
  border: 1px dashed var(--muted);
  border-radius: var(--r-md);
  font-size: 0.9375rem;
}
.co__aviso {
  margin: 0 0 var(--sp-3);
  padding: var(--sp-2) var(--sp-3);
  border-radius: var(--r-md);
  background: var(--ok-bg);
}
.co__esqueleto {
  height: 200px;
  border-radius: var(--r-lg);
  background: var(--ink-100);
}
.co__det {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: var(--sp-5);
}
@media (min-width: 1024px) {
  .co__det {
    grid-template-columns: minmax(0, 2fr) minmax(0, 1fr);
  }
}
.co__folio {
  margin: 0 0 var(--sp-3);
  font: 700 1.5rem/1.2 var(--font);
}
.co__kpi {
  display: flex;
  flex-wrap: wrap;
  gap: var(--sp-2) var(--sp-5);
  margin: 0 0 var(--sp-3);
}
.co__kpi b {
  display: block;
  font: 700 1.375rem/1.2 var(--font);
  font-variant-numeric: tabular-nums;
}
.co__kpi span {
  font-size: 0.75rem;
  color: var(--muted);
}
.co__sub {
  margin: 0 0 var(--sp-4);
  font-size: 0.875rem;
  color: var(--muted);
}
.co__h3 {
  margin: var(--sp-3) 0 var(--sp-2);
  font: 700 1.0625rem/1.3 var(--font);
}
.co__origenes {
  list-style: none;
  margin: 0;
  padding: 0;
  border: 1px solid var(--border);
  border-radius: var(--r-lg);
}
.co__origenes li {
  display: flex;
  justify-content: space-between;
  gap: var(--sp-3);
  min-height: 44px;
  align-items: center;
  padding: var(--sp-2) var(--sp-4);
}
.co__origenes li + li {
  border-top: 1px solid var(--border);
}
.co__nota {
  font-size: 0.875rem;
  color: var(--muted);
}
.co__lado {
  display: grid;
  gap: var(--sp-3);
  align-content: start;
}
.co__cerrada {
  margin: 0;
  padding: var(--sp-2) var(--sp-3);
  border: 1px dashed var(--muted);
  border-radius: var(--r-md);
  font-size: 0.9375rem;
}
</style>
