<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from "vue"
import { useRoute, useRouter } from "vue-router"
import { BloqueEstado, Boton } from "../../../shared/ui"
import { useAcceso } from "../../acceso/store"
import { useConexion } from "../../../shared/utils/conexion"
import { useCola } from "../../../shared/offline/useCola"
import { esErrorDeRed } from "../../../shared/supabase/errores"
import { fabAccion } from "../../../app/fab"
import { agrupar, diaDelCiclo, type UsoTina } from "../../fermentacion/api"
import {
  cargarHoy,
  fechaLarga,
  recortar,
  resumenHoy,
  rotuloHora,
  rutaCorregir,
  tieneLotes,
  type DatosHoy,
} from "../api"
import FilaTinaHoy from "../components/FilaTinaHoy.vue"
import FilaCorridaHoy from "../components/FilaCorridaHoy.vue"
import FilaColectorHoy from "../components/FilaColectorHoy.vue"
import FilaColaHoy from "../components/FilaColaHoy.vue"

// Inicio / Hoy (registry "inicio" 0.3.0, ronda inicio-hoy/r01, §13.2 #3):
// lectura + atajos, nunca captura. Resumen + Toca medir › Destilación › Por
// enviar. Una primaria: Medir de la tina más atrasada (en compact, el FAB
// del shell). Cuando la empresa no tiene lotes, ofrece el primer arranque
// (§13.2 #2, ronda arranque/r01).
const acceso = useAcceso()
const route = useRoute()
const router = useRouter()
const { enLinea } = useConexion()
const cola = useCola()
const org = computed(() => acceso.membresiaActual?.organization_id ?? "")
const slug = computed(() => String(route.params.slug ?? acceso.slug ?? ""))
const rol = computed(() => acceso.membresiaActual?.role)
const puedeMedir = computed(() => !acceso.modoLectura)
const puedeGestionar = computed(
  () => (rol.value === "admin" || rol.value === "productor") && !acceso.modoLectura,
)

const estado = ref<"cargando" | "sin-lotes" | "hoy" | "error">("cargando")
const datos = ref<DatosHoy | null>(null)
const instantanea = ref<string | null>(null)
const errorTexto = ref("")
const aviso = ref<string | null>(route.query.aviso === "medida" ? "Medición guardada." : null)
let peticion = 0

async function cargar() {
  const empresa = org.value
  if (!empresa) return
  const id = ++peticion
  estado.value = "cargando"
  try {
    // Sin señal `tieneLotes` no tiene instantánea: se pasa directo a las
    // instantáneas de fermentación y destilación (si tampoco hay, error).
    const lotes = await tieneLotes(empresa).catch((e) => {
      if (esErrorDeRed(e)) return true
      throw e
    })
    if (!lotes) {
      if (id === peticion) estado.value = "sin-lotes"
      return
    }
    const r = await cargarHoy(empresa)
    if (id !== peticion) return
    datos.value = r.datos
    instantanea.value = r.instantanea
    estado.value = "hoy"
  } catch (e) {
    if (id !== peticion) return
    errorTexto.value = e instanceof Error ? e.message : String(e)
    estado.value = "error"
  }
}
watch(org, cargar, { immediate: true })
watch(enLinea, (online) => {
  if (online) void cargar()
})

const hoy = new Date()
const grupos = computed(() => agrupar(datos.value?.usos ?? [], hoy))
const esperados = computed(() => datos.value?.ajustes.fermentation_expected_days ?? 7)
const rotulo = computed(() => rotuloHora(hoy, datos.value?.ajustes.measurement_reminder_hour ?? 9))
const porMedir = computed(() => recortar(grupos.value.porMedir))
const primera = computed<UsoTina | undefined>(() => grupos.value.porMedir[0])
const dia = (u: UsoTina) => diaDelCiclo(u.started_at, hoy)
const medirTo = (u: UsoTina) =>
  puedeMedir.value ? `/e/${slug.value}/fermentacion/${u.cycle_id}/medir?volver=inicio` : null
const resumen = computed(() =>
  resumenHoy({
    porMedir: grupos.value.porMedir.length,
    corridas: datos.value?.corridas.length ?? 0,
    cola: cola.elementos.value.length,
  }),
)
const nadaPendiente = computed(
  () =>
    estado.value === "hoy" &&
    grupos.value.porMedir.length === 0 &&
    (datos.value?.corridas.length ?? 0) === 0 &&
    (datos.value?.colectores.length ?? 0) === 0 &&
    cola.elementos.value.length === 0,
)
const contexto = computed(() => {
  const partes = []
  if (grupos.value.medidas.length)
    partes.push(
      `${grupos.value.medidas.length} tina${grupos.value.medidas.length === 1 ? "" : "s"} ya medida${grupos.value.medidas.length === 1 ? "" : "s"} hoy`,
    )
  if (grupos.value.listas.length)
    partes.push(
      `${grupos.value.listas.length} lista${grupos.value.listas.length === 1 ? "" : "s"} para destilar`,
    )
  return partes.join(" · ")
})
const fecha = fechaLarga(hoy)
const fechaInstantanea = computed(() =>
  instantanea.value
    ? new Intl.DateTimeFormat("es-MX", { dateStyle: "medium", timeStyle: "short" }).format(
        new Date(instantanea.value),
      )
    : "",
)

