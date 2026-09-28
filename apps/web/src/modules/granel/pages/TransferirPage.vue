<script setup lang="ts">
import { computed, onMounted, ref, watch } from "vue"
import { useRoute, useRouter } from "vue-router"
import { ErrorAcceso } from "../../../shared/supabase/errores"
import {
  AvisoNota,
  BloqueEstado,
  Boton,
  CampoCuando,
  CampoNumero,
  CampoTexto,
  SegmentoOpciones,
  Selector,
} from "../../../shared/ui"
import { useConexion } from "../../../shared/utils/conexion"
import { useAcceso } from "../../acceso/store"
import {
  bloqueaCapacidad,
  cargarGranel,
  ErrorGranel,
  folioSugerido,
  litros,
  transferir,
  type DatosGranel,
} from "../api"

// Transferir (§5.1; ronda granel/r01): origen (colector con mezcal o tanque
// con lote) → destino (tanque) → litros → % Alc. → si el destino tiene
// lote: conservar (sugerido) o renombrar. Requiere señal; admin y productor.
const acceso = useAcceso()
const route = useRoute()
const router = useRouter()
const { enLinea } = useConexion()
const org = computed(() => acceso.membresiaActual?.organization_id ?? "")
const slug = computed(() => String(route.params.slug))
const rol = computed(() => acceso.membresiaActual?.role)
const puede = computed(
  () => (rol.value === "admin" || rol.value === "productor") && !acceso.modoLectura,
)

const datos = ref<DatosGranel | null>(null)
const errorCarga = ref<string | null>(null)
const origen = ref("")
const destino = ref("")
const lts = ref<number | null>(null)
const abv = ref<number | null>(null)
const decision = ref<"conservar" | "renombrar">("conservar")
const folioNuevo = ref("")
const nota = ref("")
const cuando = ref<string | null>(null)
const ocupado = ref(false)
const error = ref<string | null>(null)
const avisoServidor = ref<string | null>(null)

interface OrigenT {
  id: string
  resource_id: string
  lot_id: string
  etiqueta: string
  saldo: number
  abv: number | null
}
const origenes = computed<OrigenT[]>(() => {
  const d = datos.value
  if (!d) return []
  const cols = d.colectores.map((c) => ({
    id: `${c.resource_id}:${c.lot_id}`,
    resource_id: c.resource_id,
    lot_id: c.lot_id,
    etiqueta: `${c.colector} · ${c.folio} · ${litros(c.litros)}${c.abv !== null ? ` a ${c.abv} %` : ""}`,
    saldo: c.litros,
    abv: c.abv,
  }))
  const tqs = d.tanques.flatMap((t) =>
    t.lotes.map((l) => ({
      id: `${t.resource_id}:${l.lot_id}`,
      resource_id: t.resource_id,
      lot_id: l.lot_id,
      etiqueta: `${t.tanque} · ${l.folio} · ${litros(l.litros)}${l.abv !== null ? ` a ${l.abv} %` : ""}`,
      saldo: l.litros,
      abv: l.abv,
    })),
  )
  return [...cols, ...tqs]
})
const origenSel = computed(() => origenes.value.find((o) => o.id === origen.value) ?? null)
const destinos = computed(() =>
  (datos.value?.tanques ?? []).filter((t) => t.resource_id !== origenSel.value?.resource_id),
)
const destinoSel = computed(
  () => destinos.value.find((t) => t.resource_id === destino.value) ?? null,
)
const loteDestino = computed(() =>
  destinoSel.value ? folioSugerido(destinoSel.value.lotes) : null,
)

async function cargar() {
  errorCarga.value = null
  try {
    const r = await cargarGranel(org.value)
    datos.value = r.datos
    decision.value = r.datos.ajustes.default_folio_decision
    const qo = typeof route.query.origen === "string" ? route.query.origen : null
    const qd = typeof route.query.destino === "string" ? route.query.destino : null
    origen.value =
      (qo ? origenes.value.find((o) => o.resource_id === qo) : origenes.value[0])?.id ?? ""
    destino.value =
      (qd && destinos.value.find((t) => t.resource_id === qd)?.resource_id) ??
      destinos.value[0]?.resource_id ??
      ""
  } catch (e) {
    errorCarga.value = e instanceof Error ? e.message : String(e)
  }
}
onMounted(() => {
  if (puede.value) cargar()
})
watch(origenSel, (o) => {
  if (o && abv.value === null) abv.value = o.abv
  if (o && !destinos.value.some((t) => t.resource_id === destino.value))
    destino.value = destinos.value[0]?.resource_id ?? ""
})

