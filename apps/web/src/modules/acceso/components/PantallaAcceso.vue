<script setup lang="ts">
import { Aviso } from "../../../shared/ui"
import { useConexion } from "../../../shared/utils/conexion"
import type { PortalBranding } from "../api"
import MarcaPortal from "./MarcaPortal.vue"

// Composición común de las pantallas sin sesión (portal, cambio obligatorio,
// bienvenida): tarjeta de 440 centrada en medium/expanded, una columna a
// sangre en compact con la acción primaria persistente abajo (slot
// "primaria"). Un solo aviso a la vez: sin conexión gana a solo lectura.
defineProps<{ portal: PortalBranding | undefined; soloLectura?: boolean }>()
const { enLinea } = useConexion()
defineExpose({ enLinea })
</script>

<template>
  <div class="pantalla">
    <Aviso v-if="!enLinea" variante="offline" titulo="Sin conexión."
      >Para entrar necesitas señal.</Aviso
    >
    <Aviso v-else-if="soloLectura" variante="readonly" titulo="Solo lectura."
      >La suscripción venció: puedes consultar y exportar, no registrar.</Aviso
    >
    <main class="pantalla__tarjeta">
      <MarcaPortal :portal="portal" />
      <div class="pantalla__cuerpo"><slot :en-linea="enLinea" /></div>
      <div v-if="$slots.primaria" class="pantalla__primaria">
        <slot name="primaria" :en-linea="enLinea" />
      </div>
      <footer v-if="$slots.pie" class="pantalla__pie"><slot name="pie" /></footer>
    </main>
  </div>
</template>

<style scoped>
.pantalla {
  min-height: 100vh;
  background: var(--canvas);
  color: var(--text);
}
.pantalla__tarjeta {
  max-width: 440px;
  margin: var(--sp-8) auto;
  padding: var(--sp-6);
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--r-2xl);
  box-shadow: var(--shadow);
  display: grid;
  grid-template-columns: minmax(0, 1fr); /* nunca más ancha que el viewport (texto al 200 %) */
  align-content: start; /* con min-height (compact) las filas no se estiran */
  gap: var(--sp-6);
}
.pantalla__cuerpo {
  display: grid;
  gap: var(--sp-4);
}
.pantalla__pie {
  text-align: center;
  font-size: 0.875rem;
  color: var(--muted);
}
@media (max-width: 599px) {
  .pantalla__tarjeta {
    max-width: none;
    margin: 0;
    padding: var(--sp-4) var(--sp-4) calc(var(--sp-10) + var(--tap) + env(safe-area-inset-bottom));
    border: 0;
    border-radius: 0;
    box-shadow: none;
    min-height: 100vh;
  }
  .pantalla__primaria {
    position: fixed;
    left: 0;
    right: 0;
    bottom: 0;
    padding: var(--sp-3) var(--sp-4) calc(var(--sp-3) + env(safe-area-inset-bottom));
    background: var(--surface);
    border-top: 1px solid var(--border);
    z-index: 5;
  }
}
</style>
