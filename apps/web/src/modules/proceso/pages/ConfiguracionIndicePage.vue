<script setup lang="ts">
import { computed } from "vue"
import { useRoute } from "vue-router"
import { BloqueEstado, Boton } from "../../../shared/ui"
import { useAcceso } from "../../acceso/store"

// Índice provisional de Configuración (§13.2 #8) dentro del shell. La ronda
// configuracion/r01 construye las secciones; hoy solo Equipo existe. Sin
// admin → estado "sin permiso" (mismo patrón que Equipo; la base rechaza).
const acceso = useAcceso()
const route = useRoute()
const slug = computed(() => String(route.params.slug))
const SECCIONES = [
  { t: "Recursos", d: "hornos, molinos, tinas, alambiques, colectores, tanques" },
  { t: "Catálogos", d: "tipos, conceptos de movimiento, especies, predios, proveedores, insumos" },
  { t: "Ajustes", d: "mediciones, puntas, folios y rangos de aviso" },
  { t: "Portal y marca", d: "nombre, color, mensaje, logo y enlace del portal" },
]
</script>

<template>
  <div class="cfg">
    <BloqueEstado
      v-if="!acceso.esAdmin"
      variante="denied"
      titulo="Solo el administrador puede ver la configuración"
      :texto="`Pídele a quien administra ${acceso.membresiaActual?.name ?? 'la empresa'} lo que necesites cambiar.`"
    >
      <Boton intent="secondary" :to="`/e/${slug}/inicio`">Volver a Inicio</Boton>
    </BloqueEstado>
    <template v-else>
      <p class="cfg__texto">Lo que define cómo trabaja {{ acceso.membresiaActual?.name }}.</p>
      <ul class="cfg__lista">
        <li v-for="s in SECCIONES" :key="s.t" class="cfg__item cfg__item--pronto">
          <b>{{ s.t }}</b>
          <span class="cfg__desc">{{ s.d }} · próximamente</span>
        </li>
        <li>
          <RouterLink class="cfg__item" :to="`/e/${slug}/equipo`">
            <b>Equipo</b>
            <span class="cfg__desc">quién entra y qué puede hacer</span>
          </RouterLink>
        </li>
      </ul>
    </template>
  </div>
</template>

<style scoped>
.cfg {
  padding: var(--sp-5);
  max-width: 640px;
}
.cfg__texto {
  margin: 0 0 var(--sp-4);
  color: var(--muted);
}
.cfg__lista {
  list-style: none;
  margin: 0;
  padding: 0;
  display: grid;
  gap: var(--sp-2);
}
.cfg__item {
  display: grid;
  gap: 2px;
  min-height: 56px;
  padding: var(--sp-3) var(--sp-4);
  border: 1px solid var(--border);
  border-radius: var(--r-lg);
  background: var(--surface);
  color: var(--text);
  text-decoration: none;
}
a.cfg__item:hover {
  border-color: var(--ink-900);
}
a.cfg__item:focus-visible {
  outline: 3px solid var(--ink-900);
  outline-offset: 2px;
}
.cfg__item--pronto {
  border-style: dashed;
  color: var(--muted);
}
.cfg__desc {
  font-size: 0.875rem;
  color: var(--muted);
}
</style>
