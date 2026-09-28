<script setup lang="ts">
import { computed, onMounted, ref } from "vue"
import { useRoute, useRouter } from "vue-router"
import { useFab } from "../../../app/fab"
import { useCola } from "../../../shared/offline/useCola"
import { haceCuanto } from "../../../shared/offline/instantanea"
import { ErrorAcceso } from "../../../shared/supabase/errores"
import { BloqueEstado, Boton } from "../../../shared/ui"
import { useConexion } from "../../../shared/utils/conexion"
import { useAcceso } from "../../acceso/store"
import {
  agrupar,
  cargarUsos,
  cerrarCiclo,
  declararLista,
  diaDelCiclo,
  ErrorFermentacion,
  recursosDe,
  tinasLibres,
  type DatosFermentacion,
  type RecursoBreve,
  type UsoTina,
} from "../api"
import ConfirmarCiclo from "../components/ConfirmarCiclo.vue"
import FilaUso from "../components/FilaUso.vue"
import TinaFermentabaCapa from "../components/TinaFermentabaCapa.vue"

// Usos de tinas (§13.1: usos, no tinas; ronda fermentacion/r01, congelada):
// agrupados por lo que hay que hacer hoy. Una primaria: Medir (FAB en
// compact vía app/fab.ts; botón en la cabecera en ≥600) → la primera por
// medir. Sin señal, la lista viene de la instantánea.
const acceso = useAcceso()
const route = useRoute()
const router = useRouter()
const { enLinea } = useConexion()
const cola = useCola()
const org = computed(() => acceso.membresiaActual?.organization_id ?? "")
const slug = computed(() => String(route.params.slug))
const rol = computed(() => acceso.membresiaActual?.role)
const puedeGestionar = computed(
  () => (rol.value === "admin" || rol.value === "productor") && !acceso.modoLectura,
)
const puedeMedir = computed(() => !acceso.modoLectura)

const datos = ref<DatosFermentacion | null>(null)
const instantanea = ref<string | null>(null)
const errorCarga = ref<string | null>(null)
const aviso = ref<string | null>(
  route.query.aviso === "formulacion"
    ? "Formulación registrada: las tinas ya aparecen aquí."
    : route.query.aviso === "medida"
      ? "Medición guardada."
      : null,
)
const hoy = new Date()
const grupos = computed(() => agrupar(datos.value?.usos ?? [], hoy))
const esperados = computed(() => datos.value?.ajustes.fermentation_expected_days ?? 7)
const dia = (u: UsoTina) => diaDelCiclo(u.started_at, hoy)
const tieneTinas = ref<boolean | null>(null)
const libres = ref<RecursoBreve[]>([])

// Capturas en cola por ciclo (pendiente / fallo con motivo)
const enCola = computed(() => {
  const m: Record<string, { pendiente: boolean; fallo: string | null; id: string }> = {}
  for (const e of cola.elementos.value) {
    if (e.rpc !== "registrar_medicion") continue
    const c = String(e.params.p_ciclo)
    m[c] = {
      pendiente: e.estado !== "fallo",
      fallo: e.estado === "fallo" ? (e.error ?? "falló") : null,
      id: e.id,
    }
  }
  return m
})

async function cargar() {
  errorCarga.value = null
  try {
    const r = await cargarUsos(org.value)
    datos.value = r.datos
    instantanea.value = r.instantanea
    if (r.datos.usos.length === 0 && !r.instantanea) {
      const tinas = await recursosDe(org.value, "tina").catch(() => null)
      tieneTinas.value = tinas ? tinas.length > 0 : null
    }
  } catch (e) {
    errorCarga.value = e instanceof Error ? e.message : String(e)
  }
}
onMounted(cargar)

const primera = computed(() => grupos.value.porMedir[0] ?? null)
const irAMedir = (u: UsoTina | null = primera.value) => {
  if (u) router.push(`/e/${slug.value}/fermentacion/${u.cycle_id}/medir`)
}
useFab(() => irAMedir())

// Declarar lista / cerrar ciclo (requieren señal; admin y productor)
const confirmar = ref<{ tipo: "lista" | "cerrar"; uso: UsoTina } | null>(null)
const ocupado = ref(false)
const errorConfirmar = ref<string | null>(null)
async function confirmado(nota: string | null, cuando: string | null) {
  if (!confirmar.value) return
  ocupado.value = true
  errorConfirmar.value = null
  const { tipo, uso } = confirmar.value
  try {
    if (tipo === "lista") await declararLista(org.value, uso.cycle_id, nota, cuando)
    else await cerrarCiclo(org.value, uso.cycle_id, nota, cuando)
    aviso.value =
      tipo === "lista"
        ? `${uso.tina} declarada lista.`
        : `${uso.tina} quedó libre; ${uso.folio} terminó.`
    confirmar.value = null
    await cargar()
  } catch (e) {
    errorConfirmar.value =
      e instanceof ErrorFermentacion || e instanceof ErrorAcceso ? e.message : String(e)
  } finally {
    ocupado.value = false
  }
}
const capaFermentaba = ref(false)
async function abrirFermentaba() {
  libres.value = await tinasLibres(org.value, datos.value?.usos ?? []).catch(() => [])
  capaFermentaba.value = true
}
async function fermentabaGuardada(tina: string) {
  capaFermentaba.value = false
  aviso.value = `${tina} registrada: ya aparece en uso.`
  await cargar()
}
function corregir(cycleId: string) {
  const e = enCola.value[cycleId]
  if (e) router.push(`/e/${slug.value}/fermentacion/${cycleId}/medir?corregir=${e.id}`)
}
</script>

