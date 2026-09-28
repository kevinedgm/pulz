<script setup lang="ts">
import { computed, onMounted, ref } from "vue"
import {
  BloqueEstado,
  Boton,
  CampoNumero,
  CampoTexto,
  CapaTarea,
  ChipEstado,
  ListaApilada,
  MenuFila,
  SegmentoOpciones,
  Selector,
  type AccionFila,
} from "../../../shared/ui"
import { useAcceso } from "../../acceso/store"
import {
  catalogoDeKind,
  crearRecurso,
  editarRecurso,
  elementosCatalogo,
  KINDS,
  recursos as cargarRecursos,
  recursosEnUso,
  type CapacityPolicy,
  type ElementoCatalogo,
  type LiquidClass,
  type Recurso,
  type RecursoEnUso,
  type ResourceKind,
} from "../api"
import SoloAdmin from "../components/SoloAdmin.vue"

// Recursos (§3, §10.3; ronda configuracion/r01, congelada). Un modelo para
// los seis tipos. Alta/edición en capa; desactivar con confirmación que
// avisa si hay litros o ciclos abiertos (recurso_en_uso, 0025). Nunca borrar.
const acceso = useAcceso()
const org = computed(() => acceso.membresiaActual?.organization_id ?? "")

const lista = ref<Recurso[] | null>(null)
const enUso = ref<Record<string, RecursoEnUso>>({})
const tipos = ref<Record<string, ElementoCatalogo[]>>({})
const errorCarga = ref<string | null>(null)
const filtro = ref<ResourceKind | "todos">("todos")
const busqueda = ref("")
const aviso = ref<string | null>(null)

type Capa =
  null | { tipo: "alta" } | { tipo: "editar"; r: Recurso } | { tipo: "desactivar"; r: Recurso }
const capa = ref<Capa>(null)
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

const OPC_KIND = KINDS.map((k) => ({ valor: k.valor, etiqueta: k.etiqueta }))
const OPC_FILTRO = [
  { valor: "todos", etiqueta: "Todos" },
  ...KINDS.map((k) => ({ valor: k.valor, etiqueta: k.plural })),
]
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
const tipoNombre = (r: Recurso) =>
  tipos.value[catalogoDeKind(r.kind)]?.find((t) => t.id === r.type_item_id)?.name ?? "—"
const kindEtiqueta = (k: ResourceKind) => KINDS.find((x) => x.valor === k)!.etiqueta
const opcTipos = computed(() =>
  (tipos.value[catalogoDeKind(form.value.kind)] ?? [])
    .filter((t) => t.active || t.id === form.value.type_item_id)
    .map((t) => ({ valor: t.id, etiqueta: t.name })),
)
const visibles = computed(() => {
  const q = busqueda.value.trim().toLowerCase()
  return (lista.value ?? []).filter(
    (r) =>
      (filtro.value === "todos" || r.kind === filtro.value) &&
      (!q || r.code.toLowerCase().includes(q)),
  )
})
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

async function cargar() {
  errorCarga.value = null
  try {
    const [rs, uso] = await Promise.all([cargarRecursos(org.value), recursosEnUso(org.value)])
    lista.value = rs
    enUso.value = Object.fromEntries(uso.map((u) => [u.resource_id, u]))
    const kinds = [...new Set(rs.map((r) => r.kind))]
    for (const k of KINDS.map((x) => x.valor)) {
      if (!tipos.value[catalogoDeKind(k)] && (kinds.includes(k) || true))
        tipos.value[catalogoDeKind(k)] = await elementosCatalogo(org.value, catalogoDeKind(k))
    }
  } catch (e) {
    errorCarga.value = (e as Error).message
  }
}
onMounted(() => {
  if (acceso.esAdmin) cargar()
})

