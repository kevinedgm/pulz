# Declaración de cumplimiento · DESTILACIÓN · r01

| Campo | Valor |
|---|---|
| Ruta | R1 |
| Fidelidad | F2 |
| Pregunta de diseño | ¿Puede el operador, junto al alambique y sin señal, registrar un corte (clase, litros, % Alc.) en menos de 20 segundos sin equivocarse de colector, y ver de un vistazo qué corridas están abiertas, qué se ha cortado y qué hay en cada colector? |
| Artefactos | `brief.md` (brief + 2 flujos) · `index.html` (wireframe, kit inline) · `hallazgos.md` · `declaracion.md` |
| Modifica producción | No |

## Estándares leídos

`wireframing.md`, `fidelidad.md`, `validacion.md`, `hig-web-pwa.md`; WCAG 2.2 AA; `0018`, `0019` (transferir), `0026`; `organization_settings`; ronda fermentacion/r01 (piezas reutilizadas y su evidencia).

## Desviaciones del protocolo

Ninguna. Aprobación en automático (`CLAUDE.md` §4): roles = `rpc_guard`; reglas de clase/colector y capacidad = RPC.

## Comprobaciones ejecutadas

- `check_artifact.py --fidelidad F2`: 0 errores · 0 avisos.
- Chromium (Playwright): **66 combinaciones** (3 espacios × 22 estados): sin desborde, ≤1 primaria visible por vista, 0 targets <44 px, 0 errores JS.
- Estados: corridas default · carga · vacío · sin alambiques · sin conexión (instantánea, corte pendiente) · corte con fallo (corrida cerrada) · solo lectura · operador · menú · contenido largo · abrir (formulario) · abrir con aviso de mezcla 2ª y capacidad · abrir sin orígenes · corrida abierta con cortes · sin cortes · cerrada · cerrar (confirmar) · corte paso 1 clase · paso 2 litros · revisar con aviso de capacidad · guardado pendiente · sin colector de esa clase.
- Capturas revisadas: 1440 corridas, 390 corridas / corte paso 1 / abrir con aviso / corrida.

## Matriz de adaptación

| Elemento | compact (<600) | medium (600–1023) | expanded (≥1024) | Motivo | Técnica | Foco/estado |
|---|---|---|---|---|---|---|
| Primaria «Abrir corrida» | FAB | botón en cabecera | botón en cabecera | una primaria; «Registrar corte» por corrida es secundaria | `fab` con acción / `page-header` | — |
| Fila de corrida / colector | apilada | apilada | una línea | igual que fermentación | grid por container | chips de cola en la fila |
| Abrir corrida | una columna; primaria en barra del pulgar; el botón dice los litros | parejas en dos columnas | igual | formulario largo con decisión (orígenes) | página | total y avisos en vivo |
| Corrida | una columna; «Registrar corte» en barra | una columna | dos columnas (cortes \| acciones) | igual que uso de tina | grid | — |
| Corte | un paso por pantalla, barra fija | centrado 520 | igual | igual que medición | `step-flow` | Atrás conserva |
| Diálogo cerrar | hoja inferior | centrado | centrado | destructiva con Cancelar primaria | `task-layer` | foco vuelve |

## Comprobaciones NO ejecutadas

- Corte por la cola contra el proyecto y e2e con 2 cortes en modo avión: en coco (extiende `e2e-offline.mjs`).
- Puntas con `record_puntas` encendido: en coco por Vitest (la semilla lo tiene apagado).

## Hallazgos

Ver `hallazgos.md`: 3 altos (colector por clase; «pasar a granel» es transferir; abrir requiere señal con avisos conocidos antes), 3 medios, 2 bajos.

## Traspaso

- **→ lima · pieza candidata al sistema (nueva):** `origin-allocation` (patrón: lista de orígenes con saldo, campo de cantidad, total vs. capacidad y aviso local) — ya existe inline en `FormularPage` (fermentación): extraer y reutilizar aquí y en horneado. **Reutiliza:** `step-flow`, `big-number-field`, `datetime-field`, `soft-warning-note`, `segmented-choice` (pasada), `status-chip` (`pending`, `failed`, `partial` abierta, `off` cerrada, `on` con saldo), `banner`, `list-stack`, `row-menu`, `state-block`, `task-layer`, `button`, `select`, `number-field`, `text-field`, `file-picker`. **Local (product-application `destilacion`):** `DestilacionPage`, `AbrirCorridaPage`, `CorridaPage`, `CortePage`, `FilaCorrida`, `FilaColector`, `ConfirmarCierre`, `api.ts` (puras: `colectorPorClase`, `avisosDeApertura`, `avisoCapacidadColector`).
- **Datos (`coco.data_contract`):** `Corrida` = fila de `corridas` (orígenes y cortes jsonb); `ColectorConSaldo` = fila de `colectores_con_saldo`; `NuevaCorrida = { alambique, pasada, origenes: [{resource_id, lot_id, litros}], nota?, folio?, occurred_at }` → `abrir_corrida`; `NuevoCorte = { corrida, clase, litros, abv, colector, nota?, folio?, occurred_at, idempotency_key, foto? }` → `registrar_corte` por la cola; `cerrar_corrida(corrida, nota?, cuándo)`; orígenes cargables = `tinas_en_uso` (litros > 0) + `colectores_con_saldo`; alambiques = `resources` kind alambique.
- **→ coco:** rutas `/e/:slug/destilacion`, `/…/destilacion/abrir`, `/…/destilacion/:corrida`, `/…/destilacion/:corrida/corte`; `destinos.ts` sin `proximamente` para destilación; instantánea de `corridas`, `colectores_con_saldo`, colectores activos, `record_puntas`. Evidencia real con Tomás (operador) en Cuatro Vientos: abrir DES-004 en Alambique 1 con 290 L de Tina 1 (lista), cortes 8 mezcal @ 51, 40 ordinario @ 24, 12 colas @ 9, cerrar; e2e offline extendido con 2 cortes en modo avión (§16: «3 mediciones y 2 cortes»).
- **→ mora:** nada hasta implementar.

## Siguiente paso

Aprobación automática (CLAUDE.md §4) → lima → coco → mora.
