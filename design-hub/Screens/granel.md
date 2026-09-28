# Granel: tanques y movimientos · `granel`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | product-application · **candidate 0.2.0** · owner lima (registry) |
| Ronda de origen | `lab/granel/r01` |
| Código | `apps/web/src/modules/granel/{api.ts, routes.ts, pages/{GranelPage,TanquePage,MovimientoPage,TransferirPage}.vue, components/TarjetaTanque.vue}` |
| Rutas | `/e/:slug/granel` (destino) · `/…/granel/transferir?origen=\|destino=` · `/…/granel/:tanque` · `/…/granel/:tanque/movimiento?direccion=` |
| Pruebas | `modules/granel/__tests__/api.test.ts` (8) · `qa/evidencia-granel.mjs` |
| Evidencia | `qa/evidence/granel-r01/*` |

## Propósito

Ver cuánto mezcal hay en cada tanque y a qué grado, y registrar cada
entrada, salida y transferencia con quién, cuándo y por qué. **El sistema
no calcula el grado**: la persona declara volumen y % Alc. resultantes
(§5.1, §13.2 #6).

## Cómo funciona

**Tanques.** Una tarjeta por tanque activo (`tanques`): saldo, cada lote
con folio, litros, **% Alc. declarado vigente** (quién y cuándo,
`lot_declared_abv`) y nivel de historia como texto; Entrada / Salida /
Transferir (admin y productor, con señal). Debajo, colectores con mezcal →
«Pasar a granel». Sin FAB: la acción depende del tanque.

**Tanque.** Saldo, lotes con grado vigente, acciones y el **historial**
(`movement_log` del recurso, últimas 100 patas) con filtros por lote y
persona; las patas de conciliación se leen como «el sistema registró una
diferencia de −0.2 L» bajo su entrada.

**Movimiento.** Elegir dirección y concepto (los del catálogo, con su
comportamiento como ayuda) → el formulario **se arma con el concepto**
(`camposDe`): litros; lote afectado si hay varios; lote de origen y dónde
está (`source_lot`); decisión conservar / renombrar al unir; volumen y
% Alc. resultantes (`asks_result`) con el ledger esperado y la diferencia
que registrará la conciliación; contraparte y documento
(`asks_counterparty`); proveedor y certificado opcional en la compra
(`creates_lot`); ¿cuándo pasó?; nota obligatoria si hay aviso
(`diferencia_volumen`, `abv_fuera_rango`, `excede_capacidad`). El botón
dice lo que hará → `registrar_movimiento_granel`.

**Transferir.** Origen (colector con mezcal o lote de un tanque) → destino
(tanque) → litros → % Alc. (por defecto el declarado) → si el destino tiene
lote: conservar (sugerido: el mayor) o renombrar → `transferir`. Destilación
llega aquí con el origen puesto.

## Estados

Carga · sin tanques · tanques vacíos · default · sin conexión (lectura) ·
solo lectura · operador (sin botones) · tanque sin movimientos / con
historial · elegir concepto · formulario por concepto · diferencia conocida
antes · sin contraparte (bloquea) · capacidad estricta (bloquea) / flexible
(nota) · error del servidor (saldo) · transferir con destino ocupado / vacío
· registrado (vuelve al tanque con aviso).

## Componentes usados

`app-shell` · `page-header` · `list-stack` · `state-block` · `banner` ·
`button` · `segmented-choice` · `select` · `number-field` · `text-field` ·
`datetime-field` · `soft-warning-note` · `status-chip`.

## Criterios verificados

Con Aurelia en Cuatro Vientos (escrituras reales): 8 L del Colector mezcal al
Tanque 1 conservando G-COMPRA-01; 2 L de agua en Tanque 2 declarando 343.6 L
a 44.7 % con la diferencia de −0.2 L conocida antes (nota) y registrada
como conciliación; venta de 10 L con contraparte y documento; historial del
Tanque 2 con los tres. Sin FAB; 4 anchos × 2 temas sin desborde.

## No verificado

Compra real con certificado (por tipos y Vitest); unión con renombrar
(por tipos); operador real; lector de pantalla; zoom nativo.
