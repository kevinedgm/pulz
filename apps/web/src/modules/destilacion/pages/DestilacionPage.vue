<script setup lang="ts">
import { computed, onMounted, ref } from "vue"
import { useRoute, useRouter } from "vue-router"
import { useFab } from "../../../app/fab"
import { descartar } from "../../../shared/offline/cola"
import { haceCuanto } from "../../../shared/offline/instantanea"
import { useCola } from "../../../shared/offline/useCola"
import { ErrorAcceso } from "../../../shared/supabase/errores"
import { BloqueEstado, Boton } from "../../../shared/ui"
import { useConexion } from "../../../shared/utils/conexion"
import { useAcceso } from "../../acceso/store"
import {
  cargarDestilacion,
  cerrarCorrida,
  ErrorDestilacion,
  type Corrida,
  type DatosDestilacion,
} from "../api"
import ConfirmarCierre from "../components/ConfirmarCierre.vue"
import FilaColector from "../components/FilaColector.vue"
import FilaCorrida from "../components/FilaCorrida.vue"

// Corridas (ronda destilacion/r01, congelada): abiertas, colectores con
// contenido y últimas cerradas. Una primaria: Abrir corrida (FAB en compact
// vía app/fab.ts; botón en cabecera en ≥600). «Registrar corte» por corrida
// es secundaria. Sin señal: instantánea; cortes sí, abrir/cerrar no.
const acceso = useAcceso()
const route = useRoute()
const router = useRouter()
const { enLinea } = useConexion()
const cola = useCola()
const org = computed(() => acceso.membresiaActual?.organization_id ?? "")
const slug = computed(() => String(route.params.slug))
const rol = computed(() => acceso.membresiaActual?.role)
const puedeEscribir = computed(() => !acceso.modoLectura)
const puedeTransferir = computed(
  () => (rol.value === "admin" || rol.value === "productor") && puedeEscribir.value,
)

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
const abiertas = computed(() => (datos.value?.corridas ?? []).filter((c) => c.status === "abierta"))
const cerradas = computed(() =>
  (datos.value?.corridas ?? []).filter((c) => c.status === "cerrada").slice(0, 10),
)

// Cortes en cola por corrida
const enCola = computed(() => {
  const m: Record<
    string,
    { pendientes: number; fallo: { id: string; texto: string; corregible: boolean } | null }
  > = {}
  for (const e of cola.elementos.value) {
    if (e.rpc !== "registrar_corte") continue
    const c = String(e.params.p_corrida)
    m[c] ??= { pendientes: 0, fallo: null }
    if (e.estado === "fallo")
      m[c].fallo = { id: e.id, texto: e.error ?? "falló", corregible: Boolean(e.requiereNota) }
    else m[c].pendientes += 1
  }
  return m
})

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
useFab(() => router.push(`/e/${slug.value}/destilacion/abrir`))

const cerrando = ref<Corrida | null>(null)
const ocupado = ref(false)
const errorCerrar = ref<string | null>(null)
async function cerrarConfirmado(nota: string | null, cuando: string | null) {
  if (!cerrando.value) return
  ocupado.value = true
  errorCerrar.value = null
  try {
    await cerrarCorrida(org.value, cerrando.value.run_id, nota, cuando)
    aviso.value = `${cerrando.value.folio} cerrada.`
    cerrando.value = null
    await cargar()
  } catch (e) {
    errorCerrar.value =
      e instanceof ErrorDestilacion || e instanceof ErrorAcceso ? e.message : String(e)
  } finally {
    ocupado.value = false
  }
}
async function descartarFallo(runId: string) {
  const f = enCola.value[runId]?.fallo
  if (!f) return
  await descartar(f.id)
  await cola.refrescar()
}
function corregir(runId: string) {
  const f = enCola.value[runId]?.fallo
  if (f) router.push(`/e/${slug.value}/destilacion/${runId}/corte?corregir=${f.id}`)
}
</script>

