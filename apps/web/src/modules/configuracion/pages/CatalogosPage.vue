<script setup lang="ts">
import { computed, onMounted, ref, watch } from "vue"
import {
  BloqueEstado,
  Boton,
  CampoTexto,
  CapaTarea,
  ChipEstado,
  Interruptor,
  ListaApilada,
  MenuFila,
  SegmentoOpciones,
  Selector,
  type AccionFila,
} from "../../../shared/ui"
import { useAcceso } from "../../acceso/store"
import {
  actualizar,
  CATALOGOS,
  elementosCatalogo,
  insertar,
  listar,
  type CatalogKind,
  type Concepto,
  type ElementoCatalogo,
  type Especie,
  type Insumo,
  type Predio,
  type Proveedor,
  type Tabla,
} from "../api"
import SoloAdmin from "../components/SoloAdmin.vue"

// Catálogos (§10.2, §5.2; ronda configuracion/r01, congelada). Un select
// elige el catálogo; lista con las columnas propias de su tabla; una capa
// por tabla real (no formulario dinámico). Sembrados de plantilla y propios
// se OCULTAN (active=false), nunca se borran.
type Grupo = CatalogKind | "concepto" | "especie" | "predio" | "proveedor" | "insumo"
interface Fila {
  id: string
  nombre: string
  active: boolean
  plantilla: boolean
  extra: string[]
  raw: Record<string, unknown>
}
const acceso = useAcceso()
const org = computed(() => acceso.membresiaActual?.organization_id ?? "")

const OPC_GRUPO = [
  ...CATALOGOS.map((c) => ({ valor: c.valor as Grupo, etiqueta: c.etiqueta })),
  { valor: "concepto" as Grupo, etiqueta: "Conceptos de movimiento" },
  { valor: "especie" as Grupo, etiqueta: "Especies" },
  { valor: "predio" as Grupo, etiqueta: "Predios" },
  { valor: "proveedor" as Grupo, etiqueta: "Proveedores" },
  { valor: "insumo" as Grupo, etiqueta: "Insumos" },
]
const grupo = ref<Grupo>("tipo_tina")
const filas = ref<Fila[] | null>(null)
const errorCarga = ref<string | null>(null)
const busqueda = ref("")
const aviso = ref<string | null>(null)
const tiposProveedor = ref<ElementoCatalogo[]>([])
const unidadesInsumo = ref<ElementoCatalogo[]>([])

const esTipo = (g: Grupo) => g.startsWith("tipo_") || g === "unidad_insumo"
const tablaDe = (g: Grupo): Tabla =>
  esTipo(g)
    ? "catalog_items"
    : g === "concepto"
      ? "movement_concepts"
      : g === "especie"
        ? "species"
        : g === "predio"
          ? "predios"
          : g === "proveedor"
            ? "suppliers"
            : "supplies"
const singular = computed(() => {
  const c = CATALOGOS.find((x) => x.valor === grupo.value)
  return c
    ? c.singular
    : (
        {
          concepto: "concepto",
          especie: "especie",
          predio: "predio",
          proveedor: "proveedor",
          insumo: "insumo",
        } as Record<string, string>
      )[grupo.value]
})
const columnas = computed<string[]>(() =>
  grupo.value === "concepto"
    ? ["Nombre", "Dirección", "Comportamiento", "Contraparte"]
    : grupo.value === "especie"
      ? ["Nombre", "Nombre científico"]
      : grupo.value === "predio"
        ? ["Nombre", "Municipio"]
        : grupo.value === "proveedor"
          ? ["Nombre", "Tipo · teléfono"]
          : grupo.value === "insumo"
            ? ["Nombre", "Unidad"]
            : ["Nombre"],
)
const visibles = computed(() => {
  const q = busqueda.value.trim().toLowerCase()
  return (filas.value ?? []).filter((f) => !q || f.nombre.toLowerCase().includes(q))
})

