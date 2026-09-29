# Fase 5 · Captura por etapa y offline

> **Revisión vigente: 2026-09-28.** Ver
> [implementación, pruebas nuevas y pendientes](CONTINUACION-2026-09-28.md).
> Los resultados fechados de abajo son históricos, no certifican el estado actual.

> Sigue `PULZ_MAESTRO.md` §16 (Fase 5), §4 (el proceso etapa por etapa), §5
> (granel y catálogo de movimientos), §8.3 (offline), §11.1 (roles), §12
> (RPC), §13.2 (pantallas 3–6), §13.3 (accesibilidad de campo), §15 (pruebas)
> y `CLAUDE.md` (nunca Docker; migraciones "desde cero"; **toda pantalla
> empieza por `kiwi`**; decisiones en automático per §4). Objetivo, literal
> de §16: *"Maguey, horneado, formulación, fermentación con medición diaria
> (dos modos), destilación con cortes, granel con catálogo de movimientos.
> Cola offline para mediciones, cortes y fotos."* **Acepta:** *"E2E del
> proceso completo de la simulación desde la interfaz; E2E offline:
> registrar 3 mediciones y 2 cortes en modo avión, reconectar, que lleguen
> una sola vez y en orden; los avisos blandos piden nota y quedan
> registrados."*
>
> **Estado (2026-09-27): plan decidido en automático** (`CLAUDE.md` §4): no
> toca precio, límites ni roles del maestro; los supuestos de negocio que sí
> abre van a `docs/DUDAS.md` y se implementa el supuesto (fácil de cambiar).

## Qué entra y qué no

**Entra (§16 Fase 5):** los cinco destinos de proceso dejan de ser
"próximamente":

- **Maguey**: recepciones (`registrar_recepcion_maguey`) y lista de lotes de
  maguey con saldo sólido.
- **Horneado**: abrir y cerrar horneadas, entrada directa de agave cocido
  (`registrar_entrada('agave_cocido')`), lista de cocido con saldo.
- **Fermentación**: **usos** de tinas (no tinas, §13.1), formulación que
  reparte a tinas (§4.3 — vive aquí porque su resultado son ciclos), **medición
  diaria en dos modos** (§4.4, §13.2 #4: una mano, números grandes, un gesto
  por pantalla, sin señal), anular con motivo, declarar lista, cerrar ciclo.
- **Destilación**: corridas (abrir con orígenes tina/colector y litros,
  cortes por clase con litros y % Alc. a colector o a granel, cerrar),
  colectores con contenido; avisos blandos con nota.
- **Granel**: tanques con saldo, grado declarado vigente (quién y cuándo),
  historial (`movement_log`), Entrada / Salida / Transferir con el
  comportamiento de cada concepto (crea lote, pide resultado, pide
  contraparte), conservar o renombrar folio, conciliación automática visible.
