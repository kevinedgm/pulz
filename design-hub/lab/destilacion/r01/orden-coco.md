# Orden de construcción para coco · destilacion/r01 · lima · 2026-09-27

Estructura congelada en `brief.md`, `index.html` (66 combinaciones · 0
hallazgos), `hallazgos.md`, `declaracion.md`. Aprobación automática
(`CLAUDE.md` §4).

## Clasificación y reutilización

| Pieza | Clase | Decisión | Contrato |
|---|---|---|---|
| `origin-allocation` | pattern | **new** · `AsignacionOrigenes.vue` — **extraída** de `FormularPage` (fermentación) y reutilizada ahí | lista de orígenes (título, subtítulo con lote y saldo, unidad) con un `number-field` de cantidad por fila; total en vivo; opcional: capacidad y política del destino → texto «Total N de C» y aviso local (`estricta`: bloquea con motivo; `flexible`: código `excede_capacidad` para `soft-warning-note`); cantidad > saldo → error en la fila. `modelValue: Record<id, number\|null>`. Sin dominio: quién carga qué lo decide la página. |
| `destilacion` | product-application | **new** | ver abajo |
| `step-flow`, `big-number-field`, `datetime-field`, `soft-warning-note`, `segmented-choice`, `status-chip`, `banner`, `list-stack`, `row-menu`, `state-block`, `task-layer`, `button`, `select`, `number-field`, `text-field`, `file-picker`, `fab`, `page-header`, `app-shell` | — | **reuse** | sin cambios (`segmented-choice` con 3–4 opciones de clase: dentro de su contrato «2–3, más → select»: se acepta 4 solo con `record_puntas` porque son botones de una palabra; si molesta en 390, r02) |

Registro: `origin-allocation` y `destilacion` entran como `draft` 0.1.0
(`sourceRound: lab/destilacion/r01`).

## Orden de construcción

1. **Sistema**: `shared/ui/AsignacionOrigenes.vue` + prueba; `FormularPage`
   pasa a usarla (cocido en kg; tinas en L) sin cambiar comportamiento
   (evidencia de fermentación sigue en verde: estado vacío real).
2. **Módulo `modules/destilacion/`**: `api.ts` (lecturas con instantánea:
   `corridas`, `colectores_con_saldo`, colectores y alambiques activos,
   `tinas_en_uso`, ajustes; puras: `colectoresDeClase`, `clasesDisponibles`,
   `avisoCapacidad`, `avisosApertura`, `resumenCortes`; escrituras:
   `abrirCorrida`, `encolarCorte` (cola), `cerrarCorrida`); `routes.ts`
   (`/e/:slug/destilacion` con `fab: Abrir corrida`, `/…/abrir`,
   `/…/:corrida`, `/…/:corrida/corte`); `pages/{DestilacionPage,
   AbrirCorridaPage, CorridaPage, CortePage}.vue`; `components/{FilaCorrida,
   FilaColector, ConfirmarCierre}.vue`; `app/destinos.ts` sin `proximamente`
   en destilación; `data_contract`.
3. **Verificación**: `vue-tsc`, eslint, prettier, Vitest; `build:hub`;
   Playwright `qa/evidencia-destilacion.mjs` (Aurelia: corridas, abrir
   DES-004 REAL en Alambique 1 con 290 L de Tina 1, 3 cortes reales por la
   cola —mezcal 8 @ 51, ordinario 40 @ 24, colas 12 @ 9—, corrida con
   cortes, cerrar; 4 anchos × 2 temas); `qa/e2e-offline.mjs` extendido: con
   señal abre una corrida chica (20 L de Tina 1), en modo avión registra 3
   mediciones **y 2 cortes**, reconecta: 5 operaciones una sola vez y en
   orden. Los cortes no se anulan: quedan hasta `db reset` (declarado).
4. Declaración → lima → mora (fichas `Patterns/origin-allocation.md`,
   `Screens/destilacion.md`; `Screens/fermentacion.md` menciona la
   extracción) → sitio regenerado.