function cambiarKind() {
  form.value.type_item_id = ""
  form.value.liquid_class = ""
}
function abrirAlta() {
  const kind = filtro.value === "todos" ? "tanque" : filtro.value
  form.value = {
    kind,
    code: "",
    type_item_id: "",
    capacity: null,
    capacity_policy: kind === "horno" || kind === "molino" ? "libre" : "flexible",
    liquid_class: "",
    location: "",
  }
  tocado.value = { code: false, capacity: false }
  errorCapa.value = null
  capa.value = { tipo: "alta" }
}
function abrirEditar(r: Recurso) {
  form.value = {
    kind: r.kind,
    code: r.code,
    type_item_id: r.type_item_id ?? "",
    capacity: r.capacity,
    capacity_policy: r.capacity_policy,
    liquid_class: r.liquid_class ?? "",
    location: r.location ?? "",
  }
  tocado.value = { code: false, capacity: false }
  errorCapa.value = null
  capa.value = { tipo: "editar", r }
}
function cerrarCapa() {
  if (
    (capa.value?.tipo === "alta" || capa.value?.tipo === "editar") &&
    form.value.code &&
    !confirm("¿Descartar lo que escribiste?")
  )
    return
  capa.value = null
  errorCapa.value = null
}
async function guardar() {
  tocado.value = { code: true, capacity: true }
  if (!valido.value || ocupado.value || !capa.value) return
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
    if (capa.value.tipo === "alta") {
      await crearRecurso(org.value, { kind: f.kind, ...datos })
      aviso.value = `${datos.code} quedó dado de alta.`
    } else if (capa.value.tipo === "editar") {
      await editarRecurso(org.value, capa.value.r.id, datos)
      aviso.value = `${datos.code} quedó actualizado.`
    }
    capa.value = null
    await cargar()
  } catch (e) {
    errorCapa.value = (e as Error).message
  } finally {
    ocupado.value = false
  }
}
function accionesDe(r: Recurso): AccionFila[] {
  return r.active
    ? [
        { id: "editar", etiqueta: "Editar…" },
        { id: "desactivar", etiqueta: "Desactivar…", intent: "danger" },
      ]
    : [
        { id: "editar", etiqueta: "Editar…" },
        { id: "reactivar", etiqueta: "Reactivar" },
      ]
}
async function accion(id: string, r: Recurso) {
  aviso.value = null
  if (id === "editar") abrirEditar(r)
  else if (id === "desactivar") capa.value = { tipo: "desactivar", r }
  else if (id === "reactivar") {
    try {
      await editarRecurso(org.value, r.id, { active: true })
      aviso.value = `${r.code} vuelve a estar disponible.`
      await cargar()
    } catch (e) {
      aviso.value = (e as Error).message
    }
  }
}
async function desactivar() {
  if (capa.value?.tipo !== "desactivar" || ocupado.value) return
  ocupado.value = true
  try {
    await editarRecurso(org.value, capa.value.r.id, { active: false })
    aviso.value = `${capa.value.r.code} ya no aparece al registrar. Puedes reactivarlo cuando quieras.`
    capa.value = null
    await cargar()
  } catch (e) {
    errorCapa.value = (e as Error).message
  } finally {
    ocupado.value = false
  }
}
const usoDe = (r: Recurso) => enUso.value[r.id]
const fmt = (n: number) => new Intl.NumberFormat("es-MX").format(n)
</script>

