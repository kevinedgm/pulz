# Navegación inferior · `bottom-nav`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | component · **candidate 0.2.0** · owner lima (registry) |
| Ronda de origen | `lab/shell/r01` |
| Código | `apps/web/src/shared/ui/NavInferior.vue` |
| Demo real | `Components/demo/index.html#bottom-nav` (fija en el marco; en la app es `position: fixed`) |
| Pruebas | `shell.test.ts` (2 casos: 4 + Más, aria-current, aria-haspopup; oculta) |
| Evidencia | `qa/evidence/shell-r01/*-390-*`, `mas-390-*` |

## Para qué

Solo compact (<600). Ocho destinos no caben con targets de 44 px: cuatro
fijos (Inicio · Fermentación · Destilación · Granel, decisión 2026-09-27) +
**Más**, que abre una hoja con el resto (`CapaTarea`).

## Anatomía

`nav[aria-label="Navegación principal"]` fija abajo, 5 columnas iguales:
4 `RouterLink` (icono 22 px + etiqueta 11 px, dos líneas permitidas) +
`button` «Más» (`i-menu`, `aria-haspopup=dialog`, `aria-expanded`).
Padding inferior con `env(safe-area-inset-bottom)`.

## Estados

default · current (`aria-current=page`: borde 2 px + negrita) ·
focus-visible · **oculta** (`oculta`: teclado virtual abierto).

## Accesibilidad

Ítems ≥48 px; texto nunca oculto (WCAG 1.4.4; con texto al 200 % se parte
en dos líneas como último recurso); destino actual sin depender del color.

## API real

```ts
props: { items: ItemNav[]; actual: string; masAbierto?: boolean; oculta?: boolean }
emits: { mas: [] }
```

## Implementación

Tokens: `--surface`, `--border`, `--text`, `--ink-900`, `--r-md`, `--font`.
Dependencias: ninguna. Usa `i-menu` del sprite (agregado en esta ronda).

## QA y ciclo de vida

viewports runtime-verified (390, touch emulado) · zoom 200 % aproximado.
**Pendiente para Stable:** teclado virtual en dispositivo real, lector de
pantalla, harden/audit.
