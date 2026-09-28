# Destilación: corridas y cortes · `destilacion`

| Campo | Valor (fuente) |
|---|---|
| Tipo · Estado · Versión | product-application · **candidate 0.2.0** · owner lima (registry) |
| Ronda de origen | `lab/destilacion/r01` |
| Código | `apps/web/src/modules/destilacion/{api.ts, routes.ts, pages/{DestilacionPage,AbrirCorridaPage,CorridaPage,CortePage}.vue, components/{FilaCorrida,FilaColector,ConfirmarCierre}.vue}` |
| Rutas | `/e/:slug/destilacion` (destino, FAB «Abrir corrida») · `/…/destilacion/abrir` · `/…/destilacion/:corrida` · `/…/destilacion/:corrida/corte` |
| Pruebas | `modules/destilacion/__tests__/api.test.ts` (6) · `qa/evidencia-destilacion.mjs` · `qa/e2e-offline.mjs` (3 mediciones + 2 cortes) |
| Evidencia | `qa/evidence/destilacion-r01/*` · `qa/evidence/fase5-offline/*` |

## Propósito

Abrir una corrida cuando hay olla libre con lo que haya en el origen,
registrar cada corte al salir del alambique —a veces sin señal— y cerrarla
(§4.5, §8.3, §13.2 #5).

## Cómo funciona

**Corridas.** «Corridas abiertas» (folio, alambique, pasada, cuándo y quién,
cargó N L desde qué, cortó M L por clase, chip; «Registrar corte» + menú
ver/cerrar), «Colectores con contenido» (clase, lote vivo, litros, % Alc.
declarado; **«Pasar a granel»** para el mezcal = transferir, ronda granel,
admin/productor) y «Últimas corridas» (10 cerradas). Primaria: «Abrir
corrida» (FAB en compact). Sin señal: instantánea; cortes sí; abrir y cerrar
no.

**Abrir corrida.** Alambique (capacidad y política), pasada (1ª/2ª),
orígenes con litros (`origin-allocation`: tinas con contenido —listas
primero— y colectores con saldo); capacidad estricta bloquea antes;
flexible → `excede_capacidad` con nota; 2ª con ordinario y colas →
`mezcla_clases_2a` con nota (si el ajuste avisa); ¿cuándo pasó?; folio
opcional → `abrir_corrida`. El botón dice «Abrir corrida con 290 L».

**Corrida.** KPIs (cargados, cortados, por clase), orígenes, cortes (más los
que esperan en la cola, con chip pendiente/fallo y Corregir/Descartar),
«Registrar corte», «Cerrar corrida» (diálogo: cargado vs. cortado; la
diferencia no queda como lote; Cancelar primaria).

**Corte.** `step-flow`: Clase (mezcal · ordinario · colas · puntas si
`record_puntas`; el colector se elige solo por la clase, select si hay
varios, bloqueo con enlace a Recursos si no hay) → Litros → % Alc. →
Revisar (colector con saldo y capacidad; `excede_capacidad` con nota si es
flexible; estricta bloquea; nota; foto). Guardar **siempre encola**
(`registrar_corte`) → «enviado / pendiente» → «Registrar otro corte».

## Estados

Carga · sin alambiques · sin corridas abiertas · default · sin conexión ·
corte pendiente / fallo (Corregir si pide nota, Descartar si no) · solo
lectura · abrir sin orígenes · abrir con avisos · corrida sin cortes / con
cortes / cerrada · cerrar (confirmar) · corte por pasos · sin colector de la
clase · revisar con aviso · guardado enviado / pendiente / fallo · corrida
ya cerrada.

## Componentes usados

`app-shell` · `page-header` · `fab` · `list-stack` · `row-menu` ·
`state-block` · `task-layer` · `button` · `origin-allocation` · `step-flow`
· `big-number-field` · `datetime-field` · `soft-warning-note` ·
`segmented-choice` · `status-chip` · `banner` · `select` · `number-field` ·
`text-field` · `file-picker`.

## Criterios verificados

Con Aurelia en Cuatro Vientos (escrituras reales): corrida abierta en
Alambique 1 con 290 L de la Tina 1; tres cortes por la cola (mezcal 8 @ 51,
ordinario 40 @ 24, colas 12 @ 9) que la corrida suma a 60 L; colectores con
contenido con «Pasar a granel»; cierre con diálogo destructivo; FAB solo en
compact. E2E offline (§16): 3 mediciones **y 2 cortes** en modo avión
llegan una sola vez y en orden. 4 anchos × 2 temas sin desborde.

## No verificado

Puntas con `record_puntas` (por Vitest); varios colectores de la misma
clase (por tipos); foto real de un corte por la cola; lector de pantalla;
zoom nativo.
