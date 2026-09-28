# ¿Cuándo pasó? · `datetime-field`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | component · **candidate 0.2.0** · owner lima (registry) |
| Ronda de origen | `lab/fermentacion/r01` |
| Código | `apps/web/src/shared/ui/CampoCuando.vue` |
| Demo real | `Components/demo/index.html#datetime-field` |
| Pruebas | `fermentacion-ui.test.ts` (1 caso: ahora → cambiar → futuro rechazado → ahora) |
| Evidencia | `qa/evidence/fermentacion-r01/medir-1-*`, `fermentaba-*`, `cerrar-dialogo-*` |

## Para qué

Toda captura del proceso registra **cuándo pasó**, distinto de cuándo se
registró (§3, operación). Por defecto «ahora»; «cambiar» abre fecha y hora
para capturar lo de ayer o rehacer un día; nunca futuro.

## Uso

Un `datetime-field` por captura (medición, formulación, cerrar ciclo, tina
que ya fermentaba…). `null` significa «ahora al guardar»: la API pone la
hora en el momento de encolar/enviar, no al abrir la pantalla.

## Anatomía

Etiqueta → estado «ahora» + botón «cambiar» **o** `input[type=datetime-local]`
(`max` = ahora) + botón «ahora».

## Estados

ahora · elegida (texto «27 sep 2026, 08:40») · error («No puede ser en el
futuro.») · disabled.

## Accesibilidad

Control nativo del sistema (teclado y lector de pantalla del dispositivo);
`aria-labelledby`; error por `aria-describedby`; botones 44 px.

## API real

```ts
props: { modelValue: string | null; etiqueta?: string ("¿Cuándo pasó?"); disabled? }
emits: { "update:modelValue": [string | null] }   // ISO local "YYYY-MM-DDTHH:mm" o null
```

## Implementación

Tokens: `--surface`, `--text`, `--muted`, `--ink-900`, `--late`, `--r-md`,
`--r-sm`, `--sp-*`, `--font`. Dependencias: `text-field` (contrato).

## QA y ciclo de vida

viewports runtime-verified; teclado runtime-verified (Vitest). **Pendiente
para Stable:** selector nativo en iOS/Android reales.
