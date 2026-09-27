<script setup lang="ts">
import { nextTick, onBeforeUnmount, ref, useId, watch } from "vue"

// Contrato: registry "task-layer" (pattern). Capa de tarea acotada sobre el
// contexto: drawer lateral derecho (420px) en ≥600 y hoja inferior (≤92% de
// alto, radio superior) en compact. MISMA instancia de contenido en ambos.
// role=dialog aria-modal; el foco entra, queda contenido y vuelve al
// disparador; Esc y atrás cierran. Cerrar ≠ Cancelar: el consumidor decide.
const props = withDefaults(
  defineProps<{ abierta: boolean; titulo: string; etiquetaCerrar?: string }>(),
  {
    etiquetaCerrar: "Cerrar",
  },
)
const emit = defineEmits<{ cerrar: [] }>()

const id = useId()
const capa = ref<HTMLElement | null>(null)
let disparador: HTMLElement | null = null

function focusables(): HTMLElement[] {
  return Array.from(
    capa.value?.querySelectorAll<HTMLElement>(
      'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])',
    ) ?? [],
  )
}
function onKeydown(e: KeyboardEvent) {
  if (e.key === "Escape") {
    e.preventDefault()
    emit("cerrar")
    return
  }
  if (e.key !== "Tab") return
  const f = focusables()
  if (!f.length) return
  const primero = f[0]
  const ultimo = f[f.length - 1]
  if (e.shiftKey && document.activeElement === primero) {
    e.preventDefault()
    ultimo.focus()
  } else if (!e.shiftKey && document.activeElement === ultimo) {
    e.preventDefault()
    primero.focus()
  }
}
function onPopstate() {
  emit("cerrar")
}

watch(
  () => props.abierta,
  async (abierta) => {
    if (abierta) {
      disparador = document.activeElement as HTMLElement | null
      history.pushState({ capa: id }, "")
      window.addEventListener("popstate", onPopstate)
      await nextTick()
      ;(focusables()[0] ?? capa.value)?.focus()
    } else {
      window.removeEventListener("popstate", onPopstate)
      if (history.state?.capa === id) history.back()
      disparador?.focus()
      disparador = null
    }
  },
  { immediate: true }, // si nace abierta, el foco también entra
)
onBeforeUnmount(() => window.removeEventListener("popstate", onPopstate))
</script>

<template>
  <Teleport to="body">
    <div v-if="abierta" class="capa" @keydown="onKeydown">
      <div class="capa__fondo" @click="emit('cerrar')"></div>
      <section
        ref="capa"
        class="capa__panel"
        role="dialog"
        aria-modal="true"
        :aria-labelledby="`${id}-titulo`"
        tabindex="-1"
      >
        <header class="capa__cabecera">
          <h2 :id="`${id}-titulo`" class="capa__titulo">{{ titulo }}</h2>
          <button type="button" class="capa__cerrar" @click="emit('cerrar')">
            {{ etiquetaCerrar }}
          </button>
        </header>
        <div class="capa__cuerpo"><slot /></div>
        <footer v-if="$slots.acciones" class="capa__acciones"><slot name="acciones" /></footer>
      </section>
    </div>
  </Teleport>
</template>

<style scoped>
.capa {
  position: fixed;
  inset: 0;
  z-index: 40;
  display: flex;
  justify-content: flex-end;
}
.capa__fondo {
  position: absolute;
  inset: 0;
  background: rgb(23 36 58 / 40%);
}
.capa__panel {
  position: relative;
  width: min(420px, 92vw);
  height: 100%;
  display: flex;
  flex-direction: column;
  background: var(--surface);
  color: var(--text);
  border-left: 1px solid var(--border);
  box-shadow: var(--shadow);
  outline: none;
}
.capa__cabecera {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--sp-3);
  padding: var(--sp-4) var(--sp-5);
  border-bottom: 1px solid var(--border);
}
.capa__titulo {
  margin: 0;
  font: 600 1.125rem/1.3 var(--font);
}
.capa__cerrar {
  min-height: var(--tap);
  padding: 0 var(--sp-3);
  border: 0;
  border-radius: var(--r-md);
  background: transparent;
  color: var(--ink-900);
  font: 600 0.9375rem/1 var(--font);
  cursor: pointer;
}
.capa__cerrar:focus-visible {
  outline: 3px solid var(--ink-900);
  outline-offset: 2px;
}
.capa__cuerpo {
  flex: 1 1 auto;
  overflow: auto;
  padding: var(--sp-5);
}
.capa__acciones {
  display: flex;
  gap: var(--sp-2);
  flex-wrap: wrap;
  padding: var(--sp-4) var(--sp-5);
  padding-bottom: calc(var(--sp-4) + env(safe-area-inset-bottom));
  border-top: 1px solid var(--border);
}
/* compact: hoja inferior, misma instancia */
@media (max-width: 599px) {
  .capa {
    align-items: flex-end;
    justify-content: stretch;
  }
  .capa__panel {
    width: 100%;
    height: auto;
    max-height: 92%;
    border-left: 0;
    border-top: 1px solid var(--border);
    border-radius: var(--r-2xl) var(--r-2xl) 0 0;
  }
}
</style>
