# Orden de construcción para coco · granel/r01 · lima · 2026-09-27

Estructura congelada en `brief.md`, `index.html` (60 combinaciones · 0
hallazgos), `hallazgos.md`, `declaracion.md`. Aprobación automática
(`CLAUDE.md` §4).

## Clasificación y reutilización

| Pieza | Clase | Decisión |
|---|---|---|
| `granel` | product-application | **new**: `GranelPage` (tanques + colectores con mezcal), `TanquePage` (KPIs, historial con filtros por lote y persona), `MovimientoPage` (elegir concepto → formulario armado por `source_lot` / `creates_lot` / `asks_result` / `asks_counterparty`), `TransferirPage` (origen → destino → litros → % Alc. → decisión de folio), `TarjetaTanque`. Sin piezas nuevas del sistema. |
| `segmented-choice`, `select`, `number-field`, `text-field`, `datetime-field`, `soft-warning-note`, `status-chip`, `list-stack`, `row-menu`, `state-block`, `banner`, `button`, `app-shell`, `page-header` | — | **reuse** |

`granel` entra como `draft` 0.1.0 (`sourceRound: lab/granel/r01`). El
formulario por concepto es local (`MovimientoPage`): si un tercer módulo lo
necesita se extrae como patrón.

## Orden de construcción

1. **Módulo `modules/granel/`**: `api.ts` (lecturas con instantánea:
   `tanques`, `colectores_con_saldo`, `movement_concepts` activos,
   `movement_log` por recurso, proveedores y especies para la compra,
   ajustes `default_folio_decision` y `abv_warn_*`; puras con prueba:
   `camposDe(concepto)`, `ledgerEsperado`, `diferencia`, `avisosEntrada`,
   `folioSugerido`, `origenesParaUnion`; escrituras `registrarMovimiento` y
   `transferir`, directas con señal); `routes.ts` (`/e/:slug/granel`,
   `/…/granel/transferir`, `/…/granel/:tanque`, `/…/granel/:tanque/movimiento`);
   `destinos.ts` sin `proximamente` para granel; Destilación «Pasar a granel»
   → `/granel/transferir?origen=<colector>`; `data_contract`.
2. **Verificación**: `vue-tsc`, eslint, prettier, Vitest; Playwright
   `qa/evidencia-granel.mjs` (Aurelia, Cuatro Vientos, escrituras reales en la
   primera corrida: transferir 8 L del Colector mezcal al Tanque 1
   conservando G-COMPRA-01; agua 2 L en Tanque 2 declarando 343.6 L y 44.7 %
   (diferencia −0.2 L → nota); venta 10 L del Tanque 2 con contraparte;
   historial del Tanque 2 con los tres; 4 anchos × 2 temas). `db reset` al
   cerrar la fase.
3. Declaración → lima → mora (`Screens/granel.md`, README) → sitio regenerado.
