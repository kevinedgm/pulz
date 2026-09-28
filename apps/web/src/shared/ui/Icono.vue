<script setup lang="ts">
import type { IconoNombre } from "./tipos"
import { computed } from "vue"
import {
  Sprout,
  Flame,
  Cog,
  Barrel,
  FlaskConical,
  ClipboardList,
  House,
  Ruler,
  Plus,
  Bell,
  Clock,
  Cylinder,
  GitBranch,
  SlidersHorizontal,
  Menu,
} from "@lucide/vue"

// Un solo set canónico: Lucide. El logotipo PULZ no es un icono de interfaz.
// Sin `titulo` es decorativo (aria-hidden); con `titulo` es imagen con nombre.
const props = withDefaults(
  defineProps<{
    nombre: IconoNombre
    size?: number
    titulo?: string
  }>(),
  { size: 24, titulo: undefined },
)
const iconos = {
  "i-maguey": Sprout,
  "i-horno": Flame,
  "i-molienda": Cog,
  "i-tina": Barrel,
  "i-destila": FlaskConical,
  "i-lote": ClipboardList,
  "i-home": House,
  "i-medir": Ruler,
  "i-mas": Plus,
  "i-bell": Bell,
  "i-clock": Clock,
  "i-tanque": Cylinder,
  "i-traza": GitBranch,
  "i-ajustes": SlidersHorizontal,
  "i-menu": Menu,
} satisfies Record<Exclude<IconoNombre, "pulz-mark">, unknown>
const icono = computed(() => (props.nombre === "pulz-mark" ? null : iconos[props.nombre]))
</script>

<template>
  <svg
    v-if="nombre === 'pulz-mark'"
    class="icono"
    :width="size"
    :height="size"
    :aria-hidden="titulo ? undefined : 'true'"
    :role="titulo ? 'img' : undefined"
    focusable="false"
    :aria-label="titulo"
    viewBox="0 0 96 96"
    fill="none"
    stroke="currentColor"
    stroke-linecap="round"
    stroke-linejoin="round"
  >
    <title v-if="titulo">{{ titulo }}</title>
    <circle cx="48" cy="48" r="42" stroke-width="5" />
    <path d="M18 56h14l6-16 8 32 8-40 6 24h18" stroke-width="6" />
    <path d="M48 20c-3 6-4 12-2 18" stroke-width="4" />
    <path d="M48 20c3 6 4 12 2 18" stroke-width="4" />
  </svg>
  <component
    :is="icono"
    v-else
    class="icono"
    :size="size"
    :stroke-width="2"
    :aria-hidden="titulo ? undefined : 'true'"
    :aria-label="titulo"
    :role="titulo ? 'img' : undefined"
    focusable="false"
  />
</template>

<style scoped>
.icono {
  flex: none;
  color: currentColor;
  vertical-align: middle;
}
</style>
