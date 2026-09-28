<script setup lang="ts">
import { computed } from "vue"

// Contrato: registry "brand-block" (sube al sistema desde
// modules/acceso/MarcaPortal: la misma pieza en el portal y en la vista
// previa de Configuración). Logo 56px o monograma, nombre en 2 líneas
// (completo en title), mensaje ≤140, línea de acento con el color de la
// empresa — solo acento, nunca detrás de texto. Sin `marca` = esqueleto.
const props = defineProps<{
  marca?: {
    nombre: string
    mensaje?: string | null
    logoUrl?: string | null
    acento?: string | null
  }
  nivel?: "h1" | "p"
}>()
const iniciales = computed(() =>
  (props.marca?.nombre ?? "")
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((p) => p[0]!.toUpperCase())
    .join(""),
)
</script>

<template>
  <header class="marca" :style="marca?.acento ? { '--acento': marca.acento } : undefined">
    <template v-if="marca">
      <img
        v-if="marca.logoUrl"
        class="marca__logo"
        :src="marca.logoUrl"
        alt=""
        width="56"
        height="56"
      />
      <span v-else class="marca__monograma" aria-hidden="true">{{ iniciales }}</span>
      <div class="marca__texto">
        <component :is="nivel ?? 'h1'" class="marca__nombre" :title="marca.nombre">{{
          marca.nombre
        }}</component>
        <p v-if="marca.mensaje" class="marca__mensaje">{{ marca.mensaje }}</p>
      </div>
    </template>
    <template v-else>
      <span class="marca__monograma marca__monograma--esqueleto" aria-hidden="true"></span>
      <div class="marca__texto" aria-busy="true">
        <span class="marca__linea" style="width: 70%"></span>
        <span class="marca__linea" style="width: 50%"></span>
      </div>
    </template>
  </header>
</template>

<style scoped>
.marca {
  --acento: var(--clay-300);
  display: flex;
  gap: var(--sp-4);
  align-items: center;
  padding-top: var(--sp-3);
  border-top: 4px solid var(--acento);
  min-width: 0;
}
.marca__logo,
.marca__monograma {
  flex: none;
  width: 56px;
  height: 56px;
  border-radius: var(--r-xl);
  object-fit: cover;
}
.marca__monograma {
  display: grid;
  place-items: center;
  background: var(--clay-100);
  color: var(--text);
  font: 700 1.25rem/1 var(--font);
  border: 1px solid var(--border);
}
.marca__monograma--esqueleto {
  background: var(--ink-100);
  border-color: transparent;
}
.marca__texto {
  min-width: 0;
  display: grid;
  gap: var(--sp-1);
}
.marca__nombre {
  margin: 0;
  font: 700 1.375rem/1.25 var(--font);
  color: var(--text);
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
.marca__mensaje {
  margin: 0;
  font-size: 0.9375rem;
  line-height: 1.4;
  color: var(--muted);
}
.marca__linea {
  display: block;
  height: 12px;
  border-radius: var(--r-sm);
  background: var(--ink-100);
}
@media (max-width: 599px) {
  .marca__nombre {
    font-size: 1.25rem;
  }
}
</style>
