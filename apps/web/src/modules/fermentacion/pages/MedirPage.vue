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
  CampoNumero,
  CampoTexto,
  EscalaOpciones,
  FlujoPasos,
  SelectorArchivo,
  Selector,
} from "../../../shared/ui"
import { useAcceso } from "../../acceso/store"
import {
  agrupar,
  avisoBrix,
  cargarUsos,
  diaDelCiclo,
  encolarMedicion,
  ETIQUETAS_ACIDEZ,
  ETIQUETAS_ACTIVIDAD,
  ETIQUETAS_DULZOR,
  promedio,
  type DatosFermentacion,
  type Lectura,
  type UsoTina,
  type Zona,
} from "../api"

// Medición diaria (§13.2 #4; ronda fermentacion/r01, congelada): una mano,
// números grandes, un concepto por pantalla. Mínimo: Temperatura → Brix →
// Actividad → Revisar. Completo: T. superficie (3) → T. fondo (3) → Brix
// superficie (3) → Brix fondo (3) → Actividad · Dulzor · Acidez → Revisar.
// El aviso de Brix se conoce ANTES de enviar. Guardar SIEMPRE encola.
const acceso = useAcceso()
const route = useRoute()
const cola = useCola()
const org = computed(() => acceso.membresiaActual?.organization_id ?? "")
const slug = computed(() => String(route.params.slug))
// Desde Inicio/Hoy (?volver=inicio) se regresa a Hoy; si no, a la lista de tinas
const desdeInicio = route.query.volver === "inicio"
const volver = computed(() => `/e/${slug.value}/${desdeInicio ? "inicio" : "fermentacion"}`)

const datos = ref<DatosFermentacion | null>(null)
const errorCarga = ref<string | null>(null)
const cycleId = ref(String(route.params.ciclo))
const uso = computed<UsoTina | null>(
  () => datos.value?.usos.find((u) => u.cycle_id === cycleId.value) ?? null,
)
const medibles = computed(() =>
  (datos.value?.usos ?? []).filter((u) => u.status === "fermentando" || u.status === "lista"),
)
const modo = computed(() => datos.value?.ajustes.measurement_mode ?? "minimo")
const hoy = new Date()

// Valores (se conservan al ir atrás)
const temp = ref<number | null>(null)
const brix = ref<number | null>(null)
const tSup = ref<(number | null)[]>([null, null, null])
const tFondo = ref<(number | null)[]>([null, null, null])
const bSup = ref<(number | null)[]>([null, null, null])
const bFondo = ref<(number | null)[]>([null, null, null])
const actividad = ref<number | null>(null)
const dulzor = ref<number | null>(null)
const acidez = ref<number | null>(null)
const nota = ref("")
const cuando = ref<string | null>(null)
const dia = ref<number | null>(null)
const editandoDia = ref(false)
const foto = ref<FotoPendiente | null>(null)
const errorFoto = ref<string | null>(null)
const fotoUrl = computed(() => (foto.value ? URL.createObjectURL(foto.value.blob) : null))
const cambiandoTina = ref(false)

const PASOS = computed(() =>
  modo.value === "minimo"
    ? ["temperatura", "brix", "actividad", "revisar"]
    : ["t_sup", "t_fondo", "b_sup", "b_fondo", "escalas", "revisar"],
)
const paso = ref(1)
const actual = computed(() => PASOS.value[paso.value - 1])
const errorPaso = ref<string | null>(null)

const tempProm = computed(() =>
  modo.value === "minimo" ? temp.value : promedio([...tSup.value, ...tFondo.value]),
)
const brixProm = computed(() =>
  modo.value === "minimo" ? brix.value : promedio([...bSup.value, ...bFondo.value]),
)
const aviso = computed(() =>
  avisoBrix(brixProm.value, datos.value?.ajustes ?? null, dia.value ?? 1),
)

