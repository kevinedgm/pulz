<script setup lang="ts">
import { useRouter } from "vue-router"
import { Aviso, Boton, Icono } from "../../../shared/ui"
import { useAcceso } from "../../acceso/store"

// Inicio mínimo dentro del portal: confirma dónde estás y quién eres tras
// entrar (endpoint observable del flujo 1 de la ronda acceso/r01). La
// pantalla "Inicio / hoy" real es de la Fase 4 (§13.2 #3) y pasa por kiwi.
const acceso = useAcceso()
const router = useRouter()

async function salir() {
  await acceso.cerrarSesion()
  await router.replace({ name: "portal", params: { slug: acceso.slug! } })
}
</script>

<template>
  <div class="inicio">
    <Aviso v-if="acceso.modoLectura" variante="readonly" titulo="Solo lectura."
      >La suscripción venció: puedes consultar y exportar, no registrar.</Aviso
    >
    <main class="inicio__cuerpo">
      <p class="inicio__empresa">
        <Icono nombre="pulz-mark" :size="20" /> {{ acceso.membresiaActual?.name }}
      </p>
      <h1 class="inicio__titulo">Hoy</h1>
      <p class="inicio__texto">
        Entraste como <strong>{{ acceso.membresiaActual?.username ?? "titular" }}</strong> ({{
          acceso.membresiaActual?.role
        }}). Las pantallas de trabajo llegan en la siguiente fase.
      </p>
      <nav class="inicio__acciones" aria-label="Configuración">
        <Boton v-if="acceso.esAdmin" intent="secondary" :to="`/e/${acceso.slug}/equipo`"
          >Equipo</Boton
        >
        <Boton intent="quiet" @click="salir">Cerrar sesión</Boton>
      </nav>
    </main>
  </div>
</template>

<style scoped>
.inicio {
  min-height: 100vh;
  background: var(--canvas);
  color: var(--text);
}
.inicio__cuerpo {
  max-width: 720px;
  margin: 0 auto;
  padding: var(--sp-6) var(--sp-4);
  display: grid;
  gap: var(--sp-3);
}
.inicio__empresa {
  margin: 0;
  display: flex;
  align-items: center;
  gap: var(--sp-2);
  font-weight: 600;
  color: var(--ink-900);
}
.inicio__titulo {
  margin: 0;
  font: 700 1.75rem/1.2 var(--font);
}
.inicio__texto {
  margin: 0;
  color: var(--muted);
}
.inicio__acciones {
  display: flex;
  gap: var(--sp-3);
  flex-wrap: wrap;
  margin-top: var(--sp-3);
}
</style>
