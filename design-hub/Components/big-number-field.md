# Campo grande · `big-number-field`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | component · **candidate 0.2.0** · owner lima (registry) |
| Ronda de origen | `lab/fermentacion/r01` |
| Código | `apps/web/src/shared/ui/CampoGrande.vue` |
| Demo real | `Components/demo/index.html#big-number-field` |
| Pruebas | `fermentacion-ui.test.ts` (2 casos: número/null y coma decimal; error con `aria-invalid`) |
| Evidencia | `qa/evidence/fermentacion-r01/medir-1-*` |

## Para qué

**Un número por pantalla, con una mano** (§13.2 #4): temperatura o Brix de
una tina bajo el sol. Control de 2.75 rem centrado y tabular, teclado
decimal del teléfono, unidad y rango como texto debajo. Hereda el contrato
de `number-field`.

## Uso

Solo dentro de un paso de `step-flow` (o donde ese número sea lo único que
se captura). Para formularios normales usa `number-field`. Sin spinners; el
consumidor valida al salir y pasa `error`.

## Anatomía

`label` → `input[type=text][inputmode=decimal|numeric]` grande → `p`
«unidad · rango» (`aria-describedby`) o `p` de error.

## Estados

default · focus (borde y anillo `--ink-900`) · error (`--late`, texto con
causa) · disabled.

## Accesibilidad

Etiqueta visible enlazada; rango y error por `aria-describedby`;
`aria-invalid`; `autofocus` opcional (el flujo lo usa al entrar al paso);
tamaño en `rem` (escala al 200 %).

## API real

```ts
props: { modelValue: number | null; etiqueta: string; unidad?; rango?; error?; decimales?: boolean (true); min?; max?; disabled?; autofocus?; placeholder? }
emits: { "update:modelValue": [number | null]; blur: [FocusEvent] }
expose: { enfocar(): void }
```

## Implementación

Tokens: `--surface`, `--text`, `--muted`, `--ink-900`, `--late`, `--r-lg`,
`--sp-*`, `--font`. Dependencias: `number-field` (contrato).

## QA y ciclo de vida

viewports y teclado runtime-verified (evidencia de la ronda); touch
emulado. **Pendiente para Stable:** teclado numérico real en dispositivo;
zoom nativo.
