# Asignación de orígenes · `origin-allocation`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | pattern · **candidate 0.2.0** · owner lima (registry) |
| Ronda de origen | `lab/destilacion/r01` (extraída de la formulación de `lab/fermentacion/r01`) |
| Código | `apps/web/src/shared/ui/AsignacionOrigenes.vue` |
| Demo real | `Components/demo/index.html#origin-allocation` |
| Pruebas | `asignacion.test.ts` (2 casos: mapa de cantidades y total; bloqueo estricta / aviso flexible / error por saldo) |
| Evidencia | `qa/evidence/destilacion-r01/abrir-*`, `abrir-lleno-*`; `qa/evidence/fermentacion-r01/formular-*` |

## Para qué

Decir **de dónde sale cuánto**: agave cocido a una formulación, litros de
tinas y colectores a una corrida, maguey a una horneada. Una fila por
origen con su saldo, un campo de cantidad, el total en vivo y, si el destino
tiene capacidad, «Total N de C» con el aviso que corresponda.

## Uso

- La página decide los orígenes (`id`, título, subtítulo con lote y saldo,
  unidad) y el destino (capacidad y política). El patrón no conoce el dominio.
- Estricta y total > capacidad → `bloqueo`: la página deshabilita su
  primaria con el motivo. Flexible → `aviso = "excede_capacidad"` para
  `soft-warning-note`. Libre o sin capacidad → nada.
- Cantidad > saldo → error en la fila («Solo hay 870 L.»).

## Anatomía

`div.asig` → filas (`b` título + `span` subtítulo · `number-field`) →
`p.asig__total[aria-live=polite]`.

## Responsive

<600: título y campo apilados; ≥600: dos columnas por fila.

## Accesibilidad

Cada cantidad es un `number-field` con etiqueta («Litros»/«Kilos»); el
total se anuncia al cambiar; el bloqueo se lee en el texto (no solo borde).

## API real

```ts
props: { modelValue: Record<string, number | null>; origenes: OrigenAsignable[]; capacidad?: number | null; politica?: "estricta" | "flexible" | "libre" ("libre"); destino?: string; disabled? }
emits: { "update:modelValue": [Record<string, number | null>] }
expose: { total, bloqueo, aviso, conError }
OrigenAsignable = { id; titulo; sub?; saldo?: number | null; unidad: "L" | "kg"; etiqueta? }
```

## Implementación

Tokens: `--border`, `--muted`, `--late`, `--r-md`, `--sp-*`. Dependencias:
`number-field`.

## QA y ciclo de vida

runtime-verified (abrir corrida real con 290 L de 300; formulación en
estado vacío). **Pendiente para Stable:** horneado (kg) como tercer consumidor.
