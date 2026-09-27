<script setup lang="ts">
import { computed } from "vue"
import { urlLogo, type PortalBranding } from "../api"

// Bloque de marca del portal (product-application, local: solo existe aquí).
// Lo único que se ve sin sesión (§7.1). El brand_color de la empresa entra
// solo como acento (franja fina y fondo del monograma) sobre superficie
// neutra: nunca detrás de texto (ley de color del perfil).
const props = defineProps<{ portal: PortalBranding | undefined }>()

const logo = computed(() => (props.portal ? urlLogo(props.portal.logo_path) : null))
const iniciales = computed(() =>
  (props.portal?.name ?? "")
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((p) => p[0]!.toUpperCase())
    .join(""),
)
</script>

<template>
  <header
    class="marca"
    :style="portal?.brand_color ? { '--acento': portal.brand_color } : undefined"
  >
    <template v-if="portal">
      <img v-if="logo" class="marca__logo" :src="logo" alt="" width="56" height="56" />
      <span v-else class="marca__monograma" aria-hidden="true">{{ iniciales }}</span>
      <div class="marca__texto">
        <h1 class="marca__nombre" :title="portal.name">{{ portal.name }}</h1>
        <p v-if="portal.welcome_message" class="marca__mensaje">{{ portal.welcome_message }}</p>
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
