# Hallazgos · GRANEL · r01

| Sev. | Hallazgo | Decisión | Responsable | Siguiente acción |
|---|---|---|---|---|
| Alta | Cada concepto pide datos distintos (§5.2); un formulario fijo pediría de más o de menos | El formulario **se arma con el concepto** (`source_lot`, `creates_lot`, `asks_result`, `asks_counterparty`); el comportamiento se muestra como ayuda al elegirlo | kiwi → coco | patrón `movement-form` (local: `MovimientoPage`) |
| Alta | El sistema no calcula el grado, pero puede decir qué hará con el volumen | Con `asks_result` se muestra el ledger esperado y la **diferencia** que registrará la conciliación; `diferencia_volumen` y `abv_fuera_rango` se conocen antes con la instantánea (nota) | kiwi → coco | `api.ts` puras |
| Alta | No hay FAB: la acción depende del tanque | Entrada / Salida / Transferir por tarjeta; en el tanque, Entrada es la primaria (declara grado) | kiwi | contrato de `granel` |
| Media | Unión y transferencia con destino ocupado exigen decidir el folio | `segmented-choice` conservar (sugerido: el del destino / mayor) · renombrar (folio opcional); `default_folio_decision` de la empresa | kiwi | — |
| Media | «Pasar a granel» desde Destilación | `/granel/transferir?origen=<colector>` con el origen puesto | kiwi → coco | rutas |
| Media | Un tanque puede tener varios lotes | Se listan todos con su grado; salidas y uniones piden el lote (por defecto el vivo) | kiwi | — |
| Baja | Filtro de historial por fecha | Could; lote y persona sí | — | r02 |
| Baja | Envasado con presentaciones | fuera del MVP (§1.5): «Envasado» es una salida en litros | — | — |