async function cargar() {
  errorCarga.value = null
  filas.value = null
  const g = grupo.value
  try {
    if (esTipo(g)) {
      filas.value = (await elementosCatalogo(org.value, g as CatalogKind)).map((e) => ({
        id: e.id,
        nombre: e.name,
        active: e.active,
        plantilla: !!e.template_id,
        extra: [],
        raw: e as unknown as Record<string, unknown>,
      }))
    } else if (g === "concepto") {
      filas.value = (
        await listar<Concepto>(
          org.value,
          "movement_concepts",
          "id, direction, name, source_lot, creates_lot, asks_result, asks_counterparty, template_id, active",
          "direction",
        )
      ).map((c) => ({
        id: c.id,
        nombre: c.name,
        active: c.active,
        plantilla: !!c.template_id,
        extra: [
          c.direction,
          [
            c.creates_lot ? "crea lote" : "",
            c.asks_result ? "pide resultado" : "",
            c.source_lot !== "no_aplica" ? `lote origen ${c.source_lot}` : "",
          ]
            .filter(Boolean)
            .join(" · ") || "—",
          c.asks_counterparty ? "sí" : "—",
        ],
        raw: c as unknown as Record<string, unknown>,
      }))
    } else if (g === "especie") {
      filas.value = (
        await listar<Especie>(
          org.value,
          "species",
          "id, common_name, scientific_name, template_id, active",
          "common_name",
        )
      ).map((e) => ({
        id: e.id,
        nombre: e.common_name,
        active: e.active,
        plantilla: !!e.template_id,
        extra: [e.scientific_name ?? "—"],
        raw: e as unknown as Record<string, unknown>,
      }))
    } else if (g === "predio") {
      filas.value = (
        await listar<Predio>(
          org.value,
          "predios",
          "id, name, municipality, owner_name, notes, active",
          "name",
        )
      ).map((p) => ({
        id: p.id,
        nombre: p.name,
        active: p.active,
        plantilla: false,
        extra: [p.municipality ?? "—"],
        raw: p as unknown as Record<string, unknown>,
      }))
    } else if (g === "proveedor") {
      if (!tiposProveedor.value.length)
        tiposProveedor.value = await elementosCatalogo(org.value, "tipo_proveedor")
      filas.value = (
        await listar<Proveedor>(
          org.value,
          "suppliers",
          "id, name, type_item_id, phone, notes, active",
          "name",
        )
      ).map((p) => ({
        id: p.id,
        nombre: p.name,
        active: p.active,
        plantilla: false,
        extra: [
          `${tiposProveedor.value.find((t) => t.id === p.type_item_id)?.name ?? "—"}${p.phone ? ` · ${p.phone}` : ""}`,
        ],
        raw: p as unknown as Record<string, unknown>,
      }))
    } else {
      if (!unidadesInsumo.value.length)
        unidadesInsumo.value = await elementosCatalogo(org.value, "unidad_insumo")
      filas.value = (
        await listar<Insumo>(org.value, "supplies", "id, name, unit_item_id, active", "name")
      ).map((i) => ({
        id: i.id,
        nombre: i.name,
        active: i.active,
        plantilla: false,
        extra: [unidadesInsumo.value.find((u) => u.id === i.unit_item_id)?.name ?? "—"],
        raw: i as unknown as Record<string, unknown>,
      }))
    }
  } catch (e) {
    errorCarga.value = (e as Error).message
    filas.value = []
  }
}
onMounted(() => {
  if (acceso.esAdmin) cargar()
})
watch(grupo, () => {
  busqueda.value = ""
  aviso.value = null
  cargar()
})

// ── Capa por tabla ────────────────────────────────────────────────────────
type Capa = null | { tipo: "alta" } | { tipo: "editar"; f: Fila } | { tipo: "ocultar"; f: Fila }
const capa = ref<Capa>(null)
const ocupado = ref(false)
const errorCapa = ref<string | null>(null)
const form = ref<Record<string, unknown>>({})
const tocado = ref(false)
const OPC_DIR = [
  { valor: "entrada", etiqueta: "Entrada" },
  { valor: "salida", etiqueta: "Salida" },
]
const OPC_ORIGEN = [
  { valor: "no_aplica", etiqueta: "No aplica" },
  { valor: "opcional", etiqueta: "Opcional" },
  { valor: "requerido", etiqueta: "Requerido" },
]
const nombreCampo = computed(() => (grupo.value === "especie" ? "common_name" : "name"))
const nombreValor = computed(() => String(form.value[nombreCampo.value] ?? ""))
const errorNombre = computed(() =>
  tocado.value && !nombreValor.value.trim() ? "Falta el nombre." : undefined,
)
const valido = computed(
  () =>
    nombreValor.value.trim().length > 0 && (grupo.value !== "insumo" || !!form.value.unit_item_id),
)
const opcTiposProveedor = computed(() =>
  tiposProveedor.value.filter((t) => t.active).map((t) => ({ valor: t.id, etiqueta: t.name })),
)
const opcUnidades = computed(() =>
  unidadesInsumo.value.filter((u) => u.active).map((u) => ({ valor: u.id, etiqueta: u.name })),
)