- **Inicio / hoy real** (§13.2 #3): tinas que toca medir hoy, corridas
  abiertas, colectores con contenido, capturas pendientes de enviar.
- **Cola offline** (§8.3): mediciones, cortes y fotos en IndexedDB con
  `idempotency_key` y `occurred_at` reales; envío en orden al volver la señal;
  contador y fallos visibles. Todo lo demás **requiere señal** y la interfaz
  lo dice, no falla en silencio.
- **"¿Cuándo pasó?" en toda captura**: `occurred_at` editable con valor por
  defecto "ahora" (§3 operación; hace posible rehacer la simulación con sus
  fechas y capturar "lo de ayer").
- **Foto opcional** en medición y corte: `attachments` (0008) + bucket privado
  `evidencias` (nuevo, por migración) con el tipo de adjunto del catálogo;
  en la cola viaja el blob y sube al reconectar.

**No entra:** árbol de trazabilidad, nivel de historia y completar historia
(Fase 6: el destino Trazabilidad sigue "próximamente"); `corregir_operacion`
como pantalla (Fase 6, junto a la bitácora); cobro; recordatorio por
notificación push (la "hora del recordatorio" solo ordena Inicio; ver
riesgos); edición de fotos.

## Lo que el esquema y las RPC ya resuelven (no se inventa nada)

| Pantalla | Lee (bajo RLS) | Escribe (RPC, 0014–0020) | Quién (§11.1 = `rpc_guard` real) |
|---|---|---|---|
| Maguey | `lots` maguey + `solid_lot_balances`; `species`, `predios`, `suppliers` | `registrar_recepcion_maguey(kg, especie?, predio?, proveedor?, piñas?, nota?, folio?)` | admin, productor |
| Horneado | `roasting_runs` + `roasting_run_inputs`; `solid_lot_balances` | `abrir_horneado(horno, lotes[], kilos[])` · `cerrar_horneado(horneado, kg cocidos, combustible?)` · `registrar_entrada('agave_cocido', …)` | admin, productor |
| Fermentación | `fermentation_cycles` (+ `fermentation_measurements`, `measurement_readings`), `resources` tina, `organization_settings` (modo, días esperados, rangos Brix) | `registrar_formulacion(molino, cocido[], kilos[], agua, tinas[], litros[], insumos?)` · `registrar_medicion(ciclo, día, modo, actividad?, variables[], zonas[], números[], valores[])` · `anular_medicion(motivo)` · `declarar_tina_lista` · `cerrar_ciclo` · `registrar_entrada('fermentado', tina)` (tina que ya fermentaba, DUDAS #7) | medición: **admin, productor, operador**; anular/formular/lista/cerrar: admin, productor |
| Destilación | `distillation_runs` + inputs + `distillation_cuts`; `resource_lot_balances` de tinas y colectores; `organization_settings.record_puntas` | `abrir_corrida(alambique, pasada, recursos[], lotes[], litros[])` · `registrar_corte(corrida, clase, litros, abv, colector)` · `cerrar_corrida` | abrir/corte: **admin, productor, operador**; cerrar: admin, productor |
| Granel | `resource_lot_balances` + `lot_declared_abv` + `movement_log`; `movement_concepts` (dirección, crea lote, pide resultado, pide contraparte, lote de origen) | `transferir(origen, destino, lote, litros, abv?, decisión, folio nuevo?)` · `registrar_movimiento_granel(concepto, tanque, litros, …resultado, contraparte, datos de compra)` | admin, productor |
| Inicio / hoy | las vistas nuevas de abajo + cola local | — | todos |

Avisos blandos que la interfaz debe saber pedir con nota (`REQUIERE_NOTA:<código>`,
§12.1): `mezcla_clases_2a`, `abv_fuera_rango`, `brix_fuera_rango`,
`excede_capacidad` (política flexible), `cierre_con_saldo`,
`diferencia_volumen` (conciliación) y `contraparte` (salidas que la piden).
Errores duros: `SALDO_INSUFICIENTE:`, `CAPACIDAD_EXCEDIDA:`, `NO_PERMITIDO:`,
`LIMITE_PLAN:`. Un solo traductor en `shared/supabase/errores.ts` (ya existe
para acceso; crece con estos prefijos) y **un solo patrón de interfaz** para
"aviso → pide nota → reintenta con la nota".

## Servidor primero (no depende de la compuerta de interfaz)

1. **`0026_vistas_proceso.sql`** — vistas `security_invoker` que dan a la
   interfaz lo derivado sin lógica en el cliente (§8.2):
   - `tinas_en_uso`: ciclo, tina (código, capacidad), lote (folio), estado,
     `started_at` (de la operación), **día de hoy** (`current_date -
     started_at::date + 1`, en la zona horaria de la operación), última
     medición (fecha, día, actividad, promedio de temperatura y Brix al
     vuelo), litros dentro (`resource_lot_balances`), formulación (si la hay).
   - `corridas_abiertas`: corrida, alambique, pasada, litros cargados,
     litros cortados por clase, hora de apertura, quién.
   - `colectores_con_saldo`: colector, clase, lote vivo, litros, grado
     declarado vigente.
   - `tanques`: tanque, lote(s), litros, grado declarado (quién, cuándo).
   - `mediciones_del_ciclo`: una fila por medición con sus lecturas agregadas
     (promedio por variable y zona), anuladas incluidas y marcadas.
2. **`0027_evidencias.sql`** — bucket privado `evidencias` (10 MB, jpeg/png/webp/pdf)
   con políticas por empresa (`is_member` para leer/subir; borrar nadie) y
   catálogo `tipo_adjunto` sembrado si 0004 no lo trae ya; RLS de
   `attachments` verificada (0013).
3. **pgTAP `proceso.test.sql`**: cada vista contra la simulación de Cuatro
   Vientos (Tina 1 lista con 5 mediciones; Tina 2 fermentando día N; Tina 3
   sin formulación; corridas cerradas; colector colas 16 L; Tanque 1 250 L y
   Tanque 2 341.8 L con su grado y quién lo declaró); aislamiento (Prueba B
   ve vacío); bucket y políticas.
4. `supabase db reset --linked --yes` · `db query --linked -f` · `db advisors
   --linked` con 0 errores.

Las RPC **no se tocan** salvo que una pantalla demuestre un hueco; si pasa,
se edita la migración correspondiente (régimen "desde cero") y se anota en
`DECISIONES.md`.

## Cola offline (§8.3) — infraestructura antes de la primera pantalla

`apps/web/src/shared/offline/`:

- `cola.ts`: IndexedDB (`pulz-cola`, un store por empresa). Elemento:
  `{ id = idempotency_key (uuid del teléfono), org, rpc, params, occurred_at,
  creado_en, estado: pendiente | enviando | fallo, error?, intentos }`.
  `encolar()` devuelve enseguida; `enviar()` recorre **en orden de creación**,
  llama la RPC, y ante error de **red** se detiene (lo reintenta el siguiente
  disparo); ante error de **dominio** (`P0001`) marca `fallo` con el mensaje
  traducido y sigue con el siguiente. Disparos: evento `online`, arranque de
  la app, botón "Reintentar". Reenviar es seguro: la RPC devuelve el
  resultado original por `idempotency_key` (§12.1).
- `fotos.ts`: el blob viaja en la cola (IndexedDB guarda `Blob`); al enviar,
  sube a `evidencias/<org>/<operation_id>/<uuid>.<ext>` y crea la fila de
  `attachments`.
- `instantanea.ts`: última respuesta de `tinas_en_uso`, `corridas_abiertas`,
  `colectores_con_saldo` y ajustes por empresa, guardada en IndexedDB para
  que Fermentación y Destilación **se abran sin señal** con "datos de hace X
  min"; las escrituras de la cola se reflejan encima (medición pendiente se
  ve como "hoy: enviada / pendiente").
- `useCola()`: `pendientes`, `fallos`, `enviando`, `reintentar()`; el shell lo
  muestra en el banner y en Inicio.
- Solo **medición, corte y foto** pasan por la cola. El resto de acciones,
  sin señal, se deshabilitan con texto ("Necesitas señal para transferir").
- Vitest con `fake-indexeddb` (devDependency, sin costo): orden, una sola vez,
  fallo de dominio no bloquea, fallo de red sí, reanudación tras recargar.

## Compuerta de interfaz (CLAUDE.md §3) — cinco rondas de kiwi, en orden

Cada ronda: `kiwi` → aprobación automática registrada en `DECISIONES.md`
→ `lima` → `coco` → `mora-docs`, como shell/configuración/arranque. Todas
dentro del shell; todas con "¿Cuándo pasó?" y con el patrón de aviso blando.

**Ronda 1 · `lab/fermentacion/r01` — usos de tinas y medición diaria.**
Brief: §4.4 y §13.2 #4. Lista de tinas en uso (día N de M esperados, última
medición, litros, estado) ordenada por "toca medir"; **medición** como
pantalla de una mano: números grandes, un gesto por pantalla (temperatura →
Brix → actividad en mínimo; en completo, 3 lecturas superficie/fondo + dulzor
y acidez 1–6), promedio al vuelo, aviso `brix_fuera_rango` con nota, guardado
que **siempre** entra a la cola y dice "enviada" o "pendiente de enviar";
anular con motivo; declarar lista; cerrar ciclo; formulación (molino, cocido
en kg, agua, insumos, reparto a tinas con litros y folios opcionales); tina
que ya fermentaba (entrada `fermentado`). Estados: sin tinas, sin ciclos,
tina lista, en vaciado, sin señal (con instantánea), pendientes en cola,
fallo con motivo, sin permiso (operador solo mide). Piezas candidatas:
`big-number-field` (número grande con teclado numérico), `reading-stepper`
(1–6 con etiqueta), `pending-chip` (enviada/pendiente/fallo),
`soft-warning-note` (patrón aviso→nota), `when-field` (¿cuándo pasó?).

