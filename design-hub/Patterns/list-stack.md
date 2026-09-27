# Lista apilada · `list-stack`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | pattern · **candidate 0.2.0** · owner lima (registry) |
| Ronda de origen | `lab/acceso/r01` |
| Código | `apps/web/src/shared/ui/ListaApilada.vue` |
| Demo real | `Components/demo/index.html#list-stack` |
| Pruebas | sin prueba de componente propia (capturas) |
| Evidencia | `qa/evidence/acceso-r01/equipo-1440-*` (tabla), `equipo-768-*`, `equipo-390-*` (apilada) |

## Para qué

Registros comparables (personas del equipo) como **tabla semántica** que en
≤1023 se apila en tarjetas con el rótulo de cada celda. Nunca se ocultan
columnas de datos para «caber».

## Uso

- El consumidor pone `data-label="…"` en cada `td` de datos; la celda de
  acciones va **sin** `data-label` (el botón ya se llama «Acciones»).
- `resumen` es el `caption` (solo para lectores de pantalla).
- Acciones al final; filas ≥ 48 px.

## Anatomía

`div.lista` → `table` → `caption` (sr-only) · `thead` (slot `cabecera`) ·
`tbody` (slot default con las filas).

## Responsive

≥1024: tabla con `th` en mayúsculas pequeñas `--muted`. ≤1023: `thead`
oculto; cada `tr` es un bloque separado por `--border`; cada `td[data-label]`
antepone «Rótulo · » en `--muted`.

## Accesibilidad

Tabla real (`th[scope=col]` los pone el consumidor), `caption` con resumen;
en modo apilado el rótulo visible viene del `data-label`.

## API real

```ts
props: { resumen: string }
slots: cabecera (fila de th) · default (filas)
```

## Implementación

Tokens: `--text`, `--muted`, `--border`, `--sp-*`, `--font`. Dependencias:
ninguna. Del contrato, la **búsqueda** existe en Equipo como filtro local
(«Buscar por nombre o usuario»); la **paginación por 50 no está
implementada**: la lista carga a todo el equipo.

## QA y ciclo de vida

Capturas en 4 anchos × 2 temas; sin desborde al 200 % en 1440/390.
**Pendiente para Stable:** listas grandes (búsqueda/paginación), texto largo
real, harden/audit.
