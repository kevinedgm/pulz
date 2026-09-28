<script setup lang="ts">
import { computed } from "vue"
import { useRouter } from "vue-router"
import { Boton, CapaTarea, ChipEstado, SegmentoOpciones } from "../shared/ui"
import { useAcceso } from "../modules/acceso/store"
import { useTema, type Tema } from "./tema"

// Cuenta (shell/r01): persona y rol, otras empresas (sin canceladas; las
// vencidas en solo lectura), tema, Equipo (admin) y Cerrar sesión.
// Reutiliza task-layer: hoja en compact, drawer en medium/expanded
// (excepción declarada por lima: no se inventa un popover).
defineProps<{ abierta: boolean }>()
const emit = defineEmits<{ cerrar: []; ir: [to: string] }>()

const acceso = useAcceso()
const router = useRouter()
const { tema, aplicarTema } = useTema()

const m = computed(() => acceso.membresiaActual)
const otras = computed(() =>
  (acceso.membresias ?? []).filter((x) => !x.cancelled && x.slug !== acceso.slug),
)
const OPCIONES_TEMA = [
  { valor: "sistema" as Tema, etiqueta: "Sistema" },
  { valor: "claro" as Tema, etiqueta: "Claro" },
  { valor: "oscuro" as Tema, etiqueta: "Oscuro" },
]

async function salir() {
  emit("cerrar")
  await acceso.cerrarSesion()
  await router.replace({ name: "portal", params: { slug: acceso.slug! } })
}
</script>

<template>
  <CapaTarea :abierta="abierta" titulo="Tu cuenta" @cerrar="emit('cerrar')">
    <div class="cta">
      <div>
        <p class="cta__nombre">{{ m?.username ?? "titular" }}</p>
        <p class="cta__sub">{{ m?.role }} · {{ m?.name }}</p>
      </div>

      <section v-if="otras.length" aria-labelledby="cta-emp">
        <h3 id="cta-emp" class="cta__h">Tus empresas</h3>
        <ul class="cta__lista">
          <li>
            <span class="cta__emp" aria-current="true">
              <b>{{ m?.name }}</b>
              <ChipEstado variante="on">actual</ChipEstado>
            </span>
          </li>
          <li v-for="o in otras" :key="o.slug">
            <a
              class="cta__emp"
              :href="`/e/${o.slug}/inicio`"
              @click.prevent="emit('ir', `/e/${o.slug}/inicio`)"
            >
              <b>{{ o.name }}</b>
              <ChipEstado v-if="o.read_only" variante="partial">solo lectura</ChipEstado>
            </a>
          </li>
        </ul>
      </section>

      <SegmentoOpciones
        :model-value="tema"
        :opciones="OPCIONES_TEMA"
        etiqueta="Tema"
        @update:model-value="aplicarTema($event)"
      />

      <div class="cta__acciones">
        <a
          v-if="acceso.esAdmin"
          class="cta__enlace"
          :href="`/e/${acceso.slug}/equipo`"
          @click.prevent="emit('ir', `/e/${acceso.slug}/equipo`)"
          >Equipo</a
        >
        <Boton intent="quiet" @click="salir">Cerrar sesión</Boton>
      </div>
    </div>
  </CapaTarea>
</template>

<style scoped>
.cta {
  display: grid;
  gap: var(--sp-5);
}
.cta__nombre {
  margin: 0;
  font: 700 1.25rem/1.2 var(--font);
}
.cta__sub {
  margin: 2px 0 0;
  color: var(--muted);
  font-size: 0.9375rem;
}
.cta__h {
  margin: 0 0 var(--sp-2);
  font: 600 0.9375rem/1.3 var(--font);
}
.cta__lista {
  list-style: none;
  margin: 0;
  padding: 0;
  display: grid;
  gap: 2px;
}
.cta__emp {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--sp-2);
  min-height: var(--tap);
  padding: 0 var(--sp-3);
  border: 2px solid transparent;
  border-radius: var(--r-md);
  color: var(--text);
  text-decoration: none;
}
.cta__emp[aria-current] {
  border-color: var(--ink-900);
}
a.cta__emp:hover {
  background: var(--ink-100);
}
a.cta__emp:focus-visible {
  outline: 3px solid var(--ink-900);
  outline-offset: 2px;
}
.cta__enlace {
  display: inline-flex;
  align-items: center;
  min-height: var(--tap);
  padding: 0 var(--sp-4);
  border: 1px solid var(--border);
  border-radius: var(--r-lg);
  color: var(--text);
  font: 600 1rem/1.2 var(--font);
  text-decoration: none;
}
.cta__enlace:hover {
  background: var(--ink-100);
}
.cta__enlace:focus-visible {
  outline: 3px solid var(--ink-900);
  outline-offset: 2px;
}
.cta__acciones {
  display: flex;
  flex-wrap: wrap;
  gap: var(--sp-2);
}
</style>
