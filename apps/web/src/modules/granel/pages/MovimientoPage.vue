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
  avisosEntrada,
  bloqueaCapacidad,
  camposDe,
  cargarGranel,
  diferencia,
  ErrorGranel,
  fmt,
  folioSugerido,
  ledgerEsperado,
  litros,
  loteVivo,
  registrarMovimiento,
  type Concepto,
  type DatosGranel,
  type Tanque,
} from "../api"

// Movimiento de granel (§5; ronda granel/r01): elegir el concepto y el
// formulario se arma con su comportamiento (source_lot, creates_lot,
// asks_result, asks_counterparty). El sistema no calcula el grado: se
// declara volumen y % Alc. resultantes y la diferencia con el ledger se
// muestra antes (conciliación). Requiere señal; admin y productor.
const acceso = useAcceso()
const route = useRoute()
const router = useRouter()
const { enLinea } = useConexion()
const org = computed(() => acceso.membresiaActual?.organization_id ?? "")
const slug = computed(() => String(route.params.slug))
const tanqueId = computed(() => String(route.params.tanque))
const rol = computed(() => acceso.membresiaActual?.role)
const puede = computed(
  () => (rol.value === "admin" || rol.value === "productor") && !acceso.modoLectura,
)

const datos = ref<DatosGranel | null>(null)
const errorCarga = ref<string | null>(null)
const tanque = computed<Tanque | null>(
  () => datos.value?.tanques.find((t) => t.resource_id === tanqueId.value) ?? null,
)
const direccion = ref<"entrada" | "salida">(
  route.query.direccion === "salida" ? "salida" : "entrada",
)
const conceptoId = ref("")
const paso = ref<"concepto" | "datos">("concepto")

// Campos
const lts = ref<number | null>(null)
const loteId = ref("")
const origenId = ref("")
const abvEntra = ref<number | null>(null)
const resultadoL = ref<number | null>(null)
const resultadoAbv = ref<number | null>(null)
const decision = ref<"conservar" | "renombrar">("conservar")
const folioNuevo = ref("")
const contraparte = ref("")
const documento = ref("")
const proveedorId = ref("")
const proveedorNombre = ref("")
const folioCert = ref("")
const organismo = ref("")
const especieId = ref("")
const predio = ref("")
const nota = ref("")
const cuando = ref<string | null>(null)
const ocupado = ref(false)
const error = ref<string | null>(null)
const avisoServidor = ref<string | null>(null)

const conceptos = computed(() =>
  (datos.value?.conceptos ?? []).filter(
    (c) => c.direction === direccion.value && !/carga inicial/i.test(c.name),
  ),
)
const concepto = computed<Concepto | null>(
  () => conceptos.value.find((c) => c.id === conceptoId.value) ?? null,
)
const campos = computed(() =>
  concepto.value && tanque.value ? camposDe(concepto.value, tanque.value.lotes.length) : null,
)
const lote = computed(
  () =>
    tanque.value?.lotes.find((l) => l.lot_id === loteId.value) ??
    (tanque.value ? loteVivo(tanque.value) : null),
)
const comportamiento = (c: Concepto) =>
  [
    c.creates_lot ? "crea lote" : null,
    c.source_lot === "requerido"
      ? "lote de origen"
      : c.source_lot === "opcional"
        ? "lote de origen opcional"
        : null,
    c.asks_result ? "pide volumen y % Alc. resultantes" : null,
    c.asks_counterparty ? (c.creates_lot ? "pide proveedor" : "pide contraparte") : null,
  ]
    .filter(Boolean)
    .join(" · ") || "solo litros"

