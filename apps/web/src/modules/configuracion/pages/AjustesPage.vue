<script setup lang="ts">
import { computed, onMounted, ref } from "vue"
import { onBeforeRouteLeave } from "vue-router"
import { BloqueEstado, Boton, CampoNumero, Interruptor, SegmentoOpciones } from "../../../shared/ui"
import { useAcceso } from "../../acceso/store"
import { ajustes as cargarAjustes, guardarAjustes, type Ajustes } from "../api"
import SoloAdmin from "../components/SoloAdmin.vue"

// Ajustes (organization_settings; ronda configuracion/r01). Los 10 campos en
// tres grupos, en lenguaje del palenque. Validación al salir (mín < máx,
// hora 0–23); una primaria "Guardar ajustes"; salir con cambios pregunta.
const acceso = useAcceso()
const org = computed(() => acceso.membresiaActual?.organization_id ?? "")
const original = ref<Ajustes | null>(null)
const f = ref<Omit<Ajustes, "organization_id"> | null>(null)
const errorCarga = ref<string | null>(null)
const errorGuardar = ref<string | null>(null)
const ocupado = ref(false)
const guardado = ref(false)

const OPC_MODO = [
  { valor: "minimo" as const, etiqueta: "Mínimo", ayuda: "Actividad y temperatura." },
  {
    valor: "completo" as const,
    etiqueta: "Completo",
    ayuda: "Además Brix, dulzor y acidez por zona.",
  },
]
const OPC_FOLIO = [
  {
    valor: "conservar" as const,
    etiqueta: "Se conserva",
    ayuda: "El lote sigue con su folio al moverse.",
  },
  {
    valor: "renombrar" as const,
    etiqueta: "Se renombra",
    ayuda: "Cada movimiento puede dar folio nuevo.",
  },
]
const errores = computed(() => {
  const a = f.value
  if (!a) return {}
  return {
    hora:
      a.measurement_reminder_hour < 0 || a.measurement_reminder_hour > 23
        ? "Entre 0 y 23."
        : undefined,
    dias: a.fermentation_expected_days < 1 ? "Al menos 1 día." : undefined,
    brix:
      a.brix_warn_min >= a.brix_warn_max ? "El mínimo debe ser menor que el máximo." : undefined,
    abv: a.abv_warn_min >= a.abv_warn_max ? "El mínimo debe ser menor que el máximo." : undefined,
  }
})
const valido = computed(() => f.value !== null && Object.values(errores.value).every((e) => !e))
const cambiado = computed(
  () =>
    original.value !== null &&
    f.value !== null &&
    JSON.stringify({ ...original.value, organization_id: undefined }) !==
      JSON.stringify({ ...f.value, organization_id: undefined }),
)

async function cargar() {
  errorCarga.value = null
  try {
    const a = await cargarAjustes(org.value)
    original.value = a
    const { organization_id: _o, ...resto } = a
    void _o
    f.value = { ...resto }
  } catch (e) {
    errorCarga.value = (e as Error).message
  }
}
onMounted(() => {
  if (acceso.esAdmin) cargar()
})
async function guardar() {
  if (!valido.value || ocupado.value || !f.value) return
  ocupado.value = true
  errorGuardar.value = null
  guardado.value = false
  try {
    await guardarAjustes(org.value, f.value)
    original.value = { organization_id: org.value, ...f.value }
    guardado.value = true
  } catch (e) {
    errorGuardar.value = (e as Error).message
  } finally {
    ocupado.value = false
  }
}
onBeforeRouteLeave(() =>
  cambiado.value && !confirm("Tienes cambios sin guardar. ¿Salir de todos modos?") ? false : true,
)
const num = (v: number | null, actual: number) => (v === null ? actual : v)
</script>

