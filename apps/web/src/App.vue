<script setup lang="ts">
import { computed } from "vue"
import { useRoute } from "vue-router"
import sprite from "./shared/ui/iconos.svg?raw"
import AppShell from "./app/AppShell.vue"

// El sprite de iconos (un solo set, §13.4) se inyecta una vez; <Icono> lo
// referencia con <use href="#…">. Es un archivo estático del repo, no dato
// de usuario: v-html es seguro aquí.
// Layout por ruta (shell/r01): las rutas con meta.shell van dentro del
// shell de la app; las de acceso (portal, bienvenida, cambio, 404) no.
const route = useRoute()
const conShell = computed(() => Boolean(route.meta.shell))
</script>

<template>
  <!-- eslint-disable-next-line vue/no-v-html -- sprite estático del repo, no dato de usuario -->
  <div class="sprite" aria-hidden="true" v-html="sprite"></div>
  <AppShell v-if="conShell" />
  <router-view v-else />
</template>

<style scoped>
.sprite {
  position: absolute;
  width: 0;
  height: 0;
  overflow: hidden;
}
</style>
