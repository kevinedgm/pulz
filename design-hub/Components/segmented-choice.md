# Segmento de opciones · `segmented-choice`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | component · **candidate 0.2.0** · owner lima (registry) |
| Ronda de origen | `lab/acceso/r01` |
| Código | `apps/web/src/shared/ui/SegmentoOpciones.vue` |
| Demo real | `Components/demo/index.html#segmented-choice` |
| Pruebas | `ui.test.ts` (2 casos: radiogroup/ayuda, clic y flechas circulares) |
| Evidencia | `qa/evidence/acceso-r01/equipo-alta-*` |

## Para qué

2–3 opciones excluyentes con texto, como `radiogroup`. Más de 3 → `select`
nativo (no es este componente).

## Uso

Usos aprobados: **Rol** (Admin / Productor / Operador) y **¿Cómo le entregas
el acceso?** (Enlace por WhatsApp / Contraseña dictada). La opción elegida
puede mostrar una ayuda debajo (`ayuda` de la opción).

## Anatomía

`span` etiqueta (`aria-labelledby` del grupo) → `div[role=radiogroup]` con
`button[role=radio]` por opción → `p` de ayuda de la opción elegida.

## Estados

default · **selected** (`aria-checked=true`, borde 2 px `--ink-900` y fondo
`--ink-100`: forma + peso, no solo color) · focus-visible · disabled.

## Comportamiento

- Clic emite `update:modelValue`.
- Flechas ←/→ y ↑/↓ mueven la selección de forma circular y enfocan la
  opción (`tabindex` 0 solo en la elegida: un solo tab-stop).

## Responsive

Ancho completo; `n` columnas iguales. Si una etiqueta no cabe (texto al 200 %
en compact) la opción **baja de fila** en vez de recortarse (corregido en la
compuerta de lima).

## Accesibilidad

Semántica de radiogroup; targets 44 px; borde de opción `--muted`; selección
perceptible sin color.

## API real

```ts
// genérico: T extends string
props: {
  modelValue: T
  opciones: { valor: T; etiqueta: string; ayuda?: string }[]
  etiqueta: string
  disabled?: boolean
}
emits: { "update:modelValue": [T] }
```

## Implementación

Tokens: `--muted`, `--ink-900`, `--ink-100`, `--surface`, `--text`, `--tap`,
`--sp-*`, `--r-md`, `--font`. Dependencias: ninguna.

## QA y ciclo de vida

viewports runtime-verified · teclado en jsdom (aprox.) · touch emulado ·
zoom 200 % aproximado. **Pendiente para Stable:** teclado en navegador real,
harden/audit.
