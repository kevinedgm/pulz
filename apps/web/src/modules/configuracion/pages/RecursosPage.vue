<script setup lang="ts">
import { computed, onMounted, ref } from "vue"
import {
  BloqueEstado,
  Boton,
  CampoTexto,
  CapaTarea,
  ChipEstado,
  ListaApilada,
  MenuFila,
  Selector,
  type AccionFila,
} from "../../../shared/ui"
import { useAcceso } from "../../acceso/store"
import {
  catalogoDeKind,
  editarRecurso,
  elementosCatalogo,
  KINDS,
  recursos as cargarRecursos,
  recursosEnUso,
  type ElementoCatalogo,
  type Recurso,
  type RecursoEnUso,
  type ResourceKind,
} from "../api"
import RecursoCapa from "../components/RecursoCapa.vue"
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

const OPC_FILTRO = [
  { valor: "todos", etiqueta: "Todos" },
  ...KINDS.map((k) => ({ valor: k.valor, etiqueta: k.plural })),
]
const tipoNombre = (r: Recurso) =>
  tipos.value[catalogoDeKind(r.kind)]?.find((t) => t.id === r.type_item_id)?.name ?? "—"
const kindEtiqueta = (k: ResourceKind) => KINDS.find((x) => x.valor === k)!.etiqueta
const visibles = computed(() => {
  const q = busqueda.value.trim().toLowerCase()
  return (lista.value ?? []).filter(
    (r) =>
      (filtro.value === "todos" || r.kind === filtro.value) &&
      (!q || r.code.toLowerCase().includes(q)),
  )
})
const kindInicial = computed<ResourceKind>(() =>
  filtro.value === "todos" ? "tanque" : filtro.value,
)

async function cargar() {
  errorCarga.value = null
  try {
    const [rs, uso] = await Promise.all([cargarRecursos(org.value), recursosEnUso(org.value)])
    lista.value = rs
    enUso.value = Object.fromEntries(uso.map((u) => [u.resource_id, u]))
    for (const k of [...new Set(rs.map((r) => r.kind))]) {
      if (!tipos.value[catalogoDeKind(k)])
        tipos.value[catalogoDeKind(k)] = await elementosCatalogo(org.value, catalogoDeKind(k))
    }
  } catch (e) {
    errorCarga.value = (e as Error).message
  }
}
onMounted(() => {
  if (acceso.esAdmin) cargar()
})

function cerrarCapa() {
  capa.value = null
  errorCapa.value = null
}
async function guardado(code: string) {
  aviso.value =
    capa.value?.tipo === "editar" ? `${code} quedó actualizado.` : `${code} quedó dado de alta.`
  capa.value = null
  await cargar()
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
  if (id === "editar") capa.value = { tipo: "editar", r }
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
  <SoloAdmin v-slot="{ puedeEscribir, slug }" seccion="Recursos">
    <div class="rec__cab">
      <Boton
        v-if="lista && lista.length"
        intent="primary"
        adapt="page-primary"
        :disabled="!puedeEscribir"
        :motivo-deshabilitado="
          !puedeEscribir ? 'Para cambiar algo necesitas señal y suscripción vigente.' : undefined
        "
        @click="capa = { tipo: 'alta' }"
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
    <p class="rec__enlace">
      <RouterLink :to="`/e/${slug}/arranque`"
        >Registrar lo que hay en tanques, tinas y colectores</RouterLink
      >
    </p>
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
      <Boton v-if="puedeEscribir" intent="primary" @click="capa = { tipo: 'alta' }"
        >Agregar recurso</Boton
      >
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

    <RecursoCapa
      :org="org"
      :abierta="capa?.tipo === 'alta' || capa?.tipo === 'editar'"
      :recurso="capa?.tipo === 'editar' ? capa.r : null"
      :kind-inicial="kindInicial"
      :puede-escribir="puedeEscribir"
      @cerrar="cerrarCapa"
      @guardado="guardado"
    />

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
.rec__enlace {
  margin: 0 0 var(--sp-4);
  font-size: 0.9375rem;
}
.rec__enlace a {
  color: var(--ink-900);
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
