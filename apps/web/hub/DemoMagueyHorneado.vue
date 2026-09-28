<script setup lang="ts">
import { computed, ref, shallowRef, watch } from "vue"
import { useRoute } from "vue-router"
import { Boton, NavInferior, NavLateral, Selector, CapaTarea } from "../src/shared/ui"
import SuperficieMH from "../src/modules/maguey-horneado/components/SuperficieMH.vue"
import { ejemploMH } from "../src/modules/maguey-horneado/ejemplo"
import type { CapturaMH } from "../src/modules/maguey-horneado/modelo"
const route = useRoute(),
  datos = ref(ejemploMH()),
  estado = shallowRef("normal"),
  mas = shallowRef(false),
  revision = shallowRef(0)
const destino = computed(() => (route.path.includes("maguey") ? "maguey" : "horneado"))
const items = [
  { id: "maguey", etiqueta: "Maguey", icono: "i-maguey" as const, to: "/maguey" },
  { id: "horneado", etiqueta: "Horneado", icono: "i-horno" as const, to: "/horneado" },
]
const fijos = [
  { id: "inicio", etiqueta: "Inicio", icono: "i-home" as const, to: "/fuera/inicio" },
  {
    id: "fermentacion",
    etiqueta: "Fermentación",
    icono: "i-tina" as const,
    to: "/fuera/fermentacion",
  },
  {
    id: "destilacion",
    etiqueta: "Destilación",
    icono: "i-destila" as const,
    to: "/fuera/destilacion",
  },
  { id: "granel", etiqueta: "Granel", icono: "i-tanque" as const, to: "/fuera/granel" },
]
const estados = [
  "normal",
  "vacío",
  "carga",
  "error",
  "operador",
  "sin conexión",
  "texto largo",
  "fallo de envío",
  "texto 200%",
]
watch(estado, () => {
  datos.value = ejemploMH()
  revision.value++
  if (estado.value === "vacío") {
    datos.value.lotes = []
    datos.value.horneadas = []
  }
  if (estado.value === "texto largo")
    datos.value.lotes[0].folio = "MAG-2026-09-27-TOBALA-LOMA-DEL-TORO-0001"
})
async function guardar(c: CapturaMH) {
  if (estado.value === "fallo de envío")
    throw new Error("Ejemplo: saldo actualizado por otra persona. Vuelve a revisar los kilos.")
  const id = crypto.randomUUID(),
    fecha = c.fecha || new Date().toISOString()
  if (c.tipo === "abrir") {
    for (const o of c.lotes) {
      const l = datos.value.lotes.find((l) => l.id === o.id)
      if (l) l.saldo -= o.kg
    }
    datos.value.horneadas.unshift({
      id,
      folio: c.folio || "HOR-NUEVA · ejemplo",
      hornoId: c.horno,
      horno: datos.value.hornos.find((h) => h.id === c.horno)?.nombre ?? "",
      estado: "abierta",
      inicio: fecha,
      fin: null,
      cargados: c.lotes.reduce((n, l) => n + l.kg, 0),
      cocidos: null,
      combustible: "",
      origenes: c.lotes
        .map((l) => `${datos.value.lotes.find((o) => o.id === l.id)?.folio} · ${l.kg} kg`)
        .join(" / "),
      quien: "Aurelia",
    })
  } else {
    if (c.tipo === "cerrar") {
      const h = datos.value.horneadas.find((h) => h.id === c.horneada)
      if (h) {
        h.estado = "cerrada"
        h.cocidos = c.kg
        h.fin = fecha
        h.combustible = c.combustible
      }
    }
    datos.value.lotes.unshift({
      id,
      folio: c.folio || `${c.tipo === "recepcion" ? "MAG" : "AC"}-NUEVO · ejemplo`,
      material: c.tipo === "recepcion" ? "maguey" : "agave_cocido",
      inicial: c.kg,
      saldo: c.kg,
      contexto:
        c.tipo === "recepcion"
          ? (datos.value.especies.find((e) => e.id === c.especie)?.nombre ??
            "Especie sin especificar")
          : c.tipo === "cocido"
            ? "Carga inicial sin historia"
            : "De horneada cerrada",
      nota: c.nota,
      cuando: fecha,
      quien: "Aurelia",
    })
  }
  return id
}
</script>
<template>
  <div class="mh-demo">
    <div class="mh-demo-controls">
      <Selector
        v-model="estado"
        etiqueta="Estado de demostración"
        :opciones="estados.map((e) => ({ valor: e, etiqueta: e }))"
      /><Boton to="/maguey">Maguey</Boton><Boton to="/horneado">Horneado</Boton>
    </div>
    <div class="mh-demo-shell" :class="{ 'mh-demo-zoom': estado === 'texto 200%' }">
      <aside>
        <NavLateral
          class="mh-navigation"
          :items="[...fijos.slice(0, 1), ...items, ...fijos.slice(1)]"
          :actual="destino"
          :empresa="{ nombre: 'Mezcal Cuatro Vientos', iniciales: 'CV' }"
        />
      </aside>
      <main class="mh-demo-body">
        <p v-if="route.path.includes('/fuera/')">
          Fin de este recorrido de demostración. El destino existente queda fuera de la ronda.
        </p>
        <SuperficieMH
          v-else
          :key="`${destino}:${revision}`"
          :datos="estado === 'carga' ? null : datos"
          :destino="destino"
          :puede="estado !== 'operador'"
          :en-linea="estado !== 'sin conexión'"
          :error-carga="estado === 'error' ? 'Ejemplo: no pudimos conectar.' : ''"
          :guardar="guardar"
          formulacion="/fuera/fermentacion"
          simulado
          @recargar="estado === 'error' && (estado = 'normal')"
        />
      </main>
    </div>
    <div class="mh-demo-bottom">
      <NavInferior :items="fijos" :actual="destino" :mas-abierto="mas" @mas="mas = true" />
    </div>
    <CapaTarea :abierta="mas" titulo="Destinos del proceso" @cerrar="mas = false"
      ><div class="mh-demo-links">
        <Boton v-for="i in items" :key="i.id" :to="i.to" @click="mas = false">{{
          i.etiqueta
        }}</Boton>
      </div></CapaTarea
    >
  </div>
</template>
<style scoped>
.mh-demo-controls {
  display: flex;
  align-items: end;
  gap: var(--space-3);
  flex-wrap: wrap;
  margin-bottom: var(--space-6);
}
.mh-demo-shell {
  display: grid;
  grid-template-columns: 240px minmax(0, 1fr);
}
.mh-demo-body {
  padding: var(--space-6);
  min-width: 0;
}
.mh-demo-bottom {
  display: none;
}
.mh-demo-links {
  display: grid;
  gap: var(--space-3);
}
@media (min-width: 600px) and (max-width: 1023px) {
  .mh-demo-shell {
    grid-template-columns: 160px minmax(0, 1fr);
  }
  .mh-demo-shell :deep(.lat) {
    width: 160px;
  }
}
@media (max-width: 599px) {
  .mh-demo-shell {
    display: block;
  }
  .mh-demo-shell > aside {
    display: none;
  }
  .mh-demo-body {
    padding: var(--space-4);
    padding-bottom: var(--space-24);
  }
  .mh-demo-bottom {
    display: block;
  }
}
/* Aproximación explícita de texto ampliado, no zoom nativo del navegador. */
.mh-demo-zoom :deep(.mh-surface) {
  font-size: 2rem;
}
.mh-demo-zoom :deep(.mh-surface input),
.mh-demo-zoom :deep(.mh-surface button),
.mh-demo-zoom :deep(.mh-surface label) {
  font-size: 2rem;
}
</style>
