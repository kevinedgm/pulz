# lima · Compuerta Candidate — ronda inicio-hoy/r01

Evaluada el 2026-09-28 con `coco-declaracion.md`, 41 capturas de
`qa/evidence/inicio-hoy-r01/` (PASS tras `db reset`, medición real desde Hoy)
y Vitest 193/193. **`inicio` pasa a `candidate` 0.3.0.** Decisión automática
per `CLAUDE.md` §4.

| Criterio | Evidencia | Resultado |
|---|---|---|
| Anatomía | resumen + Toca medir › Destilación › Por enviar; sin lotes → arranque | ✔ |
| Estados | default, tras medir, sin señal (instantánea), operador, sin lotes, todo medido, nada pendiente, cola con fallo/pendiente (Vitest) | ✔ (Por enviar real: por Vitest) |
| Responsive | 1 col <1024 / 2 col ≥1024; filas apiladas <600; FAB en compact, botón en ≥600 | ✔ |
| A11y base | status del resumen, secciones rotuladas, una primaria, motivos de deshabilitado, `<time>` en la instantánea, targets 44 | ✔ |
| critique→polish | manual-playbook / degraded | registrado |

Hallazgos devueltos a coco: dos corregidos en la ronda (tieneLotes sin red;
mayúsculas heredadas).

No verificado (Stable): cola con fallo en navegador real, lector de
pantalla, zoom nativo, harden/audit.

Entrega a mora: `Screens/inicio.md` (reescribir contra el código 0.3.0),
README, sitio regenerado.