**Ronda 2 · `lab/destilacion/r01` — corridas y cortes.** §4.5, §13.2 #5.
Corridas abiertas por alambique; abrir: alambique, pasada, orígenes (tinas
listas o colectores con saldo) con litros de cada uno y aviso de capacidad;
cortes: clase (puntas solo si `record_puntas`), litros, % Alc., destino
(colector de esa clase o tanque para "ya mezcal"), aviso `abv_fuera_rango`,
`mezcla_clases_2a` al abrir 2ª con ordinario y colas; cerrar (aviso
`cierre_con_saldo`). Cortes por la cola. Colectores con contenido. Piezas
candidatas: `origin-allocation` (lista de orígenes con cantidad y saldo),
reutiliza las de la ronda 1.

**Ronda 3 · `lab/granel/r01` — tanques y movimientos.** §5, §13.2 #6.
Tanque: saldo, lote(s), grado declarado vigente con quién y cuándo, historial
filtrable; Entrada / Salida / Transferir según el catálogo: el formulario se
arma con `crea lote`, `pide resultado` (volumen y % Alc. resultantes: **el
sistema no calcula el grado**), `pide contraparte`, `lote de origen`;
conservar/renombrar folio al juntar (sugerencia = lote mayor; ajuste
`default_folio_decision`); compra de granel con certificado opcional;
conciliación automática mostrada como "el sistema registró una diferencia de
X L". Requiere señal. Piezas candidatas: `movement-form` (patrón por
concepto), `folio-decision` (conservar/renombrar).

