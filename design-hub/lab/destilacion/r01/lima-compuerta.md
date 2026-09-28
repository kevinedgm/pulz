# lima · Compuerta Candidate — ronda destilacion/r01

Evaluada el 2026-09-27 con `coco-declaracion.md`, 37 capturas de
`qa/evidence/destilacion-r01/` (8/8 corridas, escrituras reales), el e2e
offline completo de §16 (3 mediciones + 2 cortes) y Vitest 98/98. **Pasan a
`candidate` 0.2.0:** `origin-allocation`, `destilacion`. Decisión
automática per `CLAUDE.md` §4.

| Criterio | Evidencia | Resultado |
|---|---|---|
| Anatomía | corridas (abiertas / colectores / últimas), abrir con orígenes, corrida con cortes, corte por pasos, cerrar | ✔ |
| Estados | default, carga, sin alambiques, sin corridas abiertas, sin conexión (instantánea), pendiente/fallo en cola, solo lectura, abrir sin orígenes, avisos, corrida sin cortes / con cortes / cerrada, cerrar, pasos, sin colector de la clase, revisar con aviso, guardado enviado/pendiente | ✔ (sin colector de la clase, capacidad estricta y fallo de cola: por Vitest y wireframe) |
| Responsive | filas apiladas <1024; FAB solo en compact; barra del pulgar; detalle a dos columnas | ✔ |
| A11y base | radiogroup de clases, status en pasos y resultado, alert en avisos, dialog en cerrar, targets 44, foco por paso | ✔ |
| Demo | origin-allocation en el Hub; pantallas por capturas | ✔ |
| critique→polish | manual-playbook / degraded | registrado |

Hallazgos devueltos a coco durante la compuerta: ninguno abierto.

No verificado (Stable): puntas encendidas con la RPC real, varios
colectores de la misma clase, foto real de un corte, lector de pantalla,
zoom nativo, harden/audit.

Entrega a mora: `Patterns/origin-allocation.md`, `Screens/destilacion.md`;
`Screens/fermentacion.md` menciona la extracción; README; regenerar `site/`.
