<script setup lang="ts">
import { onMounted, ref, watch } from "vue"
import { BloqueEstado, Boton } from "../../../shared/ui"
import { useAcceso } from "../../acceso/store"
import { tieneLotes } from "../api"

// Inicio (registry "inicio", ronda shell/r01): destino del shell. "Hoy" con
// datos reales es Fase 5 (§13.2 #3): aquí no se inventa contenido. Cuando la
// empresa no tiene lotes, ofrece el primer arranque (ronda arranque/r01).
const acceso = useAcceso()
const estado = ref<"cargando" | "sin-lotes" | "con-lotes" | "error">("cargando")

async function cargar() {
  const org = acceso.membresiaActual?.organization_id
  if (!org) return
  estado.value = "cargando"
  try {
    estado.value = (await tieneLotes(org)) ? "con-lotes" : "sin-lotes"
  } catch {
    estado.value = "error"
  }
}
onMounted(cargar)
watch(() => acceso.membresiaActual?.organization_id, cargar)
</script>

<template>
  <div class="hoy">
    <h2 class="hoy__titulo">Hoy</h2>

    <div v-if="estado === 'cargando'" class="hoy__esqueleto" aria-busy="true">
      <div v-for="n in 3" :key="n" class="hoy__tarjeta hoy__tarjeta--esqueleto"></div>
    </div>

    <BloqueEstado
      v-else-if="estado === 'error'"
      variante="error"
      titulo="No pudimos cargar tu empresa"
      texto="Revisa tu señal."
    >
      <Boton intent="secondary" @click="cargar">Reintentar</Boton>
    </BloqueEstado>

    <BloqueEstado
      v-else-if="estado === 'sin-lotes'"
      variante="empty"
      titulo="¿Qué tienes hoy?"
      texto="Dinos qué hay en tus tanques y tinas para empezar a registrar desde el día uno."
    >
      <Boton v-if="!acceso.modoLectura" intent="primary" :to="`/e/${acceso.slug}/arranque`"
        >Empezar</Boton
      >
    </BloqueEstado>

    <div v-else class="hoy__lista">
      <p class="hoy__tarjeta hoy__tarjeta--pronto">
        <b>Tinas que toca medir hoy</b><span>Fase 5 · aquí verás cuáles y a qué hora.</span>
      </p>
      <p class="hoy__tarjeta hoy__tarjeta--pronto">
        <b>Corridas abiertas y colectores con contenido</b><span>Fase 5.</span>
      </p>
      <p class="hoy__tarjeta hoy__tarjeta--pronto">
        <b>Capturas pendientes de enviar</b><span>Fase 5 · cola sin señal.</span>
      </p>
    </div>
  </div>
</template>

<style scoped>
.hoy {
  padding: var(--sp-5);
  max-width: 720px;
}
.hoy__titulo {
  margin: 0 0 var(--sp-4);
  font: 700 1.5rem/1.2 var(--font);
}
.hoy__lista,
.hoy__esqueleto {
  display: grid;
  gap: var(--sp-3);
}
.hoy__tarjeta {
  display: grid;
  gap: 2px;
  margin: 0;
  min-height: 72px;
  padding: var(--sp-4);
  border: 1px solid var(--border);
  border-radius: var(--r-lg);
  background: var(--surface);
}
.hoy__tarjeta--pronto {
  border-style: dashed;
  color: var(--muted);
}
.hoy__tarjeta--pronto b {
  color: var(--text);
}
.hoy__tarjeta--esqueleto {
  background: var(--ink-100);
  border: 0;
}
</style>
