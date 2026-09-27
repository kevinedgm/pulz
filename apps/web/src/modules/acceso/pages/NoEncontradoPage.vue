<script setup lang="ts">
import { Boton } from "../../../shared/ui"

// 404 genérico (§7.4): idéntico para empresa inexistente, cancelada, ruta
// desconocida o sesión que no pertenece al slug. Sin marca, sin pistas.
</script>

<template>
  <main class="no-encontrado">
    <h1 class="titulo">No encontramos esta página</h1>
    <p class="texto">Revisa el enlace que te compartieron.</p>
    <Boton intent="secondary" href="https://pulz.mx">Ir a pulz.mx</Boton>
  </main>
</template>

<style scoped>
.no-encontrado {
  min-height: 100vh;
  display: grid;
  place-content: center;
  justify-items: center;
  gap: var(--sp-3);
  padding: var(--sp-8) var(--sp-4);
  background: var(--canvas);
  color: var(--text);
  text-align: center;
}
.titulo {
  margin: 0;
  font: 700 1.5rem/1.25 var(--font);
}
.texto {
  margin: 0 0 var(--sp-3);
  color: var(--muted);
}
</style>
