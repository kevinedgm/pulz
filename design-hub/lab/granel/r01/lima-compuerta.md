# lima · Compuerta Candidate — ronda granel/r01

Evaluada el 2026-09-27 con `coco-declaracion.md`, 36 capturas de
`qa/evidence/granel-r01/` (8/8 corridas, escrituras reales tras `db reset`)
y Vitest 107/107. **`granel` pasa a `candidate` 0.2.0.** Decisión
automática per `CLAUDE.md` §4.

| Criterio | Evidencia | Resultado |
|---|---|---|
| Anatomía | tanques con grado vigente, tanque con historial, movimiento por concepto, transferir | ✔ |
| Estados | default, carga, sin tanques, vacíos, sin conexión, operador, historial, elegir concepto, formularios por concepto, diferencia conocida antes, contraparte obligatoria, capacidad, error, registrado | ✔ (compra y unión con renombrar: por Vitest y tipos) |
| Responsive | tarjetas 1 col <1024 / 2 col ≥1024; historial apilado; sin FAB | ✔ |
| A11y base | radiogroup de conceptos, alert en avisos, botones que dicen lo que harán, targets 44 | ✔ |
| critique→polish | manual-playbook / degraded | registrado |

Hallazgos devueltos a coco: dos corregidos en la ronda (etiqueta del botón
de transferir; contraparte en el historial).

No verificado (Stable): compra real con certificado, unión con renombrar,
operador real, lector de pantalla, zoom nativo, harden/audit.

Entrega a mora: `Screens/granel.md` (ya escrita contra el código), README,
sitio regenerado.
