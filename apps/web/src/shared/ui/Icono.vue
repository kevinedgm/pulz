<script setup lang="ts">
import type { IconoNombre } from "./tipos"

// Un solo set: el sprite iconos.svg inyectado una vez en App.vue.
// Sin `titulo` es decorativo (aria-hidden); con `titulo` es imagen con nombre.
withDefaults(
  defineProps<{
    nombre: IconoNombre
    size?: number
    titulo?: string
  }>(),
  { size: 24, titulo: undefined },
)
</script>

<template>
  <svg
    class="icono"
    :width="size"
    :height="size"
    :aria-hidden="titulo ? undefined : 'true'"
    :role="titulo ? 'img' : undefined"
    focusable="false"
  >
    <title v-if="titulo">{{ titulo }}</title>
    <use :href="`#${nombre}`" />
  </svg>
</template>

<style scoped>
.icono {
  flex: none;
  color: currentColor;
  vertical-align: middle;
}
</style>
