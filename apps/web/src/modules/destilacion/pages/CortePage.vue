<script setup lang="ts">
import { computed, onMounted, ref, watch } from "vue"
import { useRoute } from "vue-router"
import { corregir as corregirEnCola, listar } from "../../../shared/offline/cola"
import { reducirImagen, type FotoPendiente } from "../../../shared/offline/fotos"
import { useCola } from "../../../shared/offline/useCola"
import {
  AvisoNota,
  BloqueEstado,
  Boton,
  CampoCuando,
  CampoGrande,
  CampoTexto,
  FlujoPasos,
  SegmentoOpciones,
  Selector,
  SelectorArchivo,
} from "../../../shared/ui"
import { useAcceso } from "../../acceso/store"
import {
  avisoCapacidad,
  cargarDestilacion,
  clasesDisponibles,
  colectoresDeClase,
  encolarCorte,
  litros,
  saldoDe,
  type Clase,
  type DatosDestilacion,
} from "../api"

// Corte (§4.5; ronda destilacion/r01): un concepto por pantalla — Clase (el
// colector se elige solo por la clase) → Litros → % Alc. → Revisar (aviso
// de capacidad del colector conocido antes, nota, foto). Guardar SIEMPRE
// encola. «Registrar otro corte» vuelve al paso 1 con la misma corrida.
const acceso = useAcceso()
const route = useRoute()
const cola = useCola()
const org = computed(() => acceso.membresiaActual?.organization_id ?? "")
const slug = computed(() => String(route.params.slug))
const runId = computed(() => String(route.params.corrida))
const volver = computed(() => `/e/${slug.value}/destilacion/${runId.value}`)

const datos = ref<DatosDestilacion | null>(null)
const errorCarga = ref<string | null>(null)
const corrida = computed(() => datos.value?.corridas.find((c) => c.run_id === runId.value) ?? null)

const clase = ref<Clase>("mezcal")
const colector = ref("")
const lts = ref<number | null>(null)
const abv = ref<number | null>(null)
const nota = ref("")
const cuando = ref<string | null>(null)
const foto = ref<FotoPendiente | null>(null)
const errorFoto = ref<string | null>(null)
const fotoUrl = computed(() => (foto.value ? URL.createObjectURL(foto.value.blob) : null))
const PASOS = ["clase", "litros", "abv", "revisar"] as const
const paso = ref(1)
const actual = computed(() => PASOS[paso.value - 1])
const errorPaso = ref<string | null>(null)
const corrigiendo = ref<{ id: string; codigo: string; resumen: string } | null>(null)

const clases = computed(() =>
  datos.value
    ? clasesDisponibles(datos.value.ajustes).map((c) => ({
        valor: c.valor,
        etiqueta: c.etiqueta,
        ayuda: ayudaDe(c.valor),
      }))
    : [],
)
const colectoresClase = computed(() =>
  datos.value ? colectoresDeClase(clase.value, datos.value.colectoresActivos) : [],
)
const colectorSel = computed(
  () => colectoresClase.value.find((c) => c.id === colector.value) ?? null,
)
const saldo = computed(() =>
  datos.value && colectorSel.value ? saldoDe(colectorSel.value.id, datos.value.colectores) : 0,
)
function ayudaDe(c: Clase) {
  const cs = datos.value ? colectoresDeClase(c, datos.value.colectoresActivos) : []
  if (cs.length === 0) return "sin colector de esta clase"
  const primero = cs[0]!
  const s = datos.value ? saldoDe(primero.id, datos.value.colectores) : 0
  return `→ ${primero.code}${primero.capacity ? ` · ${litros(s)} de ${litros(primero.capacity)}` : ` · ${litros(s)}`}${cs.length > 1 ? ` (+${cs.length - 1})` : ""}`
}
watch([clase, colectoresClase], () => {
  if (!colectoresClase.value.some((c) => c.id === colector.value))
    colector.value = colectoresClase.value[0]?.id ?? ""
})
const capacidad = computed(() =>
  colectorSel.value && lts.value
    ? avisoCapacidad(
        saldo.value,
        lts.value,
        colectorSel.value.capacity,
        colectorSel.value.capacity_policy,
      )
    : null,
)
const avisoCodigo = computed(
  () =>
    corrigiendo.value?.codigo ??
    (capacidad.value === "excede_capacidad" ? "excede_capacidad" : null),
)
const notaObligatoria = computed(() => Boolean(avisoCodigo.value) && !nota.value.trim())

