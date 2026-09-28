<script setup lang="ts">
import { computed, reactive } from "vue"
import { Boton, CampoNumero, CampoTexto, CampoCuando, Selector } from "../../../shared/ui"
import { errorCaptura, kilos, type DatosMH, type Recepcion } from "../modelo"
const props = defineProps<{ datos: DatosMH; bloqueado: boolean; ocupado: boolean; error: string }>()
const emit = defineEmits<{ guardar: [Recepcion]; cancelar: [] }>()
const f = reactive({
  kg: null as number | null,
  pinas: null as number | null,
  especie: "",
  predio: "",
  proveedor: "",
  nota: "",
  folio: "",
  fecha: null as string | null,
})
const idem = crypto.randomUUID()
const captura = computed<Recepcion>(() => ({ ...f, kg: f.kg ?? 0, tipo: "recepcion", idem }))
const invalido = computed(() => errorCaptura(captura.value))
const opciones = (lista: DatosMH["especies"]) => [
  { valor: "", etiqueta: "Sin especificar" },
  ...lista.map((o) => ({ valor: o.id, etiqueta: o.nombre })),
]
function guardar() {
  if (!invalido.value && !props.bloqueado && !props.ocupado) emit("guardar", captura.value)
}
</script>
<template>
  <form class="mh-form" @submit.prevent="guardar">
    <fieldset :disabled="ocupado">
      <legend>Lo que llegó</legend>
      <CampoNumero
        v-model="f.kg"
        etiqueta="Kilos (obligatorio)"
        unidad="kg"
        :min="0.001"
        required
      />
      <details class="mh-details">
        <summary>Detalles opcionales</summary>
        <div class="mh-fields">
          <CampoNumero
            v-model="f.pinas"
            etiqueta="Piñas (opcional)"
            :decimales="false"
            :min="0"
            :error="
              f.pinas !== null && (!Number.isInteger(f.pinas) || f.pinas < 0)
                ? 'Usa un entero no negativo.'
                : undefined
            "
          />
          <Selector
            v-model="f.especie"
            etiqueta="Especie (opcional)"
            :opciones="opciones(datos.especies)"
          />
          <Selector
            v-model="f.predio"
            etiqueta="Predio (opcional)"
            :opciones="opciones(datos.predios)"
          />
          <Selector
            v-model="f.proveedor"
            etiqueta="Proveedor (opcional)"
            :opciones="opciones(datos.proveedores)"
          />
          <CampoTexto v-model="f.nota" etiqueta="Nota de calidad (opcional)" />
        </div>
      </details>
    </fieldset>
    <fieldset :disabled="ocupado">
      <legend>Cuándo y folio</legend>
      <div class="mh-fields">
        <CampoCuando v-model="f.fecha" /><CampoTexto
          v-model="f.folio"
          etiqueta="Folio (opcional)"
          placeholder="Automático"
        />
      </div>
    </fieldset>
    <p v-if="error" role="alert" class="mh-error">
      {{ error }} Lo capturado se conserva; puedes reintentar.
    </p>
    <div class="mh-actions">
      <Boton
        type="submit"
        intent="primary"
        :loading="ocupado"
        :disabled="bloqueado || !!invalido"
        >{{ f.kg ? kilos(f.kg) + " · Registrar recepción" : "Registrar recepción" }}</Boton
      ><Boton :disabled="ocupado" @click="emit('cancelar')">Volver sin borrar</Boton>
    </div>
  </form>
</template>
