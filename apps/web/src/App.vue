<script setup lang="ts">
import { computed } from "vue"
import { useRoute } from "vue-router"
import AppShell from "./app/AppShell.vue"

// Layout por ruta (shell/r01): las rutas con meta.shell van dentro del
// shell de la app; las de acceso (portal, bienvenida, cambio, 404) no.
const route = useRoute()
const conShell = computed(() => Boolean(route.meta.shell))
</script>

<template>
  <AppShell v-if="conShell" />
  <router-view v-else />
</template>
