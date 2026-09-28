<script setup lang="ts">
import { computed, onMounted, ref } from "vue"
import { useRoute, useRouter } from "vue-router"
import { ErrorAcceso } from "../../../shared/supabase/errores"
import {
  AsignacionOrigenes,
  AvisoNota,
  BloqueEstado,
  Boton,
  CampoCuando,
  CampoTexto,
  SegmentoOpciones,
  Selector,
  type OrigenAsignable,
} from "../../../shared/ui"
import { useConexion } from "../../../shared/utils/conexion"
import { useAcceso } from "../../acceso/store"
import {
  abrirCorrida,
  avisoCapacidad,
  avisosApertura,
  cargarDestilacion,
  ErrorDestilacion,
  litros,
  type Clase,
  type DatosDestilacion,
  type Pasada,
} from "../api"

// Abrir corrida (§4.5; ronda destilacion/r01): alambique, pasada y
// orígenes con litros (tinas con contenido —listas primero— y colectores
// con saldo). Capacidad estricta bloquea antes; flexible y mezcla en 2ª
// avisan antes con nota. Consume saldos: requiere señal.
const acceso = useAcceso()
const route = useRoute()
const router = useRouter()
const { enLinea } = useConexion()
const org = computed(() => acceso.membresiaActual?.organization_id ?? "")
const slug = computed(() => String(route.params.slug))

const datos = ref<DatosDestilacion | null>(null)
const errorCarga = ref<string | null>(null)
const alambique = ref("")
const pasada = ref<Pasada>("primera")
const litrosPor = ref<Record<string, number | null>>({})
const nota = ref("")
const folio = ref("")
const cuando = ref<string | null>(null)
const ocupado = ref(false)
const error = ref<string | null>(null)
const avisoServidor = ref<string | null>(null)

async function cargar() {
  errorCarga.value = null
  try {
    const r = await cargarDestilacion(org.value)
    datos.value = r.datos
    alambique.value = r.datos.alambiques[0]?.id ?? ""
  } catch (e) {
    errorCarga.value = e instanceof Error ? e.message : String(e)
  }
}
onMounted(cargar)

const alambiqueSel = computed(
  () => datos.value?.alambiques.find((a) => a.id === alambique.value) ?? null,
)
const opAlambiques = computed(() =>
  (datos.value?.alambiques ?? []).map((a) => ({
    valor: a.id,
    etiqueta: `${a.code}${a.capacity ? ` · ${litros(a.capacity)} · ${a.capacity_policy}` : ""}`,
  })),
)
// Orígenes: tinas con litros (listas primero) + colectores con saldo
const origenes = computed<
  (OrigenAsignable & { resource_id: string; lot_id: string; clase: Clase | null })[]
