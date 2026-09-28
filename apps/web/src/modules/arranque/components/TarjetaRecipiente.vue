<script setup lang="ts">
import { computed, ref } from "vue"
import { Boton, CampoNumero, ChipEstado, SegmentoOpciones } from "../../../shared/ui"
import type { Recurso, RecursoEnUso } from "../../configuracion/api"
import { esRecipiente, type KindRecipiente } from "../api"

// Tarjeta de un recipiente (ronda arranque/r01, congelada): decide "vacío"
// o "tiene algo" (litros + % Alc. en tanque/colector), guarda sola con su
// idempotency_key y se colapsa. Guardar es irreversible aquí: el botón dice
// exactamente qué hará.
const props = defineProps<{
  recurso: Recurso
  tipoNombre: string
  uso?: RecursoEnUso
  vacio: boolean
  puedeEscribir: boolean
  enLinea: boolean
  ocupado: boolean
  error?: string | null
}>()
const emit = defineEmits<{ guardar: [litros: number, abv: number | null]; vacio: [boolean] }>()

const kind = computed<KindRecipiente>(() =>
  esRecipiente(props.recurso.kind) ? props.recurso.kind : "tanque",
)
const guardado = computed(
  () => !!props.uso && (props.uso.saldo_l > 0 || props.uso.ciclos_abiertos > 0),
)
const decision = ref<"" | "vacio" | "algo">("")
const litros = ref<number | null>(null)
const abv = ref<number | null>(null)
const tocado = ref(false)
const pideAbv = computed(() => kind.value !== "tina")
const OPC = [
  { valor: "vacio", etiqueta: "Vacío" },
  { valor: "algo", etiqueta: "Tiene algo" },
]
const fmt = (n: number) => new Intl.NumberFormat("es-MX").format(n)
const errorLitros = computed(() =>
  tocado.value && (litros.value === null || litros.value <= 0)
    ? "Pon los litros que hay."
    : undefined,
)
const errorAbv = computed(() =>
  abv.value !== null && (abv.value < 0 || abv.value > 100) ? "Entre 0 y 100." : undefined,
)
const avisoCapacidad = computed(() =>
  litros.value !== null && props.recurso.capacity !== null && litros.value > props.recurso.capacity
    ? props.recurso.capacity_policy === "estricta"
      ? `Son más litros que la capacidad (${fmt(props.recurso.capacity)} L) y la política es estricta: no se va a poder guardar.`
      : props.recurso.capacity_policy === "flexible"
        ? `Son más litros que la capacidad (${fmt(props.recurso.capacity)} L). Con política flexible se guarda y queda un aviso.`
        : null
    : null,
)
const valido = computed(() => litros.value !== null && litros.value > 0 && !errorAbv.value)
const subtitulo = computed(() => {
  const r = props.recurso
  return [
    kind.value,
    props.tipoNombre !== "—" ? props.tipoNombre : "",
    r.capacity !== null ? `${fmt(r.capacity)} L` : "",
    r.liquid_class ? `clase ${r.liquid_class}` : "",
  ]
    .filter(Boolean)
    .join(" · ")
})
function elegir(v: string) {
  decision.value = v as "vacio" | "algo"
  if (v === "vacio") emit("vacio", true)
}
function cambiar() {
  emit("vacio", false)
  decision.value = ""
}
function guardar() {
  tocado.value = true
  if (!valido.value || props.ocupado) return
  emit("guardar", litros.value!, pideAbv.value ? abv.value : null)
}
</script>

<template>
  <article
    class="tr"
    :class="{ 'tr--ok': guardado, 'tr--vacia': vacio && !guardado }"
    :aria-labelledby="`tr-${recurso.id}`"
  >
    <h3 :id="`tr-${recurso.id}`" class="tr__titulo">{{ recurso.code }}</h3>
    <p class="tr__sub">{{ subtitulo }}</p>

    <p v-if="guardado" class="tr__estado">
      <ChipEstado variante="on">guardado</ChipEstado>
      <span v-if="uso!.saldo_l > 0">{{ fmt(uso!.saldo_l) }} L</span>
      <span v-if="uso!.ciclos_abiertos > 0">ciclo abierto</span>
    </p>
    <p v-else-if="vacio" class="tr__estado">
      <ChipEstado variante="off">vacío</ChipEstado>
      <Boton v-if="puedeEscribir" intent="quiet" @click="cambiar">Cambiar</Boton>
    </p>
    <template v-else>
      <SegmentoOpciones
        :model-value="decision"
        etiqueta="¿Tiene algo?"
        :opciones="OPC"
        :disabled="!puedeEscribir"
        @update:model-value="elegir"
      />
      <template v-if="decision === 'algo'">
        <div class="tr__fila">
          <CampoNumero
            v-model="litros"
            etiqueta="Litros"
            unidad="L"
            :error="errorLitros"
            :disabled="!puedeEscribir"
            @blur="tocado = true"
          />
          <CampoNumero
            v-if="pideAbv"
            v-model="abv"
            etiqueta="% Alc."
            unidad="%"
            :error="errorAbv"
            ayuda="Si lo sabes."
            :disabled="!puedeEscribir"
          />
        </div>
        <p v-if="avisoCapacidad" class="tr__aviso">{{ avisoCapacidad }}</p>
        <p v-if="error" class="tr__rechazo" role="alert">{{ error }}</p>
        <Boton
          intent="primary"
          :loading="ocupado"
          :disabled="!puedeEscribir || !enLinea || !valido"
          :motivo-deshabilitado="
            !enLinea ? 'Para guardar necesitas señal; lo escrito se conserva.' : undefined
          "
          @click="guardar"
          >Guardar {{ litros !== null && litros > 0 ? `${fmt(litros)} L` : "" }} en
          {{ recurso.code }}</Boton
        >
      </template>
    </template>
  </article>
</template>

<style scoped>
.tr {
  display: grid;
  gap: var(--sp-3);
  min-width: 0;
  padding: var(--sp-4);
  border: 1px solid var(--border);
  border-radius: var(--r-lg);
  background: var(--surface);
  color: var(--text);
}
.tr--ok {
  border: 2px solid var(--ok);
}
.tr--vacia {
  color: var(--muted);
}
.tr__titulo {
  margin: 0;
  font: 700 1.0625rem/1.2 var(--font);
}
.tr__sub {
  margin: -6px 0 0;
  font-size: 0.8125rem;
  color: var(--muted);
}
.tr__estado {
  margin: 0;
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: var(--sp-2);
}
.tr__fila {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: var(--sp-3);
}
@media (min-width: 600px) {
  .tr__fila {
    grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
  }
}
.tr__aviso {
  margin: 0;
  padding: var(--sp-2) var(--sp-3);
  border: 1px dashed var(--pend);
  border-radius: var(--r-md);
  background: var(--pend-bg);
  font-size: 0.875rem;
}
.tr__rechazo {
  margin: 0;
  padding: var(--sp-3) var(--sp-4);
  border: 2px solid var(--late);
  border-radius: var(--r-md);
  background: var(--late-bg);
  font-weight: 600;
}
@media (max-width: 599px) {
  .tr :deep(.boton--primary) {
    width: 100%;
  }
}
</style>
