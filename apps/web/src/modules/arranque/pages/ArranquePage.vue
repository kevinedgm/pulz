<script setup lang="ts">
import { computed, onMounted, ref } from "vue"
import { useRoute } from "vue-router"
import { Aviso, BloqueEstado, Boton } from "../../../shared/ui"
import { useConexion } from "../../../shared/utils/conexion"
import { useAcceso } from "../../acceso/store"
import {
  catalogoDeKind,
  elementosCatalogo,
  recursos as cargarRecursos,
  recursosEnUso,
  type ElementoCatalogo,
  type Recurso,
  type RecursoEnUso,
} from "../../configuracion/api"
import RecursoCapa from "../../configuracion/components/RecursoCapa.vue"
import { tieneLotes } from "../../inicio/api"
import {
  cargaInicial,
  esRecipiente,
  guardarEstado,
  KINDS_RECIPIENTE,
  leerEstado,
  nuevaClave,
  type EstadoLocal,
} from "../api"
import TarjetaRecipiente from "../components/TarjetaRecipiente.vue"

// Primer arranque "¿Qué tienes hoy?" (§13.2 #2; ronda arranque/r01,
// congelada): una lista de recipientes, no un asistente. Cada tarjeta
// decide vacío / tiene algo y guarda sola (registrar_entrada carga_inicial,
// idempotente). Se puede dejar a medias y volver.
const acceso = useAcceso()
const route = useRoute()
const { enLinea } = useConexion()
const org = computed(() => acceso.membresiaActual?.organization_id ?? "")
const slug = computed(() => String(route.params.slug))
const puedeRegistrar = computed(
  () => acceso.membresiaActual?.role === "admin" || acceso.membresiaActual?.role === "productor",
)
const puedeEscribir = computed(() => puedeRegistrar.value && !acceso.modoLectura)

const lista = ref<Recurso[] | null>(null)
const enUso = ref<Record<string, RecursoEnUso>>({})
const tipos = ref<Record<string, ElementoCatalogo[]>>({})
const errorCarga = ref<string | null>(null)
const yaArranco = ref(false)
const local = ref<EstadoLocal>({})
const ocupados = ref<Record<string, boolean>>({})
const errores = ref<Record<string, string | null>>({})
const capaAlta = ref(false)
const aviso = ref<string | null>(null)

const recipientes = computed(() =>
  (lista.value ?? []).filter((r) => r.active && esRecipiente(r.kind)),
)
const tipoNombre = (r: Recurso) =>
  tipos.value[catalogoDeKind(r.kind)]?.find((t) => t.id === r.type_item_id)?.name ?? "—"
const guardado = (r: Recurso) => {
  const u = enUso.value[r.id]
  return !!u && (u.saldo_l > 0 || u.ciclos_abiertos > 0)
}
const decididos = computed(
  () => recipientes.value.filter((r) => guardado(r) || local.value[r.id]?.vacio).length,
)
const todos = computed(
  () => recipientes.value.length > 0 && decididos.value === recipientes.value.length,
)

async function cargar() {
  errorCarga.value = null
  try {
    const [rs, uso, lotes] = await Promise.all([
      cargarRecursos(org.value),
      recursosEnUso(org.value),
      tieneLotes(org.value),
    ])
    lista.value = rs
    enUso.value = Object.fromEntries(uso.map((u) => [u.resource_id, u]))
    yaArranco.value = lotes
    local.value = leerEstado(org.value)
    for (const k of KINDS_RECIPIENTE) {
      if (!tipos.value[catalogoDeKind(k)])
        tipos.value[catalogoDeKind(k)] = await elementosCatalogo(org.value, catalogoDeKind(k))
    }
  } catch (e) {
    errorCarga.value = (e as Error).message
  }
}
onMounted(() => {
  if (puedeRegistrar.value) cargar()
})

function claveDe(r: Recurso) {
  if (!local.value[r.id]) local.value[r.id] = { idem: nuevaClave(), vacio: false }
  return local.value[r.id]!.idem
}
function marcarVacio(r: Recurso, v: boolean) {
  claveDe(r)
  local.value[r.id]!.vacio = v
  guardarEstado(org.value, local.value)
}
async function guardar(r: Recurso, litros: number, abv: number | null) {
  if (!esRecipiente(r.kind) || ocupados.value[r.id]) return
  ocupados.value[r.id] = true
  errores.value[r.id] = null
  try {
    await cargaInicial(org.value, claveDe(r), r.kind, r.id, litros, abv, r.code)
    guardarEstado(org.value, local.value)
    aviso.value = `${r.code}: ${new Intl.NumberFormat("es-MX").format(litros)} L guardados.`
    const uso = await recursosEnUso(org.value)
    enUso.value = Object.fromEntries(uso.map((u) => [u.resource_id, u]))
  } catch (e) {
    const msg = (e as Error).message
    // La tina ya tenía ciclo abierto: en realidad ya está "guardada"
    if (/ciclo abierto/i.test(msg)) {
      const uso = await recursosEnUso(org.value).catch(() => [])
      enUso.value = Object.fromEntries(uso.map((u) => [u.resource_id, u]))
    }
    errores.value[r.id] = msg
  } finally {
    ocupados.value[r.id] = false
  }
}
async function recursoCreado(code: string) {
  capaAlta.value = false
  aviso.value = `${code} quedó dado de alta. Ahora di qué tiene.`
  await cargar()
}
</script>

