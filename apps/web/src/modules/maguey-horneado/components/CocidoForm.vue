<script setup lang="ts">
import { computed } from "vue"
import { Boton, CampoNumero, CampoTexto, CampoCuando } from "../../../shared/ui"
import {
  errorCaptura,
  kilos,
  type Cierre,
  type EntradaCocido,
  type Horneada,
  type BorradorCocido,
} from "../modelo"
const props = defineProps<{
  horneada?: Horneada
  bloqueado: boolean
  ocupado: boolean
  error: string
}>()
const emit = defineEmits<{ guardar: [Cierre | EntradaCocido]; cancelar: [] }>()
const f = defineModel<BorradorCocido>({ required: true })
const captura = computed<Cierre | EntradaCocido>(() =>
  props.horneada
    ? { ...f.value, kg: f.value.kg ?? 0, tipo: "cerrar", horneada: props.horneada.id }
    : { ...f.value, kg: f.value.kg ?? 0, tipo: "cocido" },
)
const invalido = computed(() => errorCaptura(captura.value))
const anterior = computed(
  () =>
    props.horneada &&
    f.value.fecha &&
    Date.parse(f.value.fecha) < Date.parse(props.horneada.inicio),
)
function guardar() {
  if (!invalido.value && !props.bloqueado && !props.ocupado) emit("guardar", captura.value)
}
</script>
<template>
  <form class="mh-form" @submit.prevent="guardar">
    <p v-if="horneada">
      Cargó <b>{{ kilos(horneada.cargados) }}</b> ({{ horneada.origenes }}). Se registra el agave
      cocido y sus lotes de origen. No se reabre.
    </p>
    <p v-else>Cocido que ya tenías: se registra como carga inicial sin historia.</p>
    <fieldset :disabled="ocupado">
      <legend>Agave cocido</legend>
      <CampoNumero v-model="f.kg" etiqueta="Kilos cocidos" unidad="kg" :min="0.001" required />
      <p v-if="horneada && f.kg !== null">Diferencia: {{ kilos(horneada.cargados - f.kg) }}.</p>
      <CampoTexto v-if="horneada" v-model="f.combustible" etiqueta="Combustible (opcional)" />
      <CampoCuando v-model="f.fecha" etiqueta="¿Cuándo terminó?" />
      <p v-if="anterior" role="status">
        La fecha precede al inicio de la horneada. Revisa el dato antes de registrar.
      </p>
      <CampoTexto
        v-model="f.folio"
        etiqueta="Folio del cocido (opcional)"
        placeholder="Automático"
      />
      <CampoTexto v-model="f.nota" etiqueta="Nota (opcional)" />
    </fieldset>
    <p v-if="error" role="alert" class="mh-error">
      {{ error }} El borrador se conserva; puedes reintentar.
    </p>
    <div class="mh-actions">
      <Boton type="submit" intent="primary" :loading="ocupado" :disabled="bloqueado || !!invalido"
        >{{ horneada ? "Cerrar con" : "Registrar" }} {{ kilos(f.kg ?? 0) }} de cocido</Boton
      ><Boton :disabled="ocupado" @click="emit('cancelar')">Cancelar</Boton>
    </div>
  </form>
</template>
