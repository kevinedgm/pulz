# Hallazgos · MAGUEY y HORNEADO · r01

| Sev. | Hallazgo | Decisión | Responsable | Siguiente acción |
|---|---|---|---|---|
| Alta | La recepción pide muchos datos opcionales y en campo solo importan los kilos | Solo **kilos** obligatorios (0015); especie, predio, proveedor, piñas y nota opcionales; sin catálogos se registra igual con un enlace a Catálogos | kiwi → coco | contrato de `maguey-horneado` |
| Alta | Abrir horneada consume saldo sólido de varios lotes | Reutiliza `origin-allocation` en kg (tercer consumidor): error por fila si pasa el saldo, bloqueo antes de enviar | kiwi → coco | — |
| Alta | Cerrar horneada es irreversible y crea el cocido | Capa (`task-layer`) con kg cargados como referencia; el botón dice los kilos cocidos; merma visible, no se guarda | kiwi | DUDAS #15 (misma pregunta que vinazas) |
| Media | El cocido con saldo es lo que la formulación necesita | Sección «Agave cocido con saldo» con «Llenar tinas» → Fermentación/formular | kiwi | — |
| Media | Operador en maguey | No registra (§18 #4, supuesto vigente); se oculta la primaria | kiwi | — |
| Baja | Agotados llenan la lista | Plegados, últimos 10 | kiwi | — |
| Baja | Fecha de jima, foto de recepción | Could; no hay campo | — | r02 |