async function cargar() {
  errorCarga.value = null
  try {
    const r = await cargarDestilacion(org.value)
    datos.value = r.datos
    const idCorregir = typeof route.query.corregir === "string" ? route.query.corregir : null
    if (idCorregir) {
      const el = (await listar(org.value)).find((e) => e.id === idCorregir)
      if (el) {
        corrigiendo.value = {
          id: el.id,
          codigo: el.requiereNota ?? "excede_capacidad",
          resumen: el.resumen,
        }
        paso.value = PASOS.length
      }
    }
  } catch (e) {
    errorCarga.value = e instanceof Error ? e.message : String(e)
  }
}
onMounted(cargar)

const rango = (v: number | null, min: number, max: number) =>
  v !== null && (v < min || v > max) ? `Entre ${min} y ${max}.` : null
function validar(): string | null {
  switch (actual.value) {
    case "clase":
      return colectoresClase.value.length === 0
        ? `No hay un colector de clase ${clase.value}. Agrégalo en Configuración → Recursos.`
        : null
    case "litros":
      return lts.value === null || lts.value <= 0 ? "Escribe los litros." : null
    case "abv":
      return abv.value === null ? "Escribe el % Alc." : rango(abv.value, 0, 100)
    default:
      return null
  }
}
function siguiente() {
  errorPaso.value = validar()
  if (errorPaso.value) return
  if (actual.value === "revisar") return guardar()
  paso.value += 1
}
function atras() {
  errorPaso.value = null
  if (paso.value > 1) paso.value -= 1
}
async function elegirFoto(f: File) {
  errorFoto.value = null
  if (!datos.value?.tipoFoto) {
    errorFoto.value = "La empresa no tiene el tipo de adjunto «Foto» en su catálogo."
    return
  }
  const blob = await reducirImagen(f)
  foto.value = {
    blob,
    tipo: blob.type || f.type,
    lot_id: "",
    kind_item_id: datos.value.tipoFoto,
    caption: `${corrida.value?.folio} · corte ${clase.value}`,
  }
}

const guardando = ref(false)
const resultado = ref<{ estado: "enviada" | "pendiente" | "fallo"; error?: string } | null>(null)
async function guardar() {
  if (
    !corrida.value ||
    !colectorSel.value ||
    guardando.value ||
    notaObligatoria.value ||
    capacidad.value === "bloqueo"
  )
    return
  guardando.value = true
  try {
    let id: string
    if (corrigiendo.value) {
      await corregirEnCola(corrigiendo.value.id, { p_nota: nota.value.trim() })
      id = corrigiendo.value.id
    } else {
      const el = await encolarCorte(org.value, {
        corrida: corrida.value.run_id,
        folioCorrida: corrida.value.folio,
        clase: clase.value,
        litros: lts.value as number,
        abv: abv.value as number,
        colector: colectorSel.value.id,
        colectorNombre: colectorSel.value.code,
        nota: nota.value,
        occurred_at: cuando.value,
        // El lote del corte lo decide la RPC (acumula o nace): la foto va sin lote y
        // se liga al resultado al subir (fotos.ts usa lot_id si viene; aquí el de la operación)
        ...(foto.value ? { foto: foto.value } : {}),
      })
      id = el.id
    }
    await cola.enviarAhora()
    const queda = (await listar(org.value)).find((e) => e.id === id)
    resultado.value = !queda
      ? { estado: "enviada" }
      : queda.estado === "fallo"
        ? { estado: "fallo", error: queda.error }
        : { estado: "pendiente" }
  } finally {
    guardando.value = false
  }
}
function otroCorte() {
  resultado.value = null
  corrigiendo.value = null
  paso.value = 1
  lts.value = null
  abv.value = null
  nota.value = ""
  foto.value = null
}
const etiquetaSiguiente = computed(() =>
  actual.value === "revisar"
    ? corrigiendo.value
      ? "Reenviar con la nota"
      : "Guardar corte"
    : actual.value === "abv"
      ? "Revisar"
      : "Siguiente",
)
const opColectores = computed(() =>
  colectoresClase.value.map((c) => ({
    valor: c.id,
    etiqueta: c.capacity ? `${c.code} · ${litros(c.capacity)}` : c.code,
  })),
)
</script>

