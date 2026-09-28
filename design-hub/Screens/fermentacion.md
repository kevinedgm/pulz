# Fermentación: usos de tinas y medición diaria · `fermentacion`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | product-application · **candidate 0.2.0** · owner lima (registry) |
| Ronda de origen | `lab/fermentacion/r01` |
| Código | `apps/web/src/modules/fermentacion/{api.ts, routes.ts, pages/{FermentacionPage,UsoTinaPage,MedirPage,FormularPage}.vue, components/{FilaUso,ConfirmarCiclo,TinaFermentabaCapa}.vue}` · cola en `shared/offline/` |
| Rutas | `/e/:slug/fermentacion` (destino, FAB «Medir») · `/…/fermentacion/formular` · `/…/fermentacion/:ciclo` · `/…/fermentacion/:ciclo/medir` |
| Pruebas | `modules/fermentacion/__tests__/api.test.ts` (12) · `shared/offline/__tests__/cola.test.ts` (8) · `qa/evidencia-fermentacion.mjs` · `qa/e2e-offline.mjs` |
| Evidencia | `qa/evidence/fermentacion-r01/*` (61) · `qa/evidence/fase5-offline/*` (4 + resultado) |

## Propósito

Medir cada tina todos los días con una mano y a veces sin señal, saber de
un vistazo cuáles faltan hoy y confiar en que lo capturado llega una sola
vez (§4.4, §8.3, §13.2 #3–#4).

## Cómo funciona

**Usos de tinas.** Lista de ciclos abiertos (`tinas_en_uso`) en tres grupos:
«Toca medir hoy» (fermentando sin medición válida hoy), «Ya medidas hoy»,
«Listas o en vaciado». Fila: tina, folio, litros, **día N** (de ~esperados),
última medición, chip de estado, «Medir», menú (ver mediciones, declarar
lista, cerrar ciclo). Primaria «Medir»: FAB en compact, botón en la
cabecera en ≥600; abre la primera por medir. Pie (admin/productor): «Llenar
tinas (formulación)» y «Tina que ya fermentaba» (capa).

**Uso de tina.** KPIs (día, litros, Brix y °C de la última), mediciones (la
más reciente arriba; anuladas tachadas con motivo), «Medir hoy», anular
(motivo obligatorio), declarar lista, cerrar ciclo (diálogo destructivo con
Cancelar como primaria).

**Medición.** `step-flow` con un concepto por paso. Mínimo: Temperatura →
Brix → Actividad → Revisar. Completo: T. superficie (3 lecturas) → T. fondo
(3) → Brix superficie (3) → Brix fondo (3) → Actividad · Dulzor · Acidez →
Revisar. Cabecera: tina («otra tina» en el primer paso), día corregible,
«¿Cuándo pasó?». Revisar: resumen, aviso de Brix con nota obligatoria si
sale del rango de la empresa, nota opcional, foto opcional (reducida a
1600 px). **Guardar siempre encola** (`registrar_medicion` con
`idempotency_key`): «Guardada · enviada» o «Guardada · pendiente de
enviar», y «Medir la siguiente».

**Sin señal.** La lista y la medición se abren desde la instantánea
(«datos de hace X»); el shell muestra «N capturas pendientes · M fallaron»
con Reintentar; cada fila lleva su chip; un fallo de dominio trae
«Corregir» (reabre Revisar con la nota que pedía el servidor).

**Formulación.** Página: agave cocido con saldo (kg) y reparto a tinas
libres (litros) con `origin-allocation` (extraído en destilacion/r01),
molino, agua, insumo, folio opcional, cuándo y método →
`registrar_formulacion`. Requiere señal. **Tina que ya fermentaba:** capa
de tres campos → `registrar_entrada('fermentado')` (DUDAS #7).

## Estados

Carga · sin tinas en uso · la empresa no tiene tinas · todas medidas hoy ·
sin conexión (instantánea) · pendiente / fallo en cola · solo lectura ·
operador (sin gestionar) · detalle sin mediciones · anulada · confirmar
lista / cerrar · pasos · revisar con aviso · guardada (enviada, pendiente,
fallo) · error de dominio (ciclo cerrado) · formulación sin cocido / sin
tinas libres · sin permiso.

## Componentes usados

`app-shell` (banner de cola, FAB con acción) · `page-header` · `fab` ·
`list-stack` · `row-menu` · `state-block` · `task-layer` · `button` ·
`big-number-field` · `scale-choice` · `datetime-field` · `step-flow` ·
`soft-warning-note` · `status-chip` (`pending`, `failed`) · `banner`
(`cola`) · `number-field` · `select` · `text-field` · `file-picker`.

## Criterios verificados

Con Aurelia en Cuatro Vientos (escrituras reales): medición de Tina 2 con
Brix 19 → aviso → nota → enviada → «Ya medidas hoy» → anulada con motivo;
FAB solo en compact; formulación (estado vacío real); capa sin tinas libres.
E2E offline (§16): 3 mediciones en modo avión → banner «3 capturas» →
reconectar → llegan una sola vez y en orden → recargar no duplica. 4 anchos
× 2 temas sin desborde; 0 errores JS.

## No verificado

Modo completo con la RPC real desde la pantalla; foto real por la cola;
formulación real (sin cocido con saldo en la semilla); lector de pantalla;
zoom nativo.