<template>
  <div class="fer">
    <div class="fer__cuerpo">
      <div class="fer__arriba">
        <p v-if="datos" class="fer__resumen" role="status">
          {{ datos.usos.length }} tina{{ datos.usos.length === 1 ? "" : "s" }} en uso ·
          <b>{{ grupos.porMedir.length }} por medir hoy</b>
        </p>
        <!-- La raíz de Boton es un fragmento: el estilo scoped no lo alcanza; se envuelve -->
        <div v-if="primera && puedeMedir" class="fer__medir">
          <Boton intent="primary" :to="`/e/${slug}/fermentacion/${primera.cycle_id}/medir`"
            >Medir</Boton
          >
        </div>
      </div>
      <p v-if="instantanea" class="fer__instantanea">
        Datos de <b>{{ haceCuanto(instantanea) }}</b> (última vez con señal). Puedes medir: se
        guarda en el teléfono y se envía al reconectar.
      </p>
      <p v-if="aviso" class="fer__aviso" role="status">{{ aviso }}</p>

      <div v-if="!datos && !errorCarga" class="fer__esqueleto" aria-busy="true">
        <div v-for="n in 3" :key="n"></div>
      </div>
      <BloqueEstado
        v-else-if="errorCarga"
        variante="error"
        titulo="No pudimos cargar las tinas"
        :texto="errorCarga"
      >
        <Boton intent="secondary" @click="cargar">Reintentar</Boton>
      </BloqueEstado>
      <template v-else-if="datos && datos.usos.length === 0">
        <BloqueEstado
          v-if="tieneTinas === false"
          variante="empty"
          titulo="Tu palenque aún no tiene tinas"
          texto="Agrégalas en Configuración → Recursos y después llénalas desde aquí."
        >
          <Boton v-if="acceso.esAdmin" intent="secondary" :to="`/e/${slug}/configuracion/recursos`"
            >Ir a Recursos</Boton
          >
        </BloqueEstado>
        <BloqueEstado
          v-else
          variante="empty"
          titulo="No hay tinas en uso"
          texto="Cuando llenes una tina, aquí verás qué toca medir cada día."
        >
          <Boton
            v-if="puedeGestionar"
            intent="primary"
            :to="`/e/${slug}/fermentacion/formular`"
            :disabled="!enLinea"
            :motivo-deshabilitado="!enLinea ? 'Necesitas señal para formular.' : undefined"
            >Llenar tinas (formulación)</Boton
          >
          <Boton v-if="puedeGestionar" intent="quiet" :disabled="!enLinea" @click="abrirFermentaba"
            >Tina que ya fermentaba</Boton
          >
        </BloqueEstado>
      </template>
      <template v-else-if="datos">
        <div v-if="grupos.porMedir.length === 0" class="fer__hecho" role="status">
          <b>Hoy ya mediste todas.</b>
          <span>Mañana vuelven a aparecer aquí.</span>
        </div>
        <section v-if="grupos.porMedir.length" class="fer__grupo">
          <h2 class="fer__titulo">Toca medir hoy</h2>
          <ul class="fer__lista">
            <FilaUso
              v-for="u in grupos.porMedir"
              :key="u.cycle_id"
              :uso="u"
              :dia="dia(u)"
              :esperados="esperados"
              :slug="slug"
              :pendiente="enCola[u.cycle_id]?.pendiente"
              :fallo="enCola[u.cycle_id]?.fallo"
              :puede-medir="puedeMedir"
              :puede-gestionar="puedeGestionar && enLinea"
              @ver="router.push(`/e/${slug}/fermentacion/${u.cycle_id}`)"
              @lista="confirmar = { tipo: 'lista', uso: u }"
              @cerrar="confirmar = { tipo: 'cerrar', uso: u }"
              @corregir="corregir(u.cycle_id)"
            />
          </ul>
        </section>
        <section v-if="grupos.medidas.length" class="fer__grupo">
          <h2 class="fer__titulo">Ya medidas hoy</h2>
          <ul class="fer__lista">
            <FilaUso
              v-for="u in grupos.medidas"
              :key="u.cycle_id"
              :uso="u"
              :dia="dia(u)"
              :esperados="esperados"
              :slug="slug"
              :pendiente="enCola[u.cycle_id]?.pendiente"
              :fallo="enCola[u.cycle_id]?.fallo"
              :puede-medir="puedeMedir"
              :puede-gestionar="puedeGestionar && enLinea"
              @ver="router.push(`/e/${slug}/fermentacion/${u.cycle_id}`)"
              @lista="confirmar = { tipo: 'lista', uso: u }"
              @cerrar="confirmar = { tipo: 'cerrar', uso: u }"
              @corregir="corregir(u.cycle_id)"
            />
          </ul>
        </section>
        <section v-if="grupos.listas.length" class="fer__grupo">
          <h2 class="fer__titulo">Listas o en vaciado</h2>
          <ul class="fer__lista">
            <FilaUso
              v-for="u in grupos.listas"
              :key="u.cycle_id"
              :uso="u"
              :dia="dia(u)"
              :esperados="esperados"
              :slug="slug"
              :pendiente="enCola[u.cycle_id]?.pendiente"
              :fallo="enCola[u.cycle_id]?.fallo"
              :puede-medir="puedeMedir"
              :puede-gestionar="puedeGestionar && enLinea"
              @ver="router.push(`/e/${slug}/fermentacion/${u.cycle_id}`)"
              @lista="confirmar = { tipo: 'lista', uso: u }"
              @cerrar="confirmar = { tipo: 'cerrar', uso: u }"
              @corregir="corregir(u.cycle_id)"
            />
          </ul>
        </section>
        <div v-if="puedeGestionar" class="fer__pie">
          <Boton
            intent="secondary"
            :to="`/e/${slug}/fermentacion/formular`"
            :disabled="!enLinea"
            :motivo-deshabilitado="!enLinea ? 'Necesitas señal para formular.' : undefined"
            >Llenar tinas (formulación)</Boton
          >
          <Boton
            intent="secondary"
            :disabled="!enLinea"
            :motivo-deshabilitado="!enLinea ? 'Necesitas señal para registrar.' : undefined"
            @click="abrirFermentaba"
            >Tina que ya fermentaba</Boton
          >
        </div>
      </template>
    </div>

    <ConfirmarCiclo
      :abierta="confirmar !== null"
      :tipo="confirmar?.tipo ?? 'lista'"
      :uso="confirmar?.uso ?? null"
      :ocupado="ocupado"
      :error="errorConfirmar"
      @cerrar="confirmar = null"
      @confirmar="confirmado"
    />
    <TinaFermentabaCapa
      :abierta="capaFermentaba"
      :org="org"
      :tinas="libres"
      :en-linea="enLinea"
      @cerrar="capaFermentaba = false"
      @guardado="fermentabaGuardada"
    />
  </div>