<template>
  <div class="corte">
    <div v-if="!datos && !errorCarga" class="corte__esqueleto" aria-busy="true"></div>
    <BloqueEstado
      v-else-if="errorCarga"
      variante="error"
      titulo="No pudimos abrir el corte"
      :texto="errorCarga"
    >
      <Boton intent="secondary" @click="cargar">Reintentar</Boton>
    </BloqueEstado>
    <BloqueEstado
      v-else-if="!corrida"
      variante="empty"
      titulo="Esta corrida no existe"
      texto="El enlace no es de esta empresa."
    >
      <Boton intent="secondary" :to="`/e/${slug}/destilacion`">Ir a Destilación</Boton>
    </BloqueEstado>
    <BloqueEstado
      v-else-if="corrida.status !== 'abierta'"
      variante="empty"
      :titulo="`${corrida.folio} ya está cerrada`"
      texto="No se registran cortes en una corrida cerrada."
    >
      <Boton intent="secondary" :to="volver">Ver la corrida</Boton>
    </BloqueEstado>
    <BloqueEstado
      v-else-if="acceso.modoLectura"
      variante="denied"
      titulo="Solo lectura"
      texto="La suscripción venció: puedes consultar, no registrar."
    >
      <Boton intent="secondary" :to="volver">Volver</Boton>
    </BloqueEstado>

    <div v-else-if="resultado" class="corte__hecho">
      <div
        class="corte__caja"
        role="status"
        :class="{ 'corte__caja--fallo': resultado.estado === 'fallo' }"
      >
        <b v-if="resultado.estado === 'enviada'">Corte guardado · enviado</b>
        <b v-else-if="resultado.estado === 'pendiente'">Corte guardado · pendiente de enviar</b>
        <b v-else>El corte no pasó</b>
        <span v-if="resultado.estado === 'fallo'"
          >{{ resultado.error }} Queda en la corrida con «Corregir» o «Descartar».</span
        >
        <span v-else
          >{{ corrida.folio }} · {{ clase }} {{ litros(lts ?? 0) }} a {{ abv }} % →
          {{ colectorSel?.code
          }}<template v-if="resultado.estado === 'pendiente'"
            >. Se envía solo cuando haya señal.</template
          ></span
        >
      </div>
      <div class="corte__acciones">
        <Boton intent="primary" adapt="page-primary" @click="otroCorte">Registrar otro corte</Boton>
        <Boton intent="secondary" :to="`${volver}?aviso=corte`">Volver a la corrida</Boton>
      </div>
    </div>

    <FlujoPasos
      v-else
      :paso="paso"
      :total="PASOS.length"
      :etiqueta-siguiente="etiquetaSiguiente"
      :ocupado="guardando"
      :siguiente-deshabilitado="
        (actual === 'clase' && colectoresClase.length === 0) ||
        (actual === 'revisar' && (notaObligatoria || capacidad === 'bloqueo'))
      "
      :motivo-deshabilitado="
        actual === 'revisar' && capacidad === 'bloqueo'
          ? `No cabe: ${colectorSel?.code} tiene política estricta.`
          : actual === 'revisar' && notaObligatoria
            ? 'Escribe la nota que pide el aviso.'
            : undefined
      "
      :cancelar-to="volver"
      @siguiente="siguiente"
      @atras="atras"
    >
      <template #cabecera>
        <h2 class="corte__folio">{{ corrida.folio }}</h2>
        <span class="corte__ctx"
          >{{ corrida.alambique }} · {{ corrida.pass === "primera" ? "1ª" : "2ª" }}</span
        >
      </template>
      <CampoCuando v-if="paso === 1" v-model="cuando" />
      <template v-if="actual === 'clase'">
        <SegmentoOpciones v-model="clase" etiqueta="Clase del corte" :opciones="clases" />
        <Selector
          v-if="colectoresClase.length > 1"
          v-model="colector"
          etiqueta="Colector"
          :opciones="opColectores"
        />
        <p v-if="errorPaso" class="corte__error" role="alert">
          {{ errorPaso }}
          <Boton v-if="acceso.esAdmin" intent="quiet" :to="`/e/${slug}/configuracion/recursos`"
            >Ir a Recursos</Boton
          >
        </p>
      </template>
      <template v-else-if="actual === 'litros'">
        <p class="corte__sub">{{ clase }} → {{ colectorSel?.code }}</p>
        <CampoGrande
          v-model="lts"
          etiqueta="Litros"
          unidad="L"
          :rango="
            colectorSel?.capacity
              ? `el colector tiene ${litros(saldo)} de ${litros(colectorSel.capacity)}`
              : `el colector tiene ${litros(saldo)}`
          "
          placeholder="8"
          :error="errorPaso ?? undefined"
          autofocus
        />
      </template>
      <template v-else-if="actual === 'abv'">
        <p class="corte__sub">{{ clase }} · {{ litros(lts ?? 0) }} → {{ colectorSel?.code }}</p>
        <CampoGrande
          v-model="abv"
          etiqueta="% Alc."
          unidad="%"
          rango="entre 0 y 100"
          placeholder="51"
          :error="errorPaso ?? undefined"
          autofocus
        />
      </template>
      <template v-else>
        <h3 class="corte__h3">Revisar</h3>
        <ul v-if="!corrigiendo" class="corte__resumen">
          <li>
            <span>Clase</span><b>{{ clase }}</b>
          </li>
          <li>
            <span>Litros</span><b>{{ litros(lts ?? 0) }}</b>
          </li>
          <li>
            <span>% Alc.</span><b>{{ abv }} %</b>
          </li>
          <li>
            <span>Colector</span
            ><b
              >{{ colectorSel?.code }} ({{ litros(saldo)
              }}<template v-if="colectorSel?.capacity">
                de {{ litros(colectorSel.capacity) }}</template
              >)</b
            >
          </li>
          <li>
            <span>Cuándo</span
            ><b>{{
              cuando
                ? new Date(cuando).toLocaleString("es-MX", {
                    dateStyle: "medium",
                    timeStyle: "short",
                  })
                : "ahora"
            }}</b>
          </li>
        </ul>
        <p v-else class="corte__sub">
          {{ corrigiendo.resumen }}: el servidor pidió una nota. Escríbela y se reenvía el mismo
          corte.
        </p>
        <p v-if="capacidad === 'bloqueo'" class="corte__error" role="alert">
          No cabe: {{ colectorSel?.code }} tiene política estricta ({{ litros(saldo) }} de
          {{ litros(colectorSel?.capacity ?? 0) }}). Baja los litros o cambia la política en
          Recursos.
        </p>
        <AvisoNota
          v-model="nota"
          :codigo="avisoCodigo"
          :detalle="
            avisoCodigo === 'excede_capacidad' && colectorSel
              ? `${litros(saldo + (lts ?? 0))} en uno de ${litros(colectorSel.capacity ?? 0)}. Se guarda igual; escribe por qué.`
              : undefined
          "
        />
        <CampoTexto
          v-if="!avisoCodigo"
          v-model="nota"
          etiqueta="Nota (opcional)"
          autocapitalize="sentences"
        />
        <SelectorArchivo
          v-if="!corrigiendo"
          etiqueta="Foto (opcional)"
          :accept="['image/jpeg', 'image/png', 'image/webp']"
          :max-bytes="10 * 1024 * 1024"
          :preview-url="fotoUrl"
          texto-subir="Tomar o elegir foto"
          :error="errorFoto ?? undefined"
          @elegir="elegirFoto"
          @quitar="foto = null"
          @rechazar="errorFoto = $event"
        />
      </template>
    </FlujoPasos>
  </div>
