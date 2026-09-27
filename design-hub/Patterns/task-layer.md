# Capa de tarea · `task-layer`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | pattern · **candidate 0.2.0** · owner lima (registry) |
| Ronda de origen | `lab/acceso/r01` |
| Código | `apps/web/src/shared/ui/CapaTarea.vue` |
| Demo real | `Components/demo/index.html#task-layer` |
| Pruebas | `ui.test.ts` (2 casos: dialog/foco/Esc/fondo; foco vuelve al disparador) |
| Evidencia | `qa/evidence/acceso-r01/equipo-alta-*` |

## Para qué

Una tarea acotada **sobre** el contexto (la lista sigue visible detrás):
agregar persona, cambiar rol, acceso creado. Misma instancia de contenido en
todos los rangos; solo cambia la capa.

## Uso

- El consumidor decide qué hace `cerrar`: **Cerrar ≠ Cancelar**. Con datos
  escritos, Equipo pregunta «¿Descartar lo que escribiste?» antes de cerrar.
- Una primaria + Cancelar/Cerrar en el slot `acciones`.
- Sin navegación anidada dentro de la capa.

## Anatomía

`Teleport → body`: scrim (`.capa__fondo`) + `section[role=dialog]
[aria-modal=true][aria-labelledby]` con cabecera (título `h2` + botón
«Cerrar» de texto), cuerpo con scroll y pie de acciones opcional.

## Comportamiento

- Al abrir: guarda el disparador, hace `pushState` (el botón atrás cierra la
  capa antes de salir de la vista), mueve el foco al primer control.
- Tab/Shift+Tab quedan contenidos; **Esc** y clic en el scrim emiten `cerrar`.
- Al cerrar: retira el `popstate`, deshace su entrada de historial y devuelve
  el foco al disparador. Si nace abierta también entra el foco (`immediate`).

## Responsive

≥600: drawer lateral derecho `min(420px, 92vw)`, alto completo, borde
izquierdo y sombra. <600: **hoja inferior** a ancho completo, ≤92 % de alto,
radio superior `--r-2xl`, pie con área segura.

## Accesibilidad

`role=dialog` + `aria-modal`; título enlazado; foco atrapado y devuelto;
botón Cerrar 44 px; sin `outline: none` sin reemplazo.

## API real

```ts
props: { abierta: boolean; titulo: string; etiquetaCerrar?: string }  // "Cerrar"
emits: { cerrar: [] }
slots: default (cuerpo) · acciones (pie)
```

## Implementación

Tokens: `--surface`, `--text`, `--border`, `--ink-900`, `--shadow`, `--tap`,
`--sp-*`, `--r-md`, `--r-2xl`, `--font`. Dependencias: `button`.

## QA y ciclo de vida

teclado y foco runtime-verified (Playwright + pane) · viewports · touch
emulado · zoom 200 % aproximado. **Pendiente para Stable:** harden/audit.
