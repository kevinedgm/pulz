<script setup lang="ts">
import { computed, onMounted, ref } from "vue"
import { useRoute } from "vue-router"
import { haceCuanto } from "../../../shared/offline/instantanea"
import { ErrorAcceso } from "../../../shared/supabase/errores"
import {
  BloqueEstado,
  Boton,
  CampoTexto,
  CapaTarea,
  ChipEstado,
  ListaApilada,
  MenuFila,
  type ChipVariante,
} from "../../../shared/ui"
import { useConexion } from "../../../shared/utils/conexion"
import { useAcceso } from "../../acceso/store"
import {
  anularMedicion,
  cargarMediciones,
  cargarUsos,
  cerrarCiclo,
  cuandoCorto,
  declararLista,
  diaDelCiclo,
  ErrorFermentacion,
  litros,
  type DatosFermentacion,
  type Medicion,
  type UsoTina,
} from "../api"
import ConfirmarCiclo from "../components/ConfirmarCiclo.vue"

// Uso de una tina (ronda fermentacion/r01): KPIs, mediciones (la más
// reciente arriba; las anuladas tachadas con motivo), «Medir hoy» como
// primaria; anular (motivo), declarar lista y cerrar ciclo para admin y
// productor.
const acceso = useAcceso()
const route = useRoute()
const { enLinea } = useConexion()
const org = computed(() => acceso.membresiaActual?.organization_id ?? "")
const slug = computed(() => String(route.params.slug))
const cycleId = computed(() => String(route.params.ciclo))
const rol = computed(() => acceso.membresiaActual?.role)
const puedeGestionar = computed(
  () =>
    (rol.value === "admin" || rol.value === "productor") && !acceso.modoLectura && enLinea.value,
)

const datos = ref<DatosFermentacion | null>(null)
const mediciones = ref<Medicion[] | null>(null)
const instantanea = ref<string | null>(null)
const errorCarga = ref<string | null>(null)
const aviso = ref<string | null>(null)
const uso = computed<UsoTina | null>(
  () => datos.value?.usos.find((u) => u.cycle_id === cycleId.value) ?? null,
)
const hoy = new Date()
const dia = computed(() => (uso.value ? diaDelCiclo(uso.value.started_at, hoy) : 0))
const ultimaValida = computed(() => mediciones.value?.find((m) => !m.voided_at) ?? null)
const chip = computed<{ v: ChipVariante; t: string }>(() =>
  uso.value?.status === "fermentando"
    ? { v: "partial", t: "fermentando" }
    : uso.value?.status === "lista"
      ? { v: "on", t: "lista" }
      : { v: "draft", t: "en vaciado" },
)
const fecha = (iso: string) =>
  new Intl.DateTimeFormat("es-MX", { day: "numeric", month: "short" }).format(new Date(iso))

async function cargar() {
  errorCarga.value = null
  try {
    const [u, m] = await Promise.all([
      cargarUsos(org.value),
      cargarMediciones(org.value, cycleId.value),
    ])
    datos.value = u.datos
    mediciones.value = m.datos
    instantanea.value = u.instantanea ?? m.instantanea
  } catch (e) {
    errorCarga.value = e instanceof Error ? e.message : String(e)
  }
}
onMounted(cargar)

// Anular con motivo (0017: no se borra)
const anular = ref<Medicion | null>(null)
const motivo = ref("")
const ocupado = ref(false)
const errorAccion = ref<string | null>(null)
async function anularConfirmado() {
  if (!anular.value || !motivo.value.trim()) return
  ocupado.value = true
  errorAccion.value = null
  try {
    await anularMedicion(org.value, anular.value.measurement_id, motivo.value)
    aviso.value = `Medición del día ${anular.value.day_no} anulada.`
    anular.value = null
    motivo.value = ""
    await cargar()
  } catch (e) {
    errorAccion.value =
      e instanceof ErrorFermentacion || e instanceof ErrorAcceso ? e.message : String(e)
  } finally {
    ocupado.value = false
  }
}
const confirmar = ref<"lista" | "cerrar" | null>(null)
async function confirmado(nota: string | null, cuando: string | null) {
  if (!confirmar.value || !uso.value) return
  ocupado.value = true
  errorAccion.value = null
  try {
    if (confirmar.value === "lista")
      await declararLista(org.value, uso.value.cycle_id, nota, cuando)
    else await cerrarCiclo(org.value, uso.value.cycle_id, nota, cuando)
    aviso.value =
      confirmar.value === "lista"
        ? `${uso.value.tina} declarada lista.`
        : `${uso.value.tina} quedó libre.`
    confirmar.value = null
    await cargar()
  } catch (e) {
    errorAccion.value =
      e instanceof ErrorFermentacion || e instanceof ErrorAcceso ? e.message : String(e)
  } finally {
    ocupado.value = false
  }
}
</script>