</template>

<style scoped>
.corte__esqueleto {
  margin: var(--sp-5);
  height: 240px;
  border-radius: var(--r-lg);
  background: var(--ink-100);
}
.corte__folio {
  margin: 0;
  font: 700 1.25rem/1.2 var(--font);
}
.corte__ctx,
.corte__sub {
  margin: 0;
  font-size: 0.9375rem;
  color: var(--muted);
}
.corte__error {
  margin: 0;
  color: var(--late);
  font-weight: 600;
}
.corte__h3 {
  margin: 0;
  font: 700 1.0625rem/1.3 var(--font);
}
.corte__resumen {
  list-style: none;
  margin: 0;
  padding: 0;
  border: 1px solid var(--border);
  border-radius: var(--r-lg);
}
.corte__resumen li {
  display: flex;
  justify-content: space-between;
  gap: var(--sp-3);
  align-items: center;
  min-height: 44px;
  padding: var(--sp-2) var(--sp-4);
}
.corte__resumen li + li {
  border-top: 1px solid var(--border);
}
.corte__hecho {
  max-width: 520px;
  margin: 0 auto;
  padding: var(--sp-5) var(--sp-4);
  display: grid;
  gap: var(--sp-4);
}
.corte__caja {
  display: grid;
  gap: var(--sp-2);
  padding: var(--sp-4);
  border: 2px solid var(--ink-900);
  border-radius: var(--r-lg);
}
.corte__caja--fallo {
  border-color: var(--late);
}
.corte__caja span {
  font-size: 0.9375rem;
}
.corte__acciones {
  display: grid;
  gap: var(--sp-2);
}
</style>
