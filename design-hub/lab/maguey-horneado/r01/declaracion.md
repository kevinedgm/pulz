# Declaración de cumplimiento · MAGUEY y HORNEADO · r01

| Campo | Valor |
|---|---|
| Ruta | R1 |
| Fidelidad | F2 |
| Pregunta de diseño | ¿Puede el productor registrar una recepción en menos de un minuto con solo los kilos, abrir una horneada eligiendo qué maguey y cuántos kilos sin pasarse del saldo, y cerrarla con los kilos cocidos de forma que el cocido quede listo para la formulación? |
| Artefactos | `brief.md` (brief + flujo) · `index.html` (wireframe, kit inline) · `hallazgos.md` · `declaracion.md` |
| Modifica producción | No |

## Estándares leídos

`wireframing.md`, `fidelidad.md`, `validacion.md`, `hig-web-pwa.md`; WCAG 2.2 AA; `0015`, `0016`, `0011` (`solid_lot_balances`); catálogos de especies, predios y proveedores; piezas de las rondas anteriores.

## Desviaciones del protocolo

Ninguna. Aprobación en automático (`CLAUDE.md` §4): roles = `rpc_guard` y §18 #4 (supuesto vigente).

## Comprobaciones ejecutadas

- `check_artifact.py --fidelidad F2`: 0 errores · 0 avisos.
- Chromium (Playwright): **60 combinaciones** (3 espacios × 20 estados): sin desborde, ≤1 primaria visible por vista, 0 targets <44 px, 0 errores JS. Un hallazgo corregido en la validación: el enlace «Agregar en Catálogos» medía menos de 44 px.
- Estados: maguey default · carga · vacío · sin conexión · solo lectura · operador · contenido largo · recepción · sin catálogos · error · horneado default · vacío · sin hornos · sin conexión · abrir · abrir por encima del saldo · abrir sin maguey · cerrar (capa) · cocido que ya tenía (capa) · menú.

## Matriz de adaptación

| Elemento | compact (<600) | medium (600–1023) | expanded (≥1024) | Motivo | Técnica |
|---|---|---|---|---|---|
| Primaria (Registrar recepción / Abrir horneada) | FAB | cabecera | cabecera | una primaria | `fab` con acción / `page-header` |
| Filas de lote y horneada | apiladas | apiladas | una línea | como destilación | grid |
| Recepción / Abrir | una columna; primaria en barra con kilos | parejas | parejas | formulario corto | página |
| Cerrar / Cocido que ya tenía | hoja | drawer | drawer | 3–5 campos | `task-layer` |

## Comprobaciones NO ejecutadas

- Recepción, horneada y cierre reales contra el proyecto: en coco.

## Traspaso

- **→ lima · sin piezas nuevas del sistema.** Reutiliza `origin-allocation` (kg), `datetime-field`, `task-layer`, `list-stack`, `row-menu`, `state-block`, `banner`, `button`, `select`, `number-field`, `text-field`, `status-chip`, `fab`. **Local (product-application `maguey-horneado`):** `MagueyPage`, `RecepcionPage`, `HorneadoPage`, `AbrirHorneadaPage`, `CerrarHorneadaCapa`, `CocidoCapa`, `api.ts`.
- **Datos (`coco.data_contract`):** `LoteSolido` = `solid_lot_balances` + `maguey_receptions` (especie, predio, proveedor, piñas, kg, nota) + operación (cuándo, quién); `Horneada` = `roasting_runs` + `roasting_run_inputs`; `Recepcion = { kg, especie?, predio?, proveedor?, pinas?, nota?, folio?, occurred_at }` → `registrar_recepcion_maguey`; `NuevaHorneada = { horno, lotes: [{lot_id, kg}], folio?, occurred_at }` → `abrir_horneada`; `Cierre = { horneada, kg_cocidos, combustible?, folio?, nota?, occurred_at }` → `cerrar_horneado`; `CocidoPrevio = { kg, nota?, occurred_at }` → `registrar_entrada('agave_cocido')`.
- **→ coco:** rutas `/e/:slug/maguey`, `/…/maguey/recepcion`, `/e/:slug/horneado`, `/…/horneado/abrir`; `destinos.ts` sin `proximamente` para Maguey y Horneado. Evidencia real con Aurelia: recepción de 2,000 kg de Tobalá; horneada con esos 2,000 kg; cierre con 1,800 kg cocidos; el cocido aparece en Fermentación → Formulación.

## Siguiente paso

Aprobación automática (CLAUDE.md §4) → lima → coco → mora.
