<script setup lang="ts">
import { computed, nextTick, reactive, shallowRef, useTemplateRef, watch } from "vue"
import { guardarIntencion, leerIntencion, RechazoCapturaMH } from "../intencion"
import { BloqueEstado, Boton, CapaTarea } from "../../../shared/ui"
import RecepcionForm from "./RecepcionForm.vue"
import AperturaForm from "./AperturaForm.vue"
import CocidoForm from "./CocidoForm.vue"
import ListasMH from "./ListasMH.vue"
import {
  kilos,
  nuevoBorradorCocido,
  type BorradorCocido,
  type CapturaMH,
  type DatosMH,
  type Horneada,
  type LoteSolido,
} from "../modelo"
import "../superficie.css"
const props = withDefaults(
  defineProps<{
    datos: DatosMH | null
    destino: "maguey" | "horneado"
    puede: boolean
    enLinea: boolean
    errorCarga?: string
    instantanea?: string | null
    guardar: (c: CapturaMH) => Promise<string>
    formulacion: string
    simulado?: boolean
    contexto?: string
  }>(),
  { errorCarga: "", simulado: false, instantanea: null, contexto: "" },
)
const emit = defineEmits<{ recargar: [] }>()
const pagina = shallowRef<"lista" | "recepcion" | "abrir">("lista"),
  capa = shallowRef<"cerrar" | "cocido" | "detalle" | null>(null)
const seleccion = shallowRef<Horneada>(),
  detalle = shallowRef<LoteSolido | Horneada>()
const ocupado = shallowRef(false),
  error = shallowRef(""),
  resultado = shallowRef(""),
  version = shallowRef(0)
