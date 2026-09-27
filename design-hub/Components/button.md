# Botón · `button`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | component · **candidate 0.2.0** · owner lima (registry) |
| Ronda de origen | `lab/acceso/r01` |
| Código | `apps/web/src/shared/ui/Boton.vue` |
| Demo real | `Components/demo/index.html#button` (construida desde el código) |
| Pruebas | `apps/web/src/shared/ui/__tests__/ui.test.ts` (5 casos) |
| Evidencia | `qa/evidence/acceso-r01/*` (aparece en todas las pantallas) |

## Para qué

La única forma de disparar una acción. Expresa **intención** (`intent`) y
**dónde vive** (`adapt`); nunca estilo. Navegar no es un botón: con `href` o
`to` renderiza `<a>` / `RouterLink`.

## Uso

- Una sola `primary` por vista; `secondary` para lo demás; `quiet` para
  acciones de texto (¿No puedes entrar?, Cerrar sesión); `danger` solo para
  lo destructivo, separada y con confirmación.
- `adapt="page-primary"` para la acción principal de una pantalla de tarea:
  en compact (<600) ocupa toda la barra inferior persistente.
- `disabled` siempre con `motivoDeshabilitado` (se lee por `aria-describedby`).
- Verbo + sustantivo en la etiqueta («Crear acceso», «Guardar contraseña»).

## Anatomía

`<button>` (o `<a>`) con texto del slot; spinner opcional a la izquierda
cuando `loading`; texto de motivo debajo cuando `disabled` con motivo.

## Variantes y estados

| Eje | Valores |
|---|---|
| `intent` | primary · secondary · quiet · danger |
| `adapt` | default · page-primary |
| estados | default · hover (solo puntero) · focus-visible (anillo 3 px `--ink-900`) · pressed · loading (`aria-busy`, spinner respeta `prefers-reduced-motion`) · disabled (`disabled` + `aria-disabled`, opacidad, sin click) |

## Comportamiento

- `click` se emite solo si no está `disabled` ni `loading`.
- Los atributos sueltos (`form`, `aria-expanded`, `aria-label`, …) llegan al
  control aunque la raíz sea un fragmento (`inheritAttrs: false`).
- Con `to` genera un `<a href>` real de vue-router (rol de enlace).

## Responsive

`page-primary`: <600 → ancho completo y 52 px de alto dentro de la barra
inferior; ≥600 → en línea, dentro del formulario.

## Accesibilidad

Target ≥ 44 px (`--tap`); foco visible; nombre = texto del slot; motivo de
deshabilitado enlazado; contraste primaria 10.0 (claro) / 6.5 (oscuro).

## API real

```ts
props: {
  intent?: "primary" | "secondary" | "quiet" | "danger"   // secondary
  adapt?: "default" | "page-primary"                        // default
  type?: "button" | "submit"                                // button
  loading?: boolean; disabled?: boolean
  motivoDeshabilitado?: string
  href?: string; to?: string
}
emits: { click: [MouseEvent] }
slots: default
```

## Implementación

Tokens: `--ink-900/700/100`, `--surface`, `--text`, `--late/--late-bg`,
`--border`, `--tap`, `--sp-*`, `--r-lg`, `--r-pill`, `--font`.
Dependencias del registry: ninguna.

## QA y ciclo de vida

viewports runtime-verified · teclado runtime-verified · touch emulado ·
zoom 200 % aproximado · contraste medido. Defectos corregidos en la ronda:
atributos no heredados (el submit no enviaba), `href` indefinido pisando
RouterLink. **Pendiente para Stable:** zoom nativo a mano, forced-colors,
harden/audit.
