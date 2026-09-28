<script setup lang="ts">
import { computed, ref, watch } from "vue"
import { Boton, CampoCuando, CampoTexto, CapaTarea } from "../../../shared/ui"
import { litros, type UsoTina } from "../api"

// Declarar lista (reversible en la práctica) y cerrar ciclo (irreversible:
// libera la tina, termina el lote). La destructiva va con forma distinta y
// Cancelar es la primaria (§ riesgo por acción, ronda fermentacion/r01).
const props = defineProps<{
  abierta: boolean
  tipo: "lista" | "cerrar"
  uso: UsoTina | null
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
const titulo = computed(() =>
  props.tipo === "lista"
    ? `¿Declarar lista la ${props.uso?.tina ?? "tina"}?`
    : `¿Cerrar el ciclo de la ${props.uso?.tina ?? "tina"}?`,
)
</script>

<template>
  <CapaTarea
    :abierta="abierta"
    :titulo="titulo"
    etiqueta-cerrar="Cancelar"
    @cerrar="emit('cerrar')"
  >
    <form class="confirmar" @submit.prevent="emit('confirmar', nota || null, cuando)">
      <p v-if="tipo === 'lista'" class="confirmar__texto">
        La tina pasa a <b>lista</b> para destilar. Se puede seguir midiendo.
      </p>
      <p v-else class="confirmar__texto">
        La <b>{{ uso?.tina }}</b> queda <b>libre</b> y el lote {{ uso?.folio }} termina con lo que
        quede<template v-if="uso"> ({{ litros(uso.litros) }})</template>. No se puede deshacer.
      </p>
      <CampoCuando v-model="cuando" :disabled="ocupado" />
      <CampoTexto
        v-model="nota"
        etiqueta="Nota (opcional)"
        autocapitalize="sentences"
        :disabled="ocupado"
      />
      <p v-if="error" class="confirmar__error" role="alert">{{ error }}</p>
      <div class="confirmar__acciones">
        <template v-if="tipo === 'lista'">
          <Boton intent="primary" type="submit" :loading="ocupado">Declarar lista</Boton>
          <Boton intent="secondary" :disabled="ocupado" @click="emit('cerrar')">Cancelar</Boton>
        </template>
        <template v-else>
          <Boton intent="danger" type="submit" :loading="ocupado">Cerrar ciclo</Boton>
          <Boton intent="primary" :disabled="ocupado" @click="emit('cerrar')">Cancelar</Boton>
        </template>
      </div>
    </form>
  </CapaTarea>
</template>

<style scoped>
.confirmar {
  display: grid;
  gap: var(--sp-4);
}
.confirmar__texto {
  margin: 0;
}
.confirmar__error {
  margin: 0;
  padding: var(--sp-2) var(--sp-3);
  border: 2px solid var(--late);
  border-radius: var(--r-md);
  font-weight: 600;
}
.confirmar__acciones {
  display: flex;
  flex-wrap: wrap;
  gap: var(--sp-2);
}
</style>
