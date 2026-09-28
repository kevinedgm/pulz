# Hallazgos · DESTILACIÓN · r01

| Sev. | Hallazgo | Decisión | Responsable | Siguiente acción |
|---|---|---|---|---|
| Alta | El corte solo puede ir a un colector de su clase (0018); elegir colector es un error esperando pasar | El colector **se elige solo por la clase**; si hay varios de la clase, un select; si no hay ninguno, bloqueo con enlace a Recursos **antes** del primer número | kiwi → coco | contrato de `destilacion` |
| Alta | «Ya mezcal va directo a granel» (§4.5) no es un corte a tanque: es `transferir` (0019, admin/productor) | Destilación muestra los colectores con contenido y **«Pasar a granel»** que abre la transferencia de la ronda de Granel; el operador ve quién lo hace | kiwi | ronda granel/r01 |
| Alta | Abrir corrida consume saldos que decide el servidor | Página con orígenes y litros, **requiere señal**; capacidad estricta bloquea antes; flexible y mezcla 2ª avisan antes con nota (`soft-warning-note`) | kiwi → coco | patrón `origin-allocation` |
| Media | Corte y medición comparten forma (una mano, un número por pantalla) | Mismo `step-flow` con 4 pasos: Clase → Litros → % Alc. → Revisar; «Registrar otro corte» vuelve al paso 1 | kiwi | reutiliza fermentación |
| Media | Un corte no se anula (no hay RPC) | Se dice en la corrida; la corrección es un ajuste en Granel (Fase 6). Un fallo de cola por corrida cerrada solo se **descarta** | kiwi | DUDAS #15 |
| Media | La lista de orígenes con litros aparece por tercera vez (formulación, corrida, horneado) | Se propone la pieza `origin-allocation` (lista de orígenes con saldo + cantidad + total vs. capacidad); lima decide si se extrae de FormularPage | kiwi → lima | orden de coco |
| Baja | Rendimiento (cortado / cargado) como % | Could; se muestran los litros | — | r02 |
| Baja | Vinazas / pérdida al cerrar | No hay campo en el esquema: la diferencia se ve, no se guarda | — | DUDAS #15 |
