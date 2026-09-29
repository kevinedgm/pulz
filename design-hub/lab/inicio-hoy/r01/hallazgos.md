# Hallazgos · INICIO / HOY · r01

| # | Severidad | Hallazgo | Decisión | Responsable | Siguiente acción |
|---|---|---|---|---|---|
| 1 | Alta | El placeholder actual no responde la pregunta: tres tarjetas «Fase 5» sin datos; para saber qué medir hay que entrar a Fermentación y leer tina por tina. | Tres bloques en orden de urgencia (Toca medir › Destilación › Por enviar) con una línea resumen `role=status` arriba; «Medir» en la fila. | kiwi → coco | Implementar `HoyPage` con `agrupar(tinas_en_uso)`. |
| 2 | Alta | Sin señal, Inicio no puede ser «solo lectura»: medir y cortar van por la cola y son justo la tarea de la mañana. | Con instantánea, Medir y Cortar siguen activos; «Pasar a granel», «Abrir corrida» y «Llenar tinas» se deshabilitan; se muestra «Mostrando datos guardados el …». | kiwi → coco | `conInstantanea(org, "inicio-hoy")`; atajos de cola no dependen de `enLinea`. |
| 3 | Alta | Una sola primaria: con 3 tinas por medir hay tentación de tres botones sólidos. | Solo la primera fila (la más atrasada) lleva la primaria; las demás, secundaria. En compact la primaria baja a la barra como «Medir Tina 3» y la fila la esconde (`data-wf-persist`). | kiwi | — |
| 4 | Media | La hora del recordatorio sin push podía interpretarse como «ocultar hasta las 9». | El rótulo cambia («toca desde las 9:00» / «toca medir»); la tina no sale de la lista (DUDAS #13). | kiwi | coco lee `measurement_reminder_hour`. |
| 5 | Media | Duplicar la cola en el banner del shell y en Inicio confunde. | El banner conserva el total y «Reintentar» global; Inicio es el detalle por elemento con motivo, Reintentar, Corregir/Descartar; el bloque desaparece con la cola vacía. | kiwi → lima | lima decide si el ítem de cola es pieza del sistema (`queue-item`) o local. |
| 6 | Media | ≥12 tinas por medir alargan Inicio y esconden Destilación. | 8 filas y «y N más → Fermentación»; en expanded Destilación va en la segunda columna, así que no queda abajo. | kiwi | — |
| 7 | Baja | Fila con folio/nombre largo. | `overflow-wrap:anywhere` en título y sub; el botón no se encoge por debajo de 44 px. | kiwi | Probado en `largo` a 390/768/1440. |
| 8 | Baja | Maguey/Horneado no tienen tarea diaria y no aparecen en Hoy. | Se conserva el alcance de §13.2 #3; si el dueño quiere «lotes de maguey sin hornear» en Hoy, es r02. | dueño | — |