<template>
  <div class="arr">
    <Aviso v-if="!enLinea" variante="offline" titulo="Sin conexión."
      >Puedes escribir; para guardar necesitas señal.</Aviso
    >
    <Aviso v-else-if="acceso.modoLectura" variante="readonly" titulo="Solo lectura."
      >La suscripción venció: puedes consultar, no registrar.</Aviso
    >
    <div class="arr__cuerpo">
      <BloqueEstado
        v-if="!puedeRegistrar"
        variante="denied"
        titulo="Solo el administrador o un productor pueden registrar cargas iniciales"
        :texto="`Pídeselo a quien administra ${acceso.membresiaActual?.name ?? 'la empresa'}.`"
      >
        <Boton intent="secondary" :to="`/e/${slug}/inicio`">Volver a Inicio</Boton>
      </BloqueEstado>
      <template v-else>
        <p class="arr__intro">
          Di qué hay en cada uno. Lo que no tenga nada, márcalo <b>vacío</b>. Puedes dejarlo a
          medias y volver.
        </p>
        <p v-if="yaArranco && lista" class="arr__ya">
          Ya tienes registros. Esto solo agrega cargas iniciales a recipientes que sigan vacíos.
        </p>
        <p v-if="aviso" class="arr__aviso" role="status">{{ aviso }}</p>

        <div v-if="lista === null && !errorCarga" class="arr__grid" aria-busy="true">
          <div v-for="n in 4" :key="n" class="arr__esqueleto"></div>
        </div>
        <BloqueEstado
          v-else-if="errorCarga"
          variante="error"
          titulo="No pudimos cargar tus recipientes"
          :texto="errorCarga"
        >
          <Boton intent="secondary" @click="cargar">Reintentar</Boton>
        </BloqueEstado>
        <BloqueEstado
          v-else-if="recipientes.length === 0"
          variante="empty"
          titulo="Aún no tienes recipientes"
          texto="Agrega tus tanques, tinas y colectores; después dices qué hay en cada uno."
        >
          <Boton v-if="puedeEscribir" intent="primary" @click="capaAlta = true"
            >Agregar recipiente</Boton
          >
        </BloqueEstado>
        <template v-else>
          <p class="arr__prog" role="status">
            {{ decididos }} de {{ recipientes.length }} recipientes decididos
          </p>
          <div class="arr__grid">
            <TarjetaRecipiente
              v-for="r in recipientes"
              :key="r.id"
              :recurso="r"
              :tipo-nombre="tipoNombre(r)"
              :uso="enUso[r.id]"
              :vacio="!!local[r.id]?.vacio"
              :puede-escribir="puedeEscribir"
              :en-linea="enLinea"
              :ocupado="!!ocupados[r.id]"
              :error="errores[r.id]"
              @vacio="marcarVacio(r, $event)"
              @guardar="(l, a) => guardar(r, l, a)"
            />
          </div>
          <div class="arr__pie">
            <Boton intent="secondary" :disabled="!puedeEscribir" @click="capaAlta = true"
              >Agregar recipiente</Boton
            >
            <Boton v-if="todos" intent="primary" adapt="page-primary" :to="`/e/${slug}/inicio`"
              >Listo, ir a Inicio</Boton
            >
            <span v-else class="arr__nota">Cuando todos estén decididos aparece «Listo».</span>
          </div>
        </template>
      </template>
    </div>

    <RecursoCapa
      :org="org"
      :abierta="capaAlta"
      :kinds="KINDS_RECIPIENTE"
      kind-inicial="tanque"
      :puede-escribir="puedeEscribir"
      @cerrar="capaAlta = false"
      @guardado="recursoCreado"
    />
  </div>
</template>

<style scoped>
.arr__cuerpo {
  padding: var(--sp-5);
  max-width: 960px;
}
.arr__intro {
  margin: 0 0 var(--sp-3);
}
.arr__ya {
  margin: 0 0 var(--sp-3);
  padding: var(--sp-2) var(--sp-3);
  border: 1px dashed var(--muted);
  border-radius: var(--r-md);
  font-size: 0.9375rem;
}
.arr__aviso {
  margin: 0 0 var(--sp-3);
  padding: var(--sp-2) var(--sp-3);
  border-radius: var(--r-md);
  background: var(--ok-bg);
}
.arr__prog {
  margin: 0 0 var(--sp-3);
  font-size: 0.875rem;
  color: var(--muted);
}
.arr__grid {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: var(--sp-3);
}
@media (min-width: 1024px) {
  .arr__grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}
.arr__esqueleto {
  height: 120px;
  border-radius: var(--r-lg);
  background: var(--ink-100);
}
.arr__pie {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--sp-3);
  margin-top: var(--sp-5);
}
.arr__nota {
  font-size: 0.875rem;
  color: var(--muted);
}
</style>
