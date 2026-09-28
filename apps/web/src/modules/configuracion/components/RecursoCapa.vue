<script setup lang="ts">
import { computed, ref, watch } from "vue"
import {
  Boton,
  CampoNumero,
  CampoTexto,
  CapaTarea,
  SegmentoOpciones,
  Selector,
} from "../../../shared/ui"
import {
  catalogoDeKind,
  crearRecurso,
  editarRecurso,
  elementosCatalogo,
  KINDS,
  type CapacityPolicy,
  type ElementoCatalogo,
  type LiquidClass,
  type Recurso,
  type ResourceKind,
} from "../api"

// Capa de alta/edición de recurso (ronda configuracion/r01; extraída de
// RecursosPage en arranque/r01 para que Recursos y Arranque usen la misma).
// Un modelo para los seis tipos: código, tipo del catálogo, capacidad con
// unidad por kind, política, clase de líquido solo colector, ubicación.
const props = withDefaults(
  defineProps<{
    org: string
    abierta: boolean
    recurso?: Recurso | null // null/undefined = alta
    kinds?: ResourceKind[] // limitar tipos (arranque: tanque/tina/colector)
    kindInicial?: ResourceKind
    puedeEscribir?: boolean
  }>(),
  { recurso: null, kinds: undefined, kindInicial: "tanque", puedeEscribir: true },
)
const emit = defineEmits<{ cerrar: []; guardado: [code: string] }>()

const tipos = ref<Record<string, ElementoCatalogo[]>>({})
const ocupado = ref(false)
const errorCapa = ref<string | null>(null)
const form = ref({
  kind: "tanque" as ResourceKind,
  code: "",
  type_item_id: "",
  capacity: null as number | null,
  capacity_policy: "flexible" as CapacityPolicy,
  liquid_class: "" as LiquidClass | "",
  location: "",
})
const tocado = ref({ code: false, capacity: false })

const kindsVisibles = computed(() =>
  KINDS.filter((k) => !props.kinds || props.kinds.includes(k.valor)),
)
const OPC_KIND = computed(() =>
  kindsVisibles.value.map((k) => ({ valor: k.valor, etiqueta: k.etiqueta })),
)
const OPC_POLITICA = [
  {
    valor: "estricta" as CapacityPolicy,
    etiqueta: "Estricta",
    ayuda: "No deja pasarse de la capacidad.",
  },
  {
    valor: "flexible" as CapacityPolicy,
    etiqueta: "Flexible",
    ayuda: "Avisa si te pasas, pero deja.",
  },
  { valor: "libre" as CapacityPolicy, etiqueta: "Libre", ayuda: "No mira la capacidad." },
]
const OPC_CLASE = [
  { valor: "mezcal", etiqueta: "Mezcal" },
  { valor: "ordinario", etiqueta: "Ordinario" },
  { valor: "colas", etiqueta: "Colas" },
  { valor: "puntas", etiqueta: "Puntas" },
]
const unidadDe = (k: ResourceKind) => KINDS.find((x) => x.valor === k)!.unidad
const pluralDe = (k: ResourceKind) => KINDS.find((x) => x.valor === k)!.plural.toLowerCase()
const opcTipos = computed(() =>
  (tipos.value[catalogoDeKind(form.value.kind)] ?? [])
    .filter((t) => t.active || t.id === form.value.type_item_id)
    .map((t) => ({ valor: t.id, etiqueta: t.name })),
)
const errorCode = computed(() =>
  tocado.value.code && !form.value.code.trim() ? "Falta el código." : undefined,
)
const errorCap = computed(() =>
  tocado.value.capacity && form.value.capacity !== null && form.value.capacity <= 0
    ? "Debe ser mayor a cero."
    : undefined,
)
const errorClase = computed(() =>
  form.value.kind === "colector" && !form.value.liquid_class
    ? "Elige la clase de líquido."
    : undefined,
)
const valido = computed(
  () =>
    form.value.code.trim().length > 0 &&
    !errorCap.value &&
    (form.value.kind !== "colector" || !!form.value.liquid_class),
)
const hayTexto = computed(() => form.value.code.trim().length > 0)