**Ronda 4 · `lab/maguey-horneado/r01` — recepción y horneadas.** §4.1–4.2.
Dos destinos, una ronda: recepción (kg obligatorio, especie, piñas, predio,
proveedor, nota); lotes de maguey con saldo; horneadas abiertas/cerradas;
abrir (horno, lotes con kg, aviso de saldo sólido), cerrar (kg cocidos,
combustible), entrada directa de cocido; lotes de cocido con saldo.
Reutiliza `origin-allocation` (kg en vez de L).

**Ronda 5 · `lab/inicio-hoy/r01` — Inicio con datos reales.** §13.2 #3.
Reemplaza el bloque "Hoy" provisional: tinas que toca medir hoy (por la hora
del recordatorio y la última medición), corridas abiertas, colectores con
contenido, capturas pendientes de enviar (con "Reintentar"), acceso directo
a medir; conserva "¿Qué tienes hoy?" → arranque cuando no hay lotes. Va al
final porque compone lo que las otras cuatro producen.

Orden de construcción en coco: cola offline → 1 → 2 → 3 → 4 → 5. kiwi puede
adelantar las rondas 2–4 mientras coco construye la 1.

## Tareas, en orden

1. Servidor 1–4 (`0026`, `0027`, pgTAP `proceso.test.sql`, reset, advisors).
2. Cola offline + instantánea + fotos (`shared/offline/`), Vitest con
   `fake-indexeddb`; traductor de errores con los prefijos y códigos de §12.1.
3. Ronda **fermentacion/r01** completa (kiwi → lima → coco → mora), incluida
   la interfaz de la cola en el shell (banner y contador).
4. Ronda **destilacion/r01**.
5. Ronda **granel/r01**.
6. Ronda **maguey-horneado/r01**.
7. Ronda **inicio-hoy/r01**.
8. **E2E proceso completo** (`qa/e2e-fase5.mjs`, real contra el proyecto
   alojado): en **Prueba B** (vacía) rehacer la simulación de
   `supabase/seed.sql` **desde la interfaz** con sus fechas (recursos por
   Configuración; carga inicial; Tina 3 que ya fermentaba; maguey; horneada;
   formulación a dos tinas; mediciones; lista; DES-001/002 de 1ª; DES-003 de 2ª
   con ordinario y colas → nota; transferencia a granel con folio nuevo;
   compra; agua; ventas…) y comprobar que los saldos finales de Prueba B
   coinciden con §15.1 (Colector colas 16 · Tanque 1 250 · Tanque 2 341.8 ·
   Tina 1 870 · Tina 2 1,400 · Tina 3 1,300) leyendo `resource_lot_balances`.
9. **E2E offline** (`qa/e2e-offline.mjs`): Playwright `context.setOffline(true)`
   tras cargar Fermentación → 3 mediciones y 2 cortes → contador "5
   pendientes" → `setOffline(false)` → llegan **una sola vez y en orden**
   (`operations` por `occurred_at`, 5 filas, `idempotency_key` únicas);
   segundo `enviar()` no duplica; `operation_warnings` tiene la nota de los
   avisos provocados.
