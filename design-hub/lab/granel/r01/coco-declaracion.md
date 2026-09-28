# coco · Declaración de cumplimiento — ronda granel/r01 (R3)

```text
Ruta: R3 (product-application granel; sin piezas nuevas del sistema) — orden de lima
Brief funcional: el de kiwi, vigente. data_contract registrado en el perfil: Tanque, Concepto, Pata, Movimiento, Transferencia
Reglas aplicadas:
  · el formulario se arma con el concepto (camposDe: source_lot, creates_lot, asks_result, asks_counterparty); «Carga inicial» no se ofrece aquí
  · el sistema no calcula el grado: entradas con asks_result piden volumen y % Alc. resultantes; ledger esperado y diferencia se muestran antes; diferencia_volumen, abv_fuera_rango y excede_capacidad se conocen antes (AvisoNota); estricta bloquea con motivo
  · contraparte obligatoria por concepto (bloqueo antes de enviar); compra con proveedor del catálogo o nombre y certificado opcional
  · transferir: origen (colector con mezcal o lote de un tanque) → destino → litros → % Alc. → conservar (sugerido: lote mayor; default_folio_decision) o renombrar; «Pasar a granel» de Destilación redirige aquí con el origen puesto
  · historial: movement_log por código del recurso + contraparte y documento desde operations (la vista no los trae); conciliación agrupada bajo su operación («el sistema registró una diferencia de −0.2 L»); filtros por lote y persona
  · todo requiere señal; sin FAB; Entrada primaria en el tanque; el operador solo ve
Excepciones: ninguna respecto a la ronda
Comprobado:
  · vue-tsc ✔ · eslint 0/0 ✔ · prettier ✔ · Vitest 107/107 ✔ (9 nuevas de api puras)
  · Playwright qa/evidencia-granel.mjs 8/8 ✔ (36 capturas) con Aurelia en Cuatro Vientos tras db reset, escrituras REALES: 8 L del Colector mezcal al Tanque 1 conservando G-COMPRA-01; 2 L de agua en Tanque 2 declarando 343.6 L a 44.7 % (diferencia −0.2 L conocida antes → nota → conciliación registrada); venta de 10 L con contraparte y documento (el botón espera la contraparte); Tanque 2 en 333.6 L con los tres movimientos en el historial (contraparte y documento visibles); sin FAB; 4 anchos × 2 temas sin desborde
  · capturas revisadas a ojo: transferir 1440, tanque 2 1440 claro y 390 oscuro
Auditoría arquitectónica (manual):
  · MovimientoPage: un formulario para 13 conceptos gobernado por camposDe (puro, con prueba). ~350 líneas; aceptable. Health: sano.
  · api.ts: conInstantanea duplicado por tercera vez (fermentación, destilación, granel) → se extrae en la ronda maguey-horneado (orden de lima). Health: sano con deuda anotada.
  · Findings:
    - MEDIUM · AUTO_FIX (hecho) — la etiqueta del botón de transferir perdía el espacio («Transferir8 L») al formatear el template; ahora es una sola cadena computada. Regla: etiquetas con datos, en computed.
    - MEDIUM · AUTO_FIX (hecho) — el historial no mostraba contraparte ni documento (movement_log no los trae): se leen de operations por id.
    - LOW · NO_ACTION — la evidencia leía el tanque mientras cargaba: ahora espera el encabezado y la tabla.
No pudo comprobarse: compra real con certificado (Vitest y tipos); unión con renombrar (tipos); operador real; lector de pantalla; zoom nativo.
Siguiente paso: lima → mora → ronda maguey-horneado/r01.
```
