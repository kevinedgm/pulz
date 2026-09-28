# Resultado r01 · Kiwi → Lima → Coco → Lima → Mora

**Estado final: PASS · `fermentation-vat` promovido de `draft` a `candidate`
0.2.0.** Mora fue elegible y publicó una ficha canónica nueva basada únicamente
en la ronda inmutable r01.

No se usaron `.fruti/tests/current`, resultados históricos ni la página previa
como aprobación o salida de esta ronda.

## Pipeline

| Paso | Estado | Resultado |
|---|---|---|
| Kiwi | PASS | F2 nuevo, decisiones y geometría congelada |
| Lima pre-Coco | PASS | validó F2 sin rediseñar; contrato aprobado |
| Coco | PASS | F3 implementado con PULZ Foundations canónicas |
| Lima post-Coco | PASS | Candidate Gate aprobado; Mora elegible |
| Mora | PASS | ficha, registry y sitio generado sincronizados |

## Entregables

- F2: `.fruti/tests/r01/kiwi-f2.html`
- Decisiones de Kiwi: `.fruti/tests/r01/kiwi-decisions.yaml`
- Contrato de Lima: `.fruti/tests/r01/lima-contract.yaml`
- Cumplimiento de Coco: `.fruti/tests/r01/coco-compliance.json`
- Revisión final de Lima: `.fruti/tests/r01/lima-review.yaml`
- Implementación: `apps/web/src/modules/fermentacion/components/FilaUso.vue`
- Pruebas: `apps/web/src/modules/fermentacion/__tests__/FilaUso.test.ts`
- Compliance vigente: `.fruti/reports/compliance-current.json`
- Ficha fuente de Mora: `design-hub/Components/fermentation-vat.md`
- Página generada: `design-hub/site/Components/fermentation-vat.html`
- Evidencia nueva: `design-hub/qa/evidence/fermentation-vat-immutable-r01/`

## Geometría preservada

- `GEO-CONTEXT-001`: contexto primero; región izquierda de mínimo 280 px solo
  cuando el contenedor entra en expanded.
- `GEO-METRICS-001`: temperatura, Brix y actividad como filas en compact y tres
  columnas comparables en medium/expanded.
- `GEO-ACTION-001`: CTA en footer separado, full-width en compact y alineado al
  final en medium/expanded. Nunca comparte track con las métricas.

Lima no rediseñó el F2. Coco materializó el contrato y eliminó la composición
anterior de cuatro tracks.

## Seis dimensiones

| Dimensión | Resultado | Evidencia principal |
|---|---|---|
| technical | PASS | Vitest 6/6; typecheck/build; detector 0 hallazgos; runtime sin errores/overflow |
| structural | PASS | tres decisiones GEO preservadas; CTA separado; transformaciones compact/medium/expanded |
| visual | PASS | sin collision/crowding; jerarquía, grouping, alignment, density y action dominance correctos |
| accessibility | PASS | foco y orden de teclado reales; targets 44 px; zoom nativo 200 %; contrastes AA |
| design_system | PASS | `.fruti/tokens.json` y binding canónico consumidos; sin tokens inventados ni sprite histórico |
| documentation | PASS | ficha r01, registry candidate, build del Hub, 50 páginas/0 enlaces rotos, HTTP 200 |

## Visual QA

- **Collision:** PASS. En 1440, contexto y métricas no se solapan.
- **Crowding:** PASS. Los mínimos reales son 393.3 px y 668.7 px en expanded.
- **Hierarchy:** PASS. Identidad → urgencia → métricas → acción.
- **Grouping:** PASS. Contexto, lectura y footer tienen límites funcionales.
- **Alignment:** PASS. Métricas alineadas y CTA anclado al final.
- **Density:** PASS. Compact refluye a filas; medium conserva comparación;
  expanded utiliza el espacio sin crear una cuarta columna.
- **Action dominance:** PASS. `Registrar medición` usa intención primaria; el
  menú queda secundario.
- **Responsive composition:** PASS en 1440 / 1024 / 768 / 390.
- **PULZ Foundations:** PASS. Color, tipografía, spacing, sizing, radii y
  adaptive provienen de los tokens canónicos.

## Verificaciones ejecutadas

- `kiwi check_artifact`: 0 errores, 0 avisos.
- YAML/JSON de r01 y registry parseables.
- Vitest focalizado con Node 24: 6/6.
- `vue-tsc -b && vite build`: PASS.
- `vite build --config vite.hub.config.ts`: PASS.
- detector Impeccable: 0 hallazgos.
- Playwright nuevo: 1440 / 1024 / 768 / 390, sin overflow ni errores JS.
- Teclado real: foco `Registrar medición` → `Acciones`.
- Zoom nativo 200 %: reflow sin clipping.
- Contraste: texto 16.76:1; muted 6.33:1; blanco/primary 5.15:1;
  danger-text 6.54:1.
- build del Design Hub: 47 fichas + inicio + QA + 404.
- comprobador del Hub: 50 páginas, 0 enlaces/recursos rotos.
- HTTP: ficha y demo real responden 200.

## Warnings y gaps

- No bloqueante para Candidate: falta validación en dispositivo táctil físico y
  revisión específica de `forced-colors`; quedan para Stable.
- No bloqueante de Foundations: la entrega binaria de Manrope e Instrument Serif
  sigue marcada como pendiente; la pieza consume las declaraciones canónicas con
  fallbacks explícitos.
- Stable no se intentó. Requiere harden/audit, aceptación en contexto real y una
  aprobación explícita adicional.

## Página final

`http://127.0.0.1:4321/design-hub/site/Components/fermentation-vat.html`