10. Evidencia 1440/1024/768/390 × claro/oscuro por ronda (`qa/evidencia-*.mjs`),
    zoom 200 % aproximado, Hub regenerado (`pnpm build:hub-site`) con cada
    ronda; `ESTADO.md`, `DECISIONES.md`, `DUDAS.md`; cierre con `db reset --linked`.

## Archivos que se tocan

- `supabase/migrations/20260927000026_vistas_proceso.sql`, `…0027_evidencias.sql`,
  `supabase/tests/proceso.test.sql`.
- `apps/web/src/shared/offline/{cola,fotos,instantanea,useCola}.ts` + tests;
  `shared/supabase/errores.ts` (prefijos y códigos); `shared/ui/` (piezas
  que lima registre); `app/AppShell.vue` (contador de la cola en el banner).
- `apps/web/src/modules/{fermentacion,destilacion,granel,maguey,horneado}/`
  (cada uno con `api.ts`, `routes.ts`, `pages/`, `components/`), reemplazando
  `modules/proceso/` (que se queda solo para Trazabilidad "próximamente");
  `modules/inicio/` (Hoy real); `app/destinos.ts` (quita `proximamente` de
  los cinco).
- `design-hub/lab/{fermentacion,destilacion,granel,maguey-horneado,inicio-hoy}/r01/`,
  `design-hub/system/registry.json`, fichas nuevas, `design-hub/site/`.
- `.claude/skills/lima/profiles/pulz.md` (`coco.data_contract`: Ciclo,
  Medición, Corrida, Corte, Tanque, Movimiento, Concepto, Recepción,
  Horneada, ElementoCola).
- `apps/web/package.json` (`fake-indexeddb` en dev).

## Cómo se comprueban los criterios de aceptación de §16 (Fase 5)

| Criterio | Comando / evidencia |
|---|---|
| E2E del proceso completo de la simulación desde la interfaz | `node design-hub/qa/e2e-fase5.mjs` → saldos de Prueba B = §15.1 (tabla comparada en el log) |
| E2E offline: 3 mediciones y 2 cortes en modo avión, reconectar, una sola vez y en orden | `node design-hub/qa/e2e-offline.mjs` → 5 operaciones, orden por `occurred_at`, sin duplicados tras reenviar |
| Los avisos blandos piden nota y quedan registrados | mismo e2e (2ª pasada mixta, Brix fuera de rango) → filas en `operation_warnings` con la nota escrita en pantalla |
| Cada pantalla con ronda de kiwi, compuerta de lima, auditoría de coco y ficha de mora | `design-hub/lab/*/r01/{declaracion,orden-coco,coco-declaracion,lima-compuerta}.md` + fichas + `site/` |
| Capturas sin desbordes | `qa/evidence/<ronda>/` 4 anchos × 2 temas + zoom |
| Vistas y bucket | pgTAP `proceso.test.sql` |

## Riesgos y dudas que esta fase abre

- **"Día" de la medición y "hoy"**: el teléfono decide `occurred_at`; el día
  del ciclo se sugiere desde `started_at` en la zona horaria del navegador y
  se puede corregir. Si dos personas en zonas distintas midieran la misma
  tina, el día podría diferir en uno; se acepta (palenque = una zona).
- **Recordatorio diario** (`measurement_reminder_hour`): sin notificaciones
  push en esta fase (necesitaría servidor de push o cron); Inicio usa la hora
  para ordenar "toca medir". Va a `DUDAS.md` #13.
- **Fotos offline**: blobs en IndexedDB pueden pesar; se reduce en el
  navegador a 1600 px máx. (misma técnica del logo) antes de encolar. Qué
  operaciones llevan foto (solo medición y corte en esta fase) → `DUDAS.md` #14.
- **Rehacer la simulación por interfaz** exige que **toda captura acepte
  fecha y hora**; sin eso el e2e no puede reproducir §15.1. Es una regla de
  producto real (capturar "lo de ayer"), no un artificio de prueba.
- **Modo completo de medición** (3 lecturas × 2 zonas × 2 variables + 3
  escalas = 15 números): la ronda 1 debe demostrar que cabe en "un gesto por
  pantalla" sin volverse un formulario; si no, kiwi abre r02.
