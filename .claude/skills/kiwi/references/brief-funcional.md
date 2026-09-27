# Brief funcional

El brief es la compuerta de entrada. Si no cabe en una página, la superficie está mal delimitada.

## Orden de trabajo

1. **Leer el contexto disponible**: código (rutas, stores, props, permisos), documentos de producto, perfil de lima, `coco.data_contract`, conversación previa. Anotar la fuente de cada hecho.
2. **Separar** lo que se sabe (hechos), lo que se asume para avanzar (supuestos, declarados) y lo que falta (incógnitas).
3. **Preguntar** solo las incógnitas que cambian la arquitectura de información. 2–6 preguntas, un mensaje, sin estética.

## Campos

| Campo | Buena forma | Mala forma |
|---|---|---|
| Enunciado | "La recepcionista necesita confirmar la llegada de un paciente porque la sala se satura" | "Pantalla de pacientes" |
| Pregunta de diseño | "¿La lista permite distinguir en 2 s quién ya llegó?" | "¿Se ve bien?" |
| Verbo principal | registrar, comparar, aprobar, reprogramar | gestionar, administrar, manejar |
| Resultado verificable | "La cita cambia a *En sala* y aparece en la cola" | "El usuario queda satisfecho" |
| Dato dominante | El que se mira primero y decide la acción | Todos los campos de la API |

## Riesgo por acción

| Tipo | Ejemplo | Confirmación |
|---|---|---|
| Reversible | Filtrar, ordenar, guardar favorito | Ninguna; feedback breve |
| Con deshacer | Archivar, marcar como leído | Toast con **Deshacer** (≥ 5 s) |
| Destructiva | Eliminar, cancelar cita con cobro | Diálogo con consecuencia explícita y verbo del resultado ("Cancelar cita") |

## Continuidad

Para cada superficie declara: conexión lenta (skeleton con misma huella), sin conexión (qué se ve, qué se encola, qué se bloquea), error (mensaje + reintento, sin perder lo capturado), sesión reanudada (dónde vuelve), cambio de tamaño/orientación (qué estado y foco se conservan).

## Antipatrones

- Inventar campos para "llenar" un layout.
- Mezclar preguntas funcionales con estéticas.
- Brief que describe la UI ("un grid de tarjetas") en lugar de la tarea.
- Omitir incógnitas para parecer completo.
