<script setup lang="ts">
import { computed, onMounted, ref } from "vue"
import { useRoute, useRouter } from "vue-router"
import { ErrorAcceso } from "../../../shared/supabase/errores"
import {
  AvisoNota,
  BloqueEstado,
  Boton,
  CampoCuando,
  CampoNumero,
  CampoTexto,
  Selector,
} from "../../../shared/ui"
import { useConexion } from "../../../shared/utils/conexion"
import { useAcceso } from "../../acceso/store"
import {
  cargarUsos,
  ErrorFermentacion,
  insumos as cargarInsumos,
  litros,
  lotesCocido,
  recursosDe,
  registrarFormulacion,
  tinasLibres,
  type Insumo,
  type LoteCocido,
  type RecursoBreve,
} from "../api"

// Formulación (§4.3; ronda fermentacion/r01): agave cocido (kg) + agua +
// insumos → reparto a tinas LIBRES (una por tina, regla dura). Página, no
// capa. Admin y productor; requiere señal.
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

const cocido = ref<LoteCocido[] | null>(null)
const molinos = ref<RecursoBreve[]>([])
const insumos = ref<Insumo[]>([])
const tinas = ref<RecursoBreve[]>([])
const errorCarga = ref<string | null>(null)

const kgPor = ref<Record<string, number | null>>({})
const molino = ref("")
const agua = ref<number | null>(null)
const insumoId = ref("")
const insumoCant = ref<number | null>(null)
const litrosPor = ref<Record<string, number | null>>({})
const folioPor = ref<Record<string, string>>({})
const metodo = ref("")
const nota = ref("")
const cuando = ref<string | null>(null)
const ocupado = ref(false)
const error = ref<string | null>(null)
const avisoCodigo = ref<string | null>(null)

async function cargar() {
  errorCarga.value = null
  try {
    const usos = await cargarUsos(org.value)
    const [c, m, i, t] = await Promise.all([
      lotesCocido(org.value),
      recursosDe(org.value, "molino"),
      cargarInsumos(org.value),
      tinasLibres(org.value, usos.datos.usos),
    ])
    cocido.value = c
    molinos.value = m
    insumos.value = i
    tinas.value = t
    molino.value = m[0]?.id ?? ""
  } catch (e) {
    errorCarga.value = e instanceof Error ? e.message : String(e)
  }
}
onMounted(() => {
  if (puede.value) cargar()
})

const kgTotal = computed(() => Object.values(kgPor.value).reduce<number>((a, b) => a + (b ?? 0), 0))
const litrosTotal = computed(() =>
  Object.values(litrosPor.value).reduce<number>((a, b) => a + (b ?? 0), 0),
)
const errores = computed(() => {
  const e: string[] = []
  for (const l of cocido.value ?? []) {
    const kg = kgPor.value[l.lot_id]
    if (kg !== null && kg !== undefined && kg > l.remaining_kg)
      e.push(`${l.folio}: quedan ${l.remaining_kg} kg.`)
  }
  for (const t of tinas.value) {
    const v = litrosPor.value[t.id]
    if (v && t.capacity && v > t.capacity)
      e.push(`${t.code}: capacidad ${litros(t.capacity)} (se avisa al guardar).`)
  }
  return e
})
const valido = computed(
  () =>
    kgTotal.value > 0 &&
    litrosTotal.value > 0 &&
    (agua.value ?? 0) >= 0 &&
    !(avisoCodigo.value && !nota.value.trim()),
)
async function guardar() {
  if (!valido.value || ocupado.value) return
  ocupado.value = true
  error.value = null
  try {
    await registrarFormulacion(org.value, {
      molino: molino.value || null,
      cocido: (cocido.value ?? [])
        .filter((l) => (kgPor.value[l.lot_id] ?? 0) > 0)
        .map((l) => ({ lot_id: l.lot_id, kg: kgPor.value[l.lot_id] as number })),
      agua_l: agua.value ?? 0,
      insumos:
        insumoId.value && (insumoCant.value ?? 0) > 0
          ? [{ supply_id: insumoId.value, cantidad: insumoCant.value as number }]
          : [],
      tinas: tinas.value
        .filter((t) => (litrosPor.value[t.id] ?? 0) > 0)
        .map((t) => ({
          tina_id: t.id,
          litros: litrosPor.value[t.id] as number,
          folio: folioPor.value[t.id] || null,
        })),
      metodo: metodo.value,
      nota: nota.value,
      occurred_at: cuando.value,
    })
    router.push(`/e/${slug.value}/fermentacion?aviso=formulacion`)
  } catch (e) {
    if (e instanceof ErrorFermentacion && e.rpc.codigo === "NOTA")
      avisoCodigo.value = e.rpc.requiereNota ?? "excede_capacidad"
    else
      error.value =
        e instanceof ErrorFermentacion || e instanceof ErrorAcceso ? e.message : String(e)
  } finally {
    ocupado.value = false
  }
}
const opMolinos = computed(() => molinos.value.map((m) => ({ valor: m.id, etiqueta: m.code })))
const opInsumos = computed(() => [
  { valor: "", etiqueta: "Ninguno" },
  ...insumos.value.map((i) => ({ valor: i.id, etiqueta: i.name })),
])
</script>