const bloqueo = computed(() =>
  destinoSel.value && lts.value
    ? bloqueaCapacidad(destinoSel.value.litros, lts.value, destinoSel.value)
    : false,
)
const avisoCodigo = computed(
  () =>
    avisoServidor.value ??
    (destinoSel.value &&
    lts.value &&
    destinoSel.value.capacidad_l !== null &&
    destinoSel.value.capacity_policy === "flexible" &&
    destinoSel.value.litros + lts.value > destinoSel.value.capacidad_l
      ? "excede_capacidad"
      : null),
)
const motivo = computed(() => {
  if (!enLinea.value) return "Transferir necesita señal."
  if (!origenSel.value) return "Elige de dónde sale."
  if (!destinoSel.value) return "Elige a dónde va."
  if (!lts.value || lts.value <= 0) return "Escribe los litros."
  if (lts.value > origenSel.value.saldo)
    return `Solo hay ${litros(origenSel.value.saldo)} en el origen.`
  if (bloqueo.value) return `No cabe: ${destinoSel.value.tanque} tiene política estricta.`
  if (avisoCodigo.value && !nota.value.trim()) return "Escribe la nota que pide el aviso."
  return undefined
})
// Una sola cadena: el formateo del template no puede comerse el espacio
const etiqueta = computed(() =>
  lts.value && origenSel.value && destinoSel.value
    ? `Transferir ${litros(lts.value)} a ${destinoSel.value.tanque}`
    : "Transferir",
)
async function guardar() {
  if (motivo.value || ocupado.value || !origenSel.value || !destinoSel.value) return
  ocupado.value = true
  error.value = null
  try {
    await transferir(org.value, {
      origen: origenSel.value.resource_id,
      destino: destinoSel.value.resource_id,
      lote: origenSel.value.lot_id,
      litros: lts.value as number,
      abv: abv.value,
      decision: loteDestino.value ? decision.value : null,
      folio_nuevo: folioNuevo.value,
      nota: nota.value,
      occurred_at: cuando.value,
    })
    router.push(
      `/e/${slug.value}/granel/${destinoSel.value.resource_id}?aviso=${encodeURIComponent(`Transferidos ${litros(lts.value as number)} a ${destinoSel.value.tanque}.`)}`,
    )
  } catch (e) {
    if (e instanceof ErrorGranel && e.rpc.codigo === "NOTA")
      avisoServidor.value = e.rpc.requiereNota ?? "excede_capacidad"
    else error.value = e instanceof ErrorGranel || e instanceof ErrorAcceso ? e.message : String(e)
  } finally {
    ocupado.value = false
  }
}
const opOrigenes = computed(() =>
  origenes.value.map((o) => ({ valor: o.id, etiqueta: o.etiqueta })),
)
const opDestinos = computed(() =>
  destinos.value.map((t) => ({
    valor: t.resource_id,
    etiqueta: t.lotes.length
      ? `${t.tanque} · ${folioSugerido(t.lotes)?.folio} · ${litros(t.litros)}`
      : `${t.tanque} (vacío${t.capacidad_l ? ` · ${litros(t.capacidad_l)} ${t.capacity_policy}` : ""})`,
  })),
)
</script>

