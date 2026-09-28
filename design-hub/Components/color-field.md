# Campo de color · `color-field`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | component · **candidate 0.2.0** · owner lima (registry) |
| Ronda de origen | `lab/configuracion/r01` |
| Código | `apps/web/src/shared/ui/CampoColor.vue` |
| Demo real | `Components/demo/index.html#color-field` |
| Pruebas | `configuracion.test.ts` |
| Evidencia | `qa/evidence/configuracion-r01/portal-*` |

## Para qué
Solo el **color de acento de la empresa** (`organizations.brand_color`). La interfaz nunca lo pone detrás de texto (perfil, ley de color).

## Anatomía y estados
`input[type=color]` (56×44) + hex visible y editable (`#RRGGBB`, mayúsculas automáticas, `#` automático) + ayuda/error. Estados: default · focus · error (hex inválido, validado al salir por el formulario).

## API real
```ts
props: { modelValue: string; etiqueta: string; ayuda?; error?; disabled? }
emits: { "update:modelValue": [string]; blur: [FocusEvent] }
```
Dependencias: `text-field` (contrato).
