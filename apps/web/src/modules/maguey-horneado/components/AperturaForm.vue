<script setup lang="ts">
import { computed, nextTick, reactive, shallowRef, useTemplateRef } from "vue"
import { AsignacionOrigenes, Boton, CampoCuando, CampoTexto, Selector } from "../../../shared/ui"
import { errorCaptura, kilos, type Apertura, type DatosMH } from "../modelo"
const props = defineProps<{ datos: DatosMH; bloqueado: boolean; ocupado: boolean; error: string }>()
const emit = defineEmits<{ guardar: [Apertura]; cancelar: [] }>()
const f = reactive({
  horno: "",
  cantidades: {} as Record<string, number | null>,
  fecha: null as string | null,
  folio: "",
  nota: "",
})
const revision = shallowRef(false),
  titulo = useTemplateRef<HTMLElement>("titulo")
const idem = crypto.randomUUID()
const lotes = computed(() =>
  props.datos.lotes.filter((l) => l.material === "maguey" && l.saldo > 0),
)
const horno = computed(() => props.datos.hornos.find((h) => h.id === f.horno))
const origenes = computed(() =>
  lotes.value.map((l) => ({
    id: l.id,
    titulo: l.folio,
    sub: `${l.contexto} · quedan ${kilos(l.saldo)}`,
    saldo: l.saldo,
    unidad: "kg" as const,
    etiqueta: `Kilos de ${l.folio}`,
  })),
)
const captura = computed<Apertura>(() => ({
  tipo: "abrir",
  idem,
  horno: f.horno,
  fecha: f.fecha,
  folio: f.folio,
  nota: f.nota,
  lotes: lotes.value
    .filter((l) => (f.cantidades[l.id] ?? 0) > 0)
    .map((l) => ({ id: l.id, kg: f.cantidades[l.id]! })),
}))
const total = computed(() => captura.value.lotes.reduce((n, l) => n + l.kg, 0))
const invalido = computed(
  () =>
    errorCaptura(captura.value) ||
    lotes.value.some((l) => {
      const n = f.cantidades[l.id] ?? 0
      return !Number.isFinite(n) || n < 0 || n > l.saldo
    }),
)
const opciones = computed(() =>
  props.datos.hornos.map((h) => ({ valor: h.id, etiqueta: h.nombre })),
)
async function revisar() {
  if (invalido.value || props.bloqueado) return
  revision.value = true
  await nextTick()
  titulo.value?.focus()
}
const formulario = useTemplateRef<HTMLFormElement>("formulario")
async function volver() {
  revision.value = false
  await nextTick()
  formulario.value?.querySelector<HTMLElement>("select")?.focus()
}
function guardar() {
  if (!invalido.value && !props.bloqueado && !props.ocupado) emit("guardar", captura.value)
}
</script>
<template>
  <div class="mh-form">
    <form v-show="!revision" ref="formulario" @submit.prevent="revisar">
      <fieldset :disabled="ocupado">
        <legend>Horno</legend>
        <Selector
          v-model="f.horno"
          etiqueta="Horno"
          :opciones="opciones"
          placeholder="Elige un horno"
          required
        />
      </fieldset>
      <fieldset :disabled="ocupado">
        <legend>Maguey que entra (con kilos)</legend>
        <p>Indica kilos solo en los lotes que usarás. Vacío o cero deja el lote fuera.</p>
        <p v-if="!lotes.length">No hay maguey con saldo. Registra una recepción en Maguey.</p>
        <AsignacionOrigenes
          v-else
          v-model="f.cantidades"
          :origenes="origenes"
          :capacidad="horno?.capacidad"
          politica="libre"
          :destino="horno?.nombre"
        />
      </fieldset>
      <fieldset :disabled="ocupado">
        <legend>Cuándo y folio</legend>
        <div class="mh-fields">
          <CampoCuando v-model="f.fecha" etiqueta="¿Cuándo empezó?" /><CampoTexto
            v-model="f.folio"
            etiqueta="Folio (opcional)"
            placeholder="Automático"
          />
        </div>
      </fieldset>
      <div class="mh-actions">
        <Boton intent="primary" type="submit" :disabled="bloqueado || !!invalido"
          >Revisar {{ horno?.nombre ?? "carga" }} con {{ kilos(total) }}</Boton
        ><Boton @click="emit('cancelar')">Volver sin borrar</Boton>
      </div>
    </form>
    <section v-if="revision" class="mh-review">
      <h2 ref="titulo" tabindex="-1">Revisar carga de {{ horno?.nombre }}</h2>
      <ul>
        <li v-for="l in captura.lotes" :key="l.id">
          {{ lotes.find((o) => o.id === l.id)?.folio }} · <b>{{ kilos(l.kg) }}</b>
        </li>
      </ul>
      <p>
        <b>{{ kilos(total) }} en total</b>
      </p>
      <p>Inicio: {{ f.fecha || "ahora" }} · Folio: {{ f.folio || "automático" }}</p>
      <p>Al abrir se descuenta este maguey. Esta acción no se deshace desde Horneado.</p>
      <p v-if="error" role="alert" class="mh-error">{{ error }} El borrador se conserva.</p>
      <div class="mh-actions">
        <Boton
          intent="primary"
          :loading="ocupado"
          :disabled="bloqueado || !!invalido"
          @click="guardar"
          >Abrir {{ horno?.nombre }} con {{ kilos(total) }}</Boton
        ><Boton :disabled="ocupado" @click="volver">Volver a cantidades</Boton>
      </div>
    </section>
  </div>
</template>
