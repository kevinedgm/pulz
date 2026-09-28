# Campo numérico · `number-field`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | component · **candidate 0.2.0** · owner lima (registry) |
| Ronda de origen | `lab/configuracion/r01` |
| Código | `apps/web/src/shared/ui/CampoNumero.vue` |
| Demo real | `Components/demo/index.html#number-field` |
| Pruebas | `configuracion.test.ts` |
| Evidencia | `qa/evidence/configuracion-r01/ajustes-*`, `recursos-alta-*` |

## Para qué
Un número (capacidad, hora, rango) con `inputmode` decimal o numérico y la unidad como texto a la derecha. Sin spinners. El valor es `number | null`; acepta coma decimal.

## Reglas
El formulario valida rangos al salir (`blur`) y pasa `error` (p. ej. «El mínimo debe ser menor que el máximo.»). Números tabulares.

## API real
```ts
props: { modelValue: number | null; etiqueta: string; unidad?; ayuda?; error?; decimales?: boolean (true); min?; max?; disabled?; required? }
emits: { "update:modelValue": [number | null]; blur: [FocusEvent] }
```
Dependencias: `text-field` (contrato). **Pendiente para Stable:** teclado numérico real en dispositivo.
