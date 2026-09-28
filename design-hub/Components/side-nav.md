# Menú lateral · `side-nav`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | component · **candidate 0.2.0** · owner lima (registry) |
| Ronda de origen | `lab/shell/r01` |
| Código | `apps/web/src/shared/ui/NavLateral.vue` |
| Demo real | `Components/demo/index.html#side-nav` |
| Pruebas | `shell.test.ts` (1 caso: title, aria-current, cuenta opcional, ancho) |
| Evidencia | `qa/evidence/shell-r01/*-1440-*`, `*-1024-*`, `*-768-*` |

## Para qué

Los ocho destinos de §13.1 en medium (200 px) y expanded (240 px). En
expanded lleva además la empresa arriba (dos líneas, completa en `title`) y
el bloque de cuenta al pie; en medium ninguno de los dos (la cabecera ya
muestra la empresa).

## Anatomía

`nav[aria-label="Navegación principal"]` → bloque de empresa opcional →
`ul` de `RouterLink` (icono 22 px + texto, 44 px) → botón de cuenta opcional
(`aria-haspopup=dialog`).

## Estados

default · current (`aria-current=page`: borde 2 px `--ink-900` + negrita +
fondo `--surface`) · hover (`--ink-100`) · focus-visible · scroll interno
si no cabe (texto al 200 %).

## Accesibilidad

Enlaces reales de vue-router; destino actual sin depender del color;
targets 44 px; `title` con el nombre completo de la empresa.

## API real

```ts
props: {
  items: ItemNav[]          // { id, etiqueta, icono: IconoNombre, to }
  actual: string
  empresa?: { nombre: string; iniciales: string }
  cuenta?: { nombre: string; subtitulo: string; iniciales: string }
  ancho?: "medium" | "expanded"   // expanded
}
emits: { cuenta: [] }
```

## Implementación

Tokens: `--canvas`, `--border`, `--surface`, `--text`, `--muted`,
`--ink-900/100`, `--clay-100`, `--tap`, `--sp-*`, `--r-md`, `--r-pill`,
`--font`. Dependencias: ninguna (el filtro por rol lo hace el consumidor).

## QA y ciclo de vida

viewports runtime-verified (3 roles) · teclado runtime-verified (enlaces) ·
zoom 200 % aproximado. **Pendiente para Stable:** harden/audit.
