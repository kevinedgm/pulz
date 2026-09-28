# coco · Declaración de cumplimiento — ronda arranque/r01 (R3)

```text
Ruta: R3 (sin piezas nuevas del sistema) + refactor RecursoCapa
Brief funcional: el de kiwi, vigente. data_contract: Recipiente = Recurso (tanque/tina/colector activo); CargaInicial {resource_id, idempotency_key local, litros, abv?} → registrar_entrada carga_inicial; guardado derivado de recurso_en_uso
Reglas aplicadas:
  · lista de tarjetas, no asistente; cada tarjeta guarda sola con su idempotency_key (localStorage pulz:arranque:<org>); "vacío" es local
  · material por kind (tanque→granel, tina→fermentado y abre ciclo, colector→destilado); % Alc. solo tanque/colector
  · Guardar irreversible sin modal: el botón dice "Guardar 300 L en Tanque B1"; la tarjeta se colapsa como guardada
  · aviso local de capacidad (estricta: no se podrá; flexible: se guarda con aviso); errores CAPACIDAD:/ciclo abierto/red traducidos bajo la tarjeta; tina con ciclo abierto pasa a "guardada"
  · admin y productor; operador → state-block denied; offline: se escribe, no se guarda; readonly: solo ver
  · agregar recipiente con la MISMA capa de Recursos (RecursoCapa extraída, kinds limitados a tanque/tina/colector)
  · progreso en texto ("2 de 2 recipientes decididos"), "Listo, ir a Inicio" solo cuando todos están decididos (page-primary en compact)
  · Inicio → "Empezar" apunta al arranque; Recursos enlaza "Registrar lo que hay"
Excepciones: ninguna respecto a la ronda
Comprobado:
  · vue-tsc ✔ · eslint 0/0 ✔ · prettier ✔ · Vitest 52/52 ✔ (5 nuevos: tarjeta ×3, api ×2)
  · Playwright qa/evidencia-arranque.mjs 8/8 ✔ (13 capturas) con la dueña de Prueba B, escrituras REALES: Inicio sin lotes → Empezar; Tanque B1 creado con la capa; 300 L @ 47 guardados (registrar_entrada real, lote G-… con saldo); Tina B1 vacía; "2 de 2"; Listo; tras recargar se conserva (localStorage + recurso_en_uso); Inicio ya muestra "Hoy"; en las 7 corridas siguientes la pantalla muestra "Ya tienes registros" y Tanque B1 guardado desde la base
  · RecursosPage refactorizada sobre RecursoCapa: evidencia de configuración re-ejecutada (ver lima-compuerta)
Auditoría arquitectónica (manual):
  · RecursoCapa: componente del módulo configuración con estado propio (carga sus catálogos, valida, guarda) y API por eventos (cerrar, guardado): reduce duplicación real entre dos consumidores. Health: sano.
  · TarjetaRecipiente: local del módulo arranque; sin dominio de red (emite guardar/vacío); la página decide. Health: sano.
  · Findings:
    - LOW · NO_ACTION — "vacío" solo en este navegador; si se usa desde otro teléfono vuelve a "pendiente" (decisión registrada; r02 si molesta).
    - INFO — Prueba B queda con Tanque B1 y un lote de 300 L hasta el db reset.
No pudo comprobarse: capacidad flexible con aviso del servidor (rpc_warn) desde la pantalla; colector real (Prueba B no tiene); lector de pantalla; zoom nativo.
Siguiente paso: lima → mora → prueba de punta a punta de la Fase 4 (tarea 5) → ronda del Hub.
```