<template>
  <div class="uso">
    <div class="uso__cuerpo">
      <p class="uso__volver">
        <Boton intent="quiet" :to="`/e/${slug}/fermentacion`">‹ Fermentación</Boton>
      </p>
      <p v-if="instantanea" class="uso__instantanea">
        Datos de <b>{{ haceCuanto(instantanea) }}</b
        >.
      </p>
      <p v-if="aviso" class="uso__aviso" role="status">{{ aviso }}</p>
      <div v-if="!datos && !errorCarga" class="uso__esqueleto" aria-busy="true"></div>
      <BloqueEstado
        v-else-if="errorCarga"
        variante="error"
        titulo="No pudimos cargar esta tina"
        :texto="errorCarga"
      >
        <Boton intent="secondary" @click="cargar">Reintentar</Boton>
      </BloqueEstado>
      <BloqueEstado
        v-else-if="!uso"
        variante="empty"
        titulo="Este uso ya no está abierto"
        texto="La tina se cerró o el enlace no es de esta empresa."
      >
        <Boton intent="secondary" :to="`/e/${slug}/fermentacion`">Ir a Fermentación</Boton>
      </BloqueEstado>
      <div v-else class="uso__det">
        <div class="uso__principal">
          <h2 class="uso__tina">{{ uso.tina }}</h2>
          <div class="uso__kpi">
            <div>
              <b>día {{ dia }}</b
              ><span v-if="uso.status === 'fermentando'"
                >de ~{{ datos?.ajustes.fermentation_expected_days }} esperados</span
              >
            </div>
            <div>
              <b>{{ litros(uso.litros) }}</b
              ><span>dentro</span>
            </div>
            <div v-if="ultimaValida?.brix !== null && ultimaValida?.brix !== undefined">
              <b>{{ ultimaValida.brix }}</b
              ><span>Brix {{ cuandoCorto(ultimaValida.occurred_at) }}</span>
            </div>
            <div
              v-if="ultimaValida?.temperatura !== null && ultimaValida?.temperatura !== undefined"
            >
              <b>{{ ultimaValida.temperatura }} °C</b
              ><span>{{ cuandoCorto(ultimaValida.occurred_at) }}</span>
            </div>
          </div>
          <p class="uso__sub">
            {{ uso.folio }} · desde el {{ fecha(uso.started_at)
            }}<template v-if="uso.started_by"> ({{ uso.started_by }})</template>
            <template v-if="uso.formulacion"> · formulación {{ uso.formulacion }}</template>
            <template v-else> · sin formulación</template>
            · <ChipEstado :variante="chip.v">{{ chip.t }}</ChipEstado>
          </p>

          <h3 class="uso__h3">Mediciones</h3>
          <BloqueEstado
            v-if="mediciones && mediciones.length === 0"
            variante="empty"
            titulo="Aún sin mediciones"
            texto="Se mide todos los días. La primera es hoy."
          />
          <ListaApilada
            v-else-if="mediciones"
            :resumen="`Mediciones de ${uso.tina}: día, cuándo, temperatura, Brix, actividad y quién`"
          >
            <template #cabecera>
              <tr>
                <th scope="col">Día</th>
                <th scope="col">Cuándo</th>
                <th scope="col">°C</th>
                <th scope="col">Brix</th>
                <th scope="col">Act.</th>
                <th scope="col">Quién</th>
                <th scope="col"><span class="sr">Acciones</span></th>
              </tr>
            </template>
            <tr
              v-for="m in mediciones"
              :key="m.measurement_id"
              :class="{ uso__anulada: m.voided_at }"
            >
              <td data-label="Día">{{ m.day_no }}</td>
              <td data-label="Cuándo">{{ cuandoCorto(m.occurred_at) }}</td>
              <td data-label="°C">{{ m.temperatura ?? "—" }}</td>
              <td data-label="Brix">{{ m.brix ?? "—" }}</td>
              <td data-label="Act.">
                {{ m.activity ?? "—"
                }}<template v-if="m.mode === 'completo'">
                  · d{{ m.dulzor ?? "—" }} a{{ m.acidez ?? "—" }}</template
                >
              </td>
              <td data-label="Quién">
                {{ m.recorded_by ?? "—" }}
                <span v-if="m.voided_at" class="uso__nota"
                  ><ChipEstado variante="off">anulada</ChipEstado> {{ m.void_reason }}</span
                >
                <span v-else-if="m.notes" class="uso__nota">{{ m.notes }}</span>
              </td>
              <td>
                <MenuFila
                  v-if="puedeGestionar && !m.voided_at"
                  :nombre="`medición del día ${m.day_no}`"
                  :acciones="[{ id: 'anular', etiqueta: 'Anular…', intent: 'danger' }]"
                  @seleccionar="anular = m"
                />
              </td>
            </tr>
          </ListaApilada>
        </div>
        <aside class="uso__lado">
          <Boton
            v-if="(uso.status === 'fermentando' || uso.status === 'lista') && !acceso.modoLectura"
            intent="primary"
            adapt="page-primary"
            :to="`/e/${slug}/fermentacion/${uso.cycle_id}/medir`"
            >Medir hoy</Boton
          >
          <template v-if="puedeGestionar">
            <h3 class="uso__h3">Acciones</h3>
            <div class="uso__acciones">
              <Boton
                v-if="uso.status === 'fermentando'"
                intent="secondary"
                @click="confirmar = 'lista'"
                >Declarar lista</Boton
              >
              <Boton intent="danger" @click="confirmar = 'cerrar'"
                >Cerrar ciclo (tina vaciada)</Boton
              >
            </div>
          </template>
        </aside>
      </div>
    </div>

    <CapaTarea
      :abierta="anular !== null"
      :titulo="`Anular la medición del día ${anular?.day_no ?? ''}`"
      etiqueta-cerrar="Cancelar"
      @cerrar="anular = null"
    >
      <form class="uso__form" @submit.prevent="anularConfirmado">
        <p class="uso__texto">Queda tachada con tu nombre; no se borra.</p>
        <CampoTexto
          v-model="motivo"
          etiqueta="Motivo"
          placeholder="Ej. dedo en el 7, era 27"
          autocapitalize="sentences"
          required
          :disabled="ocupado"
        />
        <p v-if="errorAccion" class="uso__error" role="alert">{{ errorAccion }}</p>
        <div class="uso__acciones-fila">
          <Boton intent="danger" type="submit" :loading="ocupado" :disabled="!motivo.trim()"
            >Anular medición</Boton
          >
          <Boton intent="primary" :disabled="ocupado" @click="anular = null">Cancelar</Boton>
        </div>
      </form>
    </CapaTarea>
    <ConfirmarCiclo
      :abierta="confirmar !== null"
      :tipo="confirmar ?? 'lista'"
      :uso="uso"
      :ocupado="ocupado"
      :error="errorAccion"
      @cerrar="confirmar = null"
      @confirmar="confirmado"
    />
  </div>
