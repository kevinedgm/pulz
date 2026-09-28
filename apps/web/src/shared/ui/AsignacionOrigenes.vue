<script setup lang="ts">
import { computed } from "vue"
import CampoNumero from "./CampoNumero.vue"

// Contrato: registry "origin-allocation" (pattern, ronda destilacion/r01;
// extraída de la formulación). Lista de orígenes con saldo y un campo de
// cantidad por fila; total en vivo; opcional capacidad y política del
// destino → «Total N de C» y aviso local: estricta bloquea (la página
// deshabilita su primaria con `bloqueo`), flexible avisa (código
// excede_capacidad para soft-warning-note). Sin dominio: la página decide
// qué orígenes y qué destino.
export interface OrigenAsignable {
  id: string
  titulo: string
  sub?: string
  saldo?: number | null
  unidad: "L" | "kg"
  etiqueta?: string
}
const props = withDefaults(
  defineProps<{
    modelValue: Record<string, number | null>
    origenes: OrigenAsignable[]
    capacidad?: number | null
    politica?: "estricta" | "flexible" | "libre"
    destino?: string
    disabled?: boolean
  }>(),
  { capacidad: null, politica: "libre", disabled: false },
)
const emit = defineEmits<{ "update:modelValue": [Record<string, number | null>] }>()

const total = computed(() => props.origenes.reduce((a, o) => a + (props.modelValue[o.id] ?? 0), 0))
const unidad = computed(() => props.origenes[0]?.unidad ?? "L")
const errorDe = (o: OrigenAsignable) => {
  const v = props.modelValue[o.id]
  if (v === null || v === undefined) return undefined
  if (v < 0) return "No puede ser negativo."
  if (o.saldo !== null && o.saldo !== undefined && v > o.saldo)
    return `Solo hay ${fmt(o.saldo)} ${o.unidad}.`
  return undefined
}
const fmt = (n: number) => new Intl.NumberFormat("es-MX").format(n)
// Aviso local por capacidad del destino
const excede = computed(
  () => props.capacidad !== null && props.politica !== "libre" && total.value > props.capacidad,
)
const bloqueo = computed(() => excede.value && props.politica === "estricta")
const aviso = computed(() =>
  excede.value && props.politica === "flexible" ? "excede_capacidad" : null,
)
const conError = computed(() => props.origenes.some((o) => errorDe(o)))
defineExpose({ total, bloqueo, aviso, conError })

function fijar(id: string, v: number | null) {
  emit("update:modelValue", { ...props.modelValue, [id]: v })
}
</script>

<template>
  <div class="asig">
    <div v-for="o in origenes" :key="o.id" class="asig__fila">
      <div class="asig__quien">
        <b>{{ o.titulo }}</b>
        <span v-if="o.sub" class="asig__sub"> · {{ o.sub }}</span>
      </div>
      <CampoNumero
        :model-value="modelValue[o.id] ?? null"
        :etiqueta="o.etiqueta ?? (o.unidad === 'kg' ? 'Kilos' : 'Litros')"
        :unidad="o.unidad"
        :min="0"
        :max="o.saldo ?? undefined"
        :error="errorDe(o)"
        :disabled="disabled"
        @update:model-value="fijar(o.id, $event)"
      />
    </div>
    <p class="asig__total" :class="{ 'asig__total--bloqueo': bloqueo }" aria-live="polite">
      Total <b>{{ fmt(total) }} {{ unidad }}</b>
      <template v-if="capacidad !== null"> de {{ fmt(capacidad) }} {{ unidad }}</template>
      <template v-if="destino"> ({{ destino }})</template>
      <template v-if="bloqueo"> · <b>no cabe: la política es estricta</b></template>
    </p>
  </div>
</template>

<style scoped>
.asig {
  display: grid;
  gap: var(--sp-3);
}
.asig__fila {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: var(--sp-2);
  align-items: end;
  padding-bottom: var(--sp-3);
  border-bottom: 1px solid var(--border);
}
@media (min-width: 600px) {
  .asig__fila {
    grid-template-columns: minmax(0, 1.5fr) minmax(0, 1fr);
  }
}
.asig__quien {
  min-width: 0;
  overflow-wrap: anywhere;
}
.asig__sub {
  font-size: 0.875rem;
  color: var(--muted);
}
.asig__total {
  margin: 0;
  padding: var(--sp-2) var(--sp-3);
  border: 1px dashed var(--muted);
  border-radius: var(--r-md);
  font-size: 0.9375rem;
}
.asig__total--bloqueo {
  border: 2px solid var(--late);
}
</style>