- **Operador**: mide y corta, no abre horneadas ni transfiere (`rpc_guard`
  real); la interfaz esconde lo que no puede y muestra "sin permiso" por URL.
- **Trazabilidad** sigue "próximamente" hasta la Fase 6; Granel muestra el
  nivel de historia como texto, sin árbol.

## Decisiones tomadas en automático al abrir la fase (`CLAUDE.md` §4)

1. Formulación vive en Fermentación (su resultado son ciclos; §13.1 no le
   da destino propio).
2. Maguey y Horneado comparten ronda de kiwi (misma estructura lista + capa
   de tarea; dos destinos).
3. La cola offline se construye antes de la primera pantalla y se prueba por
   Vitest; su interfaz entra con la ronda 1.
4. Toda captura lleva "¿Cuándo pasó?" con valor por defecto ahora.
5. Foto opcional solo en medición y corte; bucket `evidencias` privado por
   migración.

## Resultados reales (2026-09-27) — servidor, tarea 1

| Qué | Comando real | Resultado |
|---|---|---|
| `0026_vistas_proceso.sql` (`tinas_en_uso`, `mediciones_del_ciclo`, `corridas`, `colectores_con_saldo`, `tanques`) y `0027_evidencias.sql` (bucket privado + políticas + insert de `attachments`) | `supabase db reset --linked --yes` | **OK**: 27 migraciones + semilla |
| pgTAP de proceso | `supabase db query --linked -f supabase/tests/proceso.test.sql` | **57/57**: las vistas reproducen §15.1 (Tina 1 870 L en vaciado con 5 mediciones; Tina 2 1,400; Tina 3 1,300 sin formulación; DES-001 290 L cargados / 60 cortados; DES-003 2ª pasada con dos orígenes; Colector colas COL-002 16 L a 10 %; Tanque 1 250 L G-COMPRA-01 46 % declarada; Tanque 2 341.8 L a 44.9 % por Benito), Prueba B ve vacío, bucket privado con 2 políticas, el operador adjunta su foto, nadie edita, B no adjunta a A |
| pgTAP de configuración tras renombrar `storage_org_of` | `…configuracion.test.sql` | **37/37** |
| Advisors | `supabase db advisors --linked` | 0 errores |

## Resultados reales (2026-09-27) — cola offline y ronda fermentacion/r01 (tareas 2–3)

| Qué | Comando real | Resultado |
|---|---|---|
| Cola offline (`shared/offline/`) | `vitest` (`cola.test.ts` 8, `rpc.test.ts` 4) | **OK**: en orden, una sola vez, red detiene, dominio no bloquea, corregir/reintentar/descartar, foto tras la RPC, sobrevive a recargar |
| Ronda fermentacion/r01 (kiwi → lima → coco → mora) | `lab/fermentacion/r01/` completo; 6 piezas candidate 0.2.0; 3 extensiones 0.3.0; 6 fichas + sitio regenerado (36 fichas, 39 páginas, 0 rotos) | **OK** |
| Evidencia | `node design-hub/qa/evidencia-fermentacion.mjs` | **8/8**, 61 capturas, escrituras reales (medición con aviso y nota → anulada) |
| **E2E offline (§16)**: 3 mediciones en modo avión, reconectar, una sola vez y en orden | `node design-hub/qa/e2e-offline.mjs` | **OK**: 390 px, `setOffline` → 3 «pendiente de enviar» → banner «3 capturas» → señal → `operations` 13 → 16, claves únicas, `en_orden = true`, recargar no duplica (16 → 16). Los cortes se agregan en la ronda de destilación |
| Tipos · lint · Vitest | `vue-tsc -b` · `pnpm lint` · `vitest run` | ✔ · 0/0 · 90/90 |

Nota: la limpieza a mano de una corrida abortada anuló también las
mediciones de la semilla (ver DECISIONES); `db reset --linked` ejecutado
después y pgTAP `proceso.test.sql` en verde.

## Resultados reales (2026-09-27) — ronda destilacion/r01 (tarea 4)