<template>
  <SoloAdmin v-slot="{ puedeEscribir }" seccion="Ajustes">
    <div v-if="!f && !errorCarga" class="aj__esqueleto" aria-busy="true">
      <div v-for="n in 3" :key="n" class="aj__bloque"></div>
    </div>
    <BloqueEstado
      v-else-if="errorCarga"
      variante="error"
      titulo="No pudimos cargar los ajustes"
      :texto="errorCarga"
    >
      <Boton intent="secondary" @click="cargar">Reintentar</Boton>
    </BloqueEstado>
    <form v-else-if="f" id="form-ajustes" class="aj__form" novalidate @submit.prevent="guardar">
      <fieldset class="aj__grupo">
        <legend>Mediciones</legend>
        <SegmentoOpciones
          v-model="f.measurement_mode"
          etiqueta="Modo de medición"
          :opciones="OPC_MODO"
        />
        <div class="aj__fila">
          <CampoNumero
            :model-value="f.measurement_reminder_hour"
            etiqueta="Hora del recordatorio"
            :decimales="false"
            :min="0"
            :max="23"
            ayuda="0 a 23. El recordatorio de medir llega en Fase 5."
            :error="errores.hora"
            @update:model-value="
              f.measurement_reminder_hour = num($event, f.measurement_reminder_hour)
            "
          />
          <CampoNumero
            :model-value="f.fermentation_expected_days"
            etiqueta="Días esperados de fermentación"
            :decimales="false"
            :min="1"
            ayuda="Solo referencia visual."
            :error="errores.dias"
            @update:model-value="
              f.fermentation_expected_days = num($event, f.fermentation_expected_days)
            "
          />
        </div>
        <div class="aj__fila">
          <CampoNumero
            :model-value="f.brix_warn_min"
            etiqueta="Brix inicial habitual · mínimo"
            :error="errores.brix"
            @update:model-value="f.brix_warn_min = num($event, f.brix_warn_min)"
          />
          <CampoNumero
            :model-value="f.brix_warn_max"
            etiqueta="· máximo"
            @update:model-value="f.brix_warn_max = num($event, f.brix_warn_max)"
          />
        </div>
      </fieldset>
      <fieldset class="aj__grupo">
        <legend>Destilación y granel</legend>
        <Interruptor
          v-model="f.record_puntas"
          etiqueta="¿Capturan puntas?"
          ayuda="Casi nadie (menos de 300 mL); si no, no se pregunta."
        />
        <Interruptor
          v-model="f.warn_mixed_second_pass"
          etiqueta="Avisar si una segunda pasada mezcla ordinarios de distintas tinas"
          ayuda="Avisa y pide nota; nunca bloquea."
        />
        <div class="aj__fila">
          <CampoNumero
            :model-value="f.abv_warn_min"
            etiqueta="% Alc. habitual en granel · mínimo"
            unidad="%"
            :error="errores.abv"
            @update:model-value="f.abv_warn_min = num($event, f.abv_warn_min)"
          />
          <CampoNumero
            :model-value="f.abv_warn_max"
            etiqueta="· máximo"
            unidad="%"
            @update:model-value="f.abv_warn_max = num($event, f.abv_warn_max)"
          />
        </div>
      </fieldset>
      <fieldset class="aj__grupo">
        <legend>Folios</legend>
        <SegmentoOpciones
          v-model="f.default_folio_decision"
          etiqueta="Al transferir o mezclar, el folio…"
          :opciones="OPC_FOLIO"
        />
      </fieldset>
      <p v-if="errorGuardar" class="aj__rechazo" role="alert">{{ errorGuardar }}</p>
      <p v-else-if="guardado" class="aj__ok" role="status">Ajustes guardados.</p>
      <div class="aj__acciones">
        <Boton
          intent="primary"
          adapt="page-primary"
          type="submit"
          form="form-ajustes"
          :loading="ocupado"
          :disabled="!puedeEscribir || !cambiado"
          :motivo-deshabilitado="
            !puedeEscribir ? 'Para cambiar algo necesitas señal y suscripción vigente.' : undefined
          "
          >Guardar ajustes</Boton
        >
      </div>
    </form>
  </SoloAdmin>
</template>

<style scoped>
.aj__form {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: var(--sp-4);
  max-width: 640px;
}
.aj__grupo {
  display: grid;
  gap: var(--sp-4);
  margin: 0;
  padding: var(--sp-4);
  border: 1px solid var(--border);
  border-radius: var(--r-lg);
  background: var(--surface);
  min-width: 0;
}
.aj__grupo legend {
  padding: 0 var(--sp-2);
  font: 700 1.0625rem/1.2 var(--font);
}
.aj__fila {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: var(--sp-3);
}
@media (min-width: 600px) {
  .aj__fila {
    grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
  }
}
.aj__esqueleto {
  display: grid;
  gap: var(--sp-4);
  max-width: 640px;
}
.aj__bloque {
  height: 140px;
  border-radius: var(--r-lg);
  background: var(--ink-100);
}
.aj__acciones {
  display: flex;
}
.aj__rechazo {
  margin: 0;
  padding: var(--sp-3) var(--sp-4);
  border: 2px solid var(--late);
  border-radius: var(--r-md);
  background: var(--late-bg);
  font-weight: 600;
}
.aj__ok {
  margin: 0;
  padding: var(--sp-2) var(--sp-3);
  border-radius: var(--r-md);
  background: var(--ok-bg);
}
</style>
