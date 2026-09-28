# lima · Compuerta Candidate — ronda arranque/r01

Evaluada el 2026-09-27 con `coco-declaracion.md`, 13 capturas de
`qa/evidence/arranque-r01/` (8/8 corridas, escrituras reales en Prueba B),
Vitest 52/52 y la re-ejecución de la evidencia de configuración tras extraer
`RecursoCapa`. **`arranque` pasa a `candidate` 0.2.0.**

| Criterio | Evidencia | Resultado |
|---|---|---|
| Anatomía | tarjeta por recipiente con decisión, campos por kind, botón con cantidad y recipiente, colapso | ✔ |
| Estados | sin lotes, pendiente, con datos, guardando, guardado, vacío, sin recipientes, ya arrancó, sin permiso, offline/readonly, errores | ✔ (errores del servidor: por Vitest y traducción; no provocados en Playwright) |
| Responsive | 1 columna <1024, 2 columnas ≥1024; pares apilados <600; Listo en barra en compact | ✔ |
| A11y base | radiogroup, describedby, targets 44, foco, aviso de capacidad en texto, progreso role=status | ✔ |
| Demo | pantallas reales + capturas (product-application) | ✔ |
| critique→polish | manual-playbook / degraded | registrado |

Refactor aceptado: `RecursoCapa` como componente del módulo de configuración
(no del sistema): dos consumidores, misma conducta, evidencia de Recursos
re-ejecutada en verde.

No verificado (Stable): `rpc_warn` de capacidad flexible desde la pantalla,
colector real, lector de pantalla, zoom nativo, harden/audit.

Entrega a mora: `Screens/arranque.md`; README.
