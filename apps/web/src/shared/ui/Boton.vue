<script setup lang="ts">
import { computed, useAttrs, useId } from "vue"
import { RouterLink } from "vue-router"
import type { BotonAdapt, BotonIntent } from "./tipos"

// Contrato: registry "button" (draft, lab/acceso/r01).
// intent decide el color; adapt decide dónde vive (page-primary = barra
// inferior persistente en compact). Sin props de estilo. href → <a>,
// to → RouterLink, si no → <button>. Nunca un botón para navegar.
const props = withDefaults(
  defineProps<{
    intent?: BotonIntent
    adapt?: BotonAdapt
    type?: "button" | "submit"
    loading?: boolean
    disabled?: boolean
    motivoDeshabilitado?: string
    href?: string
    to?: string
  }>(),
  { intent: "secondary", adapt: "default", type: "button", loading: false, disabled: false },
)
const emit = defineEmits<{ click: [MouseEvent] }>()
// La raíz es un fragmento (botón + motivo): los atributos sueltos
// (form, aria-expanded, aria-label…) se pasan a mano al control.
defineOptions({ inheritAttrs: false })
const attrs = useAttrs()

const motivoId = useId()
const inactivo = computed(() => props.disabled || props.loading)
const tag = computed(() => (props.href ? "a" : props.to ? RouterLink : "button"))
// Solo el atributo de destino que aplica: un `href` indefinido pisa el que
// RouterLink calcula y deja un <a> sin destino (sin rol de enlace).
const extra = computed(() => ({
  ...attrs,
  ...(props.href ? { href: props.href } : props.to ? { to: props.to } : {}),
}))

function onClick(e: MouseEvent) {
  if (inactivo.value) {
    e.preventDefault()
    return
  }
  emit("click", e)
}
</script>

<template>
  <component
    :is="tag"
    v-bind="extra"
    class="boton"
    :class="[`boton--${intent}`, `boton--adapt-${adapt}`, { 'boton--cargando': loading }]"
    :type="tag === 'button' ? type : undefined"
    :disabled="tag === 'button' && inactivo ? true : undefined"
    :aria-disabled="inactivo ? 'true' : undefined"
    :aria-busy="loading ? 'true' : undefined"
    :aria-describedby="disabled && motivoDeshabilitado ? motivoId : undefined"
    @click="onClick"
  >
    <span v-if="loading" class="boton__espera" aria-hidden="true"></span>
    <slot />
  </component>
  <span v-if="disabled && motivoDeshabilitado" :id="motivoId" class="boton__motivo">
    {{ motivoDeshabilitado }}
  </span>
</template>

<style scoped>
.boton {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--sp-2);
  min-height: var(--tap);
  padding: 0 var(--sp-4);
  border: 1px solid transparent;
  border-radius: var(--r-lg);
  font: 600 1rem/1.2 var(--font);
  text-decoration: none;
  cursor: pointer;
  background: var(--surface);
  color: var(--text);
}
.boton:focus-visible {
  outline: 3px solid var(--ink-900);
  outline-offset: 2px;
}
.boton--primary {
  background: var(--ink-900);
  color: var(--surface);
}
.boton--primary:hover {
  background: var(--ink-700);
}
.boton--secondary {
  border-color: var(--border);
}
.boton--secondary:hover {
  background: var(--ink-100);
}
.boton--quiet {
  background: transparent;
  color: var(--ink-900);
  text-decoration: underline;
  text-underline-offset: 3px;
  font-weight: 500;
}
.boton--danger {
  border-color: var(--late);
  color: var(--late);
}
.boton--danger:hover {
  background: var(--late-bg);
}
.boton[aria-disabled="true"] {
  opacity: 0.55;
  cursor: not-allowed;
}
.boton--cargando {
  cursor: progress;
}
.boton__espera {
  width: 1em;
  height: 1em;
  border: 2px solid currentColor;
  border-right-color: transparent;
  border-radius: var(--r-pill);
  animation: boton-gira 0.8s linear infinite;
}
@media (prefers-reduced-motion: reduce) {
  .boton__espera {
    animation: none;
    border-right-color: currentColor;
    opacity: 0.6;
  }
}
@keyframes boton-gira {
  to {
    transform: rotate(360deg);
  }
}
.boton__motivo {
  display: block;
  margin-top: var(--sp-1);
  font-size: 0.8125rem;
  color: var(--muted);
}
/* page-primary: en compact ocupa todo el ancho de la barra inferior */
@media (max-width: 599px) {
  .boton--adapt-page-primary {
    width: 100%;
    min-height: calc(var(--tap) + var(--sp-2));
  }
}
</style>