// FAB del shell (meta.fab «Medir»): apunta a la primera tina por medir y
// queda nulo (deshabilitado) cuando no hay ninguna. No se usa useFab porque
// la acción depende de los datos, no del montaje.
watch(
  [primera, puedeMedir],
  ([p, puede]) => {
    fabAccion.value = p && puede ? () => void router.push(medirTo(p) as string) : null
  },
  { immediate: true },
)
onBeforeUnmount(() => (fabAccion.value = null))

const corregirTo = (id: string) => {
  const e = cola.elementos.value.find((x) => x.id === id)
  return e ? rutaCorregir(slug.value, e) : null
}
</script>

<template>
  <div class="hoy">
    <div class="hoy__cabecera">
      <h2 class="hoy__titulo">Hoy</h2>
      <p class="hoy__fecha">
        {{ fecha
        }}<template v-if="instantanea">
          · Mostrando datos guardados el
          <time :datetime="instantanea">{{ fechaInstantanea }}</time></template
        >
      </p>
    </div>

    <p v-if="aviso" class="hoy__aviso" role="status">{{ aviso }}</p>

    <div v-if="estado === 'cargando'" class="hoy__esqueleto" aria-busy="true">
      <div v-for="n in 3" :key="n" class="hoy__tarjeta hoy__tarjeta--esqueleto"></div>
    </div>

    <BloqueEstado
      v-else-if="estado === 'error'"
      variante="error"
      titulo="No pudimos cargar tu día"
      :texto="errorTexto || 'Revisa tu señal.'"
    >
      <Boton intent="secondary" @click="cargar">Reintentar carga</Boton>
    </BloqueEstado>

    <BloqueEstado
      v-else-if="estado === 'sin-lotes'"
      variante="empty"
      titulo="¿Qué tienes hoy?"
      texto="Dinos qué hay en tus tanques y tinas para empezar a registrar desde el día uno."
    >
      <Boton v-if="!acceso.modoLectura" intent="primary" :to="`/e/${slug}/arranque`">Empezar</Boton>
    </BloqueEstado>

    <template v-else-if="datos">
      <p class="hoy__resumen" role="status">{{ resumen }}</p>
      <p v-if="instantanea && puedeMedir" class="hoy__instantanea">
        Sin señal puedes medir y cortar: se guardan en el teléfono y se envían al reconectar.
      </p>

      <BloqueEstado
        v-if="nadaPendiente"
        variante="empty"
        titulo="Hoy no hay nada pendiente"
        texto="Tinas medidas, sin corridas abiertas y todo enviado."
      >
        <Boton :to="`/e/${slug}/fermentacion`">Fermentación</Boton
        ><Boton :to="`/e/${slug}/destilacion`">Destilación</Boton
        ><Boton :to="`/e/${slug}/granel`">Granel</Boton>
      </BloqueEstado>

      <div v-else class="hoy__columnas">
        <section class="hoy__bloque" aria-labelledby="hoy-medir">
          <h3 id="hoy-medir" class="hoy__h">
            <span>Toca medir · {{ grupos.porMedir.length }}</span>
            <Boton intent="quiet" :to="`/e/${slug}/fermentacion`">Fermentación</Boton>
          </h3>
          <ul v-if="grupos.porMedir.length" class="hoy__lista">
            <FilaTinaHoy
              v-for="(u, i) in porMedir.visibles"
              :key="u.cycle_id"
              :uso="u"
              :dia="dia(u)"
              :esperados="esperados"
              :rotulo="rotulo"
              :medir-to="medirTo(u)"
              :primaria="i === 0"
            />
            <li v-if="porMedir.restantes" class="hoy__mas">
              y {{ porMedir.restantes }} más por medir →
              <RouterLink :to="`/e/${slug}/fermentacion`">Fermentación</RouterLink>
            </li>
          </ul>
          <div v-else-if="datos.usos.length" class="hoy__vacio" role="status">
            <b>Todo medido por hoy.</b>
            <span v-if="contexto">{{ contexto }}.</span>
          </div>
          <div v-else class="hoy__vacio" role="status">
            <b>Sin tinas fermentando.</b>
            <span>Cuando llenes tinas, aquí verás cuáles medir cada día.</span>
            <Boton
              v-if="puedeGestionar"
              :disabled="!enLinea"
              motivo-deshabilitado="Necesitas señal para formular"
              :to="`/e/${slug}/fermentacion/formular`"
              >Llenar tinas</Boton
            >
          </div>
          <p v-if="grupos.porMedir.length && contexto" class="hoy__contexto">{{ contexto }}.</p>
        </section>

        <div class="hoy__lado">
          <section class="hoy__bloque" aria-labelledby="hoy-dest">
            <h3 id="hoy-dest" class="hoy__h">
              <span>Destilación</span>
              <Boton intent="quiet" :to="`/e/${slug}/destilacion`">Ver todo</Boton>
            </h3>
            <ul v-if="datos.corridas.length || datos.colectores.length" class="hoy__lista">
              <FilaCorridaHoy
                v-for="c in datos.corridas"
                :key="c.run_id"
                :corrida="c"
                :cortar-to="puedeMedir ? `/e/${slug}/destilacion/${c.run_id}/corte` : null"
                :ver-to="`/e/${slug}/destilacion/${c.run_id}`"
              />
              <FilaColectorHoy
                v-for="k in datos.colectores"
                :key="k.resource_id + k.lot_id"
                :colector="k"
                :granel-to="
                  k.liquid_class === 'mezcal' && puedeGestionar && enLinea
                    ? `/e/${slug}/granel/transferir?origen=${k.resource_id}`
                    : null
                "
                :ver-to="`/e/${slug}/destilacion`"
              />
            </ul>
            <div v-else class="hoy__vacio" role="status">
              <b>Sin corridas abiertas ni colectores con líquido.</b>
              <Boton
                v-if="puedeGestionar"
                :disabled="!enLinea"
                motivo-deshabilitado="Necesitas señal para abrir una corrida"
                :to="`/e/${slug}/destilacion/abrir`"
                >Abrir corrida</Boton
              >
              <span v-else>Las corridas las abre el productor.</span>
            </div>
          </section>

          <section
            v-if="cola.elementos.value.length"
            class="hoy__bloque"
            aria-labelledby="hoy-cola"
          >
            <h3 id="hoy-cola" class="hoy__h">
              <span>Por enviar · {{ cola.elementos.value.length }}</span>
            </h3>
            <ul class="hoy__lista">
              <FilaColaHoy
                v-for="e in cola.elementos.value"
                :key="e.id"
                :elemento="e"
                :corregir-to="corregirTo(e.id)"
                :enviando="cola.enviando.value"
                @reintentar="cola.reintentar(e.id)"
                @descartar="cola.descartar(e.id)"
              />
            </ul>
          </section>
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
.hoy {
  padding: var(--sp-5);
  max-width: 1100px;
}
.hoy__cabecera {
  margin: 0 0 var(--sp-3);
}
.hoy__titulo {
  margin: 0;
  font: 700 1.5rem/1.2 var(--font);
}
.hoy__fecha {
  margin: 2px 0 0;
  font-size: 0.875rem;
  color: var(--muted);
}
.hoy__fecha::first-letter {
  text-transform: uppercase;
}
.hoy__resumen {
  margin: 0 0 var(--sp-4);
  font-size: 1rem;
}
.hoy__aviso,
.hoy__instantanea {
  margin: 0 0 var(--sp-3);
  padding: var(--sp-2) var(--sp-3);
  border: 1px dashed var(--muted);
  border-radius: var(--r-md);
  font-size: 0.9375rem;
}
.hoy__columnas {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: var(--sp-5);
  align-items: start;
}
@media (min-width: 1024px) {
  .hoy__columnas {
    grid-template-columns: minmax(0, 3fr) minmax(0, 2fr);
  }
}
.hoy__lado {
  display: grid;
  gap: var(--sp-5);
}
.hoy__h {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: var(--sp-2);
  margin: 0 0 var(--sp-2);
  font: 600 0.75rem/1.2 var(--font);
  letter-spacing: 0.05em;
  text-transform: uppercase;
  color: var(--muted);
}
/* El enlace de la cabecera del bloque no hereda las mayúsculas del rótulo */
.hoy__h :deep(.boton) {
  text-transform: none;
  letter-spacing: 0;
}
.hoy__lista {
  list-style: none;
  margin: 0;
  padding: 0;
  border: 1px solid var(--border);
  border-radius: var(--r-lg);
  background: var(--surface);
}
.hoy__mas {
  padding: var(--sp-2) var(--sp-4);
  border-top: 1px solid var(--border);
  font-size: 0.875rem;
}
.hoy__mas a {
  color: var(--ink-900);
}
.hoy__vacio {
  display: grid;
  gap: var(--sp-2);
  justify-items: start;
  padding: var(--sp-4);
  border: 1px dashed var(--muted);
  border-radius: var(--r-lg);
  font-size: 0.9375rem;
  color: var(--muted);
}
.hoy__vacio b {
  color: var(--text);
}
.hoy__contexto {
  margin: var(--sp-2) 0 0;
  font-size: 0.875rem;
  color: var(--muted);
}
.hoy__esqueleto {
  display: grid;
  gap: var(--sp-3);
}
.hoy__tarjeta--esqueleto {
  min-height: 72px;
  border-radius: var(--r-lg);
  background: var(--ink-100);
}
</style>
