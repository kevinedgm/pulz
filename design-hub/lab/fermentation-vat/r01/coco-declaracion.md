# Coco · declaración de cumplimiento · fermentation-vat/r01

Ruta: **R3**, implementación de la estructura F2 congelada por Kiwi y gobernada por Lima.

- Brief funcional: el operador reconoce si la tina requiere atención y abre el flujo real para registrar la siguiente medición.
- Reglas aplicadas: tokens versionados PULZ; una acción por objeto; atraso con texto + forma; targets de 44 px; props abajo/eventos arriba; composición por container query.
- Excepciones: el perfil no declara fuentes visuales normativas; no se inventaron. Texto al 200% y forced-colors no pudieron verificarse en runtime.
- Comprobado: `vue-tsc -b` PASS; Vitest 5/5; builds producción y Hub PASS; 390/768/1024/1440 sin overflow; foco visible; estados default/atrasada/sin medición mediante pruebas y preview.
- Auditoría arquitectónica: Feature/Domain; 0 CRITICAL/HIGH/MEDIUM/LOW, 2 INFO; Component Health saludable.
- Detector: un warning por borde lateral de 4 px, corregido a 2 px; no se volvió a ejecutar para respetar el pase único del detector.
- Cobertura documental: lista para Mora; registry censado como `fermentation-vat`.
- No pudo comprobarse: dispositivo táctil físico, zoom de texto real al 200%, forced-colors.
- Siguiente paso: Lima consume `.fruti/reports/compliance-current.json`; no repite la auditoría.