</template>

<style scoped>
.fer__cuerpo {
  padding: var(--sp-5);
  max-width: 960px;
}
.fer__arriba {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--sp-3);
  margin: 0 0 var(--sp-3);
}
.fer__resumen {
  margin: 0;
  font-size: 0.875rem;
  color: var(--muted);
}
@media (max-width: 599px) {
  .fer__medir {
    display: none; /* en compact la primaria es el FAB del shell */
  }
}
.fer__instantanea {
  margin: 0 0 var(--sp-3);
  padding: var(--sp-2) var(--sp-3);
  border: 1px dashed var(--muted);
  border-radius: var(--r-md);
  font-size: 0.9375rem;
}
.fer__aviso {
  margin: 0 0 var(--sp-3);
  padding: var(--sp-2) var(--sp-3);
  border-radius: var(--r-md);
  background: var(--ok-bg);
}
.fer__esqueleto {
  display: grid;
  gap: var(--sp-2);
}
.fer__esqueleto > div {
  height: 72px;
  border-radius: var(--r-lg);
  background: var(--ink-100);
}
.fer__hecho {
  display: grid;
  gap: var(--sp-1);
  padding: var(--sp-4);
  border: 2px solid var(--ink-900);
  border-radius: var(--r-lg);
  margin: 0 0 var(--sp-3);
}
.fer__hecho span {
  font-size: 0.875rem;
  color: var(--muted);
}
.fer__grupo {
  margin: var(--sp-5) 0 0;
}
.fer__titulo {
  margin: 0 0 var(--sp-2);
  font: 600 0.75rem/1.2 var(--font);
  letter-spacing: 0.05em;
  text-transform: uppercase;
  color: var(--muted);
}
.fer__lista {
  list-style: none;
  margin: 0;
  padding: 0;
}
.fer__pie {
  display: flex;
  flex-wrap: wrap;
  gap: var(--sp-2);
  margin-top: var(--sp-5);
}
</style>
