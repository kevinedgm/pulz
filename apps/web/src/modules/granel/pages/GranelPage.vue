<script setup lang="ts">
import { computed, onMounted, ref } from "vue"
import { useRoute, useRouter } from "vue-router"
import { haceCuanto } from "../../../shared/offline/instantanea"
import { BloqueEstado, Boton, ChipEstado } from "../../../shared/ui"
import { useConexion } from "../../../shared/utils/conexion"
import { useAcceso } from "../../acceso/store"
import { cargarGranel, cuandoCorto, litros, type DatosGranel } from "../api"
import TarjetaTanque from "../components/TarjetaTanque.vue"

// Tanques (§13.2 #6; ronda granel/r01, congelada): una tarjeta por tanque
// con saldo, lotes y grado declarado vigente; colectores con mezcal →
// «Pasar a granel». Sin FAB: la acción depende del tanque. Todo movimiento
// necesita señal; sin ella, lectura desde la instantánea.
const acceso = useAcceso()
const route = useRoute()
const router = useRouter()
const { enLinea } = useConexion()
const org = computed(() => acceso.membresiaActual?.organization_id ?? "")
const slug = computed(() => String(route.params.slug))
const rol = computed(() => acceso.membresiaActual?.role)
const puedeMover = computed(
  () => (rol.value === "admin" || rol.value === "productor") && !acceso.modoLectura,
)

const datos = ref<DatosGranel | null>(null)
const instantanea = ref<string | null>(null)
const errorCarga = ref<string | null>(null)
const aviso = ref<string | null>(typeof route.query.aviso === "string" ? route.query.aviso : null)
const totalLitros = computed(() => (datos.value?.tanques ?? []).reduce((a, t) => a + t.litros, 0))

async function cargar() {
  errorCarga.value = null
  try {
    const r = await cargarGranel(org.value)
    datos.value = r.datos
    instantanea.value = r.instantanea
  } catch (e) {
    errorCarga.value = e instanceof Error ? e.message : String(e)
  }
}
onMounted(() => {
  // Destilación llega con ?transferir=<colector>: va directo a transferir
  if (typeof route.query.transferir === "string")
    router.replace(`/e/${slug.value}/granel/transferir?origen=${route.query.transferir}`)
  else cargar()
})
</script>

<template>
  <div class="gr">
    <div class="gr__cuerpo">
      <p v-if="datos" class="gr__resumen" role="status">
        {{ datos.tanques.length }} tanque{{ datos.tanques.length === 1 ? "" : "s" }} ·
        <b>{{ litros(totalLitros) }} de granel</b>
      </p>
      <p v-if="instantanea" class="gr__instantanea">
        Datos de <b>{{ haceCuanto(instantanea) }}</b
        >. Los movimientos de granel necesitan señal.
      </p>
      <p v-if="aviso" class="gr__aviso" role="status">{{ aviso }}</p>
      <div v-if="!datos && !errorCarga" class="gr__grid" aria-busy="true">
        <div v-for="n in 2" :key="n" class="gr__esqueleto"></div>
      </div>
      <BloqueEstado
        v-else-if="errorCarga"
        variante="error"
        titulo="No pudimos cargar los tanques"
        :texto="errorCarga"
      >
        <Boton intent="secondary" @click="cargar">Reintentar</Boton>
      </BloqueEstado>
      <BloqueEstado
        v-else-if="datos && datos.tanques.length === 0"
        variante="empty"
        titulo="Tu palenque aún no tiene tanques"
        texto="Agrégalos en Configuración → Recursos; después registra lo que hay (carga inicial) o una compra."
      >
        <Boton v-if="acceso.esAdmin" intent="secondary" :to="`/e/${slug}/configuracion/recursos`"
          >Ir a Recursos</Boton
        >
      </BloqueEstado>
      <template v-else-if="datos">
        <div class="gr__grid">
          <TarjetaTanque
            v-for="t in datos.tanques"
            :key="t.resource_id"
            :tanque="t"
            :slug="slug"
            :puede-mover="puedeMover"
            :en-linea="enLinea"
          />
        </div>
        <section v-if="datos.colectores.length" class="gr__grupo">
          <h2 class="gr__titulo">Colectores con mezcal</h2>
          <ul class="gr__lista">
            <li
              v-for="c in datos.colectores"
              :key="c.resource_id + c.lot_id"
              class="gr__col"
              :aria-label="c.colector"
            >
              <div>
                <h3 class="gr__col-titulo">{{ c.colector }}</h3>
                <span class="gr__sub"
                  >{{ c.folio
                  }}<template v-if="c.capacidad_l">
                    · {{ litros(c.capacidad_l) }} de capacidad</template
                  ></span
                >
              </div>
              <div class="gr__sub">
                <b class="gr__b">{{ litros(c.litros) }}</b>
                <template v-if="c.abv !== null">
                  · {{ c.abv }} % Alc.<template v-if="c.abv_by">
                    ({{ c.abv_by }}, {{ cuandoCorto(c.abv_at) }})</template
                  ></template
                >
              </div>
              <ChipEstado variante="on">con saldo</ChipEstado>
              <div>
                <Boton
                  v-if="puedeMover"
                  intent="secondary"
                  :to="`/e/${slug}/granel/transferir?origen=${c.resource_id}`"
                  :disabled="!enLinea"
                  :motivo-deshabilitado="!enLinea ? 'Necesitas señal.' : undefined"
                  >Pasar a granel</Boton
                >
                <span v-else class="gr__sub">a granel lo pasa el productor</span>
              </div>
            </li>
          </ul>
        </section>
      </template>
    </div>
  </div>
</template>

<style scoped>
.gr__cuerpo {
  padding: var(--sp-5);
  max-width: 960px;
}
.gr__resumen {
  margin: 0 0 var(--sp-3);
  font-size: 0.875rem;
  color: var(--muted);
}
.gr__instantanea {
  margin: 0 0 var(--sp-3);
  padding: var(--sp-2) var(--sp-3);
  border: 1px dashed var(--muted);
  border-radius: var(--r-md);
  font-size: 0.9375rem;
}
.gr__aviso {
  margin: 0 0 var(--sp-3);
  padding: var(--sp-2) var(--sp-3);
  border-radius: var(--r-md);
  background: var(--ok-bg);
}
.gr__grid {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: var(--sp-3);
}
@media (min-width: 1024px) {
  .gr__grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}
.gr__esqueleto {
  height: 180px;
  border-radius: var(--r-lg);
  background: var(--ink-100);
}
.gr__grupo {
  margin: var(--sp-5) 0 0;
}
.gr__titulo {
  margin: 0 0 var(--sp-2);
  font: 600 0.75rem/1.2 var(--font);
  letter-spacing: 0.05em;
  text-transform: uppercase;
  color: var(--muted);
}
.gr__lista {
  list-style: none;
  margin: 0;
  padding: 0;
}
.gr__col {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  gap: var(--sp-2) var(--sp-3);
  align-items: center;
  padding: var(--sp-3) var(--sp-4);
  border: 1px solid var(--border);
  border-radius: var(--r-lg);
  background: var(--surface);
}
@media (min-width: 1024px) {
  .gr__col {
    grid-template-columns: minmax(0, 1.2fr) minmax(0, 1.5fr) auto auto;
  }
}
.gr__col-titulo {
  margin: 0;
  font: 700 1.0625rem/1.3 var(--font);
}
.gr__sub {
  font-size: 0.875rem;
  color: var(--muted);
}
.gr__b {
  color: var(--text);
}
</style>
