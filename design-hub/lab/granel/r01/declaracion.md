# Declaración de cumplimiento · GRANEL · r01

| Campo | Valor |
|---|---|
| Ruta | R1 |
| Fidelidad | F2 |
| Pregunta de diseño | ¿Puede el productor, en un minuto y sin conocer el catálogo de memoria, registrar cualquier movimiento de granel con los datos que ese concepto exige y ninguno de más, ver el saldo y el grado vigente de cada tanque con quién y cuándo lo declaró, y entender qué hizo el sistema cuando el volumen declarado no cuadró? |
| Artefactos | `brief.md` (brief + 2 flujos) · `index.html` (wireframe, kit inline) · `hallazgos.md` · `declaracion.md` |
| Modifica producción | No |

## Estándares leídos

`wireframing.md`, `fidelidad.md`, `validacion.md`, `hig-web-pwa.md`; WCAG 2.2 AA; `0019`, `0011`, `0026`; `movement_concepts` y su semilla; `organization_settings`; rondas fermentacion/destilacion (piezas y evidencia).

## Desviaciones del protocolo

Ninguna. Aprobación en automático (`CLAUDE.md` §4): roles = `rpc_guard`; reglas por concepto = catálogo + RPC.

## Comprobaciones ejecutadas

- `check_artifact.py --fidelidad F2`: 0 errores · 0 avisos.
- Chromium (Playwright): **60 combinaciones** (3 espacios × 20 estados): sin desborde, ≤1 primaria visible por vista, 0 targets <44 px, 0 errores JS.
- Estados: tanques default · carga · sin tanques · tanques vacíos · sin conexión · solo lectura · operador · contenido largo (varios lotes) · menú · tanque con historial · sin movimientos · elegir concepto · agua (resultado y diferencia) · venta (contraparte) · compra (crea lote, certificado) · unión (conservar / renombrar) · error del servidor · transferir con destino ocupado · a tanque vacío · registrado.
- Capturas revisadas: 1440 tanques; 390 tanques / agua / unión / transferir / tanque / concepto.

## Matriz de adaptación

| Elemento | compact (<600) | medium (600–1023) | expanded (≥1024) | Motivo | Técnica | Foco/estado |
|---|---|---|---|---|---|---|
| Tarjetas de tanque | una columna; tres botones a ancho repartido | una columna | dos columnas | cada tanque es una decisión (qué hacer con él) | grid | — |
| Tanque | una columna; Entrada/Salida en barra | una columna | dos columnas (historial \| acciones) | igual que corrida | grid | — |
| Movimiento / Transferir | una columna; primaria en barra con el verbo y la cantidad | parejas en dos columnas | igual | formulario armado por concepto | página | los datos se conservan ante error |
| Elegir concepto | lista de botones grandes con su comportamiento | igual | igual | leer qué pide cada uno | `radiogroup` | — |
| Historial | tabla apilada con rótulos | apilada | tabla | bitácora | `list-stack` | filtros arriba |

## Comprobaciones NO ejecutadas

- Movimientos reales contra el proyecto (agua, venta, compra, unión, transferencia): en coco.
- Conciliación real (`diferencia_volumen`) y `abv_fuera_rango` desde la pantalla: en coco.

## Hallazgos

Ver `hallazgos.md`: 3 altos (formulario por concepto; diferencia conocida antes; sin FAB), 3 medios, 2 bajos.

## Traspaso

- **→ lima · sin piezas nuevas del sistema.** **Reutiliza:** `segmented-choice` (dirección, decisión de folio), `select`, `number-field`, `text-field`, `datetime-field`, `soft-warning-note`, `status-chip`, `list-stack`, `row-menu`, `state-block`, `banner`, `button`. **Local (product-application `granel`):** `GranelPage`, `TanquePage`, `MovimientoPage` (formulario armado por concepto), `TransferirPage`, `TarjetaTanque`, `api.ts` (puras: `camposDe(concepto)`, `ledgerEsperado`, `diferencia`, `avisosEntrada`, `folioSugerido`).
- **Datos (`coco.data_contract`):** `Tanque` = fila de `tanques` (lotes jsonb con abv/abv_by/abv_at/history); `Concepto` = `movement_concepts` (direction, source_lot, creates_lot, asks_result, asks_counterparty); `Movimiento = { concepto, tanque, litros, lote?, lote_origen?, recurso_origen?, resultado_l?, resultado_abv?, abv?, decision?, folio_nuevo?, contraparte?, documento?, proveedor?, proveedor_nombre?, folio_certificado?, organismo?, especie?, predio_declarado?, nota?, occurred_at }` → `registrar_movimiento_granel`; `Transferencia = { origen, destino, lote, litros, abv?, decision?, folio_nuevo?, nota?, occurred_at }` → `transferir`; historial = `movement_log` filtrado por recurso; orígenes para unión/transferir = `colectores_con_saldo` + lotes de `tanques`.
- **→ coco:** rutas `/e/:slug/granel`, `/…/granel/transferir?origen=`, `/…/granel/:tanque`, `/…/granel/:tanque/movimiento`; `destinos.ts` sin `proximamente` para granel; Destilación «Pasar a granel» ya apunta a `/granel?transferir=<colector>` → redirigir a `/granel/transferir?origen=`. Evidencia real con Aurelia en Cuatro Vientos: transferir el mezcal del colector (MEZ-002, 8 L) al Tanque 1 (conservar G-COMPRA-01), agua 2 L en Tanque 2 con resultado que no cuadra (nota), venta 10 L (contraparte), historial. `db reset` al cerrar la fase.
- **→ mora:** nada hasta implementar.

## Siguiente paso

Aprobación automática (CLAUDE.md §4) → lima → coco → mora.
