<script setup lang="ts">
import { useAcceso } from "../../acceso/store"
import SoloAdmin from "../components/SoloAdmin.vue"

// Índice de Configuración (§13.2 #8; rondas shell/r01 y configuracion/r01).
const acceso = useAcceso()
const SECCIONES = [
  { r: "recursos", t: "Recursos", d: "hornos, molinos, tinas, alambiques, colectores, tanques" },
  {
    r: "catalogos",
    t: "Catálogos",
    d: "tipos, conceptos de movimiento, especies, predios, proveedores, insumos",
  },
  { r: "ajustes", t: "Ajustes", d: "mediciones, puntas, folios y rangos de aviso" },
  { r: "portal", t: "Portal y marca", d: "nombre, color, mensaje, logo y enlace del portal" },
]
</script>

<template>
  <SoloAdmin v-slot="{ slug }">
    <p class="idx__texto">Lo que define cómo trabaja {{ acceso.membresiaActual?.name }}.</p>
    <ul class="idx__lista">
      <li v-for="s in SECCIONES" :key="s.r">
        <RouterLink class="idx__item" :to="`/e/${slug}/configuracion/${s.r}`">
          <b>{{ s.t }}</b>
          <span class="idx__desc">{{ s.d }}</span>
        </RouterLink>
      </li>
      <li>
        <RouterLink class="idx__item" :to="`/e/${slug}/equipo`">
          <b>Equipo</b>
          <span class="idx__desc">quién entra y qué puede hacer</span>
        </RouterLink>
      </li>
    </ul>
  </SoloAdmin>
</template>

<style scoped>
.idx__texto {
  margin: 0 0 var(--sp-4);
  color: var(--muted);
}
.idx__lista {
  list-style: none;
  margin: 0;
  padding: 0;
  display: grid;
  gap: var(--sp-2);
  max-width: 640px;
}
.idx__item {
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
.idx__item:hover {
  border-color: var(--ink-900);
}
.idx__item:focus-visible {
  outline: 3px solid var(--ink-900);
  outline-offset: 2px;
}
.idx__desc {
  font-size: 0.875rem;
  color: var(--muted);
}
</style>
