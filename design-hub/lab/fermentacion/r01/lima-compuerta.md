# lima · Compuerta Candidate — ronda fermentacion/r01

Evaluada el 2026-09-27 con `coco-declaracion.md`, 61 capturas de
`qa/evidence/fermentacion-r01/` (8/8 corridas, escrituras reales en Cuatro
Vientos), `qa/evidence/fase5-offline/` (e2e de aceptación offline en verde)
y Vitest 90/90. **Pasan a `candidate` 0.2.0:** `big-number-field`,
`scale-choice`, `datetime-field`, `step-flow`, `soft-warning-note`,
`fermentacion`. **Extensiones aceptadas (0.3.0):** `status-chip`
(`pending`, `failed`), `banner` (`cola` con acción), `app-shell` (banner de
cola + FAB con acción). Decisión automática per `CLAUDE.md` §4.

| Criterio | Evidencia | Resultado |
|---|---|---|
| Anatomía | lista por grupos, fila de uso, detalle con KPIs y tabla, medición por pasos, revisar, formulación, capa | ✔ |
| Estados | default, carga, vacío (sin tinas en uso / sin tinas), todas medidas, sin conexión (instantánea), pendiente y fallo en cola, solo lectura, operador, detalle sin mediciones, anulada, confirmar lista/cerrar, pasos, revisar con aviso, guardada enviada/pendiente/fallo, error de dominio | ✔ (todos medidos hoy y fallo de cola: por prueba unitaria y wireframe; no provocados en Playwright) |
| Responsive | fila apilada <1024 y en línea ≥1024; FAB solo en compact; barra del pulgar en compact; detalle a dos columnas ≥1024 | ✔ |
| A11y base | radiogroup con etiqueta viva, role=status en pasos y resultado, alert en avisos, dialog en capas, targets 44/52, foco al primer control por paso, datetime-local nativo, sin color solo | ✔ |
| Demo | demos reales de las 5 piezas en el Hub; pantallas por capturas | ✔ |
| critique→polish | manual-playbook / degraded | registrado |

Hallazgos devueltos a coco durante la compuerta: ninguno abierto (el del
botón «Medir» duplicado en compact se corrigió en la ronda).

No verificado (Stable): modo completo con la RPC real desde la pantalla,
foto real por la cola, formulación real, lector de pantalla, zoom nativo,
harden/audit.

Entrega a mora: `Components/{big-number-field,scale-choice,datetime-field}.md`,
`Patterns/{step-flow,soft-warning-note}.md`, `Screens/fermentacion.md`;
actualizar `Components/status-chip.md`, `Patterns/banner.md`,
`Patterns/app-shell.md`, README; regenerar `site/`.
