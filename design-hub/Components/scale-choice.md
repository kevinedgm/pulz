# Escala de opciones · `scale-choice`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | component · **candidate 0.2.0** · owner lima (registry) |
| Ronda de origen | `lab/fermentacion/r01` |
| Código | `apps/web/src/shared/ui/EscalaOpciones.vue` |
| Demo real | `Components/demo/index.html#scale-choice` |
| Pruebas | `fermentacion-ui.test.ts` (1 caso: 6 radios, etiqueta viva, flechas, tope) |
| Evidencia | `qa/evidence/fermentacion-r01/medir-3-*` |

## Para qué

Elegir un valor entero de una escala corta con etiqueta por valor:
actividad, dulzor y acidez **1–6** (§18 #1; el tope vive en el CHECK del
esquema, aquí solo se pinta). Seis botones iguales en una fila caben en
390 px.

## Uso

`etiquetas` trae una palabra por valor («quieta … muy activa»). Para 2–3
opciones con texto usa `segmented-choice`; para más de ~7 valores, un
`select` o `number-field`.

## Anatomía

`div[role=radiogroup]` con etiqueta → fila de `button[role=radio]` (uno por
valor, `aria-label` «n · etiqueta») → `p[aria-live=polite]` con «n ·
etiqueta» del valor elegido (o «Elige un valor»).

## Estados

sin valor · elegido (borde 3 px + fondo `--ink-100` + negrita) · focus ·
disabled.

## Accesibilidad

Selección por forma, nunca solo color; flechas mueven sin salirse del rango;
`tabindex` rotativo (uno en el grupo); la leyenda se anuncia al cambiar;
targets 52 px.

## API real

```ts
props: { modelValue: number | null; etiqueta: string; etiquetas: string[]; min?: number (1); max?: number (6); disabled? }
emits: { "update:modelValue": [number | null] }
```

## Implementación

Tokens: `--surface`, `--text`, `--muted`, `--ink-900`, `--ink-100`,
`--r-md`, `--sp-*`, `--font`. Dependencias: ninguna.

## QA y ciclo de vida

viewports, teclado y touch emulado runtime-verified. **Pendiente para
Stable:** forced-colors (la selección depende de `border`/`background`).
