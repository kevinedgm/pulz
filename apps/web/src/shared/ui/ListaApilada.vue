<script setup lang="ts">
// Contrato: registry "list-stack" (pattern). Tabla semántica en ≥1024; en
// ≤1023 cada fila se apila como tarjeta y cada celda muestra su rótulo
// (atributo data-label puesto por el consumidor). Nunca se ocultan columnas
// de datos para "caber": se apila. Acciones al final; filas ≥ 48px.
defineProps<{ resumen: string }>()
</script>

<template>
  <div class="lista">
    <table class="lista__tabla">
      <caption class="lista__resumen">
        {{
          resumen
        }}
      </caption>
      <thead class="lista__cabecera">
        <slot name="cabecera" />
      </thead>
      <tbody>
        <slot />
      </tbody>
    </table>
  </div>
</template>

<style scoped>
.lista__tabla {
  width: 100%;
  border-collapse: collapse;
  font: 400 0.9375rem/1.4 var(--font);
  color: var(--text);
}
.lista__resumen {
  position: absolute;
  width: 1px;
  height: 1px;
  overflow: hidden;
  clip: rect(0 0 0 0);
  white-space: nowrap;
}
.lista__tabla :deep(th) {
  text-align: left;
  padding: var(--sp-2) var(--sp-3);
  border-bottom: 1px solid var(--border);
  font: 600 0.75rem/1.2 var(--font);
  letter-spacing: 0.04em;
  text-transform: uppercase;
  color: var(--muted);
}
.lista__tabla :deep(td) {
  padding: var(--sp-3);
  border-bottom: 1px solid var(--border);
  vertical-align: top;
  min-height: 48px;
}
@media (max-width: 1023px) {
  .lista__cabecera {
    display: none;
  }
  .lista__tabla :deep(tr) {
    display: block;
    padding: var(--sp-2) 0;
    border-bottom: 1px solid var(--border);
  }
  .lista__tabla :deep(td) {
    display: block;
    border: 0;
    padding: 2px var(--sp-3);
    min-height: 0;
  }
  .lista__tabla :deep(td[data-label])::before {
    content: attr(data-label) " · ";
    color: var(--muted);
    font-size: 0.75rem;
  }
}
</style>