function base(): Record<string, unknown> {
  const g = grupo.value
  if (g === "concepto")
    return {
      name: "",
      direction: "salida",
      source_lot: "no_aplica",
      creates_lot: false,
      asks_result: false,
      asks_counterparty: false,
    }
  if (g === "especie") return { common_name: "", scientific_name: "" }
  if (g === "predio") return { name: "", municipality: "", owner_name: "", notes: "" }
  if (g === "proveedor") return { name: "", type_item_id: "", phone: "", notes: "" }
  if (g === "insumo") return { name: "", unit_item_id: "" }
  return { name: "" }
}
async function abrirAlta() {
  if (grupo.value === "proveedor" && !tiposProveedor.value.length)
    tiposProveedor.value = await elementosCatalogo(org.value, "tipo_proveedor")
  if (grupo.value === "insumo" && !unidadesInsumo.value.length)
    unidadesInsumo.value = await elementosCatalogo(org.value, "unidad_insumo")
  form.value = base()
  tocado.value = false
  errorCapa.value = null
  capa.value = { tipo: "alta" }
}
async function abrirEditar(f: Fila) {
  await abrirAlta()
  const b = base()
  for (const k of Object.keys(b)) form.value[k] = f.raw[k] ?? b[k]
  capa.value = { tipo: "editar", f }
}
function cerrarCapa() {
  if (
    (capa.value?.tipo === "alta" || capa.value?.tipo === "editar") &&
    nombreValor.value &&
    !confirm("¿Descartar lo que escribiste?")
  )
    return
  capa.value = null
  errorCapa.value = null
}
function limpiar(fila: Record<string, unknown>): Record<string, unknown> {
  const out: Record<string, unknown> = {}
  for (const [k, v] of Object.entries(fila)) out[k] = typeof v === "string" ? v.trim() || null : v
  if (grupo.value === "concepto" && out.direction === "salida") {
    out.source_lot = "no_aplica"
    out.creates_lot = false
    out.asks_result = false
  }
  return out
}
async function guardar() {
  tocado.value = true
  if (!valido.value || ocupado.value || !capa.value) return
  ocupado.value = true
  errorCapa.value = null
  try {
    const datos = limpiar(form.value)
    if (esTipo(grupo.value)) datos.catalog = grupo.value
    if (capa.value.tipo === "alta") {
      await insertar(org.value, tablaDe(grupo.value), datos)
      aviso.value = `${nombreValor.value.trim()} quedó en ${OPC_GRUPO.find((o) => o.valor === grupo.value)?.etiqueta.toLowerCase()}.`
    } else if (capa.value.tipo === "editar") {
      await actualizar(org.value, tablaDe(grupo.value), capa.value.f.id, datos)
      aviso.value = `${nombreValor.value.trim()} quedó actualizado.`
    }
    capa.value = null
    await cargar()
  } catch (e) {
    errorCapa.value = (e as Error).message
  } finally {
    ocupado.value = false
  }
}
function accionesDe(f: Fila): AccionFila[] {
  return [
    { id: "editar", etiqueta: "Editar…" },
    f.active
      ? { id: "ocultar", etiqueta: "Ocultar…", intent: "danger" }
      : { id: "mostrar", etiqueta: "Mostrar" },
  ]
}
async function accion(id: string, f: Fila) {
  aviso.value = null
  if (id === "editar") await abrirEditar(f)
  else if (id === "ocultar") capa.value = { tipo: "ocultar", f }
  else if (id === "mostrar") {
    try {
      await actualizar(org.value, tablaDe(grupo.value), f.id, { active: true })
      aviso.value = `${f.nombre} vuelve a ofrecerse.`
      await cargar()
    } catch (e) {
      aviso.value = (e as Error).message
    }
  }
}
async function ocultar() {
  if (capa.value?.tipo !== "ocultar" || ocupado.value) return
  ocupado.value = true
  try {
    await actualizar(org.value, tablaDe(grupo.value), capa.value.f.id, { active: false })
    aviso.value = `${capa.value.f.nombre} ya no se ofrece. Puedes mostrarlo de nuevo cuando quieras.`
    capa.value = null
    await cargar()
  } catch (e) {
    errorCapa.value = (e as Error).message
  } finally {
    ocupado.value = false
  }
}
const str = (k: string) => String(form.value[k] ?? "")
const set = (k: string, v: unknown) => (form.value[k] = v)
</script>