const ofrecerFormulacion = shallowRef(false)
const fechaInstantanea = computed(() => {
  if (!props.instantanea || !Number.isFinite(Date.parse(props.instantanea)))
    return "fecha no disponible"
  return new Intl.DateTimeFormat("es-MX", { dateStyle: "medium", timeStyle: "short" }).format(
    new Date(props.instantanea),
  )
})
const tituloRef = useTemplateRef<HTMLElement>("tituloRef")
const resultadoRef = useTemplateRef<HTMLElement>("resultadoRef")
watch(pagina, async () => {
  await nextTick()
  tituloRef.value?.focus()
})
watch(resultado, async () => {
  await nextTick()
  await nextTick()
  resultadoRef.value?.focus()
})
function iniciar() {
  pagina.value = props.destino === "maguey" ? "recepcion" : "abrir"
  error.value = ""
}
function entradaCocido() {
  capa.value = "cocido"
  error.value = ""
}
const bloqueado = computed(() => !props.puede || !props.enLinea || !!props.instantanea)
const titulo = computed(() =>
  pagina.value === "recepcion"
    ? "Registrar recepción"
    : pagina.value === "abrir"
      ? "Abrir horneada"
      : props.destino === "maguey"
        ? "Maguey"
        : "Horneado",
)
const borradores = reactive<Record<string, BorradorCocido>>({ entrada: nuevoBorradorCocido() })
const claveBorrador = computed(() =>
  capa.value === "cerrar" && seleccion.value ? seleccion.value.id : "entrada",
)
const borrador = computed({
  get: () => borradores[claveBorrador.value],
  set: (v: BorradorCocido) => {
    borradores[claveBorrador.value] = v
  },
})
function cerrar(h: Horneada) {
  if (bloqueado.value) return
  borradores[h.id] ??= nuevoBorradorCocido()
  seleccion.value = h
  error.value = ""
  capa.value = "cerrar"
}
function ver(d: LoteSolido | Horneada) {
  detalle.value = d
  capa.value = "detalle"
}
function salir() {
  if (!ocupado.value) capa.value = null
}
// Snapshot de la petición en vuelo: un resultado incierto solo permite reintentar
// la misma carga con la misma clave. Nunca se confirma otro contenido por error.
const pendiente = shallowRef<CapturaMH | null>(null)
const errorPersistencia = shallowRef("")
try {
  pendiente.value = leerIntencion(props.contexto)
} catch {
  errorPersistencia.value =
    "No se pudo recuperar el envío pendiente. No registres de nuevo hasta revisar el almacenamiento local."
}
async function enviarCaptura(c: CapturaMH) {
  if (ocupado.value || bloqueado.value || errorPersistencia.value) return
  const preparada = { ...c, fecha: c.fecha ?? pendiente.value?.fecha ?? new Date().toISOString() }
  if (pendiente.value && JSON.stringify(pendiente.value) !== JSON.stringify(preparada)) {
    error.value =
      "El envío anterior quedó sin confirmar. Reintenta los datos originales antes de cambiar la captura."
    return
  }
  ocupado.value = true
  error.value = ""
  try {
    pendiente.value = JSON.parse(JSON.stringify(preparada)) as CapturaMH
    guardarIntencion(props.contexto, pendiente.value)
    await props.guardar(pendiente.value!)
    ofrecerFormulacion.value = c.tipo === "cerrar" || c.tipo === "cocido"
    const n = c.tipo === "abrir" ? c.lotes.reduce((a, l) => a + l.kg, 0) : c.kg
    resultado.value = `${c.tipo === "abrir" ? "Horneada abierta" : c.tipo === "cerrar" ? "Horneada cerrada" : c.tipo === "recepcion" ? "Recepción registrada" : "Cocido registrado"} · ${kilos(n)}${props.simulado ? " (simulación; no se guardó en la base)" : ""}`
    guardarIntencion(props.contexto, null)
    pendiente.value = null
    borradores[claveBorrador.value] = nuevoBorradorCocido()
    capa.value = null
    pagina.value = "lista"
    version.value++
    emit("recargar")
  } catch (e) {
    error.value = e instanceof Error ? e.message : String(e)
    if (e instanceof RechazoCapturaMH) {
      try {
        guardarIntencion(props.contexto, null)
        pendiente.value = null
      } catch {
        errorPersistencia.value =
          "No se pudo liberar la intención local rechazada. Revisa el almacenamiento antes de registrar otra captura."
      }
    }
  } finally {
    ocupado.value = false
  }
}
async function reintentarOriginal() {
  if (pendiente.value) await enviarCaptura(pendiente.value)
}
</script>
<template>
  <div class="mh-surface">
    <header class="mh-heading">
      <h1 ref="tituloRef" tabindex="-1">{{ titulo }}</h1>
      <Boton
        v-if="pagina === 'lista' && datos && puede"
        intent="primary"
        :disabled="bloqueado || (destino === 'horneado' && !datos.hornos.length)"
        @click="iniciar"
        >{{ destino === "maguey" ? "Registrar recepción" : "Abrir horneada" }}</Boton
      ><Boton v-if="pagina !== 'lista'" @click="pagina = 'lista'">Volver sin borrar</Boton>
    </header>
    <p v-if="simulado" class="mh-muted">
      Ejemplo interactivo · datos simulados · sin escrituras remotas
    </p>
    <p v-if="!puede" role="status">
      Solo lectura. Registrar requiere ser administrador o productor y una suscripción activa.
    </p>
    <p v-if="!enLinea || instantanea" role="status">
      Necesitas señal para registrar.
      <template v-if="instantanea"
        >Mostrando datos guardados el <time :datetime="instantanea">{{ fechaInstantanea }}</time
        >.
      </template>
    </p>
    <p v-if="errorPersistencia" role="alert">{{ errorPersistencia }}</p>
    <p v-if="pendiente && !ocupado" role="status">
      Hay un envío sin confirmar ({{ pendiente.tipo }} · {{ pendiente.fecha }}).
      {{
        kilos(
          pendiente.tipo === "abrir" ? pendiente.lotes.reduce((n, l) => n + l.kg, 0) : pendiente.kg,
        )
      }}
      · {{ pendiente.folio || "folio automático" }}. No lo captures de nuevo. Reintenta el envío
      original: conserva datos, hora y clave.
    </p>
    <p v-if="instantanea && enLinea"><Boton @click="emit('recargar')">Actualizar datos</Boton></p>
    <p v-if="resultado" ref="resultadoRef" tabindex="-1" class="mh-result" role="status">
      {{ resultado }} <Boton v-if="ofrecerFormulacion" :to="formulacion">Llenar tinas</Boton>
    </p>
    <BloqueEstado
      v-if="errorCarga"
      variante="error"
      titulo="No pudimos actualizar"
      :texto="errorCarga"
      ><Boton @click="emit('recargar')">Reintentar carga</Boton></BloqueEstado
    >
    <div v-if="!datos && !errorCarga" class="mh-loading" aria-busy="true" role="status">
      Cargando lotes y horneadas…
    </div>
    <template v-if="datos">
      <div v-show="pagina === 'lista'">
        <ListasMH
          :datos="datos"
          :destino="destino"
          :bloqueado="bloqueado"
          :formulacion="formulacion"
          @cerrar="cerrar"
          @cocido="entradaCocido"
          @ver="ver"
        />
        <p v-if="destino === 'horneado' && !datos.hornos.length">
          No hay hornos activos. Un administrador puede agregarlos en Configuración → Recursos.
        </p>
      </div>
      <RecepcionForm
        v-if="puede && destino === 'maguey'"
        v-show="pagina === 'recepcion'"
        :key="`r${version}`"
        :datos="datos"
        :bloqueado="bloqueado"
        :ocupado="ocupado"
        :error="error"
        @guardar="enviarCaptura"
        @cancelar="pagina = 'lista'"
      />
      <AperturaForm
        v-if="puede && destino === 'horneado'"
        v-show="pagina === 'abrir'"
        :key="`a${version}`"
        :datos="datos"
        :bloqueado="bloqueado"
        :ocupado="ocupado"
        :error="error"
        @guardar="enviarCaptura"
        @cancelar="pagina = 'lista'"
      />
    </template>
    <CapaTarea
      :abierta="capa !== null"
      :titulo="
        capa === 'detalle'
          ? (detalle?.folio ?? 'Detalle')
          : capa === 'cerrar'
            ? `Cerrar ${seleccion?.folio}`
            : 'Cocido que ya tenía'
      "
      foco-inicial="input"
      :ancho="440"
      @cerrar="salir"
    >
      <div class="mh-surface mh-layer">
        <CocidoForm
          v-if="capa === 'cerrar' || capa === 'cocido'"
          v-model="borrador"
          :horneada="capa === 'cerrar' ? seleccion : undefined"
          :bloqueado="bloqueado"
          :ocupado="ocupado"
          :error="error"
          @guardar="enviarCaptura"
          @cancelar="salir"
        />
        <dl v-else-if="detalle">
          <template v-if="'saldo' in detalle"
            ><dt>Kilos restantes</dt>
            <dd>{{ kilos(detalle.saldo) }} de {{ kilos(detalle.inicial) }}</dd>
            <dt>Contexto</dt>
            <dd>{{ detalle.contexto }}</dd>
            <dt>Nota</dt>
            <dd>{{ detalle.nota || "Sin nota" }}</dd></template
          ><template v-else
            ><dt>Horno</dt>
            <dd>{{ detalle.horno }}</dd>
            <dt>Orígenes</dt>
            <dd>{{ detalle.origenes }}</dd>
            <dt>Cargados</dt>
            <dd>{{ kilos(detalle.cargados) }}</dd>
            <dt>Estado</dt>
            <dd>{{ detalle.estado }}</dd></template
          >
        </dl>
        <Boton
          v-if="pendiente && !ocupado"
          :loading="ocupado"
          :disabled="bloqueado"
          @click="reintentarOriginal"
          >Reintentar envío original</Boton
        >
      </div>
    </CapaTarea>
    <Boton
      v-if="pendiente && !ocupado && !capa"
      :loading="ocupado"
      :disabled="bloqueado"
      @click="reintentarOriginal"
      >Reintentar envío original</Boton
    >
  </div>
</template>
