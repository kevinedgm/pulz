<script setup lang="ts">
import { ref, watch } from "vue"
import { Boton, CampoCuando, CampoTexto, CapaTarea } from "../../../shared/ui"
import { litros, type Corrida } from "../api"

// Cerrar corrida: irreversible (no se reabre). Muestra cargado vs. cortado;
// la diferencia (vinazas, pérdida) no queda como lote. Destructiva con
// forma distinta y Cancelar como primaria.
const props = defineProps<{
  abierta: boolean
  corrida: Corrida | null
  ocupado: boolean
  error: string | null
}>()
const emit = defineEmits<{ cerrar: []; confirmar: [nota: string | null, cuando: string | null] }>()
const nota = ref("")
const cuando = ref<string | null>(null)
watch(
  () => props.abierta,
  (a) => {
    if (a) {
      nota.value = ""
      cuando.value = null
    }
  },
)
</script>

<template>
  <CapaTarea
    :abierta="abierta"
    :titulo="`¿Cerrar la corrida ${corrida?.folio ?? ''}?`"
    etiqueta-cerrar="Cancelar"
    @cerrar="emit('cerrar')"
  >
    <form class="cierre" @submit.prevent="emit('confirmar', nota || null, cuando)">
      <p v-if="corrida" class="cierre__texto">
        Cargó <b>{{ litros(corrida.litros_cargados) }}</b> y se cortaron
        <b>{{ litros(corrida.litros_cortados) }}</b
        >. La diferencia (vinazas, pérdida) no queda como lote. No se puede reabrir.
      </p>
      <CampoCuando v-model="cuando" :disabled="ocupado" />
      <CampoTexto
        v-model="nota"
        etiqueta="Nota (opcional)"
        autocapitalize="sentences"
        :disabled="ocupado"
      />
      <p v-if="error" class="cierre__error" role="alert">{{ error }}</p>
      <div class="cierre__acciones">
        <Boton intent="danger" type="submit" :loading="ocupado">Cerrar corrida</Boton>
        <Boton intent="primary" :disabled="ocupado" @click="emit('cerrar')">Cancelar</Boton>
      </div>
    </form>
  </CapaTarea>
</template>

<style scoped>
.cierre {
  display: grid;
  gap: var(--sp-4);
}
.cierre__texto {
  margin: 0;
}
.cierre__error {
  margin: 0;
  padding: var(--sp-2) var(--sp-3);
  border: 2px solid var(--late);
  border-radius: var(--r-md);
  font-weight: 600;
}
.cierre__acciones {
  display: flex;
  flex-wrap: wrap;
  gap: var(--sp-2);
}
</style>
