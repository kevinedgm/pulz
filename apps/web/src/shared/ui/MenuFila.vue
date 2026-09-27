<script setup lang="ts">
import { nextTick, onBeforeUnmount, ref, useId, watch } from "vue"
import type { AccionFila } from "./tipos"

// Contrato: registry "row-menu". Botón "Acciones" con nombre accesible por
// fila (aria-haspopup=menu, aria-expanded) + menú de ≤4 acciones: el
// destructivo va al final, separado, con intent danger. Popover anclado en
// ≥600; hoja inferior en compact. Esc y clic fuera cierran; el foco vuelve
// al botón. Las acciones condicionales las decide el consumidor (solo pasa
// las que aplican). El sprite no tiene "⋯": el botón lleva texto.
const props = defineProps<{ acciones: AccionFila[]; nombre: string }>()
const emit = defineEmits<{ seleccionar: [id: string] }>()

const id = useId()
const abierto = ref(false)
const raiz = ref<HTMLElement | null>(null)
const boton = ref<HTMLButtonElement | null>(null)
const items = ref<HTMLButtonElement[]>([])

function abrir() {
  abierto.value = true
  nextTick(() => items.value[0]?.focus())
}
function cerrar(devolverFoco = true) {
  if (!abierto.value) return
  abierto.value = false
  if (devolverFoco) boton.value?.focus()
}
function elegir(a: AccionFila) {
  cerrar()
  emit("seleccionar", a.id)
}
function onKeydown(e: KeyboardEvent) {
  const i = items.value.findIndex((el) => el === document.activeElement)
  if (e.key === "Escape") {
    e.preventDefault()
    cerrar()
  } else if (e.key === "ArrowDown") {
    e.preventDefault()
    items.value[(i + 1) % items.value.length]?.focus()
  } else if (e.key === "ArrowUp") {
    e.preventDefault()
    items.value[(i - 1 + items.value.length) % items.value.length]?.focus()
  }
}
function onClickFuera(e: MouseEvent) {
  if (abierto.value && raiz.value && !raiz.value.contains(e.target as Node)) cerrar(false)
}
watch(abierto, (v) => {
  if (v) document.addEventListener("click", onClickFuera, true)
  else document.removeEventListener("click", onClickFuera, true)
})
onBeforeUnmount(() => document.removeEventListener("click", onClickFuera, true))
</script>

<template>
  <div ref="raiz" class="menu" @keydown="onKeydown">
    <button
      ref="boton"
      type="button"
      class="menu__boton"
      :aria-label="`Acciones para ${props.nombre}`"
      aria-haspopup="menu"
      :aria-expanded="abierto ? 'true' : 'false'"
      :aria-controls="id"
      @click="abierto ? cerrar() : abrir()"
    >
      Acciones
    </button>
    <div v-if="abierto" class="menu__fondo" @click="cerrar(false)"></div>
    <div
      v-if="abierto"
      :id="id"
      class="menu__lista"
      role="menu"
      :aria-label="`Acciones para ${props.nombre}`"
    >
      <button
        v-for="a in acciones"
        :key="a.id"
        ref="items"
        type="button"
        role="menuitem"
        class="menu__item"
        :class="{ 'menu__item--danger': a.intent === 'danger' }"
        @click="elegir(a)"
      >
        {{ a.etiqueta }}
      </button>
    </div>
  </div>
</template>

<style scoped>
.menu {
  position: relative;
  display: inline-block;
}
.menu__boton {
  min-height: var(--tap);
  padding: 0 var(--sp-3);
  border: 1px solid var(--border);
  border-radius: var(--r-md);
  background: var(--surface);
  color: var(--text);
  font: 600 0.9375rem/1 var(--font);
  cursor: pointer;
}
.menu__boton[aria-expanded="true"] {
  background: var(--ink-100);
}
.menu__boton:focus-visible,
.menu__item:focus-visible {
  outline: 3px solid var(--ink-900);
  outline-offset: 2px;
}
.menu__fondo {
  display: none;
}
.menu__lista {
  position: absolute;
  right: 0;
  top: calc(100% + var(--sp-1));
  z-index: 30;
  min-width: 220px;
  display: grid;
  gap: 2px;
  padding: var(--sp-2);
  border: 1px solid var(--border);
  border-radius: var(--r-lg);
  background: var(--surface);
  box-shadow: var(--shadow);
}
.menu__item {
  min-height: var(--tap);
  padding: 0 var(--sp-3);
  border: 0;
  border-radius: var(--r-md);
  background: transparent;
  color: var(--text);
  font: 500 0.9375rem/1 var(--font);
  text-align: left;
  cursor: pointer;
}
.menu__item:hover {
  background: var(--ink-100);
}
.menu__item--danger {
  margin-top: var(--sp-2);
  border-top: 1px solid var(--border);
  border-radius: 0 0 var(--r-md) var(--r-md);
  padding-top: var(--sp-2);
  color: var(--late);
}
.menu__item--danger:hover {
  background: var(--late-bg);
}
/* compact: hoja inferior con las mismas acciones */
@media (max-width: 599px) {
  .menu__fondo {
    display: block;
    position: fixed;
    inset: 0;
    z-index: 30;
    background: rgb(23 36 58 / 40%);
  }
  .menu__lista {
    position: fixed;
    left: 0;
    right: 0;
    top: auto;
    bottom: 0;
    z-index: 31;
    border-radius: var(--r-2xl) var(--r-2xl) 0 0;
    padding: var(--sp-4);
    padding-bottom: calc(var(--sp-4) + env(safe-area-inset-bottom));
  }
  .menu__item {
    min-height: calc(var(--tap) + var(--sp-1));
  }
}
</style>