<template>
  <div class="tr">
    <div class="tr__cuerpo">
      <p class="tr__volver"><Boton intent="quiet" :to="`/e/${slug}/granel`">‹ Granel</Boton></p>
      <BloqueEstado
        v-if="!puede"
        variante="denied"
        titulo="Solo el administrador o un productor pueden transferir"
        :texto="`Pídeselo a quien administra ${acceso.membresiaActual?.name ?? 'la empresa'}.`"
      >
        <Boton intent="secondary" :to="`/e/${slug}/granel`">Volver</Boton>
      </BloqueEstado>
      <div v-else-if="!datos && !errorCarga" class="tr__esqueleto" aria-busy="true"></div>
      <BloqueEstado
        v-else-if="errorCarga"
        variante="error"
        titulo="No pudimos cargar los datos"
        :texto="errorCarga"
      >
        <Boton intent="secondary" @click="cargar">Reintentar</Boton>
      </BloqueEstado>
      <BloqueEstado
        v-else-if="origenes.length === 0"
        variante="empty"
        titulo="No hay nada que transferir"
        texto="Ningún colector con mezcal ni tanque con lote."
      >
        <Boton intent="secondary" :to="`/e/${slug}/granel`">Volver</Boton>
      </BloqueEstado>
      <form v-else class="tr__form" @submit.prevent="guardar">
        <fieldset class="tr__grupo">
          <legend>De dónde y a dónde</legend>
          <div class="tr__fila">
            <Selector
              v-model="origen"
              etiqueta="Origen"
              :opciones="opOrigenes"
              :disabled="ocupado"
            />
            <Selector
              v-model="destino"
              etiqueta="Destino"
              :opciones="opDestinos"
              :disabled="ocupado"
            />
          </div>
          <div class="tr__fila">
            <CampoNumero
              v-model="lts"
              etiqueta="Litros"
              unidad="L"
              :min="0"
              :max="origenSel?.saldo"
              :disabled="ocupado"
              required
            />
            <CampoNumero
              v-model="abv"
              etiqueta="% Alc."
              unidad="%"
              :min="0"
              :max="100"
              ayuda="Por defecto, el declarado del lote de origen."
              :disabled="ocupado"
            />
          </div>
        </fieldset>
        <fieldset v-if="loteDestino" class="tr__grupo">
          <legend>El destino ya tiene lote</legend>
          <SegmentoOpciones
            v-model="decision"
            etiqueta="Folio del lote que queda"
            :opciones="[
              {
                valor: 'conservar',
                etiqueta: `Conservar ${loteDestino.folio}`,
                ayuda:
                  'Sugerido: el folio del lote que ya está en el destino. Se guarda el aporte de cada uno.',
              },
              {
                valor: 'renombrar',
                etiqueta: 'Renombrar (folio nuevo)',
                ayuda: 'Los dos se consumen y nace uno nuevo con el aporte de cada uno.',
              },
            ]"
            :disabled="ocupado"
          />
          <CampoTexto
            v-if="decision === 'renombrar'"
            v-model="folioNuevo"
            etiqueta="Folio nuevo (opcional)"
            placeholder="automático (G-…)"
            :disabled="ocupado"
          />
        </fieldset>
        <fieldset v-else-if="destinoSel" class="tr__grupo">
          <legend>Folio del lote en el tanque</legend>
          <CampoTexto
            v-model="folioNuevo"
            etiqueta="Folio nuevo (opcional)"
            placeholder="automático (G-…)"
            ayuda="Destino vacío: el destilado se vuelve granel con folio nuevo."
            :disabled="ocupado"
          />
        </fieldset>
        <fieldset class="tr__grupo">
          <legend>Cuándo y nota</legend>
          <CampoCuando v-model="cuando" :disabled="ocupado" />
          <CampoTexto
            v-if="!avisoCodigo"
            v-model="nota"
            etiqueta="Nota (opcional)"
            autocapitalize="sentences"
            :disabled="ocupado"
          />
        </fieldset>
        <AvisoNota v-model="nota" :codigo="avisoCodigo" :disabled="ocupado" />
        <p v-if="error" class="tr__error" role="alert">{{ error }}</p>
        <div class="tr__acciones">
          <Boton
            intent="primary"
            adapt="page-primary"
            type="submit"
            :loading="ocupado"
            :disabled="Boolean(motivo)"
            :motivo-deshabilitado="motivo"
            >{{ etiqueta }}</Boton
          >
          <Boton intent="secondary" :to="`/e/${slug}/granel`" :disabled="ocupado">Cancelar</Boton>
        </div>
      </form>
    </div>
  </div>
</template>

<style scoped>
.tr__cuerpo {
  padding: var(--sp-4) var(--sp-5) var(--sp-6);
  max-width: 760px;
}
.tr__volver {
  margin: 0 0 var(--sp-2);
}
.tr__esqueleto {
  height: 240px;
  border-radius: var(--r-lg);
  background: var(--ink-100);
}
.tr__form {
  display: grid;
  gap: var(--sp-4);
}
.tr__grupo {
  margin: 0;
  padding: var(--sp-3) var(--sp-4) var(--sp-4);
  border: 1px solid var(--border);
  border-radius: var(--r-lg);
  display: grid;
  gap: var(--sp-3);
  min-width: 0;
}
.tr__grupo legend {
  padding: 0 var(--sp-1);
  font-weight: 700;
}
.tr__fila {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: var(--sp-3);
}
@media (min-width: 600px) {
  .tr__fila {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}
.tr__error {
  margin: 0;
  padding: var(--sp-2) var(--sp-3);
  border: 2px solid var(--late);
  border-radius: var(--r-md);
  font-weight: 600;
}
.tr__acciones {
  display: flex;
  flex-wrap: wrap;
  gap: var(--sp-2);
}
</style>