// Orígenes para unión / puntas: colectores con mezcal y lotes de otros tanques
interface OrigenU {
  id: string
  resource_id: string
  lot_id: string
  etiqueta: string
  saldo: number
  abv: number | null
}
const origenes = computed<OrigenU[]>(() => {
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
  const tqs = d.tanques
    .filter((t) => t.resource_id !== tanqueId.value)
    .flatMap((t) =>
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
const origenSel = computed(() => origenes.value.find((o) => o.id === origenId.value) ?? null)
watch(origenSel, (o) => {
  if (o && abvEntra.value === null) abvEntra.value = o.abv
})

async function cargar() {
  errorCarga.value = null
  try {
    const r = await cargarGranel(org.value)
    datos.value = r.datos
    decision.value = r.datos.ajustes.default_folio_decision
    if (tanque.value) loteId.value = loteVivo(tanque.value)?.lot_id ?? ""
    if (
      typeof route.query.concepto === "string" &&
      conceptos.value.some((c) => c.id === route.query.concepto)
    ) {
      conceptoId.value = route.query.concepto
      paso.value = "datos"
    }
  } catch (e) {
    errorCarga.value = e instanceof Error ? e.message : String(e)
  }
}
onMounted(() => {
  if (puede.value) cargar()
})
watch(direccion, () => (conceptoId.value = ""))

// Ledger esperado y diferencia (solo entradas con resultado)
const saldoLote = computed(() => (concepto.value?.creates_lot ? 0 : (lote.value?.litros ?? 0)))
const ledger = computed(() =>
  campos.value?.resultado && lts.value
    ? ledgerEsperado(
        saldoLote.value,
        lts.value,
        decision.value === "renombrar" && Boolean(lote.value),
        0,
      )
    : null,
)
const dif = computed(() =>
  ledger.value !== null ? diferencia(resultadoL.value, ledger.value) : null,
)
const bloqueo = computed(() =>
  tanque.value && direccion.value === "entrada" && lts.value
    ? bloqueaCapacidad(tanque.value.litros, lts.value, tanque.value)
    : false,
)
const avisos = computed(() =>
  datos.value && tanque.value && direccion.value === "entrada"
    ? avisosEntrada(
        dif.value,
        resultadoAbv.value,
        datos.value.ajustes,
        lts.value
          ? {
              saldo: tanque.value.litros,
              litros: lts.value,
              capacidad: tanque.value.capacidad_l,
              politica: tanque.value.capacity_policy,
            }
          : null,
      )
    : [],
)
const avisoCodigo = computed(() => avisoServidor.value ?? avisos.value[0] ?? null)
const motivo = computed(() => {
  if (!enLinea.value) return "Los movimientos de granel necesitan señal."
  if (!concepto.value || !tanque.value) return "Elige el concepto."
  if (!lts.value || lts.value <= 0) return "Escribe los litros."
  if (direccion.value === "salida" && !lote.value) return `${tanque.value.tanque} está vacío.`
  if (direccion.value === "salida" && lote.value && lts.value > lote.value.litros)
    return `Solo hay ${litros(lote.value.litros)} en ${lote.value.folio}.`
  if (campos.value?.origen === "requerido" && !origenSel.value) return "Elige el lote de origen."
  if (origenSel.value && lts.value > origenSel.value.saldo)
    return `Solo hay ${litros(origenSel.value.saldo)} en el origen.`
  if (campos.value?.resultado && resultadoL.value === null) return "Declara el volumen resultante."
  if (
    campos.value?.contraparte &&
    !contraparte.value.trim() &&
    !(campos.value.certificado && (proveedorId.value || proveedorNombre.value.trim()))
  )
    return campos.value.certificado ? "Indica el proveedor." : "Indica la contraparte."
  if (
    direccion.value === "entrada" &&
    !concepto.value.creates_lot &&
    campos.value?.origen === "no" &&
    !lote.value
  )
    return `${tanque.value.tanque} está vacío: usa carga inicial o compra.`
  if (bloqueo.value) return `No cabe: ${tanque.value.tanque} tiene política estricta.`
  if (avisoCodigo.value && !nota.value.trim()) return "Escribe la nota que pide el aviso."
  return undefined
})
const verbo = computed(() => {
  if (!concepto.value || !tanque.value || !lts.value)
    return direccion.value === "entrada" ? "Registrar entrada" : "Registrar salida"
  const n = concepto.value.name.toLowerCase()
  return direccion.value === "salida"
    ? `Sacar ${litros(lts.value)} de ${tanque.value.tanque} (${n})`
    : concepto.value.creates_lot
      ? `Registrar ${n} de ${litros(lts.value)} en ${tanque.value.tanque}`
      : origenSel.value
        ? `Unir ${litros(lts.value)} de ${origenSel.value.etiqueta.split(" · ")[1]} en ${tanque.value.tanque}`
        : `Registrar ${litros(lts.value)} de ${n} en ${tanque.value.tanque}`
})
async function guardar() {
  if (motivo.value || ocupado.value || !concepto.value || !tanque.value) return
  ocupado.value = true
  error.value = null
  try {
    const provNombre =
      proveedorNombre.value.trim() ||
      datos.value?.proveedores.find((p) => p.id === proveedorId.value)?.name ||
      ""
    await registrarMovimiento(org.value, {
      concepto: concepto.value.id,
      tanque: tanque.value.resource_id,
      litros: lts.value as number,
      lote: !concepto.value.creates_lot && lote.value ? lote.value.lot_id : null,
      lote_origen: origenSel.value?.lot_id ?? null,
      recurso_origen: origenSel.value?.resource_id ?? null,
      resultado_l: campos.value?.resultado ? resultadoL.value : null,
      resultado_abv: campos.value?.resultado ? resultadoAbv.value : null,
      abv:
        direccion.value === "entrada"
          ? (abvEntra.value ?? (concepto.value.creates_lot ? resultadoAbv.value : null))
          : null,
      decision: campos.value?.decision ? decision.value : null,
      folio_nuevo: folioNuevo.value,
      contraparte: contraparte.value || provNombre,
      documento: documento.value,
      proveedor: proveedorId.value || null,
      proveedor_nombre: proveedorNombre.value,
      folio_certificado: folioCert.value,
      organismo: organismo.value,
      especie: especieId.value || null,
      predio_declarado: predio.value,
      nota: nota.value,
      occurred_at: cuando.value,
    })
    const extra = dif.value
      ? ` El sistema registró una diferencia de ${dif.value > 0 ? "+" : ""}${fmt(dif.value)} L.`
      : ""
    router.push(
      `/e/${slug.value}/granel/${tanque.value.resource_id}?aviso=${encodeURIComponent(`Registrado: ${verbo.value.replace(/^(Registrar|Sacar|Unir)\s/, (m) => m.toLowerCase())}.${extra}`)}`,
    )
  } catch (e) {
    if (e instanceof ErrorGranel && e.rpc.codigo === "NOTA")
      avisoServidor.value = e.rpc.requiereNota ?? "diferencia_volumen"
    else error.value = e instanceof ErrorGranel || e instanceof ErrorAcceso ? e.message : String(e)
  } finally {
    ocupado.value = false
  }
}
const opLotes = computed(() =>
  (tanque.value?.lotes ?? []).map((l) => ({
    valor: l.lot_id,
    etiqueta: `${l.folio} · ${litros(l.litros)}${l.abv !== null ? ` a ${l.abv} %` : ""}`,
  })),
)
const opOrigenes = computed(() => [
  { valor: "", etiqueta: campos.value?.origen === "requerido" ? "Elige…" : "Sin lote de origen" },
  ...origenes.value.map((o) => ({ valor: o.id, etiqueta: o.etiqueta })),
])
const opProveedores = computed(() => [
  { valor: "", etiqueta: "Otro (escribir)" },
  ...(datos.value?.proveedores ?? []).map((p) => ({ valor: p.id, etiqueta: p.name })),
])
const opEspecies = computed(() => [
  { valor: "", etiqueta: "—" },
  ...(datos.value?.especies ?? []).map((e) => ({ valor: e.id, etiqueta: e.common_name })),
])
const sugerido = computed(() => (tanque.value ? folioSugerido(tanque.value.lotes) : null))
</script>

<template>
  <div class="mv">
    <div class="mv__cuerpo">
      <p class="mv__volver">
        <Boton intent="quiet" :to="`/e/${slug}/granel/${tanqueId}`">‹ Tanque</Boton>
      </p>
      <BloqueEstado
        v-if="!puede"
        variante="denied"
        titulo="Solo el administrador o un productor mueven granel"
        :texto="`Pídeselo a quien administra ${acceso.membresiaActual?.name ?? 'la empresa'}.`"
      >
        <Boton intent="secondary" :to="`/e/${slug}/granel`">Volver</Boton>
      </BloqueEstado>
      <div v-else-if="!datos && !errorCarga" class="mv__esqueleto" aria-busy="true"></div>
      <BloqueEstado
        v-else-if="errorCarga"
        variante="error"
        titulo="No pudimos cargar los datos"
        :texto="errorCarga"
      >
        <Boton intent="secondary" @click="cargar">Reintentar</Boton>
      </BloqueEstado>
      <BloqueEstado
        v-else-if="!tanque"
        variante="empty"
        titulo="Este tanque no existe"
        texto="El enlace no es de esta empresa."
      >
        <Boton intent="secondary" :to="`/e/${slug}/granel`">Ir a Granel</Boton>
      </BloqueEstado>

      <form v-else-if="paso === 'concepto'" class="mv__form" @submit.prevent="paso = 'datos'">
        <fieldset class="mv__grupo">
          <legend>¿Qué pasó en {{ tanque.tanque }}?</legend>
          <SegmentoOpciones
            v-model="direccion"
            etiqueta="Dirección"
            :opciones="[
              { valor: 'entrada', etiqueta: 'Entrada' },
              { valor: 'salida', etiqueta: 'Salida' },
            ]"
          />
          <div class="mv__conceptos" role="radiogroup" aria-label="Concepto">
            <button
              v-for="c in conceptos"
              :key="c.id"
              type="button"
              role="radio"
              class="mv__concepto"
              :aria-checked="c.id === conceptoId ? 'true' : 'false'"
              @click="conceptoId = c.id"
            >
              <span>{{ c.name }}</span
              ><span class="mv__comp">{{ comportamiento(c) }}</span>
            </button>
          </div>
          <p class="mv__sub">
            Los conceptos son los del catálogo de la empresa (Configuración → Catálogos).
          </p>
        </fieldset>
        <div class="mv__acciones">
          <Boton
            intent="primary"
            adapt="page-primary"
            type="submit"
            :disabled="!concepto"
            motivo-deshabilitado="Elige un concepto."
            >Siguiente</Boton
          >
          <Boton intent="secondary" :to="`/e/${slug}/granel/${tanqueId}`">Cancelar</Boton>
        </div>
      </form>

      <form v-else-if="concepto && campos" class="mv__form" @submit.prevent="guardar">
        <p class="mv__ctx">
          {{ direccion === "entrada" ? "Entrada" : "Salida" }} · <b>{{ concepto.name }}</b> ·
          {{ tanque.tanque
          }}<template v-if="lote && !concepto.creates_lot">
            · lote {{ lote.folio }} ({{ litros(lote.litros)
            }}<template v-if="lote.abv !== null"> a {{ lote.abv }} %</template>)</template
          >
          <Boton intent="quiet" @click="paso = 'concepto'">cambiar concepto</Boton>
        </p>
        <fieldset class="mv__grupo">
          <legend>{{ direccion === "entrada" ? "Cuánto entra" : "Cuánto sale" }}</legend>
          <Selector
            v-if="campos.loteAfectado"
            v-model="loteId"
            etiqueta="Lote"
            :opciones="opLotes"
            :disabled="ocupado"
          />
          <div class="mv__fila">
            <CampoNumero
              v-model="lts"
              etiqueta="Litros"
              unidad="L"
              :min="0"
              :disabled="ocupado"
              required
            />
            <CampoNumero
              v-if="direccion === 'entrada' && !campos.resultado"
              v-model="abvEntra"
              etiqueta="% Alc. de lo que entra"
              unidad="%"
              :min="0"
              :max="100"
              :disabled="ocupado"
            />
          </div>
          <p v-if="direccion === 'salida' && lote && lts" class="mv__calc">
            Quedan <b>{{ litros(Math.max(0, lote.litros - lts)) }}</b> en {{ tanque.tanque }}.
          </p>
        </fieldset>
        <fieldset v-if="campos.origen !== 'no'" class="mv__grupo">
          <legend>De dónde viene</legend>
          <Selector
            v-model="origenId"
            etiqueta="Lote de origen (y dónde está)"
            :opciones="opOrigenes"
            :disabled="ocupado"
          />
          <CampoNumero
            v-if="origenSel"
            v-model="abvEntra"
            etiqueta="% Alc. del que entra"
            unidad="%"
            :min="0"
            :max="100"
            :disabled="ocupado"
          />
        </fieldset>
        <fieldset v-if="campos.decision && sugerido" class="mv__grupo">
          <legend>Folio del lote que queda</legend>
          <SegmentoOpciones
            v-model="decision"
            etiqueta="Decisión"
            :opciones="[
              {
                valor: 'conservar',
                etiqueta: `Conservar ${sugerido.folio}`,
                ayuda: 'Sugerido: el folio del lote mayor. Se guarda el aporte de cada uno.',
              },
              {
                valor: 'renombrar',
                etiqueta: 'Renombrar (folio nuevo)',
                ayuda: 'Los dos se consumen y nace uno nuevo (origen «mezcla»).',
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
        <fieldset v-if="campos.resultado" class="mv__grupo">
          <legend>Lo que quedó (lo declaras tú; el sistema no calcula el grado)</legend>
          <div class="mv__fila">
            <CampoNumero
              v-model="resultadoL"
              etiqueta="Volumen resultante"
              unidad="L"
              :min="0"
              :disabled="ocupado"
              required
            />
            <CampoNumero
              v-model="resultadoAbv"
              etiqueta="% Alc. resultante"
              unidad="%"
              :min="0"
              :max="100"
              :disabled="ocupado"
            />
          </div>
          <CampoTexto
            v-if="campos.folioNuevo"
            v-model="folioNuevo"
            etiqueta="Folio del lote (opcional)"
            placeholder="automático (G-…)"
            :disabled="ocupado"
          />
          <p v-if="ledger !== null" class="mv__calc">
            El ledger quedaría en <b>{{ litros(ledger) }}</b> ({{ fmt(saldoLote) }} +
            {{ fmt(lts ?? 0) }}).
            <template v-if="dif === null"> Declara el volumen resultante.</template>
            <template v-else-if="dif === 0">
              Declaras {{ litros(resultadoL ?? 0) }}: cuadra.</template
            >
            <template v-else>
              Declaras {{ litros(resultadoL ?? 0) }}: el sistema registrará una diferencia de
              <b>{{ dif > 0 ? "+" : "" }}{{ fmt(dif) }} L</b>.</template
            >
          </p>
        </fieldset>
        <fieldset v-if="campos.contraparte" class="mv__grupo">
          <legend>
            {{
              campos.certificado
                ? "Proveedor (este concepto lo pide)"
                : "A quién (este concepto lo pide)"
            }}
          </legend>
          <template v-if="campos.certificado">
            <div class="mv__fila">
              <Selector
                v-model="proveedorId"
                etiqueta="Proveedor del catálogo"
                :opciones="opProveedores"
                :disabled="ocupado"
              />
              <CampoTexto
                v-if="!proveedorId"
                v-model="proveedorNombre"
                etiqueta="Nombre del proveedor"
                :disabled="ocupado"
              />
            </div>
            <CampoTexto
              v-model="documento"
              etiqueta="Documento (remisión, factura)"
              :disabled="ocupado"
            />
          </template>
          <div v-else class="mv__fila">
            <CampoTexto
              v-model="contraparte"
              etiqueta="Contraparte"
              placeholder="cliente, laboratorio…"
              :disabled="ocupado"
              required
            />
            <CampoTexto
              v-model="documento"
              etiqueta="Documento (remisión, factura, análisis)"
              :disabled="ocupado"
            />
          </div>
        </fieldset>
        <fieldset v-if="campos.certificado" class="mv__grupo">
          <legend>Certificado (opcional)</legend>
          <div class="mv__fila">
            <CampoTexto v-model="folioCert" etiqueta="Folio del certificado" :disabled="ocupado" />
            <CampoTexto v-model="organismo" etiqueta="Organismo" :disabled="ocupado" />
          </div>
          <div class="mv__fila">
            <Selector
              v-model="especieId"
              etiqueta="Especie declarada"
              :opciones="opEspecies"
              :disabled="ocupado"
            />
            <CampoTexto v-model="predio" etiqueta="Predio declarado" :disabled="ocupado" />
          </div>
          <p class="mv__sub">
            Nada bloquea si falta: el lote nace con historia «declarada» y los datos que haya.
          </p>
        </fieldset>
        <fieldset class="mv__grupo">
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
        <AvisoNota
          v-model="nota"
          :codigo="avisoCodigo"
          :detalle="
            avisoCodigo === 'diferencia_volumen' && dif
              ? `${dif > 0 ? '+' : ''}${fmt(dif)} L respecto al ledger. Se guarda igual; escribe por qué.`
              : undefined
          "
          :disabled="ocupado"
        />
        <p v-if="error" class="mv__error" role="alert">{{ error }}</p>
        <div class="mv__acciones">
          <Boton
            intent="primary"
            adapt="page-primary"
            type="submit"
            :loading="ocupado"
            :disabled="Boolean(motivo)"
            :motivo-deshabilitado="motivo"
            >{{ verbo }}</Boton
          >
          <Boton intent="secondary" :to="`/e/${slug}/granel/${tanqueId}`" :disabled="ocupado"
            >Cancelar</Boton
          >
        </div>
      </form>
    </div>
  </div>
</template>

<style scoped>
.mv__cuerpo {
  padding: var(--sp-4) var(--sp-5) var(--sp-6);
  max-width: 760px;
}
.mv__volver {
  margin: 0 0 var(--sp-2);
}
.mv__esqueleto {
  height: 240px;
  border-radius: var(--r-lg);
  background: var(--ink-100);
}
.mv__form {
  display: grid;
  gap: var(--sp-4);
}
.mv__ctx {
  margin: 0;
  font-size: 0.9375rem;
  color: var(--muted);
}
.mv__ctx b {
  color: var(--text);
}
.mv__grupo {
  margin: 0;
  padding: var(--sp-3) var(--sp-4) var(--sp-4);
  border: 1px solid var(--border);
  border-radius: var(--r-lg);
  display: grid;
  gap: var(--sp-3);
  min-width: 0;
}
.mv__grupo legend {
  padding: 0 var(--sp-1);
  font-weight: 700;
}
.mv__fila {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: var(--sp-3);
}
@media (min-width: 600px) {
  .mv__fila {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}
.mv__conceptos {
  display: grid;
  gap: var(--sp-2);
}
.mv__concepto {
  display: flex;
  flex-wrap: wrap;
  justify-content: space-between;
  align-items: center;
  gap: var(--sp-1) var(--sp-3);
  min-height: 56px;
  padding: var(--sp-2) var(--sp-3);
  border: 1px solid var(--muted);
  border-radius: var(--r-md);
  background: var(--surface);
  color: var(--text);
  font: 500 0.9375rem/1.3 var(--font);
  text-align: left;
  cursor: pointer;
}
.mv__concepto[aria-checked="true"] {
  border: 3px solid var(--ink-900);
  background: var(--ink-100);
  font-weight: 700;
}
.mv__concepto:focus-visible {
  outline: 3px solid var(--ink-900);
  outline-offset: 2px;
}
.mv__comp {
  font: 400 0.75rem/1.3 var(--font);
  color: var(--muted);
}
.mv__sub {
  margin: 0;
  font-size: 0.875rem;
  color: var(--muted);
}
.mv__calc {
  margin: 0;
  padding: var(--sp-2) var(--sp-3);
  border: 1px dashed var(--muted);
  border-radius: var(--r-md);
  font-size: 0.9375rem;
}
.mv__error {
  margin: 0;
  padding: var(--sp-2) var(--sp-3);
  border: 2px solid var(--late);
  border-radius: var(--r-md);
  font-weight: 600;
}
.mv__acciones {
  display: flex;
  flex-wrap: wrap;
  gap: var(--sp-2);
}
</style>
