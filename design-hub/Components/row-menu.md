# Menú de fila · `row-menu`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | component · **candidate 0.2.0** · owner lima (registry) |
| Ronda de origen | `lab/acceso/r01` |
| Código | `apps/web/src/shared/ui/MenuFila.vue` |
| Demo real | `Components/demo/index.html#list-stack` (dentro de la lista) |
| Pruebas | `ui.test.ts` (1 caso: nombre por fila, apertura, danger, Esc devuelve foco, selección) |
| Evidencia | `qa/evidence/acceso-r01/equipo-menu-*` |

## Para qué

Acciones secundarias de una fila sin llenarla de botones: un botón
**«Acciones»** con nombre accesible por fila y un menú de hasta 4 acciones;
la destructiva al final, separada, en `--late`.

> El contrato del registry dice «botón ‹⋯ Acciones›»; la implementación lleva
> **solo el texto «Acciones»** porque el sprite no tiene «⋯» (decisión
> 2026-09-27). Derivado a lima para alinear el texto del contrato.

## Uso

El consumidor pasa **solo las acciones que aplican** (p. ej. «Mandar enlace
nuevo» solo a invitados, «Desbloquear» solo a bloqueados). Máximo 4.

## Anatomía

`button` («Acciones», `aria-label="Acciones para {nombre}"`,
`aria-haspopup=menu`, `aria-expanded`, `aria-controls`) → `div[role=menu]`
con `button[role=menuitem]` por acción.

## Estados

closed · open (botón con fondo `--ink-100`) · focus en ítem.

## Comportamiento

- Abrir enfoca el primer ítem; ↑/↓ recorren circularmente; **Esc** cierra y
  devuelve el foco al botón; clic fuera cierra sin mover el foco.
- Elegir emite `seleccionar(id)` y cierra.

## Responsive

≥600: popover anclado a la derecha del botón (220 px, sombra). <600: **hoja
inferior** a ancho completo sobre scrim, mismas acciones, ítems de 48 px y
área segura.

## Accesibilidad

Nombre por fila; semántica `menu`/`menuitem`; foco visible; targets 44/48 px;
el destructivo se distingue por posición y separador, no solo por color.

## API real

```ts
props: {
  acciones: { id: string; etiqueta: string; intent?: "secondary" | "danger" }[]
  nombre: string      // nombre de la fila, para el aria-label
}
emits: { seleccionar: [id: string] }
```

## Implementación

Tokens: `--border`, `--surface`, `--text`, `--ink-900`, `--ink-100`, `--late`,
`--late-bg`, `--shadow`, `--tap`, `--sp-*`, `--r-md`, `--r-lg`, `--r-2xl`.
Dependencias del registry: `button` (contrato de foco/target).

## QA y ciclo de vida

teclado runtime-verified (Playwright + pane) · viewports · touch emulado ·
zoom 200 % aproximado. **Pendiente para Stable:** harden/audit.