<template>
  <div class="form">
    <div class="form__cuerpo">
      <p class="form__volver">
        <Boton intent="quiet" :to="`/e/${slug}/fermentacion`">‹ Fermentación</Boton>
      </p>
      <BloqueEstado
        v-if="!puede"
        variante="denied"
        titulo="Solo el administrador o un productor pueden formular"
        :texto="`Pídeselo a quien administra ${acceso.membresiaActual?.name ?? 'la empresa'}.`"
      >
        <Boton intent="secondary" :to="`/e/${slug}/fermentacion`">Volver</Boton>
      </BloqueEstado>
      <div
        v-else-if="cocido === null && !errorCarga"
        class="form__esqueleto"
        aria-busy="true"
      ></div>
      <BloqueEstado
        v-else-if="errorCarga"
        variante="error"
        titulo="No pudimos cargar los datos"
        :texto="errorCarga"
      >
        <Boton intent="secondary" @click="cargar">Reintentar</Boton>
      </BloqueEstado>
      <BloqueEstado
        v-else-if="cocido && cocido.length === 0"
        variante="empty"
        titulo="No hay agave cocido con saldo"
        texto="Cierra una horneada o registra agave cocido que ya tenías (Horneado) y vuelve aquí."
      >
        <Boton intent="secondary" :to="`/e/${slug}/horneado`">Ir a Horneado</Boton>
      </BloqueEstado>
      <BloqueEstado
        v-else-if="tinas.length === 0"
        variante="empty"
        titulo="No hay tinas libres"
        texto="Todas tienen un ciclo abierto. Cierra un ciclo (tina vaciada) o agrega tinas en Recursos."
      >
        <Boton intent="secondary" :to="`/e/${slug}/fermentacion`">Volver</Boton>
      </BloqueEstado>
      <form v-else class="form__form" @submit.prevent="guardar">
        <fieldset class="form__grupo">
          <legend>Agave cocido</legend>
          <div v-for="l in cocido" :key="l.lot_id" class="form__asig">
            <div>
              <b>{{ l.folio }}</b
              ><span class="form__sub"> · quedan {{ l.remaining_kg }} kg</span>
            </div>
            <CampoNumero
              v-model="kgPor[l.lot_id]"
              etiqueta="Kilos"
              unidad="kg"
              :min="0"
              :max="l.remaining_kg"
              :disabled="ocupado"
            />
          </div>
          <Selector
            v-if="molinos.length"
            v-model="molino"
            etiqueta="Molino"
            :opciones="opMolinos"
            :disabled="ocupado"
          />
        </fieldset>
        <fieldset class="form__grupo">
          <legend>Agua e insumos</legend>
          <div class="form__fila">
            <CampoNumero v-model="agua" etiqueta="Agua" unidad="L" :min="0" :disabled="ocupado" />
            <Selector
              v-model="insumoId"
              etiqueta="Insumo (opcional)"
              :opciones="opInsumos"
              :disabled="ocupado"
            />
          </div>
          <CampoNumero
            v-if="insumoId"
            v-model="insumoCant"
            etiqueta="Cantidad del insumo"
            :min="0"
            :disabled="ocupado"
          />
        </fieldset>
        <fieldset class="form__grupo">
          <legend>Reparto a tinas libres</legend>
          <div v-for="t in tinas" :key="t.id" class="form__asig">
            <div>
              <b>{{ t.code }}</b
              ><span v-if="t.capacity" class="form__sub"> · {{ litros(t.capacity) }} · libre</span>
            </div>
            <CampoNumero
              v-model="litrosPor[t.id]"
              etiqueta="Litros"
              unidad="L"
              :min="0"
              :disabled="ocupado"
            />
            <CampoTexto
              v-model="folioPor[t.id]"
              etiqueta="Folio (opcional)"
              placeholder="automático"
              :disabled="ocupado"
            />
          </div>
          <p class="form__sub">Total {{ litros(litrosTotal) }} · {{ kgTotal }} kg de cocido</p>
        </fieldset>
        <fieldset class="form__grupo">
          <legend>Cuándo y cómo</legend>
          <CampoCuando v-model="cuando" :disabled="ocupado" />
          <CampoTexto
            v-model="metodo"
            etiqueta="Método (opcional)"
            placeholder="Ej. tahona con mula"
            autocapitalize="sentences"
            :disabled="ocupado"
          />
          <CampoTexto
            v-if="!avisoCodigo"
            v-model="nota"
            etiqueta="Nota (opcional)"
            autocapitalize="sentences"
            :disabled="ocupado"
          />
        </fieldset>
        <AvisoNota v-model="nota" :codigo="avisoCodigo" :disabled="ocupado" />
        <ul v-if="errores.length" class="form__avisos">
          <li v-for="e in errores" :key="e">{{ e }}</li>
        </ul>
        <p v-if="error" class="form__error" role="alert">{{ error }}</p>
        <div class="form__acciones">
          <Boton
            intent="primary"
            adapt="page-primary"
            type="submit"
            :loading="ocupado"
            :disabled="!valido || !enLinea"
            :motivo-deshabilitado="
              !enLinea
                ? 'Necesitas señal para formular.'
                : !valido
                  ? 'Indica kilos de cocido y litros por tina.'
                  : undefined
            "
            >Registrar formulación</Boton
          >
          <Boton intent="secondary" :to="`/e/${slug}/fermentacion`" :disabled="ocupado"
            >Cancelar</Boton
          >
        </div>
      </form>
    </div>
  </div>
