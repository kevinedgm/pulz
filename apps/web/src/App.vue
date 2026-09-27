<script setup lang="ts">
// El sprite de iconos (un solo set, §13.4) se inyecta una vez; <Icono> lo
// referencia con <use href="#…">. Es un archivo estático del repo, no dato
// de usuario: v-html es seguro aquí.
import sprite from "./shared/ui/iconos.svg?raw"
</script>

<template>
  <!-- eslint-disable-next-line vue/no-v-html -- sprite estático del repo, no dato de usuario -->
  <div class="sprite" aria-hidden="true" v-html="sprite"></div>
  <router-view />
</template>

<style scoped>
.sprite {
  position: absolute;
  width: 0;
  height: 0;
  overflow: hidden;
}
</style>
