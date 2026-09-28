<script setup lang="ts">
import { computed, ref, watch } from "vue"
import { ErrorAcceso } from "../../../shared/supabase/errores"
import { Boton, CampoCuando, CampoNumero, CapaTarea, Selector } from "../../../shared/ui"
import { ErrorFermentacion, litros, tinaQueYaFermentaba, type RecursoBreve } from "../api"

// Tina que ya fermentaba antes de usar PULZ (DUDAS #7): entrada 'fermentado'
// que abre un ciclo sin formulación. Tres campos; requiere señal.
const props = defineProps<{
  abierta: boolean
  org: string
  tinas: RecursoBreve[]
  enLinea: boolean
}>()
const emit = defineEmits<{ cerrar: []; guardado: [tina: string] }>()
const tina = ref("")
const lts = ref<number | null>(null)
const cuando = ref<string | null>(null)
const ocupado = ref(false)
const error = ref<string | null>(null)
watch(
  () => props.abierta,
  (a) => {
    if (a) {
      tina.value = props.tinas[0]?.id ?? ""
      lts.value = null
      cuando.value = null
      error.value = null
    }
  },
)
const opciones = computed(() =>
  props.tinas.map((t) => ({
    valor: t.id,
    etiqueta: t.capacity ? `${t.code} · ${litros(t.capacity)}` : t.code,
  })),
)
const elegida = computed(() => props.tinas.find((t) => t.id === tina.value))
const valido = computed(() => Boolean(tina.value) && (lts.value ?? 0) > 0)
async function guardar() {
  if (!valido.value || ocupado.value) return
  ocupado.value = true
  error.value = null
  try {
    await tinaQueYaFermentaba(props.org, tina.value, lts.value as number, cuando.value)
    emit("guardado", elegida.value?.code ?? "")
  } catch (e) {
    error.value = e instanceof ErrorFermentacion || e instanceof ErrorAcceso ? e.message : String(e)
  } finally {
    ocupado.value = false
  }
}
</script>

<template>
  <CapaTarea
    :abierta="abierta"
    titulo="Tina que ya fermentaba"
    etiqueta-cerrar="Cancelar"
    @cerrar="emit('cerrar')"
  >
    <form class="fermentaba" @submit.prevent="guardar">
      <p class="fermentaba__texto">
        Para una tina llena antes de usar PULZ: abre un ciclo <b>sin formulación</b>. Requiere
        señal.
      </p>
      <p v-if="tinas.length === 0" class="fermentaba__vacio">
        No hay tinas libres. Todas tienen un ciclo abierto o no hay tinas dadas de alta.
      </p>
      <template v-else>
        <Selector v-model="tina" etiqueta="Tina (libre)" :opciones="opciones" :disabled="ocupado" />
        <CampoNumero
          v-model="lts"
          etiqueta="Litros"
          unidad="L"
          :min="1"
          :disabled="ocupado"
          required
        />
        <CampoCuando v-model="cuando" :disabled="ocupado" />
        <p v-if="error" class="fermentaba__error" role="alert">{{ error }}</p>
        <div class="fermentaba__acciones">
          <Boton
            intent="primary"
            type="submit"
            :loading="ocupado"
            :disabled="!valido || !enLinea"
            :motivo-deshabilitado="!enLinea ? 'Necesitas señal para registrar.' : undefined"
            >Registrar {{ lts ? litros(lts) : "litros"
            }}<template v-if="elegida"> en {{ elegida.code }}</template></Boton
          >
          <Boton intent="secondary" :disabled="ocupado" @click="emit('cerrar')">Cancelar</Boton>
        </div>
      </template>
    </form>
  </CapaTarea>
</template>

<style scoped>
.fermentaba {
  display: grid;
  gap: var(--sp-4);
}
.fermentaba__texto,
.fermentaba__vacio {
  margin: 0;
}
.fermentaba__vacio {
  color: var(--muted);
}
.fermentaba__error {
  margin: 0;
  padding: var(--sp-2) var(--sp-3);
  border: 2px solid var(--late);
  border-radius: var(--r-md);
  font-weight: 600;
}
.fermentaba__acciones {
  display: flex;
  flex-wrap: wrap;
  gap: var(--sp-2);
}
</style>
