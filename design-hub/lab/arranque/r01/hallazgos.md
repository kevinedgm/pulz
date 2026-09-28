# Hallazgos · ARRANQUE · r01

| Sev. | Hallazgo | Decisión | Responsable | Siguiente acción |
|---|---|---|---|---|
| Alta | «Guardar» una carga inicial es irreversible aquí (crea lote y saldo) y no hay confirmación modal | El botón dice exactamente qué hará («Guardar 300 L en Tanque 1») y la tarjeta muestra lo guardado; corregir litros es un ajuste en Granel (Fase 5) | kiwi (declarado) | lima fija en el contrato que el texto del botón lleva cantidad y recipiente |
| Alta | La capa de alta de recurso vive dentro de `RecursosPage`; el arranque la necesita | Extraer `RecursoCapa.vue` como componente compartido del módulo configuración (no del sistema): lo consumen Recursos y Arranque | lima → coco | refactor sin cambiar comportamiento |
| Media | «Vacío» no existe en la base: se guarda en `localStorage` por empresa; en otro teléfono el recipiente vuelve a aparecer «pendiente» | Aceptable: un recipiente sin saldo real se puede volver a marcar vacío en un segundo; la reanudación real sale de `recurso_en_uso` (saldo > 0 / ciclo abierto = guardado) | kiwi (declarado) | si molesta, `organization_settings.arranque_hecho` en r02 |
| Media | Capacidad: con política estricta el servidor rechaza (`CAPACIDAD:`); con flexible guarda y avisa (`rpc_warn`) | Aviso local amarillo antes de guardar cuando litros > capacidad; el error del servidor se traduce bajo la tarjeta | coco | mapear `CAPACIDAD:` y el aviso de la operación |
| Baja | Hornos, molinos y alambiques no aparecen (no guardan líquido); maguey/cocido iniciales quedan fuera | Alcance §13.2 #2 «tanques y tinas»; una ronda aparte si el dueño quiere kilos iniciales | kiwi | — |
| Info | Solo Prueba B tiene un recipiente en la semilla (Tina B1); la evidencia real crea tanque y colector allí | coco crea `Tanque B1` y carga 300 L @ 47 en la evidencia; `db reset` lo limpia | coco | — |