</template>

<style scoped>
.uso__cuerpo {
  padding: var(--sp-4) var(--sp-5) var(--sp-6);
  max-width: 1100px;
}
.uso__volver {
  margin: 0 0 var(--sp-2);
}
.uso__instantanea {
  margin: 0 0 var(--sp-3);
  padding: var(--sp-2) var(--sp-3);
  border: 1px dashed var(--muted);
  border-radius: var(--r-md);
  font-size: 0.9375rem;
}
.uso__aviso {
  margin: 0 0 var(--sp-3);
  padding: var(--sp-2) var(--sp-3);
  border-radius: var(--r-md);
  background: var(--ok-bg);
}
.uso__esqueleto {
  height: 200px;
  border-radius: var(--r-lg);
  background: var(--ink-100);
}
.uso__det {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: var(--sp-5);
}
@media (min-width: 1024px) {
  .uso__det {
    grid-template-columns: minmax(0, 2fr) minmax(0, 1fr);
  }
}
.uso__tina {
  margin: 0 0 var(--sp-3);
  font: 700 1.5rem/1.2 var(--font);
}
.uso__kpi {
  display: flex;
  flex-wrap: wrap;
  gap: var(--sp-2) var(--sp-5);
  margin: 0 0 var(--sp-3);
}
.uso__kpi b {
  display: block;
  font: 700 1.375rem/1.2 var(--font);
  font-variant-numeric: tabular-nums;
}
.uso__kpi span {
  font-size: 0.75rem;
  color: var(--muted);
}
.uso__sub {
  margin: 0 0 var(--sp-4);
  font-size: 0.875rem;
  color: var(--muted);
}
.uso__h3 {
  margin: var(--sp-3) 0 var(--sp-2);
  font: 700 1.0625rem/1.3 var(--font);
}
.uso__anulada td {
  color: var(--muted);
  text-decoration: line-through;
}
.uso__anulada td .uso__nota {
  text-decoration: none;
}
.uso__nota {
  display: block;
  font-size: 0.8125rem;
  color: var(--muted);
}
.uso__lado {
  display: grid;
  gap: var(--sp-3);
  align-content: start;
}
.uso__acciones {
  display: grid;
  gap: var(--sp-2);
}
.uso__acciones-fila {
  display: flex;
  flex-wrap: wrap;
  gap: var(--sp-2);
}
.uso__form {
  display: grid;
  gap: var(--sp-4);
}
.uso__texto {
  margin: 0;
}
.uso__error {
  margin: 0;
  padding: var(--sp-2) var(--sp-3);
  border: 2px solid var(--late);
  border-radius: var(--r-md);
  font-weight: 600;
}
.sr {
  position: absolute;
  width: 1px;
  height: 1px;
  overflow: hidden;
  clip: rect(0 0 0 0);
  white-space: nowrap;
}
</style>