>(() => {
  const d = datos.value
  if (!d) return []
  const orden = { lista: 0, en_vaciado: 1, fermentando: 2, cerrado: 3 }
  const tinas = d.usos
    .filter((u) => u.litros > 0)
    .sort((a, b) => orden[a.status] - orden[b.status] || a.tina.localeCompare(b.tina, "es"))
    .map((u) => ({
      id: `t:${u.tina_id}:${u.lot_id}`,
      resource_id: u.tina_id,
      lot_id: u.lot_id,
      clase: null,
      titulo: u.tina,
      sub: `${u.folio} · ${litros(u.litros)} · ${u.status === "en_vaciado" ? "en vaciado" : u.status}`,
      saldo: u.litros,
      unidad: "L" as const,
    }))
  const colectores = d.colectores.map((c) => ({
    id: `c:${c.resource_id}:${c.lot_id}`,
    resource_id: c.resource_id,
    lot_id: c.lot_id,
    clase: c.liquid_class,
    titulo: c.colector,
    sub: `${c.folio} · ${litros(c.litros)}${c.abv !== null ? ` · ${c.abv} %` : ""}`,
    saldo: c.litros,
    unidad: "L" as const,
  }))
  return [...tinas, ...colectores]
})
const elegidos = computed(() => origenes.value.filter((o) => (litrosPor.value[o.id] ?? 0) > 0))
const total = computed(() => elegidos.value.reduce((a, o) => a + (litrosPor.value[o.id] ?? 0), 0))
const capacidad = computed(() =>
  alambiqueSel.value
    ? avisoCapacidad(
        0,
        total.value,
        alambiqueSel.value.capacity,
        alambiqueSel.value.capacity_policy,
      )
    : null,
)
const conError = computed(() =>
  elegidos.value.some((o) => (litrosPor.value[o.id] ?? 0) > (o.saldo ?? Infinity)),
)
const avisos = computed(() => {
  const a = datos.value
    ? avisosApertura(
        pasada.value,
        elegidos.value.map((o) => o.clase),
        datos.value.ajustes,
      )
    : []
  if (capacidad.value === "excede_capacidad") a.push("excede_capacidad")
  return a
})
const avisoCodigo = computed(() => avisoServidor.value ?? avisos.value[0] ?? null)
const motivo = computed(() => {
  if (!enLinea.value) return "Abrir una corrida necesita señal."
  if (!alambique.value) return "Elige el alambique."
  if (elegidos.value.length === 0) return "Indica de dónde sale la carga y cuántos litros."
  if (conError.value) return "Hay litros por encima del saldo."
  if (capacidad.value === "bloqueo")
    return `No cabe: ${alambiqueSel.value?.code} tiene política estricta.`
  if (avisoCodigo.value && !nota.value.trim()) return "Escribe la nota que pide el aviso."
  return undefined
})
async function abrir() {
  if (motivo.value || ocupado.value) return
  ocupado.value = true
  error.value = null
  try {
    const runId = await abrirCorrida(org.value, {
      alambique: alambique.value,
      pasada: pasada.value,
      origenes: elegidos.value.map((o) => ({
        resource_id: o.resource_id,
        lot_id: o.lot_id,
        litros: litrosPor.value[o.id] as number,
      })),
      nota: nota.value,
      folio: folio.value,
      occurred_at: cuando.value,
    })
    router.push(`/e/${slug.value}/destilacion/${runId}?aviso=abierta`)
  } catch (e) {
    if (e instanceof ErrorDestilacion && e.rpc.codigo === "NOTA")
      avisoServidor.value = e.rpc.requiereNota ?? "excede_capacidad"
    else
      error.value =
        e instanceof ErrorDestilacion || e instanceof ErrorAcceso ? e.message : String(e)
  } finally {
    ocupado.value = false
  }
}
</script>