<template>
  <SoloAdmin v-slot="{ puedeEscribir }" seccion="Recursos">
    <div class="rec__cab">
      <Boton
        v-if="lista && lista.length"
        intent="primary"
        adapt="page-primary"
        :disabled="!puedeEscribir"
        :motivo-deshabilitado="
          !puedeEscribir ? 'Para cambiar algo necesitas señal y suscripción vigente.' : undefined
        "
        @click="abrirAlta"
        >Agregar recurso</Boton
      >
      <CampoTexto
        v-model="busqueda"
        etiqueta="Buscar por código"
        type="search"
        inputmode="search"
        placeholder="Tina 1"
      />
      <Selector v-model="filtro" etiqueta="Tipo de recurso" :opciones="OPC_FILTRO" />
    </div>
    <p v-if="aviso" class="rec__aviso" role="status">{{ aviso }}</p>

    <div v-if="lista === null && !errorCarga" class="rec__esqueleto" aria-busy="true">
      <div v-for="n in 4" :key="n" class="rec__linea"></div>
    </div>
    <BloqueEstado
      v-else-if="errorCarga"
      variante="error"
      titulo="No pudimos cargar los recursos"
      :texto="errorCarga"
    >
      <Boton intent="secondary" @click="cargar">Reintentar</Boton>
    </BloqueEstado>
    <BloqueEstado
      v-else-if="lista?.length === 0"
      variante="empty"
      titulo="Aún no hay recursos"
      texto="Empieza por lo que ya tienes: tinas, alambiques y tanques. Los tipos vienen listos."
    >
      <Boton v-if="puedeEscribir" intent="primary" @click="abrirAlta">Agregar recurso</Boton>
    </BloqueEstado>
    <BloqueEstado
      v-else-if="visibles.length === 0"
      variante="empty"
      titulo="Nada con ese filtro"
      texto="Cambia el tipo o la búsqueda."
    />
    <ListaApilada
      v-else
      resumen="Recursos de la empresa: código, tipo, capacidad y política, estado y acciones"
    >
      <template #cabecera>
        <tr>
          <th scope="col">Código</th>
          <th scope="col">Tipo</th>
          <th scope="col">Capacidad · política</th>
          <th scope="col">Estado</th>
          <th scope="col"><span class="sr">Acciones</span></th>
        </tr>
      </template>
      <tr v-for="r in visibles" :key="r.id">
        <td data-label="Código">
          <strong>{{ r.code }}</strong>
          <span class="rec__nota"
            >{{ kindEtiqueta(r.kind) }}{{ r.liquid_class ? ` · ${r.liquid_class}` : ""
            }}{{ r.location ? ` · ${r.location}` : "" }}</span
          >
        </td>
        <td data-label="Tipo">{{ tipoNombre(r) }}</td>
        <td data-label="Capacidad">
          {{ r.capacity !== null ? `${fmt(r.capacity)} ${r.capacity_unit}` : "—" }} ·
          {{ r.capacity_policy }}
        </td>
        <td data-label="Estado">
          <ChipEstado :variante="r.active ? 'on' : 'off'">{{
            r.active ? "activo" : "inactivo"
          }}</ChipEstado>
          <span
            v-if="usoDe(r) && (usoDe(r).saldo_l > 0 || usoDe(r).ciclos_abiertos > 0)"
            class="rec__nota"
          >
            {{ usoDe(r).saldo_l > 0 ? `${fmt(usoDe(r).saldo_l)} L dentro` : ""
            }}{{ usoDe(r).saldo_l > 0 && usoDe(r).ciclos_abiertos > 0 ? " · " : ""
            }}{{
              usoDe(r).ciclos_abiertos > 0 ? `${usoDe(r).ciclos_abiertos} ciclo(s) abierto(s)` : ""
            }}
          </span>
        </td>
        <td>
          <MenuFila
            v-if="puedeEscribir"
            :nombre="r.code"
            :acciones="accionesDe(r)"
            @seleccionar="accion($event, r)"
          />
        </td>
      </tr>
    </ListaApilada>

    <!-- Alta / edición -->
    <CapaTarea
      :abierta="capa?.tipo === 'alta' || capa?.tipo === 'editar'"
      :titulo="capa?.tipo === 'editar' ? `Editar ${capa.r.code}` : 'Agregar recurso'"
      etiqueta-cerrar="Cancelar"
      @cerrar="cerrarCapa"
    >
      <form id="form-recurso" class="rec__form" novalidate @submit.prevent="guardar">
        <Selector
          v-if="capa?.tipo === 'alta'"
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
          :ayuda="`Solo los ${KINDS.find((k) => k.valor === form.kind)?.plural.toLowerCase()}; se editan en Catálogos.`"
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
        <p v-if="errorCapa" class="rec__rechazo" role="alert">{{ errorCapa }}</p>
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
        <Boton intent="secondary" @click="cerrarCapa">Cancelar</Boton>
      </template>
    </CapaTarea>

    <!-- Desactivar -->
    <CapaTarea
      :abierta="capa?.tipo === 'desactivar'"
      :titulo="capa?.tipo === 'desactivar' ? `¿Desactivar ${capa.r.code}?` : ''"
      @cerrar="cerrarCapa"
    >
      <template v-if="capa?.tipo === 'desactivar'">
        <p class="rec__texto">
          Deja de aparecer al registrar. Lo ya registrado no cambia y puedes reactivarlo cuando
          quieras.
        </p>
        <p
          v-if="usoDe(capa.r) && (usoDe(capa.r).saldo_l > 0 || usoDe(capa.r).ciclos_abiertos > 0)"
          class="rec__rechazo"
          role="alert"
        >
          Ojo: {{ usoDe(capa.r).saldo_l > 0 ? `tiene ${fmt(usoDe(capa.r).saldo_l)} L dentro` : ""
          }}{{ usoDe(capa.r).saldo_l > 0 && usoDe(capa.r).ciclos_abiertos > 0 ? " y " : ""
          }}{{
            usoDe(capa.r).ciclos_abiertos > 0
              ? `${usoDe(capa.r).ciclos_abiertos} ciclo(s) de fermentación abierto(s)`
              : ""
          }}. Mejor vacíalo o ciérralo antes.
        </p>
        <p v-if="errorCapa" class="rec__rechazo" role="alert">{{ errorCapa }}</p>
      </template>
      <template #acciones>
        <Boton intent="danger" :loading="ocupado" @click="desactivar">Desactivar</Boton>
        <Boton intent="secondary" @click="cerrarCapa">Cancelar</Boton>
      </template>
    </CapaTarea>
  </SoloAdmin>
</template>

<style scoped>
.rec__cab {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: var(--sp-3);
  margin: 0 0 var(--sp-4);
  max-width: 640px;
}
@media (min-width: 600px) {
  .rec__cab {
    grid-template-columns: auto minmax(0, 1fr) minmax(0, 220px);
    align-items: end;
  }
}
.rec__aviso {
  margin: 0 0 var(--sp-3);
  padding: var(--sp-2) var(--sp-3);
  border-radius: var(--r-md);
  background: var(--ok-bg);
  color: var(--text);
}
.rec__esqueleto {
  display: grid;
  gap: var(--sp-2);
}
.rec__linea {
  height: 48px;
  border-radius: var(--r-md);
  background: var(--ink-100);
}
.rec__nota {
  display: block;
  font-size: 0.8125rem;
  color: var(--muted);
}
.rec__form {
  display: grid;
  gap: var(--sp-4);
}
.rec__texto {
  margin: 0 0 var(--sp-3);
  color: var(--muted);
}
.rec__rechazo {
  margin: 0;
  padding: var(--sp-3) var(--sp-4);
  border: 2px solid var(--late);
  border-radius: var(--r-md);
  background: var(--late-bg);
  color: var(--text);
  font-weight: 600;
}
.sr {
  position: absolute;
  width: 1px;
  height: 1px;
  overflow: hidden;
  clip: rect(0 0 0 0);
}
</style>