<template>
  <div class="des">
    <div class="des__cuerpo">
      <div class="des__arriba">
        <p v-if="datos" class="des__resumen" role="status">
          {{ abiertas.length }} corrida{{ abiertas.length === 1 ? "" : "s" }} abierta{{
            abiertas.length === 1 ? "" : "s"
          }}
          · {{ datos.colectores.length }} colector{{ datos.colectores.length === 1 ? "" : "es" }}
          con contenido
        </p>
        <!-- Boton es un fragmento: se envuelve para esconderlo en compact (ahí manda el FAB) -->
        <div v-if="datos && datos.alambiques.length && puedeEscribir" class="des__abrir">
          <Boton
            intent="primary"
            :to="`/e/${slug}/destilacion/abrir`"
            :disabled="!enLinea"
            :motivo-deshabilitado="!enLinea ? 'Abrir una corrida necesita señal.' : undefined"
            >Abrir corrida</Boton
          >
        </div>
      </div>
      <p v-if="instantanea" class="des__instantanea">
        Datos de <b>{{ haceCuanto(instantanea) }}</b
        >. Puedes registrar cortes: se guardan en el teléfono y se envían al reconectar. Abrir y
        cerrar corridas necesitan señal.
      </p>
      <p v-if="aviso" class="des__aviso" role="status">{{ aviso }}</p>

      <div v-if="!datos && !errorCarga" class="des__esqueleto" aria-busy="true">
        <div v-for="n in 3" :key="n"></div>
      </div>
      <BloqueEstado
        v-else-if="errorCarga"
        variante="error"
        titulo="No pudimos cargar las corridas"
        :texto="errorCarga"
      >
        <Boton intent="secondary" @click="cargar">Reintentar</Boton>
      </BloqueEstado>
      <BloqueEstado
        v-else-if="datos && datos.alambiques.length === 0"
        variante="empty"
        titulo="Tu palenque aún no tiene alambiques"
        texto="Agrégalos en Configuración → Recursos y después abre tu primera corrida."
      >
        <Boton v-if="acceso.esAdmin" intent="secondary" :to="`/e/${slug}/configuracion/recursos`"
          >Ir a Recursos</Boton
        >
      </BloqueEstado>
      <template v-else-if="datos">
        <BloqueEstado
          v-if="abiertas.length === 0"
          variante="empty"
          titulo="No hay corridas abiertas"
          texto="Cuando haya olla libre, abre una corrida con lo que haya en la tina o en los colectores."
        />
        <section v-else class="des__grupo">
          <h2 class="des__titulo">Corridas abiertas</h2>
          <ul class="des__lista">
            <FilaCorrida
              v-for="c in abiertas"
              :key="c.run_id"
              :corrida="c"
              :slug="slug"
              :pendientes="enCola[c.run_id]?.pendientes"
              :fallo="enCola[c.run_id]?.fallo"
              :puede-cortar="puedeEscribir"
              :puede-cerrar="puedeEscribir && enLinea"
              @ver="router.push(`/e/${slug}/destilacion/${c.run_id}`)"
              @cerrar="cerrando = c"
              @corregir="corregir(c.run_id)"
              @descartar="descartarFallo(c.run_id)"
            />
          </ul>
        </section>
        <section v-if="datos.colectores.length" class="des__grupo">
          <h2 class="des__titulo">Colectores con contenido</h2>
          <ul class="des__lista">
            <FilaColector
              v-for="c in datos.colectores"
              :key="c.resource_id + c.lot_id"
              :colector="c"
              :slug="slug"
              :puede-transferir="puedeTransferir"
            />
          </ul>
        </section>
        <section v-if="cerradas.length" class="des__grupo">
          <h2 class="des__titulo">Últimas corridas</h2>
          <ul class="des__lista">
            <FilaCorrida
              v-for="c in cerradas"
              :key="c.run_id"
              :corrida="c"
              :slug="slug"
              :puede-cortar="false"
              :puede-cerrar="false"
              @ver="router.push(`/e/${slug}/destilacion/${c.run_id}`)"
            />
          </ul>
        </section>
      </template>
    </div>
    <ConfirmarCierre
      :abierta="cerrando !== null"
      :corrida="cerrando"
      :ocupado="ocupado"
      :error="errorCerrar"
      @cerrar="cerrando = null"
      @confirmar="cerrarConfirmado"
    />
  </div>
</template>

<style scoped>
.des__cuerpo {
  padding: var(--sp-5);
  max-width: 960px;
}
.des__arriba {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--sp-3);
  margin: 0 0 var(--sp-3);
}
.des__resumen {
  margin: 0;
  font-size: 0.875rem;
  color: var(--muted);
}
@media (max-width: 599px) {
  .des__abrir {
    display: none;
  }
}
.des__instantanea {
  margin: 0 0 var(--sp-3);
  padding: var(--sp-2) var(--sp-3);
  border: 1px dashed var(--muted);
  border-radius: var(--r-md);
  font-size: 0.9375rem;
}
.des__aviso {
  margin: 0 0 var(--sp-3);
  padding: var(--sp-2) var(--sp-3);
  border-radius: var(--r-md);
  background: var(--ok-bg);
}
.des__esqueleto {
  display: grid;
  gap: var(--sp-2);
}
.des__esqueleto > div {
  height: 72px;
  border-radius: var(--r-lg);
  background: var(--ink-100);
}
.des__grupo {
  margin: var(--sp-5) 0 0;
}
.des__titulo {
  margin: 0 0 var(--sp-2);
  font: 600 0.75rem/1.2 var(--font);
  letter-spacing: 0.05em;
  text-transform: uppercase;
  color: var(--muted);
}
.des__lista {
  list-style: none;
  margin: 0;
  padding: 0;
}
</style>
