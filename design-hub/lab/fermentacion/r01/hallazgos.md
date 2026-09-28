# Hallazgos · FERMENTACIÓN · r01

| Sev. | Hallazgo | Decisión | Responsable | Siguiente acción |
|---|---|---|---|---|
| Alta | Un FAB «Medir» sin destino explícito es ambiguo cuando hay varias tinas | Abre la **primera** de «toca medir hoy»; la cabecera de la medición muestra la tina y permite **cambiar** antes del primer número. Desde la fila, «Medir» va a esa tina. Con 0 por medir, el FAB no aparece (estado «todas medidas hoy») | kiwi → coco | contrato de `fermentacion` |
| Alta | Modo completo = 15 números; un formulario los vuelve ilegibles con una mano | **Un concepto por paso** (5 pasos): T. superficie (3) → T. fondo (3) → Brix superficie (3) → Brix fondo (3) → Actividad · Dulzor · Acidez; promedio en vivo; el promedio nunca se guarda | kiwi | patrón `step-flow` |
| Alta | La captura debe funcionar sin señal y llegar una sola vez | **Toda** medición entra por la cola (una sola ruta de escritura), con señal o sin ella; la pantalla dice «enviada» o «pendiente»; la lista viene de la instantánea cuando no hay señal | kiwi → coco | `useCola`, `instantanea` |
| Media | El aviso `brix_fuera_rango` llegaría como error tras guardar (y sin señal, horas después) | Se conoce **antes**: los rangos de `organization_settings` viajan en la instantánea; «Revisar» pide la nota ahí. Si aun así el servidor lo pide (rangos cambiados), el fallo de cola trae «Corregir» que abre la nota | kiwi → coco | patrón `soft-warning-note` |
| Media | «Día N» y «hoy» no existen en el servidor (0026 entrega fechas) | El navegador calcula `día = días naturales desde started_at + 1` en su zona y lo muestra corregible en la cabecera de la medición; «toca medir hoy» = sin medición válida con fecha local de hoy | kiwi | `api.ts` (funciones puras, con prueba) |
| Media | Formulación es larga para una hoja en compact | Página propia `/fermentacion/formular`, no capa; «Tina que ya fermentaba» sí es capa (3 campos) | kiwi | rutas |
| Media | Operador puede medir pero no cerrar/formular | Las acciones que no puede **no se muestran** (no se deshabilitan); por URL, `state-block` sin permiso | kiwi → coco | guardias |
| Baja | Foto en cada paso distrae | Solo en «Revisar», opcional, con `capture="environment"` | kiwi | — |
| Baja | Curva de Brix por día | Could; el detalle muestra tabla (texto primero) | — | r02 si el productor la pide |