async function cargarTipos(k: ResourceKind) {
  const cat = catalogoDeKind(k)
  if (!tipos.value[cat]) tipos.value[cat] = await elementosCatalogo(props.org, cat)
}
function cambiarKind() {
  form.value.type_item_id = ""
  form.value.liquid_class = ""
  cargarTipos(form.value.kind)
}
watch(
  () => props.abierta,
  (abierta) => {
    if (!abierta) return
    errorCapa.value = null
    tocado.value = { code: false, capacity: false }
    const r = props.recurso
    if (r) {
      form.value = {
        kind: r.kind,
        code: r.code,
        type_item_id: r.type_item_id ?? "",
        capacity: r.capacity,
        capacity_policy: r.capacity_policy,
        liquid_class: r.liquid_class ?? "",
        location: r.location ?? "",
      }
    } else {
      const kind = props.kindInicial
      form.value = {
        kind,
        code: "",
        type_item_id: "",
        capacity: null,
        capacity_policy: kind === "horno" || kind === "molino" ? "libre" : "flexible",
        liquid_class: "",
        location: "",
      }
    }
    cargarTipos(form.value.kind)
  },
  { immediate: true },
)

function cerrar() {
  if (hayTexto.value && !props.recurso && !confirm("¿Descartar lo que escribiste?")) return
  emit("cerrar")
}
async function guardar() {
  tocado.value = { code: true, capacity: true }
  if (!valido.value || ocupado.value) return
  ocupado.value = true
  errorCapa.value = null
  const f = form.value
  const datos = {
    code: f.code.trim(),
    type_item_id: f.type_item_id || null,
    capacity: f.capacity,
    capacity_unit: unidadDe(f.kind),
    capacity_policy: f.capacity_policy,
    liquid_class: f.kind === "colector" ? (f.liquid_class as LiquidClass) : null,
    location: f.location.trim() || null,
  }
  try {
    if (props.recurso) await editarRecurso(props.org, props.recurso.id, datos)
    else await crearRecurso(props.org, { kind: f.kind, ...datos })
    emit("guardado", datos.code)
  } catch (e) {
    errorCapa.value = (e as Error).message
  } finally {
    ocupado.value = false
  }
}
</script>

<template>
  <CapaTarea
    :abierta="abierta"
    :titulo="recurso ? `Editar ${recurso.code}` : 'Agregar recurso'"
    etiqueta-cerrar="Cancelar"
    @cerrar="cerrar"
  >
    <form id="form-recurso" class="rc__form" novalidate @submit.prevent="guardar">
      <Selector
        v-if="!recurso"
        v-model="form.kind"
        etiqueta="Tipo de recurso"
        :opciones="OPC_KIND"
        ayuda="Define qué catálogo de tipos y qué unidad aplican."
        @update:model-value="cambiarKind()"
      />
      <CampoTexto
        v-model="form.code"
        etiqueta="Código (como le dicen)"
        autocapitalize="sentences"
        autocomplete="off"
        ayuda="Único en la empresa. Ej.: «Tanque 3», «Alambique chico»."
        :error="errorCode"
        @blur="tocado.code = true"
      />
      <Selector
        v-model="form.type_item_id"
        etiqueta="Tipo (catálogo)"
        :opciones="opcTipos"
        placeholder="Sin tipo"
        :ayuda="`Solo los ${pluralDe(form.kind)}; se editan en Catálogos.`"
      />
      <CampoNumero
        v-model="form.capacity"
        etiqueta="Capacidad"
        :unidad="unidadDe(form.kind)"
        :error="errorCap"
        ayuda="Opcional. Sirve para avisar o frenar según la política."
        @blur="tocado.capacity = true"
      />
      <SegmentoOpciones
        v-model="form.capacity_policy"
        etiqueta="Política de capacidad"
        :opciones="OPC_POLITICA"
      />
      <Selector
        v-if="form.kind === 'colector'"
        v-model="form.liquid_class"
        etiqueta="Clase de líquido"
        :opciones="OPC_CLASE"
        placeholder="Elige una"
        :error="errorClase"
        ayuda="Un colector recibe una sola clase."
      />
      <CampoTexto
        v-model="form.location"
        etiqueta="Ubicación (opcional)"
        autocapitalize="sentences"
        placeholder="Cuarto de atrás"
      />
      <p v-if="errorCapa" class="rc__rechazo" role="alert">{{ errorCapa }}</p>
    </form>
    <template #acciones>
      <Boton
        intent="primary"
        type="submit"
        form="form-recurso"
        :loading="ocupado"
        :disabled="!puedeEscribir"
        >Guardar recurso</Boton
      >
      <Boton intent="secondary" @click="cerrar">Cancelar</Boton>
    </template>
  </CapaTarea>
</template>

<style scoped>
.rc__form {
  display: grid;
  gap: var(--sp-4);
}
.rc__rechazo {
  margin: 0;
  padding: var(--sp-3) var(--sp-4);
  border: 2px solid var(--late);
  border-radius: var(--r-md);
  background: var(--late-bg);
  color: var(--text);
  font-weight: 600;
}
</style>