</template>

<style scoped>
.form__cuerpo {
  padding: var(--sp-4) var(--sp-5) var(--sp-6);
  max-width: 760px;
}
.form__volver {
  margin: 0 0 var(--sp-2);
}
.form__esqueleto {
  height: 240px;
  border-radius: var(--r-lg);
  background: var(--ink-100);
}
.form__form {
  display: grid;
  gap: var(--sp-4);
}
.form__grupo {
  margin: 0;
  padding: var(--sp-3) var(--sp-4) var(--sp-4);
  border: 1px solid var(--border);
  border-radius: var(--r-lg);
  display: grid;
  gap: var(--sp-3);
  min-width: 0;
}
.form__grupo legend {
  padding: 0 var(--sp-1);
  font-weight: 700;
}
.form__asig {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: var(--sp-2);
  align-items: end;
  padding-bottom: var(--sp-3);
  border-bottom: 1px solid var(--border);
}
.form__asig:last-of-type {
  border-bottom: 0;
  padding-bottom: 0;
}
.form__fila {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: var(--sp-3);
}
@media (min-width: 600px) {
  .form__asig {
    grid-template-columns: minmax(0, 1.4fr) minmax(0, 1fr) minmax(0, 1fr);
  }
  .form__fila {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}
.form__sub {
  font-size: 0.875rem;
  color: var(--muted);
  margin: 0;
}
.form__avisos {
  margin: 0;
  padding: var(--sp-2) var(--sp-4) var(--sp-2) var(--sp-6);
  border: 1px dashed var(--muted);
  border-radius: var(--r-md);
  font-size: 0.9375rem;
}
.form__error {
  margin: 0;
  padding: var(--sp-2) var(--sp-3);
  border: 2px solid var(--late);
  border-radius: var(--r-md);
  font-weight: 600;
}
.form__acciones {
  display: flex;
  flex-wrap: wrap;
  gap: var(--sp-2);
}
</style>
