# Declaración de cumplimiento · FERMENTACIÓN · r01

| Campo | Valor |
|---|---|
| Ruta | R1 |
| Fidelidad | F2 |
| Pregunta de diseño | ¿Puede una persona con el teléfono en una mano, bajo el sol y sin señal, registrar la medición de una tina en menos de 30 segundos y un solo gesto por pantalla, ver cuáles tinas le faltan hoy, y confiar en que lo capturado llega una sola vez cuando vuelve la señal? |
| Artefactos | `brief.md` (brief + 2 flujos) · `index.html` (wireframe, kit inline) · `hallazgos.md` · `declaracion.md` |
| Modifica producción | No |

## Estándares leídos

`wireframing.md`, `fidelidad.md`, `validacion.md`, `hig-web-pwa.md`; WCAG 2.2 AA (targets 44, foco, errores con causa, texto 200 %, no depender del color: chips con forma + texto); `0017`, `0016`, `0015`, `0026`; `organization_settings`; `shared/offline/`; rondas shell/r01 (FAB, cabecera, barra), configuracion/r01, arranque/r01 (tarjeta con botón que dice lo que hará).

## Desviaciones del protocolo

Ninguna. Aprobación de la ronda en automático (`CLAUDE.md` §4): no toca reglas de negocio del maestro (roles = `rpc_guard`; escala 1–6 = CHECK del esquema; modo por empresa = ajuste existente).

## Comprobaciones ejecutadas

- `check_artifact.py --fidelidad F2`: 0 errores · 0 avisos.
- Chromium (Playwright): **69 combinaciones** (3 espacios × 23 estados): sin desborde, ≤1 primaria visible por vista (cabecera / FAB / barra del pulgar se excluyen entre sí por rango), 0 targets <44 px, 0 errores JS.
- Estados: lista default · carga · vacío (sin tinas en uso) · sin tinas · todas medidas hoy · sin conexión (instantánea) · capturas en cola (pendiente + fallo con Corregir) · solo lectura · operador · menú de fila · contenido largo · detalle con mediciones · detalle sin mediciones · anular (motivo) · cerrar ciclo (confirmar, destructiva con forma distinta y Cancelar como primaria) · medir paso 1 · paso 3 escala · modo completo (3 lecturas + promedio) · revisar con aviso Brix y nota · guardada pendiente · error ciclo cerrado · formulación · tina que ya fermentaba (capa).
- Capturas revisadas: 1440 lista, 768 detalle, 390 lista / medir / completo / revisar / cola / formular.

## Matriz de adaptación