| Qué | Comando real | Resultado |
|---|---|---|
| Ronda destilacion/r01 (kiwi → lima → coco → mora) | `lab/destilacion/r01/` completo; `origin-allocation` extraído de la formulación y reutilizado; `destilacion` candidate 0.2.0; 2 fichas nuevas + sitio regenerado | **OK** |
| Evidencia | `node design-hub/qa/evidencia-destilacion.mjs` | **8/8**, 37 capturas, escrituras reales (corrida abierta con 290 L de la Tina 1; 3 cortes por la cola; cierre con diálogo) |
| **E2E offline completo (§16)**: 3 mediciones **y 2 cortes** en modo avión | `node design-hub/qa/e2e-offline.mjs` | **OK**: 390 px; con señal abre una corrida chica y precarga Medir y Corte navegando dentro de la app; sin señal 3 mediciones + 2 cortes → «5 capturas pendientes» → señal → `operations` (medición + corte) 24 → 29, claves únicas, `en_orden = true`, recargar no duplica (29 → 29) |
| Tipos · lint · Vitest | `vue-tsc -b` · `pnpm lint` · `vitest run` | ✔ · 0/0 · 98/98 (107/107 con granel) |

## Resultados reales (2026-09-27) — ronda granel/r01 (tarea 5)

| Qué | Comando real | Resultado |
|---|---|---|
| Ronda granel/r01 (kiwi → lima → coco → mora) | `lab/granel/r01/` completo; `granel` candidate 0.2.0; ficha + sitio (42 páginas, 0 rotos) | **OK** |
| Evidencia | `db reset --linked` → `evidencia-destilacion.mjs` (deja mezcal en el colector) → `evidencia-granel.mjs` | **8/8** y **8/8**: 37 + 36 capturas; transferencia conservando G-COMPRA-01, agua con diferencia −0.2 L conocida antes y conciliada, venta con contraparte; historial con los tres |
| Tipos · lint · format · Vitest | `vue-tsc -b` · `pnpm lint` · `pnpm format` · `vitest run` | ✔ · 0/0 · ✔ · 107/107 |

Siguiente en aquel cierre: ronda `maguey-horneado/r01` → coco (antecedente,
no aprobación vigente).

## Resultados reales (2026-09-28) — ronda inicio-hoy/r01 (tarea 7)

| Qué | Comando real | Resultado |
|---|---|---|
| Ronda inicio-hoy/r01 (kiwi → lima → coco → mora) | `lab/inicio-hoy/r01/` completo; `inicio` 0.2.0 → **candidate 0.3.0**; ficha reescrita + sitio regenerado | **OK** |
| Vitest | `hoy.test.ts` (10: puras, cola con fallo/pendiente, permisos, instantánea, sin lotes) | **193/193** |
| Evidencia | `db reset` → `node design-hub/qa/evidencia-inicio-hoy.mjs` | **PASS**: 4 anchos × 2 temas + operador (41 capturas); Hoy con la semilla; medición real desde Hoy y vuelta con la tina fuera de «Toca medir»; sin señal con instantánea y Medir activo; Tomás sin Abrir corrida ni Pasar a granel |
| Tipos · lint · format | `vue-tsc -b` · `pnpm lint` · `pnpm format` | ✔ · 0/0 · ✔ |

Queda de la fase: **tarea 8** (E2E proceso completo en Prueba B) y la
concurrencia real (Fase 2); `db reset --linked` al cerrar cada corrida.

### Actualización 2026-09-28 · frente único r05

R05: navegación medium corregida; recuperación/identidad/origen de cocido y
fecha de instantánea reparados.183 locales y5 acceso alojado PASS. Aceptación
PARTIAL, draft0.2.1; no RPC de negocio reales ni accesibilidad física/nativa.
Ver [checklist](CHECKLIST-MAGUEY-HORNEADO.md) y
[resultado r05](../../design-hub/lab/maguey-horneado/r05/result.md).

### Antecedente 2026-09-28 · frente único r04

Maguey/Horneado implementado localmente en `modules/maguey-horneado/` con
recepción, apertura revisada, cierre y entrada directa. F2r04 nueva; código
con Foundations actuales;28 pruebas del módulo y168 locales app PASS.
Build app/demo PASS. Intención persistida e idempotente, reconexión, permisos,
foco, contraste y geometría verificados localmente. **Aceptación parcial**:
E2E alojado y accesibilidad completa pendientes; draft, no Candidate/Stable.
Ver [checklist vivo](CHECKLIST-MAGUEY-HORNEADO.md) y resultado r04. La evidencia
histórica no cierra esos pendientes ni autoriza escrituras de prueba ahora.
