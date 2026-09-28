# Resultado · Fruti Squad Design Test · r02

Resultado general: **FAIL**

La evaluación es nueva. `r01` se conserva únicamente como evidencia histórica y no se aceptó como aprobación.

| Etapa | Resultado | Evidencia |
|---|---|---|
| Kiwi | **PASS** | F2 neutral validado con 0 errores y 0 avisos; geometría, estados, procedencia y matriz adaptativa están declarados. |
| Lima · contrato | **FAIL** | El contrato anterior cambió `expanded` de acción al pie a una cuadrícula de cuatro regiones. Lima rediseñó una estructura que debía permanecer congelada. |
| Coco | **FAIL** | Tipos, 5/5 tests y builds pasan, pero la revisión visual falla: en expanded la columna de acciones mide 50 px y el CTA ~103 px, invadiendo la región de métricas. Además, F3 visual queda bloqueado por foundations ausentes. |
| Lima · gate | **FAIL** | Candidate Gate no pasa. El registry se mantiene/revierte a `draft`, `qa.candidate=false`. |
| Mora | **FAIL** | No ejecutado: Mora solo puede documentar evidencia verificada posterior a un gate válido. La página de r01 no es un entregable válido de r02. |

## Dimensiones obligatorias

| Dimensión | Resultado | Motivo |
|---|---|---|
| technical | **PASS** | `vue-tsc`, Vitest, build de producción, build de preview y consola sin errores. |
| structural | **FAIL** | Deriva entre el F2 congelado y el contrato/implementación expanded. |
| visual | **FAIL** | Colisión y crowding visibles en 1024/1440; no-overflow no compensa el defecto. |
| accessibility | **PARTIAL** | Semántica, foco y 44 px comprobados; touch físico, zoom 200% y forced-colors pendientes. |
| design_system | **FAIL** | `design_system: NEW` sin fuentes normativas ni foundations mínimas aprobadas. |
| documentation | **FAIL** | Mora no es elegible; no se generó página canónica r02. |

## Comprobaciones ejecutadas

- Kiwi `check_artifact`: 0 errores, 0 avisos.
- `vue-tsc -b`: PASS.
- Vitest: 1 archivo, 5 pruebas, 5 PASS.
- Vite producción: 303 módulos, PASS.
- Vite Hub: 114 módulos, PASS.
- Runtime 390/768/1024/1440: 390 y 768 compuestos correctamente; 1024 y 1440 muestran la colisión expanded.
- Teclado: el primer `Tab` enfoca “Registrar medición” y `:focus-visible` es verdadero.
- Detector Impeccable: lista vacía; no detecta el fallo geométrico observado en runtime.

## Decisión de lifecycle

`fermentation-vat` queda en **draft**. El siguiente propietario es **Kiwi** para corregir la geometría expanded sin perder la acción; en paralelo, Lima debe inicializar/aprobar las foundations mínimas antes de autorizar un F3 visual.

## Design Hub

Mora no fue alcanzada válidamente. `design-hub/site/Components/fermentation-vat.html` existe por la ronda anterior, pero **no se muestra ni se considera página final de r02**.
