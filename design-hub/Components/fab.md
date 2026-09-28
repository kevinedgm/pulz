# Botón flotante · `fab`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | component · **candidate 0.2.0** · owner lima (registry) |
| Ronda de origen | `lab/shell/r01` |
| Código | `apps/web/src/shared/ui/BotonFlotante.vue` |
| Demo real | `Components/demo/index.html#fab` |
| Pruebas | `shell.test.ts` (1 caso) |
| Evidencia | ninguna pantalla real lo usa todavía (hueco; lo definen las rondas de etapa en Fase 5) |

## Para qué

La acción principal de un destino en compact (§13.1 "acción principal como
botón flotante"). **Es la primaria**: la pantalla no muestra otra mientras
el FAB esté visible.

## Anatomía

`button` 56 px de alto, pill, `--ink-900` sobre `--surface`, texto (verbo)
con icono opcional; fijo abajo a la derecha, sobre la navegación inferior
(72 px + área segura). En ≥600 no se muestra (`display: none`).

## Estados

default · hover · focus-visible (anillo con offset 3 px) · disabled. El
shell lo oculta con capas abiertas, en solo lectura y en Inicio/Configuración.

## API real

```ts
props: { etiqueta: string; icono?: IconoNombre; disabled?: boolean }
emits: { click: [] }
```
Se declara por ruta: `meta.fab = { etiqueta, icono? }`.

## Implementación

Tokens: `--ink-900/700`, `--surface`, `--shadow`, `--sp-*`, `--r-pill`,
`--font`. Dependencias: `button` (contrato de foco/target).

## QA y ciclo de vida

Demo en el Hub y prueba de componente; **sin uso real todavía** (Fase 5).
Pendiente para Stable: verlo en una pantalla real, harden/audit.
