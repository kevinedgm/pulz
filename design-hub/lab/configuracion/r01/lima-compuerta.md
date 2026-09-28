# lima · Compuerta Candidate — ronda configuracion/r01

Evaluada el 2026-09-27 con `coco-declaracion.md`, 67 capturas de
`qa/evidence/configuracion-r01/`, pgTAP 37/37 y Vitest 47/47. **Las 7 piezas
pasan a `candidate` 0.2.0**: select, number-field, switch, color-field,
file-picker, brand-block y configuracion.

| Criterio | Evidencia | Resultado |
|---|---|---|
| Anatomía / variantes | contratos + código; ninguna variante sin uso | ✔ |
| Estados | carga, vacío, error de carga y de guardado, sin permiso, offline, readonly, confirmaciones, guardado — capturas + escrituras reales | ✔ |
| Responsive | lista apilada ≤1023, capas drawer/hoja, cabecera de sección apilada <600, pares min/máx apilados <600 | ✔ |
| A11y base | etiquetas ligadas, describedby solo a ids presentes, role=switch, targets 44, foco visible, errores con causa; contraste heredado; zoom 200 % en 3 páginas | ✔ |
| Demo en el Hub | 6 secciones nuevas; configuracion = pantallas reales + capturas | ✔ |
| critique→polish | manual-playbook / degraded | registrado |

Aceptadas las excepciones de coco (recorte centrado sin arrastre; EXIF).
Hallazgo para r02 si el dueño lo pide: encuadre manual del logo.

No verificado (Stable): hoja nativa de select y cámara en dispositivo, EXIF,
texto largo real, zoom nativo, forced-colors, harden/audit.

Entrega a mora: fichas ya escritas (`Components/{select,number-field,switch,color-field,file-picker,brand-block}.md`, `Screens/configuracion.md`); README actualizado.