async function cargar() {
  errorCarga.value = null
  try {
    const r = await cargarUsos(org.value)
    datos.value = r.datos
    // Sin ciclo en la URL (FAB desde Inicio): la primera por medir
    if (!uso.value) {
      const primera = agrupar(r.datos.usos, hoy).porMedir[0] ?? medibles.value[0]
      if (primera) cycleId.value = primera.cycle_id
    }
    if (uso.value) dia.value = diaDelCiclo(uso.value.started_at, hoy)
    // «Corregir» un fallo de la cola: la misma captura con la nota que pedía
    const idCorregir = typeof route.query.corregir === "string" ? route.query.corregir : null
    if (idCorregir) {
      const el = (await listar(org.value)).find((e) => e.id === idCorregir)
      if (el) {
        corrigiendo.value = {
          id: el.id,
          codigo: el.requiereNota ?? "brix_fuera_rango",
          resumen: el.resumen,
        }
        paso.value = PASOS.value.length
      }
    }
  } catch (e) {
    errorCarga.value = e instanceof Error ? e.message : String(e)
  }
}
onMounted(cargar)
// El día del ciclo sigue a «¿Cuándo pasó?»: capturar lo de ayer (o rehacer
// una semana, §16) debe llevar el día de esa fecha, no el de hoy.
watch([cycleId, cuando], () => {
  if (uso.value)
    dia.value = diaDelCiclo(uso.value.started_at, cuando.value ? new Date(cuando.value) : hoy)
})

const rango = (v: number | null, min: number, max: number) =>
  v !== null && (v < min || v > max) ? `Entre ${min} y ${max}.` : null