<template>
  <SoloAdmin v-slot="{ puedeEscribir }" seccion="Catálogos">
    <div class="cat__cab">
      <Boton
        v-if="filas && filas.length"
        intent="primary"
        adapt="page-primary"
        :disabled="!puedeEscribir"
        :motivo-deshabilitado="
          !puedeEscribir ? 'Para cambiar algo necesitas señal y suscripción vigente.' : undefined
        "
        @click="abrirAlta"
        >Agregar {{ singular }}</Boton
      >
      <CampoTexto
        v-model="busqueda"
        etiqueta="Buscar por nombre"
        type="search"
        inputmode="search"
      />
      <Selector v-model="grupo" etiqueta="Catálogo" :opciones="OPC_GRUPO" />
    </div>
    <p v-if="aviso" class="cat__aviso" role="status">{{ aviso }}</p>

    <div v-if="filas === null" class="cat__esqueleto" aria-busy="true">
      <div v-for="n in 4" :key="n" class="cat__linea"></div>
    </div>
    <BloqueEstado
      v-else-if="errorCarga"
      variante="error"
      titulo="No pudimos cargar el catálogo"
      :texto="errorCarga"
    >
      <Boton intent="secondary" @click="cargar">Reintentar</Boton>
    </BloqueEstado>
    <BloqueEstado
      v-else-if="filas.length === 0"
      variante="empty"
      :titulo="`Aún no hay ${OPC_GRUPO.find((o) => o.valor === grupo)?.etiqueta.toLowerCase()}`"
      texto="Agrega los que uses; luego los eliges al registrar."
    >
      <Boton v-if="puedeEscribir" intent="primary" @click="abrirAlta">Agregar {{ singular }}</Boton>
    </BloqueEstado>
    <BloqueEstado
      v-else-if="visibles.length === 0"
      variante="empty"
      titulo="Nada con esa búsqueda"
    />
    <ListaApilada
      v-else
      :resumen="`${OPC_GRUPO.find((o) => o.valor === grupo)?.etiqueta}: nombre, datos, estado y acciones`"
    >
      <template #cabecera>
        <tr>
          <th v-for="c in columnas" :key="c" scope="col">{{ c }}</th>
          <th scope="col">Estado</th>
          <th scope="col"><span class="sr">Acciones</span></th>
        </tr>
      </template>
      <tr v-for="f in visibles" :key="f.id">
        <td :data-label="columnas[0]">
          <strong>{{ f.nombre }}</strong>
          <span v-if="f.plantilla" class="cat__nota">viene de plantilla</span>
        </td>
        <td v-for="(x, i) in f.extra" :key="i" :data-label="columnas[i + 1]">{{ x }}</td>
        <td data-label="Estado">
          <ChipEstado :variante="f.active ? 'on' : 'off'">{{
            f.active ? "visible" : "oculto"
          }}</ChipEstado>
        </td>
        <td>
          <MenuFila
            v-if="puedeEscribir"
            :nombre="f.nombre"
            :acciones="accionesDe(f)"
            @seleccionar="accion($event, f)"
          />
        </td>
      </tr>
    </ListaApilada>

    <!-- Alta / edición: una capa, campos por tabla -->
    <CapaTarea
      :abierta="capa?.tipo === 'alta' || capa?.tipo === 'editar'"
      :titulo="capa?.tipo === 'editar' ? `Editar ${capa.f.nombre}` : `Agregar ${singular}`"
      etiqueta-cerrar="Cancelar"
      @cerrar="cerrarCapa"
    >
      <form id="form-catalogo" class="cat__form" novalidate @submit.prevent="guardar">
        <CampoTexto
          :model-value="nombreValor"
          etiqueta="Nombre"
          autocapitalize="sentences"
          autocomplete="off"
          :error="errorNombre"
          @update:model-value="set(nombreCampo, $event)"
          @blur="tocado = true"
        />
        <template v-if="grupo === 'concepto'">
          <SegmentoOpciones
            :model-value="str('direction')"
            etiqueta="Dirección"
            :opciones="OPC_DIR"
            @update:model-value="set('direction', $event)"
          />
          <Interruptor
            :model-value="!!form.asks_counterparty"
            etiqueta="Pide contraparte"
            ayuda="Cliente, laboratorio, proveedor…"
            @update:model-value="set('asks_counterparty', $event)"
          />
          <template v-if="str('direction') === 'entrada'">
            <SegmentoOpciones
              :model-value="str('source_lot')"
              etiqueta="¿De qué lote viene?"
              :opciones="OPC_ORIGEN"
              @update:model-value="set('source_lot', $event)"
            />
            <Interruptor
              :model-value="!!form.creates_lot"
              etiqueta="Crea lote"
              ayuda="Compra o carga inicial: nace un lote nuevo."
              @update:model-value="set('creates_lot', $event)"
            />
            <Interruptor
              :model-value="!!form.asks_result"
              etiqueta="Pide volumen y % Alc. resultantes"
              @update:model-value="set('asks_result', $event)"
            />
          </template>
        </template>
        <CampoTexto
          v-if="grupo === 'especie'"
          :model-value="str('scientific_name')"
          etiqueta="Nombre científico (opcional)"
          autocapitalize="sentences"
          placeholder="Agave potatorum"
          @update:model-value="set('scientific_name', $event)"
        />
        <template v-if="grupo === 'predio'">
          <CampoTexto
            :model-value="str('municipality')"
            etiqueta="Municipio (opcional)"
            autocapitalize="words"
            @update:model-value="set('municipality', $event)"
          />
          <CampoTexto
            :model-value="str('owner_name')"
            etiqueta="Dueño del predio (opcional)"
            autocapitalize="words"
            @update:model-value="set('owner_name', $event)"
          />
          <CampoTexto
            :model-value="str('notes')"
            etiqueta="Notas (opcional)"
            autocapitalize="sentences"
            @update:model-value="set('notes', $event)"
          />
        </template>
        <template v-if="grupo === 'proveedor'">
          <Selector
            :model-value="str('type_item_id')"
            etiqueta="Tipo de proveedor"
            :opciones="opcTiposProveedor"
            placeholder="Sin tipo"
            @update:model-value="set('type_item_id', $event)"
          />
          <CampoTexto
            :model-value="str('phone')"
            etiqueta="Teléfono (opcional)"
            type="text"
            inputmode="text"
            autocomplete="tel"
            @update:model-value="set('phone', $event)"
          />
          <CampoTexto
            :model-value="str('notes')"
            etiqueta="Notas (opcional)"
            autocapitalize="sentences"
            @update:model-value="set('notes', $event)"
          />
        </template>
        <Selector
          v-if="grupo === 'insumo'"
          :model-value="str('unit_item_id')"
          etiqueta="Unidad"
          :opciones="opcUnidades"
          placeholder="Elige una"
          :error="tocado && !form.unit_item_id ? 'Elige la unidad.' : undefined"
          @update:model-value="set('unit_item_id', $event)"
        />
        <p v-if="errorCapa" class="cat__rechazo" role="alert">{{ errorCapa }}</p>
      </form>
      <template #acciones>
        <Boton
          intent="primary"
          type="submit"
          form="form-catalogo"
          :loading="ocupado"
          :disabled="!puedeEscribir"
          >Guardar</Boton
        >
        <Boton intent="secondary" @click="cerrarCapa">Cancelar</Boton>
      </template>
    </CapaTarea>

    <!-- Ocultar -->
    <CapaTarea
      :abierta="capa?.tipo === 'ocultar'"
      :titulo="capa?.tipo === 'ocultar' ? `¿Ocultar ${capa.f.nombre}?` : ''"
      @cerrar="cerrarCapa"
    >
      <p class="cat__texto">
        Deja de ofrecerse al registrar. Lo que ya lo usa no cambia. Puedes mostrarlo de nuevo cuando
        quieras.
      </p>
      <p v-if="errorCapa" class="cat__rechazo" role="alert">{{ errorCapa }}</p>
      <template #acciones>
        <Boton intent="danger" :loading="ocupado" @click="ocultar">Ocultar</Boton>
        <Boton intent="secondary" @click="cerrarCapa">Cancelar</Boton>
      </template>
    </CapaTarea>
  </SoloAdmin>
</template>

<style scoped>
.cat__cab {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: var(--sp-3);
  margin: 0 0 var(--sp-4);
  max-width: 720px;
}
@media (min-width: 600px) {
  .cat__cab {
    grid-template-columns: auto minmax(0, 1fr) minmax(0, 260px);
    align-items: end;
  }
}
.cat__aviso {
  margin: 0 0 var(--sp-3);
  padding: var(--sp-2) var(--sp-3);
  border-radius: var(--r-md);
  background: var(--ok-bg);
}
.cat__esqueleto {
  display: grid;
  gap: var(--sp-2);
}
.cat__linea {
  height: 48px;
  border-radius: var(--r-md);
  background: var(--ink-100);
}
.cat__nota {
  display: block;
  font-size: 0.8125rem;
  color: var(--muted);
}
.cat__form {
  display: grid;
  gap: var(--sp-4);
}
.cat__texto {
  margin: 0 0 var(--sp-3);
  color: var(--muted);
}
.cat__rechazo {
  margin: 0;
  padding: var(--sp-3) var(--sp-4);
  border: 2px solid var(--late);
  border-radius: var(--r-md);
  background: var(--late-bg);
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
