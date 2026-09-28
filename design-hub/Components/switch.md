# Interruptor · `switch`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | component · **candidate 0.2.0** · owner lima (registry) |
| Ronda de origen | `lab/configuracion/r01` |
| Código | `apps/web/src/shared/ui/Interruptor.vue` |
| Demo real | `Components/demo/index.html#switch` |
| Pruebas | `configuracion.test.ts` |
| Evidencia | `qa/evidence/configuracion-r01/ajustes-*` |

## Para qué
Un booleano que se aplica **al guardar** (no inmediato). Fila: etiqueta y ayuda a la izquierda, control a la derecha.

## Anatomía y estados
`button[role=switch][aria-checked]` con pista 44×24 y punto; texto «Sí / No» al lado: el estado se lee por forma y texto, nunca solo color. Estados: off · on · focus · disabled. `prefers-reduced-motion` quita la transición.

## API real
```ts
props: { modelValue: boolean; etiqueta: string; ayuda?; disabled? }
emits: { "update:modelValue": [boolean] }
```
Dependencias: ninguna.