<template>
  <div class="ab">
    <div class="ab__cuerpo">
      <p class="ab__volver">
        <Boton intent="quiet" :to="`/e/${slug}/destilacion`">‹ Destilación</Boton>
      </p>
      <BloqueEstado
        v-if="acceso.modoLectura"
        variante="denied"
        titulo="Solo lectura"
        texto="La suscripción venció: puedes consultar, no registrar."
      >
        <Boton intent="secondary" :to="`/e/${slug}/destilacion`">Volver</Boton>
      </BloqueEstado>
      <div v-else-if="!datos && !errorCarga" class="ab__esqueleto" aria-busy="true"></div>
      <BloqueEstado
        v-else-if="errorCarga"
        variante="error"
        titulo="No pudimos cargar los datos"
        :texto="errorCarga"
      >
        <Boton intent="secondary" @click="cargar">Reintentar</Boton>
      </BloqueEstado>
      <BloqueEstado
        v-else-if="datos && datos.alambiques.length === 0"
        variante="empty"
        titulo="Tu palenque aún no tiene alambiques"
        texto="Agrégalos en Configuración → Recursos."
      >
        <Boton v-if="acceso.esAdmin" intent="secondary" :to="`/e/${slug}/configuracion/recursos`"
          >Ir a Recursos</Boton
        >
      </BloqueEstado>
      <form v-else-if="datos" class="ab__form" @submit.prevent="abrir">
        <fieldset class="ab__grupo">
          <legend>Alambique y pasada</legend>
          <div class="ab__fila">
            <Selector
              v-model="alambique"
              etiqueta="Alambique"
              :opciones="opAlambiques"
              :disabled="ocupado"
            />
            <SegmentoOpciones
              v-model="pasada"
              etiqueta="Pasada"
              :opciones="[
                {
                  valor: 'primera',
                  etiqueta: '1ª pasada',
                  ayuda: 'Desde tinas: mezcal, ordinario y colas.',
                },
                {
                  valor: 'segunda',
                  etiqueta: '2ª pasada',
                  ayuda: 'Desde colectores de ordinario y colas.',
                },
              ]"
              :disabled="ocupado"
            />
          </div>
        </fieldset>
        <fieldset class="ab__grupo">
          <legend>Orígenes (con litros)</legend>
          <p v-if="origenes.length === 0" class="ab__vacio">
            No hay tinas con contenido ni colectores con saldo. Llena una tina (Fermentación) o
            espera cortes de ordinario y colas.
          </p>
          <AsignacionOrigenes
            v-else
            v-model="litrosPor"
            :origenes="origenes"
            :capacidad="alambiqueSel?.capacity ?? null"
            :politica="alambiqueSel?.capacity_policy ?? 'libre'"
            :destino="alambiqueSel?.code"
            :disabled="ocupado"
          />
          <p class="ab__nota">
            Listas primero; fermentando y en vaciado después (se puede cargar igual). La tina
            cargada pasa a «en vaciado».
          </p>
        </fieldset>
        <fieldset class="ab__grupo">
          <legend>Cuándo y folio</legend>
          <CampoCuando v-model="cuando" :disabled="ocupado" />
          <CampoTexto
            v-model="folio"
            etiqueta="Folio (opcional)"
            placeholder="automático (DES-…)"
            :disabled="ocupado"
          />
          <CampoTexto
            v-if="!avisoCodigo"
            v-model="nota"
            etiqueta="Nota (opcional)"
            autocapitalize="sentences"
            :disabled="ocupado"
          />
        </fieldset>
        <AvisoNota v-model="nota" :codigo="avisoCodigo" :disabled="ocupado" />
        <p v-if="error" class="ab__error" role="alert">{{ error }}</p>
        <div class="ab__acciones">
          <Boton
            intent="primary"
            adapt="page-primary"
            type="submit"
            :loading="ocupado"
            :disabled="Boolean(motivo)"
            :motivo-deshabilitado="motivo"
            >Abrir corrida<template v-if="total > 0"> con {{ litros(total) }}</template></Boton
          >
          <Boton intent="secondary" :to="`/e/${slug}/destilacion`" :disabled="ocupado"
            >Cancelar</Boton
          >
        </div>
      </form>
    </div>
  </div>
</template>

<style scoped>
.ab__cuerpo {
  padding: var(--sp-4) var(--sp-5) var(--sp-6);
  max-width: 760px;
}
.ab__volver {
  margin: 0 0 var(--sp-2);
}
.ab__esqueleto {
  height: 240px;
  border-radius: var(--r-lg);
  background: var(--ink-100);
}
.ab__form {
  display: grid;
  gap: var(--sp-4);
}
.ab__grupo {
  margin: 0;
  padding: var(--sp-3) var(--sp-4) var(--sp-4);
  border: 1px solid var(--border);
  border-radius: var(--r-lg);
  display: grid;
  gap: var(--sp-3);
  min-width: 0;
}
.ab__grupo legend {
  padding: 0 var(--sp-1);
  font-weight: 700;
}
.ab__fila {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: var(--sp-3);
}
@media (min-width: 600px) {
  .ab__fila {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}
.ab__vacio,
.ab__nota {
  margin: 0;
  font-size: 0.9375rem;
  color: var(--muted);
}
.ab__error {
  margin: 0;
  padding: var(--sp-2) var(--sp-3);
  border: 2px solid var(--late);
  border-radius: var(--r-md);
  font-weight: 600;
}
.ab__acciones {
  display: flex;
  flex-wrap: wrap;
  gap: var(--sp-2);
}
</style>
