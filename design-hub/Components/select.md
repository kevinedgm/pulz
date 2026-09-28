# Select · `select`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | component · **candidate 0.2.0** · owner lima (registry) |
| Ronda de origen | `lab/configuracion/r01` |
| Código | `apps/web/src/shared/ui/Selector.vue` |
| Demo real | `Components/demo/index.html#select` |
| Pruebas | `shared/ui/__tests__/configuracion.test.ts` |
| Evidencia | `qa/evidence/configuracion-r01/recursos-*`, `catalogos-*` |

## Para qué
Elegir una opción entre **4 o más** (con 3 o menos, `segmented-choice`). Select nativo: en el teléfono abre la hoja del sistema.

## Anatomía y estados
`label[for]` → `select` (44 px, borde `--muted`) → ayuda **o** error (`aria-describedby`). Estados: default · focus (anillo `--ink-900`) · disabled · error (`aria-invalid`, borde `--late`). `placeholder` = opción vacía deshabilitada.

## API real
```ts
props: { modelValue: string; etiqueta: string; opciones: { valor, etiqueta, disabled? }[]; ayuda?; error?; placeholder?; disabled?; required? }
emits: { "update:modelValue": [string]; blur: [FocusEvent] }
```
Tokens: como `text-field`. Dependencias: ninguna. **Pendiente para Stable:** la hoja nativa en iOS/Android.