const grupo = (g: (number | null)[], min: number, max: number) => {
  if (g.every((v) => v === null)) return "Captura al menos una lectura."
  for (const v of g) {
    const e = rango(v, min, max)
    if (e) return e
  }
  return null
}
function validar(): string | null {
  switch (actual.value) {
    case "temperatura":
      return temp.value === null ? "Escribe la temperatura." : rango(temp.value, 0, 100)
    case "brix":
      return brix.value === null ? "Escribe el Brix." : rango(brix.value, 0, 40)
    case "actividad":
      return actividad.value === null ? "Elige la actividad." : null
    case "t_sup":
      return grupo(tSup.value, 0, 100)
    case "t_fondo":
      return grupo(tFondo.value, 0, 100)
    case "b_sup":
      return grupo(bSup.value, 0, 40)
    case "b_fondo":
      return grupo(bFondo.value, 0, 40)
    case "escalas":
      return actividad.value === null ? "Elige la actividad." : null
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

function lecturas(): Lectura[] {
  const l: Lectura[] = []
  if (modo.value === "minimo") {
    if (temp.value !== null)
      l.push({ variable: "temperatura", zona: "unica", numero: 1, valor: temp.value })
    if (brix.value !== null)
      l.push({ variable: "brix", zona: "unica", numero: 1, valor: brix.value })
    return l
  }
  const agrega = (g: (number | null)[], variable: Lectura["variable"], zona: Zona) =>
    g.forEach((v, i) => {
      if (v !== null) l.push({ variable, zona, numero: (i + 1) as 1 | 2 | 3, valor: v })
    })
  agrega(tSup.value, "temperatura", "superficie")
  agrega(tFondo.value, "temperatura", "fondo")
  agrega(bSup.value, "brix", "superficie")
  agrega(bFondo.value, "brix", "fondo")
  if (dulzor.value !== null)
    l.push({ variable: "dulzor", zona: "unica", numero: 1, valor: dulzor.value })
  if (acidez.value !== null)
    l.push({ variable: "acidez", zona: "unica", numero: 1, valor: acidez.value })
  return l
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
    lot_id: uso.value?.lot_id ?? "",
    kind_item_id: datos.value.tipoFoto,
    caption: `${uso.value?.tina} · día ${dia.value}`,
  }
}

// Guardar: SIEMPRE por la cola; luego intenta enviar y dice qué pasó
const guardando = ref(false)
const resultado = ref<{ estado: "enviada" | "pendiente" | "fallo"; error?: string } | null>(null)
const corrigiendo = ref<{ id: string; codigo: string; resumen: string } | null>(null)
const notaObligatoria = computed(
  () => Boolean(aviso.value || corrigiendo.value) && !nota.value.trim(),
)
async function guardar() {
  if (!uso.value || guardando.value || notaObligatoria.value) return
  guardando.value = true
  try {
    let id: string
    if (corrigiendo.value) {
      await corregirEnCola(corrigiendo.value.id, { p_nota: nota.value.trim() })
      id = corrigiendo.value.id
    } else {
      const el = await encolarMedicion(
        org.value,
        {
          cycle_id: uso.value.cycle_id,
          dia: dia.value ?? 1,
          modo: modo.value,
          actividad: actividad.value,
          lecturas: lecturas(),
          nota: nota.value,
          occurred_at: cuando.value,
          ...(foto.value ? { foto: foto.value } : {}),
        },
        `Medición · ${uso.value.tina} · día ${dia.value ?? 1}`,
      )
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
// Más de una sentencia en un handler inline rompe la compilación (DECISIONES shell/r01): método
function medirSiguiente() {
  resultado.value = null
  paso.value = 1
}
const siguienteTina = computed(() => {
  if (!datos.value || !uso.value) return null
  return (
    agrupar(datos.value.usos, hoy).porMedir.find((u) => u.cycle_id !== uso.value?.cycle_id) ?? null
  )
})
const etiquetaSiguiente = computed(() =>
  actual.value === "revisar"
    ? corrigiendo.value
      ? "Reenviar con la nota"
      : "Guardar medición"
    : actual.value === "actividad" || actual.value === "escalas"
      ? "Revisar"
      : "Siguiente",
)
const opcionesTina = computed(() =>
  medibles.value.map((u) => ({ valor: u.cycle_id, etiqueta: `${u.tina} · ${u.folio}` })),
)
</script>

<template>
  <div class="medir">
    <div v-if="!datos && !errorCarga" class="medir__esqueleto" aria-busy="true"></div>
    <BloqueEstado
      v-else-if="errorCarga"
      variante="error"
      titulo="No pudimos abrir la medición"
      :texto="errorCarga"
    >
      <Boton intent="secondary" @click="cargar">Reintentar</Boton>
    </BloqueEstado>
    <BloqueEstado
      v-else-if="!uso"
      variante="empty"
      titulo="No hay tinas que medir"
      texto="Esta tina ya no está fermentando o no hay tinas en uso."
    >
      <Boton intent="secondary" :to="volver">Ir a Fermentación</Boton>
    </BloqueEstado>
    <BloqueEstado
      v-else-if="acceso.modoLectura"
      variante="denied"
      titulo="Solo lectura"
      texto="La suscripción venció: puedes consultar, no registrar."
    >
      <Boton intent="secondary" :to="volver">Volver</Boton>
    </BloqueEstado>

    <!-- Resultado: guardada (enviada / pendiente) o fallo -->
    <div v-else-if="resultado" class="medir__hecho">
      <div
        class="medir__caja"
        role="status"
        :class="{ 'medir__caja--fallo': resultado.estado === 'fallo' }"
      >
        <b v-if="resultado.estado === 'enviada'">Medición guardada · enviada</b>
        <b v-else-if="resultado.estado === 'pendiente'">Medición guardada · pendiente de enviar</b>
        <b v-else>La medición no pasó</b>
        <span v-if="resultado.estado === 'pendiente'"
          >{{ uso.tina }} · día {{ dia }}. Se envía sola cuando haya señal; la ves en la lista como
          «pendiente».</span
        >
        <span v-else-if="resultado.estado === 'fallo'"
          >{{ resultado.error }} Queda en la lista con «Corregir».</span
        >
        <span v-else>{{ uso.tina }} · día {{ dia }}.</span>
      </div>
      <div class="medir__acciones">
        <Boton
          v-if="siguienteTina"
          intent="primary"
          adapt="page-primary"
          :to="`/e/${slug}/fermentacion/${siguienteTina.cycle_id}/medir`"
          @click="medirSiguiente"
          >Medir la siguiente ({{ siguienteTina.tina }})</Boton
        >
        <Boton
          :intent="siguienteTina ? 'secondary' : 'primary'"
          :adapt="siguienteTina ? 'default' : 'page-primary'"
          :to="`${volver}?aviso=medida`"
          >Volver a {{ desdeInicio ? "Inicio" : "Fermentación" }}</Boton
        >
      </div>
    </div>

    <FlujoPasos
      v-else
      :paso="paso"
      :total="PASOS.length"
      :etiqueta-siguiente="etiquetaSiguiente"
      :ocupado="guardando"
      :siguiente-deshabilitado="actual === 'revisar' && notaObligatoria"
      :motivo-deshabilitado="
        actual === 'revisar' && notaObligatoria ? 'Escribe la nota que pide el aviso.' : undefined
      "
      :cancelar-to="volver"
      @siguiente="siguiente"
      @atras="atras"
    >
      <template #cabecera>
        <template v-if="!cambiandoTina">
          <h2 class="medir__tina">{{ uso.tina }}</h2>
          <span class="medir__ctx">
            día <b>{{ dia }}</b>
            <button
              v-if="!editandoDia"
              type="button"
              class="medir__enlace"
              @click="editandoDia = true"
            >
              cambiar
            </button>
          </span>
          <button
            v-if="medibles.length > 1 && paso === 1"
            type="button"
            class="medir__enlace"
            @click="cambiandoTina = true"
          >
            otra tina
          </button>
        </template>
        <div v-else class="medir__cambiar">
          <Selector
            v-model="cycleId"
            etiqueta="Tina"
            :opciones="opcionesTina"
            @update:model-value="cambiandoTina = false"
          />
        </div>
      </template>

      <CampoNumero
        v-if="editandoDia"
        v-model="dia"
        etiqueta="Día del ciclo"
        :decimales="false"
        :min="1"
        @blur="editandoDia = false"
      />
      <CampoCuando v-if="paso === 1" v-model="cuando" />

      <template v-if="actual === 'temperatura'">
        <CampoGrande
          v-model="temp"
          etiqueta="Temperatura"
          unidad="°C"
          rango="entre 0 y 100"
          placeholder="27.5"
          :error="errorPaso ?? undefined"
          autofocus
        />
      </template>
      <template v-else-if="actual === 'brix'">
        <CampoGrande
          v-model="brix"
          etiqueta="Brix"
          unidad="°Bx"
          rango="entre 0 y 40"
          placeholder="12.4"
          :error="errorPaso ?? undefined"
          autofocus
        />
      </template>
      <template v-else-if="actual === 'actividad'">
        <EscalaOpciones v-model="actividad" etiqueta="Actividad" :etiquetas="ETIQUETAS_ACTIVIDAD" />
        <p v-if="errorPaso" class="medir__error" role="alert">{{ errorPaso }}</p>
      </template>
      <template
        v-else-if="
          actual === 't_sup' || actual === 't_fondo' || actual === 'b_sup' || actual === 'b_fondo'
        "
      >
        <fieldset class="medir__grupo">
          <legend class="medir__legend">
            {{ actual.startsWith("t_") ? "Temperatura" : "Brix" }} ·
            {{ actual.endsWith("sup") ? "superficie" : "fondo" }}
          </legend>
          <template v-for="i in 3" :key="i">
            <CampoGrande
              v-model="
                (actual === 't_sup'
                  ? tSup
                  : actual === 't_fondo'
                    ? tFondo
                    : actual === 'b_sup'
                      ? bSup
                      : bFondo)[i - 1]
              "
              :etiqueta="`Lectura ${i}`"
              :placeholder="i === 1 ? (actual.startsWith('t_') ? '27.5' : '12.4') : ''"
              class="medir__lectura"
              :autofocus="i === 1"
            />
          </template>
          <p class="medir__prom" aria-live="polite">
            Promedio:
            <b
              >{{
                promedio(
                  actual === "t_sup"
                    ? tSup
                    : actual === "t_fondo"
                      ? tFondo
                      : actual === "b_sup"
                        ? bSup
                        : bFondo,
                ) ?? "—"
              }}
              {{ actual.startsWith("t_") ? "°C" : "°Bx" }}</b
            >
          </p>
          <p v-if="errorPaso" class="medir__error" role="alert">{{ errorPaso }}</p>
        </fieldset>
      </template>
      <template v-else-if="actual === 'escalas'">
        <EscalaOpciones v-model="actividad" etiqueta="Actividad" :etiquetas="ETIQUETAS_ACTIVIDAD" />
        <EscalaOpciones
          v-model="dulzor"
          etiqueta="Dulzor (opcional)"
          :etiquetas="ETIQUETAS_DULZOR"
        />
        <EscalaOpciones
          v-model="acidez"
          etiqueta="Acidez (opcional)"
          :etiquetas="ETIQUETAS_ACIDEZ"
        />
        <p v-if="errorPaso" class="medir__error" role="alert">{{ errorPaso }}</p>
      </template>
      <template v-else-if="actual === 'revisar'">
        <h3 class="medir__h3">Revisar</h3>
        <ul v-if="!corrigiendo" class="medir__resumen">
          <li>
            <span>Temperatura</span><b>{{ tempProm ?? "—" }} °C</b>
          </li>
          <li>
            <span>Brix</span><b>{{ brixProm ?? "—" }}</b>
          </li>
          <li>
            <span>Actividad</span
            ><b>{{ actividad }} · {{ actividad ? ETIQUETAS_ACTIVIDAD[actividad - 1] : "" }}</b>
          </li>
          <li v-if="modo === 'completo'">
            <span>Dulzor · Acidez</span><b>{{ dulzor ?? "—" }} · {{ acidez ?? "—" }}</b>
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
        <p v-else class="medir__corrigiendo">
          {{ corrigiendo.resumen }}: el servidor pidió una nota. Escríbela y se reenvía la misma
          captura.
        </p>
        <AvisoNota
          v-model="nota"
          :codigo="corrigiendo?.codigo ?? aviso"
          :detalle="
            aviso === 'brix_fuera_rango' && datos
              ? `Rango habitual: ${datos.ajustes.brix_warn_min}–${datos.ajustes.brix_warn_max}. Se guarda igual; escribe por qué.`
              : undefined
          "
        />
        <CampoTexto
          v-if="!aviso && !corrigiendo"
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
.medir__esqueleto {
  margin: var(--sp-5);
  height: 240px;
  border-radius: var(--r-lg);
  background: var(--ink-100);
}
.medir__tina {
  margin: 0;
  font: 700 1.25rem/1.2 var(--font);
}
.medir__ctx {
  font-size: 0.9375rem;
}
.medir__enlace {
  min-height: var(--tap);
  padding: 0 var(--sp-2);
  border: 0;
  background: none;
  color: var(--ink-900);
  font: 500 0.9375rem/1 var(--font);
  text-decoration: underline;
  text-underline-offset: 3px;
  cursor: pointer;
}
.medir__enlace:focus-visible {
  outline: 3px solid var(--ink-900);
  outline-offset: 2px;
  border-radius: var(--r-sm);
}
.medir__cambiar {
  flex: 1 1 100%;
}
.medir__grupo {
  margin: 0;
  padding: 0;
  border: 0;
  display: grid;
  gap: var(--sp-3);
}
.medir__legend {
  padding: 0;
  margin: 0 0 var(--sp-1);
  font: 600 1rem/1.3 var(--font);
}
.medir__grupo :deep(.grande__control) {
  font-size: 1.75rem;
  min-height: 3.5rem;
}
.medir__prom {
  margin: 0;
  padding: var(--sp-2);
  border: 1px dashed var(--muted);
  border-radius: var(--r-md);
  text-align: center;
}
.medir__error {
  margin: 0;
  color: var(--late);
  font-weight: 600;
}
.medir__h3 {
  margin: 0;
  font: 700 1.0625rem/1.3 var(--font);
}
.medir__resumen {
  list-style: none;
  margin: 0;
  padding: 0;
  border: 1px solid var(--border);
  border-radius: var(--r-lg);
}
.medir__resumen li {
  display: flex;
  justify-content: space-between;
  gap: var(--sp-3);
  align-items: center;
  min-height: 44px;
  padding: var(--sp-2) var(--sp-4);
}
.medir__resumen li + li {
  border-top: 1px solid var(--border);
}
.medir__corrigiendo {
  margin: 0;
}
.medir__hecho {
  max-width: 520px;
  margin: 0 auto;
  padding: var(--sp-5) var(--sp-4);
  display: grid;
  gap: var(--sp-4);
}
.medir__caja {
  display: grid;
  gap: var(--sp-2);
  padding: var(--sp-4);
  border: 2px solid var(--ink-900);
  border-radius: var(--r-lg);
}
.medir__caja--fallo {
  border-color: var(--late);
}
.medir__caja span {
  font-size: 0.9375rem;
}
.medir__acciones {
  display: grid;
  gap: var(--sp-2);
}
</style>