| Elemento | compact (<600) | medium (600–1023) | expanded (≥1024) | Motivo | Técnica | Foco/estado |
|---|---|---|---|---|---|---|
| Primaria «Medir» de la lista | FAB sobre la barra inferior | botón en la cabecera | botón en la cabecera | una primaria; en móvil al alcance del pulgar | `fab` (shell) / `page-header` acción | — |
| Fila de uso | tarjeta apilada: nombre+chip / última / acciones | igual | una línea: nombre · última · chip · acciones | lectura de un vistazo en escritorio; toque cómodo en móvil | grid con `grid-template-areas` por container query | el estado (pendiente / fallo) vive en la fila |
| Medición | un paso por pantalla; Siguiente en barra fija del pulgar; número 2.75 rem | igual, centrado a 520 px, botones bajo el campo | igual | «una mano, números grandes, un gesto por pantalla» (§13.2 #4) sin duplicar lógica | `step-flow`: mismo componente, la barra cambia de lugar por rango | Atrás conserva valores; la tina/día en la cabecera |
| Escala 1–6 | 6 botones de 52 px en una fila | igual | igual | cabe en 390 con márgenes de 16 | `scale-choice` (`radiogroup`) | etiqueta del valor en `aria-live` |
| Detalle | una columna: KPIs, tabla apilada, «Medir hoy» en barra, acciones | una columna; tabla apilada | dos columnas: mediciones \| acciones | acciones a la vista sin desplazar en escritorio | grid | — |
| Formulación | página, campos en una columna; primaria en barra | dos columnas por pareja | igual | larga; no cabe en hoja | página | — |
| Capa «tina que ya fermentaba» | hoja | drawer | drawer | 3 campos | `task-layer` | foco vuelve |
| Banner de cola | bajo la cabecera, con «Reintentar» | igual | igual | §8.3: cuántas esperan y cuáles fallaron | `banner` variante cola (shell) | — |

## Comprobaciones NO ejecutadas

- Envío real por la cola contra el proyecto y modo avión: en coco (`e2e-offline.mjs`).
- Modo completo con la RPC real (15 lecturas en arreglos paralelos): en coco.
- Lector de pantalla; zoom nativo.

## Hallazgos

Ver `hallazgos.md`: 3 altos (FAB con destino + cambiar tina; un concepto por paso; toda captura por la cola), 4 medios, 2 bajos.

## Traspaso

- **→ lima · piezas candidatas al sistema (nuevas):** `big-number-field` (número grande con teclado numérico, unidad y rango de entrada), `scale-choice` (1–6 con etiqueta viva), `datetime-field` («¿Cuándo pasó?»: ahora / cambiar fecha y hora), `step-flow` (patrón: cabecera con progreso + un paso + barra Atrás/Siguiente que en compact es fija), `soft-warning-note` (patrón: aviso blando conocido → nota obligatoria; y su rama de «Corregir» desde la cola). **Extiende:** `status-chip` con variantes `pendiente` / `fallo`; `banner` con variante `cola` (cuántas pendientes, cuántas fallaron, Reintentar). **Reutiliza:** `app-shell`, `page-header`, `fab`, `list-stack`, `row-menu`, `state-block`, `task-layer`, `button`, `number-field`, `select`, `text-field`, `banner`. **Local (product-application `fermentacion`):** `FermentacionPage`, `UsoTinaPage`, `MedirPage`, `FormularPage`, `FilaUso`, `TinaFermentabaCapa`, `api.ts` con las funciones puras de «día» y «toca medir hoy».
- **Datos (`coco.data_contract`):** `UsoTina` = fila de `tinas_en_uso`; `Medicion` = fila de `mediciones_del_ciclo`; `NuevaMedicion = { cycle_id, dia, modo, actividad?, lecturas: [{variable, zona, numero, valor}], nota?, occurred_at, idempotency_key, foto? }` → `registrar_medicion` (arreglos paralelos); `Formulacion = { molino, cocido: [{lot_id, kg}], agua_l, insumos?: [{supply_id, cantidad}], tinas: [{tina_id, litros, folio?}], metodo?, nota?, occurred_at, idem }` → `registrar_formulacion`; `TinaFermentaba = { tina_id, litros, occurred_at, idem }` → `registrar_entrada('fermentado')`; `Ajustes` (`measurement_mode`, `fermentation_expected_days`, `brix_warn_min/max`) en la instantánea.
- **→ coco:** rutas `/e/:slug/fermentacion`, `/…/fermentacion/formular`, `/…/fermentacion/:ciclo`, `/…/fermentacion/:ciclo/medir` (`meta.shell`, destino `fermentacion`; `fab` solo en la lista); `destinos.ts` sin `proximamente` para fermentación; banner de cola en `AppShell` (`useCola`); instantánea de `tinas_en_uso`, `mediciones_del_ciclo` (por ciclo abierto) y ajustes al cargar con señal. Evidencia real con Aurelia (productora) en Cuatro Vientos: medir Tina 2 (mínimo), y con `measurement_mode = completo` en Prueba B una medición de 15 lecturas; e2e offline con `context.setOffline`.
- **→ mora:** nada hasta implementar.

## Siguiente paso

Aprobación automática (CLAUDE.md §4) → lima → coco → mora.
