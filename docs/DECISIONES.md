# PULZ · Decisiones

> Qué se decidió, cuándo y por qué. Una entrada por decisión, no se borran.

## 2026-09-28 · R04 autónoma: implementación local, no promoción

- Autonomía del usuario: decidir detalles y continuar sólo Maguey/Horneado,
  sin pedir aprobación de cada paso. Nueva F2r04 resuelve navegación compacta
  y nota FAB; Lima permite construir F3 local, no release.
- Coco implementa con cuatro RPC existentes, sin migraciones/escrituras remotas.
  La intención incierta se guarda antes del envío por empresa/persona/destino,
  con fecha fija y rechazo tipado. No es cola offline ni envío automático.
- Dos revisores detectan y se corrigen problemas de reintento, reconexión,
  paridad demo/app, contraste y foco;28 pruebas del módulo y168 locales PASS.
- Lima mantiene draft0.2.0: falta E2E alojado, touch/AT/zoom/forced-colors y
  pulido del corte de Fermentación en medium. Mora puede documentar hechos
  verificados y límites, pero no presentar una página aceptada ni promover.
- Reversión acotada: retirar rutas del nuevo módulo y sus extensiones si se
  descarta; no tocar DB, FilaUso ni evidencia histórica. No borrar intenciones
  locales pendientes sin reconciliarlas con el servidor.

## 2026-09-28 · Frente único Maguey/Horneado y checklist verificable

- **Un solo frente:** checklist en `plan/CHECKLIST-MAGUEY-HORNEADO.md`;
  cada marca exige evidencia. No incluye concurrencia ni Inicio/hoy.
- **Kiwi r03:** borradores locales preservados, cantidades explícitas,
  controles de permiso, error/ARIA coherentes, foco cíclico y devolución.
  Columnas numéricas alineadas y rail completo; compact usa identidad de fila
  a todo el ancho y primaria en cabecera para no esconderla tras listas largas.
  Son decisiones F2, no tokens ni cambios de producto.
- **No aprobar por 11/11 tests:** confirmación muestra crowding de navegación
  a 320 px y nota heredada de FAB. Lima devuelve `MH-NAV-03`/`MH-DOC-03` a Kiwi
  r04; Coco/Mora bloqueados. Impeccable impide más pulido en este ciclo.
- **Reversión:** no hay cambios de producto/DB que deshacer en esta ronda.
  Para cambiar la propuesta, crear nueva ronda conservando r03 como evidencia;
  nunca sobrescribir r02, usar un PASS histórico ni borrar los tests nuevos.

## 2026-09-28 · Continuación: pruebas aisladas, grado declarado y assets canónicos

- **Fixtures por ejecución y rollback:** los fallos sobre la demo mutable no
  eran una base fiable para aceptar los planes. Se generan identidades nuevas
  conservando catálogos globales, se siembra por RPC y se prueban seis suites
  sin reset. Reversión: retirar el adaptador del runner, no restaurar/resetear
  datos de usuarios. Evidencia y límites en `plan/CONTINUACION-2026-09-28.md`.
- **El resultado declarado prevalece sobre el aporte en la misma operación:**
  `lot_declared_abv` podía mostrar 47 en lugar de 44.9. Filtro y desempate
  determinista, dos regresiones nuevas; primero candidato en rollback y luego
  actualización acotada de la vista alojada. No se calcula grado ni cambia
  la ley de negocio. Revertir exige reponer únicamente la definición anterior
  de esa vista (conservar security_invoker), nunca resetear la base.
- **Retirar el procedimiento dblink sobre la demo:** el rollback externo no
  deshace commits de otras sesiones. El SQL histórico aborta; nuevo runner
  de concurrencia usa tenant desechable. Tres intentos FAIL con limpieza;
  no se afirma aceptación. No reactivar el script antiguo como alternativa.
  El control de seguridad rechazó la repetición directa de una RPC durante
  diagnóstico: no se eludió; nuevas escrituras requieren alcance aprobado.
- **Assets canónicos, no nueva identidad visual:** dependencias fijadas de
  Lucide y Fontsource; se entregan Manrope/Instrument Serif localmente,
  preservando props del helper y geometría del logotipo. Cinco iconos de
  22 px pasan a 24 px canónicos. No cambia aprobación ni tokens base.
  Reversión acotada en `design-hub/lab/foundations-binding/r01/result.md`.
- **No promover Maguey/Horneado por un check mecánico:** dos revisores
  autorizados; nueva r02 mantiene defectos de flujo, composición y foco.
  Lima devuelve rule_ids a Kiwi, Coco/Mora bloqueados. Se alcanzó el límite
  de dos pasadas de Impeccable; la corrección siguiente vive en r03, no
  sobreescribe r02 ni reutiliza aprobación de r01. Revertir una propuesta no
  requiere cambiar producto: aún no se construyeron sus módulos.

## 2026-09-28 · Revisión del maestro y continuación de pendientes

- **Formulación respeta `capacity_policy`:** el cliente aplicaba capacidad
  dura a tinas flexibles. Se consume la política real y solo `estricta`
  bloquea. Flexible llega al aviso con nota de la RPC (§2.1). Sin cambiar
  estructura/estilo. Revertir: restaurar el límite cliente anterior, lo que
  reintroduciría la contradicción; mantener las nuevas pruebas como alarma.
- **Instantánea compartida:** se completa el paso 1 de la orden de Lima
  para Maguey/Horneado. Tres consumidores usan un solo helper y se preservan
  sus tipos públicos. Se espera la copia y se distinguen fallos de red de
  permisos/dominio. Revertir: restaurar las copias por módulo; conservar
  aislamiento por empresa y pruebas de error. No modifica el esquema de IDB.
- **Veredicto pgTAP, no exit code del CLI:** `db query` devuelve 0 aunque
  TAP falle. Nuevo runner comprueba resultados/planes, trata SKIP/TODO como
  parcial y guarda evidencia fechada; tests del parser añadidos a CI.
  Revertir: retirar scripts/entradas de package y CI, nunca asumir que el
  código 0 del CLI certifica negocio.
- **Prohibición de JSON limitada a tablas:** maestro §16, Fase 1, dice
  tablas; la prueba incluía vistas. Se filtra `BASE TABLE`, conservando las
  agregaciones de lectura aprobadas para `0026`. Revertir: retirar ese
  filtro solo si se aprueba extender la prohibición a vistas.
- **Sin reset para ocultar deriva de fixtures:** suites de saldos y RPC
  fallan con datos actuales. Se registra FAIL, no se cambian expectativas.
  Concurrencia `dblink` queda fuera del runner por commits externos al
  rollback. Próximo paso: fixtures aislados y dos sesiones verificables.
  Revertir esta estrategia requiere un entorno descartable o autorización
  específica para reconstruir el proyecto; no se resetea automáticamente.
- **No reaprobar rondas antiguas:** auditoría de lógica/pruebas sin rediseño.
  No se promueven piezas ni se publica Maguey/Horneado aún. Las siguientes
  pantallas requieren reevaluar contrato contra Foundations actuales.
  Revertir decisiones estructurales futuras mediante rNN+1, sin modificar
  rondas evaluadas. Evidencia: `plan/VERIFICACION-2026-09-28.md`.

## 2026-09-26 · Reubicación del paquete de documentación

`PULZ_MAESTRO.md` y `referencia/` llegaron en la raíz del repo. Se movieron a
`docs/PULZ_MAESTRO.md` y `docs/referencia/` porque así lo pide §19 del propio
documento maestro (el paquete se descomprime dentro de `docs/`).

## 2026-09-26 · pnpm vía Corepack, versión fijada

Se activó pnpm con `corepack enable` + `corepack prepare pnpm@9.15.9
--activate`, y se fijó `packageManager: "pnpm@9.15.9"` en el `package.json`
raíz. Corepack ya viene con Node y evita depender de una instalación global
aparte.

## 2026-09-26 · Node 22, no 20

El Node del sistema (v20.20.2, instalado vía Homebrew) es incompatible con
`@supabase/supabase-js@2.117.2`, que exige Node ≥ 22 en su `engines`. Se
instaló Node 22.23.3 (LTS "Jod") vía `nvm` y se fijó en `.nvmrc` y en
`engines.node` del `package.json` raíz. El Node 20 de Homebrew se queda
instalado (no se tocó) porque el `PATH` del sistema lo antepone a `nvm`; para
trabajar en este repo hay que activar 22 explícitamente
(`nvm use` o cargar `.nvmrc`).

## 2026-09-26 · Supabase alojado en vez de local, mientras no haya Docker

Ver `docs/DUDAS.md` #1. El dueño dio las credenciales de un proyecto Supabase
nuevo (`https://ypgeiyorgktshgbzhgfh.supabase.co`) para no bloquear el avance
por la falta de Docker/Colima/Podman en la máquina. Se guardaron en
`apps/web/.env.local` (no versionado; `apps/web/.env.example` documenta las
claves esperadas). **No es el proyecto heredado de Istmeño** (regla dura de
§0.3): es un proyecto nuevo, vacío, creado para PULZ. Cuando haya Docker
disponible se retoma `supabase start` para el ciclo de Fase 1 (migraciones +
`db reset` + pgTAP), que necesita poder resetear la base libremente — algo
que no se debe hacer contra un proyecto alojado compartido.

**Superada por la decisión siguiente**: se probó Colima y sí llegó a levantar
el stack completo, pero el dueño pidió explícitamente no usar Docker/Colima
en esta máquina y trabajar contra el proyecto alojado desde su propio panel.

## 2026-09-26 · Se descarta Docker/Colima; todo el trabajo va contra Supabase alojado

Instrucción explícita del dueño ("desinstala colima directamente..., en
supabase en la página se va a trabajar"). Se hizo `supabase stop`,
`colima stop`, `colima delete -f` y `brew uninstall colima` (se limpió
también `lima`, que quedó sin usuarios). El CLI de Supabase se queda
instalado (sirve para generar/editar migraciones y, más adelante, enlazar
con `supabase link` al proyecto alojado), pero **no se vuelve a intentar
`supabase start` local** salvo que el dueño lo pida de nuevo.

Consecuencia para fases futuras: la Fase 1 (`supabase db reset` + pgTAP) va
a necesitar un mecanismo contra el proyecto alojado en vez de un reset local
— por ejemplo, migraciones aplicadas con `supabase db push` y una base de
pruebas separada del proyecto de desarrollo. Se decide el detalle cuando se
llegue a esa fase; queda anotado en `docs/DUDAS.md`.

## 2026-09-26 · Agent-skills de Supabase instalados

`npx skills add supabase/agent-skills`, pedido explícitamente por el dueño.
Instala dos skills (`Supabase`, `Postgres Best Practices`) en
`.agents/skills/`, con symlink hacia `.claude/skills/` para Claude Code. El
propio instalador mostró su evaluación de riesgo ("Safe risk", 0 alertas de
Socket) antes de instalar.

## 2026-09-26 · GitHub: repo creado y sincronizado

El dueño creó `github.com/kevinedgm/pulz` y pidió subir los cambios. El repo
local ya tenía `origin` apuntando ahí (se sincronizó solo tras los commits
anteriores de esta sesión); se confirmó con `git ls-remote` que coincide con
`HEAD` y se empujó el resto de los commits sin pedir nada más — no hacía
falta crear el remoto a mano.

## 2026-09-26 · "Nunca Docker" pasa de ser una solución de Fase 0 a regla permanente del proyecto

El dueño pidió explícitamente reestructurar **todo el plan**, no solo la
Fase 0, para que Docker/Colima/Podman queden fuera para siempre: todo el
trabajo de base de datos va contra el proyecto Supabase alojado. Se escribió
como regla dura en `CLAUDE.md` (nuevo, raíz del repo) en vez de repetirla en
cada `docs/plan/FASE-N.md`, para que cualquier sesión futura la lea sin tener
que releer todo el historial de decisiones.

## 2026-09-26 · Migraciones pre-lanzamiento: "desde cero", no capas históricas

El dueño aclaró el criterio para cuando el esquema cambie durante el
desarrollo (por ejemplo, al corregir los errores que `PULZ_MAESTRO.md` §10.2
ya anticipa que va a tener `pulz_esquema.sql` al aplicarse a Postgres real):
como el producto no está lanzado y no hay datos reales que proteger, **lo que
importa es el estado final correcto del esquema, no el historial de cómo se
llegó ahí**. En vez de apilar una migración nueva de "fix" arriba de otra con
el error, se edita/reescribe la migración correspondiente para que el
conjunto siga siendo, en todo momento, "la implementación desde cero"
correcta — y se vuelve a aplicar contra el proyecto alojado (rehacer el
esquema ahí no arriesga nada porque no hay usuarios todavía).

Esto es lo opuesto de la práctica normal en producción (migraciones aditivas
e inmutables) a propósito: es una decisión explícita para la etapa
pre-lanzamiento. **Cuando el producto tenga usuarios reales, este régimen
cambia** — a partir de ahí las migraciones sí se vuelven aditivas, como pide
cualquier base de datos con datos que no se pueden perder. Regla completa en
`CLAUDE.md`.

Consecuencia práctica para la Fase 1: no tiene sentido escribir muchas
migraciones numeradas 0001, 0002, 0003... que documenten cada corrección
como si fueran commits separados de un historial de producción. Se escribe
el número mínimo de migraciones que representen el esquema correcto de una
vez, y se corrigen in situ cuando haga falta.

## 2026-09-26 · Fase 1 va con `supabase db push`/`--linked` directo, sin segundo proyecto

El dueño confirmó: "usa directo supabase db push contra el proyecto alojado,
esa es una instancia de desarrollo". Se descarta la opción de un segundo
proyecto Supabase separado para pruebas — el mismo proyecto
(`ypgeiyorgktshgbzhgfh`) sirve para desarrollo y para el ciclo de
reset/prueba de la Fase 1.

Se confirmó contra el CLI real (2.118.0), no por documentación externa, que
`supabase db reset --linked` y `supabase test db --linked` existen y hacen
justo lo que hacían sus equivalentes locales pero contra el proyecto
enlazado — o sea que **todo** el ciclo de Fase 1 (link, reset, seed, pgTAP,
consultas de verificación) se puede hacer sin Docker. Detalle completo en
`docs/plan/FASE-1.md`.

Efecto colateral importante: `supabase db reset --linked` borra y reconstruye
el proyecto alojado por completo cada vez. Mientras dure este régimen (antes
del lanzamiento), ese proyecto no debe usarse para nada que no esté en
`seed.sql` — ninguna prueba manual ni dato de demo sobrevive al siguiente
reset.

## 2026-09-27 · Fase 1 aplicada: cero errores de Postgres en el esquema de referencia

`PULZ_MAESTRO.md` §0.2 anticipaba que `pulz_esquema.sql` "no está probado
en Postgres real" y tendría errores de sintaxis u orden. Al partirlo en 13
migraciones y aplicarlo con `supabase db reset --linked` **no apareció
ninguno**: las 13 migraciones y la semilla corrieron limpias a la primera.
Lo que sí cambió respecto a la referencia fue por diseño (§10.2), no por
error — se lista abajo.

## 2026-09-27 · pgTAP se corre por la Management API, no con `supabase test db`

`supabase test db --linked` sí conecta al proyecto alojado, pero levanta
`pg_prove` en un contenedor Docker local para ejecutarlo — y Docker está
descartado (CLAUDE.md §1). Falla con `DockerRunError`. Solución sin Docker y
sin contraseña de base de datos: el test es una **función pgTAP** en el
esquema temporal, y se ejecuta con

    supabase db query --linked -f supabase/tests/aislamiento.test.sql

El runner de la Management API solo devuelve el resultado del último
statement, y ese es `runtests(...)`, que emite todas las líneas TAP. Todo va
en una transacción que termina en `rollback`, así que no deja rastro en el
proyecto. Detalle: `pg_temp` no sirve como nombre de esquema para
`runtests()`; se resuelve con `pg_my_temp_schema()`.

Con `psql` (viene con Postgres.app) también se podría, pero necesita la
contraseña de Postgres del proyecto y nunca hizo falta pedirla: `link`,
`reset` y `query` funcionan solo con `supabase login`.

## 2026-09-27 · Cambios deliberados respecto a `pulz_esquema.sql` (además de §10.2)

- **Escala de actividad 1–6** (§18 #1): el CHECK de
  `fermentation_measurements.activity` pasa de 1–10 a 1–6, y `dulzor`/`acidez`
  en `measurement_readings` quedan acotados a 1–6 por CHECK. La simulación
  traía actividades 7 y 8 (escala vieja); en `seed.sql` se recortaron a 6.
  Solo afecta la semilla; ningún saldo de §15.1 depende de eso.
- **"Anular medición"** (§4.4, §12.2 `anular_medicion`): `fermentation_measurements`
  gana `voided_at`, `voided_by`, `void_reason` (con CHECK de consistencia) para
  que la RPC de Fase 2 tenga dónde anular sin borrar.
- **Rangos de aviso configurables** (§18 #5 y #6): `organization_settings`
  gana `abv_warn_min/max` (35–55) y `brix_warn_min/max` (12–14) en vez de
  dejarlos en código.
- **`has_role()` rechaza escrituras con suscripción vencida o cancelada**
  (§11.2): se implementa dentro de la propia función, así todas las políticas
  y RPC lo heredan sin repetirlo.
- **`updated_at` con trigger** en catálogos, recursos, predios, proveedores,
  insumos, ajustes y suscripciones (§10.1 lo pedía; la referencia solo lo
  tenía en dos tablas).
- **Índices** adicionales por `(organization_id, …)` en las tablas de consulta
  frecuente y el de `organization_members (user_id, organization_id)` que pide
  §11.2.
- **Grants explícitos** (§10.1): se revoca todo a `anon`/`authenticated` en
  `public` y se otorga tabla por tabla. Los *default privileges* que el
  propio Supabase define al crear el proyecto se dejan como están (no son
  nuestros y no se tocan con `alter default privileges`); los grants
  explícitos de `0013` mandan sobre ellos.
- **`attachments.kind_item_id`** y las demás referencias tipadas verifican el
  tipo de catálogo con un trigger (`assert_catalog_item`) además de la FK
  compuesta, como pide §10.2.5.
- **`propagate_template(uuid)`** busca el id en las tres tablas de plantillas
  (un uuid solo existe en una) y devuelve cuántas filas agregó.

## 2026-09-27 · Fase 2 aplicada: 17 RPC, semilla por RPC, 26 pgTAP en verde

Las 8 migraciones de RPC (`0014`–`0021`) aplicaron sin errores. La semilla
reescrita para **construir la simulación llamando a las RPC** reproduce
exactamente la simulación de referencia: 38 operaciones, 13 lotes, 16
aristas de linaje, los mismos niveles de historia lote por lote, los dos
avisos blandos (`mezcla_clases_2a`, `diferencia_volumen`) y los saldos de
§15.1. Es la prueba de que las RPC hacen lo que la simulación hacía a mano.

## 2026-09-27 · Contrato §12.1 en helpers, no repetido en cada RPC

`rpc_guard`, `rpc_existing` (idempotencia), `rpc_open_operation`,
`rpc_set_result`, `rpc_warn` (aviso blando que exige nota o falla con
`REQUIERE_NOTA:<codigo>`), `lock_lots`/`lock_resources` (`for update` en
orden de id), `lot_balance`/`lot_total_balance`/`resource_balance`/`live_lot`
(siempre del ledger), `check_capacity` (estricta bloquea, flexible avisa),
`refresh_lot_status` (agotado/activo derivado del saldo) y
`recompute_history` (§6). Todos revocados a `authenticated`; solo los llaman
las RPC (security definer). `folio_counters` + `next_folio` dan folios por
empresa y prefijo con bloqueo de fila, **saltando los folios que el usuario
dio a mano** (la simulación trae `MEZ-001`, `DES-001`… explícitos).

## 2026-09-27 · Interpretaciones de negocio hechas en la Fase 2 (docs/DUDAS.md las lista)

- **Linaje de un corte**: se reparte entre las cargas de la corrida en
  proporción al volumen cargado, redondeado a 3 decimales. Es la única regla
  que reproduce los 20.042/5.958 y 12.333/3.667 L de la simulación.
- **Regla de acumulación (§4.5)** implementada tal cual: el corte se suma al
  lote vivo del colector salvo que ese lote esté entre las cargas de la misma
  corrida; entonces nace lote nuevo. Probado en los tres casos (colector
  vacío, lote vivo no cargado, lote vivo cargado).
- **`transferir` a un tanque vacío con `renombrar`** (o con destilado que
  entra a granel) crea el lote nuevo con `consumo` + `entrada` + linaje, como
  hace la simulación con `G-2609-01`. Con `conservar` y destino vacío es una
  pata `transferencia` simple.
- **Unión con decisión `conservar`**: el folio que se conserva es el del lote
  que ya está en el tanque destino; la sugerencia "el del lote mayor" (§5.1)
  es de la interfaz, la RPC aplica lo que llega.
- **Conciliación (§5.1)**: la nota del aviso `diferencia_volumen` se genera
  sola ("Declarado X L; ledger Y L.") porque §2.1 la marca como automática;
  no se le exige nota al usuario.
- **`abrir_horneado` en la semilla lo hace Aurelia (productor)**, no Tomás
  como en la simulación: §11.1 no permite al operador abrir horneadas y el
  documento gana sobre la semilla (§0.2). Lo mismo aplicaría a cualquier
  otra diferencia entre quién registró algo en la simulación y §11.1.
- **`registrar_medicion`** recibe `p_dia`, `p_actividad` y `p_numeros` como
  `integer` (se guardan como smallint): con `smallint` en la firma un literal
  o un número JSON no resuelve la función. Se corrigió editando `0017` (regla
  "desde cero"), no con una migración encima.
- **`operation_kind`** gana `anular_medicion` y `cerrar_ciclo` (editado en
  `0001`): la referencia no tenía tipo para esas dos acciones.
- **`corregir_operacion`** solo corrige metadatos (nota, contraparte,
  documento, fecha en que ocurrió) y deja una operación `correccion` que
  apunta a la original. Los volúmenes se corrigen con movimientos de ajuste.

## 2026-09-27 · Fase 3 (servidor): Edge Functions con `@supabase/server`, no con `Deno.serve` a mano

La skill de Supabase instalada manda verificar contra la documentación viva
y no contra memoria. La documentación y el README del paquete (unpkg) muestran
que hoy las Edge Functions se escriben con `withSupabase({ auth }, handler)`
de `npm:@supabase/server`, que da `ctx.supabase` (cliente con la RLS del que
llama), `ctx.supabaseAdmin` (llave secreta) y `ctx.userClaims`. Así se
escribieron `signup-company` (auth `publishable`), `manage-member` (auth
`user`) y `set-password` (auth `['user','publishable']`). Se despliegan con
`supabase functions deploy --use-api` (bundle en el servidor, sin Docker).
Probadas de punta a punta contra el proyecto alojado con `curl`: alta por
enlace (token de un solo uso, 72 h, solo hash en la base) y por contraseña
dictada (`must_change_password` la baja el servidor), 401/403/409 correctos,
alta de empresa con `provision_organization` y rechazo de slug reservado.

## 2026-09-27 · `supabase config push` solo con lo declarado a propósito

`config diff` mostró que el `config.toml` que genera `supabase init` habría
**cambiado 15 cosas** del proyecto alojado (apagar confirmaciones de correo y
MFA, cambiar OTP, pooler, Twilio, analytics…). Como "las propiedades que el
archivo no declara se dejan igual", se comentaron todas esas claves con la
marca `(no declarado a propósito)` y quedó declarado únicamente el hook.
Regla hacia adelante: **antes de cada `config push`, `config diff`**, y solo
se declara en `config.toml` lo que de verdad queremos que mande.

## 2026-09-27 · El hook de intentos no está en el plan: se documenta, no se finge

Ver `docs/DUDAS.md` #9 (402 de la API). `config.toml` deja el hook en
`enabled = false` con el `uri` comentado. El criterio "5 fallos bloquean" de
§16 Fase 3 queda como **no comprobable en este plan**.

## 2026-09-27 · Advisors de Supabase: se corrigió lo que era nuestro, se documentó lo que es diseño

`supabase db advisors --linked` tras la Fase 2: 8 funciones sin
`search_path` fijo (se les puso `set search_path = public` en su migración
original), `is_member`/`has_role`/`is_platform_admin`/`organizations_slug_guard`
ejecutables por `anon` (revocadas; `portal_branding` se queda para `anon` a
propósito, §7.5), políticas de `profiles` con `auth.uid()` sin `(select …)`
(corregido). Lo que queda son 21 avisos "security definer ejecutable por
authenticated": **son las RPC de negocio de §12, así es la arquitectura**
(§8.2: toda escritura pasa por RPC que verifica el rol adentro). Y uno de
protección de contraseñas filtradas (`docs/DUDAS.md` #10).

## 2026-09-27 · Contraseñas en la semilla y prueba real de login

La semilla fija `encrypted_password` con `extensions.crypt(…,
extensions.gen_salt('bf'))` (pgcrypto vive en el esquema `extensions` en
Supabase; sin el prefijo, `gen_salt` "no existe"). Con eso se probó contra
GoTrue real: el titular entra con correo, el colaborador con su correo
sintético `usuario@<organization_id>.usuarios.pulz.mx`, y contraseña mala y
usuario inexistente devuelven **exactamente el mismo** `invalid_credentials`
— la base del mensaje único "Usuario o contraseña incorrectos" (§7.5).

## 2026-09-27 · Pages Function: probada con `wrangler pages dev` real, no con un pool de Vitest

`@cloudflare/vitest-pool-workers` exige Vitest 4 y el repo usa 5 (y su
export `./config` no resolvía). En su lugar la prueba levanta `wrangler pages
dev dist` (Miniflare, sin Docker) con los bindings del proyecto alojado y
pega por HTTP: es la función real, con `HTMLRewriter` real, contra
`portal_branding` real. 5/5: título "Mezcal Cuatro Vientos · PULZ",
manifiesto por empresa, 301 del slug viejo, 404 para inexistente, marca de la
empresa B. Se corre aparte (`pnpm --filter @pulz/web test:portal`) porque
necesita `dist/`; el `pnpm test` normal la excluye. El caso "cancelada da el
mismo 404" se prueba en pgTAP (`supabase/tests/portal.test.sql`, 11/11):
`portal_branding` no devuelve fila ni para cancelada ni para inexistente, y
la función no distingue.

## 2026-09-27 · ESLint/Prettier ignoran `.claude/`, `.agents/` y `design-hub/`

Al instalar Fruti Squad y los agent-skills, el lint del repo quedó en rojo
por scripts de terceros (minificados, con `vendor/`). No es código nuestro:
se ignoran en `eslint.config.js` y `.prettierignore`, igual que
`apps/web/functions/e/` (copia literal de la referencia, como `tokens.css`).

## 2026-09-27 · coco, ronda acceso/r01: `equipo_miembros` es una función, no una vista

El dueño aprobó "la vista `equipo_miembros`". Se implementó como **función que
devuelve filas** (`equipo_miembros(p_org)`, security definer, `0023`) por dos
razones: una vista `security_invoker` no puede leer `login_throttle` ni
`member_invitations` (no tienen política para `authenticated`, y no deben
tenerla: ahí vive el hash del token), y una vista `security definer` las
expondría sin filtro por rol. La función verifica adentro que quien llama sea
**admin activo de esa empresa** — igual que las RPC de §8.2 — y devuelve
solo lo derivado (`locked_until` vigente, vencimiento y uso de la última
invitación), nunca el hash. pgTAP 12/12.

Detalle: se comprueba la membresía admin directamente y **no** con
`has_role()`, porque `has_role` rechaza cuando la suscripción está vencida y
el admin sí debe poder *ver* a su equipo en solo lectura (§7.4).

## 2026-09-27 · coco: iconos que el sprite no tiene van con texto

`pulz-iconos.svg` trae 12 símbolos del proceso (maguey, horno, tina, lote,
medir, más, campana, reloj…) y **no** trae ojo (mostrar contraseña), "⋯",
copiar ni compartir. Por la regla de un solo set (sin emojis, sin otro set),
esos controles se construyen con **texto**: "Mostrar" / "Ocultar",
"Acciones", "Copiar enlace", "Compartir…". Si el dueño quiere iconos ahí,
hay que agregarlos al sprite (Configuración → marca, otra ronda), no
mezclar sets.

## 2026-09-27 · coco (R3): lo que el navegador real encontró y las pruebas de unidad no

La verificación se hizo en tres capas y cada una encontró algo distinto:

- **En el navegador (dev server contra el proyecto alojado):** `Boton`
  renderiza un fragmento (control + texto del motivo), así que Vue no
  heredaba los atributos sueltos: `form="form-acceso"` no llegaba al
  `<button>` y **"Entrar" no enviaba nada**. También un `href` indefinido
  pasado a `RouterLink` pisaba el que este calcula y dejaba el enlace
  "Equipo" como `<a>` sin destino. Ninguna de las dos se ve con `vue-tsc`
  ni con el build. Ahora `inheritAttrs: false` + atributos a mano y solo el
  atributo de destino que aplica; hay prueba de regresión para ambos.
- **En Playwright (evidencia por ancho y tema):** el bloque de error de
  Bienvenida se estiraba a toda la pantalla en compact (tarjeta `grid` con
  `min-height: 100vh` → `align-content: start`), y la celda de acciones en
  la lista apilada decía "Acciones · Acciones".
- **En Vitest:** `aria-describedby` apuntaba a la ayuda aunque el error la
  ocultara (referencia colgante); `CapaTarea` no metía el foco si nacía
  abierta (`immediate: true`).

Además, el símbolo `i-mas` del sprite estaba dibujado como **menú** (tres
líneas) y se usaba en "Agregar persona": se redibujó como "+". Es el único
cambio al sprite; no se agregó ningún icono nuevo.

**"Solo admin" en Equipo no es un guardia del router.** La orden de lima lo
listaba como guardia, pero la ronda de kiwi tiene el estado "Sin permiso"
("Solo el administrador puede ver el equipo. Pídele a…") y un guardia que
redirige lo dejaría inalcanzable. Se quitó el `meta.soloAdmin` muerto: la
página muestra ese estado y `equipo_miembros` rechaza en la base. Inicio
solo enseña el enlace "Equipo" al admin.

**Evidencia con Playwright sin descargar nada.** `design-hub/qa` traía el
arnés de lima pero no el paquete; `@playwright/test` 1.63 pide exactamente
la revisión 1243 de Chromium, que ya estaba en la caché de la máquina, así
que se instaló con `PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1`. El script
`design-hub/qa/evidencia-acceso.mjs` recorre las pantallas reales
(inicios de sesión de la semilla incluidos) en 1440/1024/768/390 × claro/
oscuro, comprueba sin desborde horizontal, rechazo único, guardias y cierre
con confirmación, y deja 104 capturas en `design-hub/qa/evidence/acceso-r01/`.

## 2026-09-27 · lima, compuerta Candidate: medir en vez de confiar

La compuerta no se evaluó solo con la declaración de coco: lima **midió**
dos cosas que la declaración dejaba en "no comprobado" y ambas encontraron
defectos reales:

- **Contraste** sobre los pares de tokens que las piezas usan de verdad
  (claro y oscuro): `--pend/--pend-bg` = 3.03:1 en claro (texto del chip
  "invitado") y `--border/--surface` = 1.31:1 como límite de campo. Las
  piezas se corrigieron (texto en `--text`, borde en `--muted`); el token
  ámbar queda como decisión del dueño (`docs/DUDAS.md` #12), porque es un
  valor de §13.4 y cambiarlo toca a todo el sistema.
- **Texto al 200 %** (aproximado con `root font-size`, no zoom nativo): el
  `<input>` imponía su ancho intrínseco (size=20 × fuente doble) a la
  columna de grid y la tarjeta del portal se salía del viewport a 390; las
  opciones de una palabra del segmento se recortaban. Corregido con
  `minmax(0, 1fr)`, base flex 0 y opciones que bajan de fila.

Las 14 piezas pasaron a `candidate` 0.2.0. El registry guarda la
**procedencia** de cada evidencia, no un ✓ plano: `runtime-verified` solo
donde un navegador real lo ejecutó (Playwright/pane), `-emulated` para
touch, `-approx` para zoom, `manual-playbook`/`degraded` para las pasadas
de impeccable que se aplicaron a mano sin sub-agentes ni detector. Lo que
sigue pendiente (zoom nativo a mano, forced-colors, harden/audit) es la
compuerta Stable y solo se corre cuando el dueño pida estabilizar.

`production.path` ya apunta al código real aunque la pieza sea candidate:
en PULZ coco implementa directo en el stack (CLAUDE.md §3) y el Hub se
construye desde ese código; no hay promoción aparte.

## 2026-09-27 · Fase 4, servidor: Storage por migración, favicon real y sesión automática

- **El bucket `branding` y sus políticas van en una migración** (`0024`),
  no en el panel: `insert into storage.buckets … on conflict` y `create
  policy … on storage.objects` funcionan con `db reset --linked` en el plan
  actual. La carpeta raíz del objeto es la empresa (`<org_id>/logo.png`) y
  `storage_org_of(name)` + `has_role(…, admin)` deciden quién escribe; la
  lectura es pública porque el portal se ve antes de iniciar sesión. SVG
  queda fuera de `allowed_mime_types` a propósito (puede llevar script y se
  sirve público); 2 MB de tope.
- **`favicon.svg` era el de la plantilla de Vite** (rayo morado). Se
  reemplazó por la marca `pulz-mark` del sprite sobre tinta, y los iconos
  del manifest (192, 512, maskable, apple-touch) se rasterizan desde ese
  SVG con el Chromium de Playwright, sin librerías nuevas. Si el dueño tiene
  un logotipo definitivo, se cambia el SVG y se regeneran.
- **PWA mínima sin cola offline**: `vite-plugin-pwa` con `autoUpdate` y
  precache de la app; el portal (`/e/<slug>` exacto) se excluye del
  fallback de navegación porque lo sirve la Pages Function con la marca en
  el HTML (§7.7). La cola de capturas es Fase 5.
- **DUDAS #11 (decisión del dueño): sesión automática tras la bienvenida.**
  `set-password` devuelve `login_email` al canjear el token (correo real o
  sintético, tal como quedó en Auth) y `BienvenidaPage` entra de inmediato;
  si Auth no responde, cae a «Listo… Ir a entrar». Probado contra las
  funciones desplegadas.

## 2026-09-27 · Trabajo autónomo: las compuertas las decide Claude y sigue

El dueño pidió no detenerse a pedir aprobaciones ("funciona de forma
automática… decide tú… y continúa"). Queda como regla permanente en
`CLAUDE.md` §4: planes de fase, rondas de kiwi y dudas de diseño se deciden
con base en el maestro, el esquema y las decisiones previas, se anotan aquí
(qué, por qué, cómo revertir) y el squad continúa. Lo que no se decide solo:
reglas de negocio del maestro, gastos y lo innegociable de §0.3. Revertir:
pedir una ronda `rNN+1` o cambiar la regla en `CLAUDE.md`.

## 2026-09-27 · shell/r01 aprobada con estas tres decisiones

1. **Destinos fijos de la barra inferior: Inicio · Fermentación ·
   Destilación · Granel.** Por frecuencia diaria de §13.2 (medir tinas,
   corridas y cortes, tanques); Maguey y Horneado son eventos de días
   distintos y Trazabilidad es consulta. Revertir: cambiar `fijoEnCompact`
   en la lista de destinos del shell.
2. **Se agregan cuatro símbolos al sprite** (`i-tanque`, `i-traza`,
   `i-ajustes`, `i-menu`), dibujados con el mismo trazo y viewBox que los
   12 existentes. Una barra inferior con tres iconos y dos textos rompe el
   patrón y pierde el "un concepto, un icono"; agregar al set propio no
   viola la regla de un solo set (la regla prohíbe mezclar sets, no crecer
   el propio). Granel usa `i-tanque`, no `i-lote` (lote es trazabilidad).
   Revertir: quitar los símbolos y volver a texto.
3. **"Cambiar de empresa" vive solo en Cuenta.** En la semilla nadie tiene
   dos empresas y §7 no lo presenta como flujo frecuente; si en uso real lo
   fuera, se sube a la cabecera con una ronda `r02`.

## 2026-09-27 · configuracion/r01 aprobada con estas decisiones (CLAUDE.md §4)

1. **Entra `recurso_en_uso(p_org)`** (migración `0025`, función de solo
   lectura como `equipo_miembros`): por recurso, saldo actual de líquido y
   ciclos de fermentación abiertos, para que "Desactivar" avise si la tina
   fermenta o el tanque tiene litros. Es barato y evita apagar recursos con
   contenido. Revertir: quitar la función y la confirmación específica.
2. **Una capa por tabla real**, no un formulario dinámico: `tipo_*`
   comparten campos (solo nombre); conceptos, especies, predios,
   proveedores e insumos tienen la suya. Menos genérico, más honesto.
3. **Configuración sigue siendo solo admin**, aunque la RLS deje al
   productor escribir predios/proveedores/insumos: el productor los captura
   desde Maguey en Fase 5, en contexto. Revertir: quitar `soloAdmin` del
   destino y mostrar solo esas tres secciones al productor.
4. **Piezas nuevas del sistema**: `select`, `number-field`, `switch`,
   `color-field`, `file-picker`; `MarcaPortal` sube al sistema como
   `brand-block` porque ya se usa en dos contextos (portal y vista previa).
5. **Recorte del logo en el navegador con canvas**, sin librería; si una
   foto de teléfono llega rotada (EXIF), se sube sin recortar (≤2 MB) y se
   anota. Se prueba con archivos reales en coco.
6. Reordenar catálogos (`sort_order`) no entra (Could).

## 2026-09-27 · arranque/r01 aprobada con estas decisiones (CLAUDE.md §4)

1. **Lista de recipientes, no asistente de pasos**: cada tanque, tina o
   colector activo es una tarjeta que decide «vacío» o «tiene algo» y guarda
   sola. Se puede dejar a medias y volver; no hay orden obligatorio.
2. **Guardar es irreversible sin modal**: el botón dice exactamente
   «Guardar 300 L en Tanque 1» y la tarjeta muestra lo guardado; los litros
   se corrigen después en Granel con un ajuste (Fase 5).
3. **«Vacío» no existe en la base**: se guarda en el navegador por empresa.
   Lo real (saldo o ciclo abierto) sale de `recurso_en_uso`. Si molesta en
   uso real: `organization_settings.arranque_hecho` en r02.
4. **`RecursoCapa` sale de `RecursosPage`** como componente del módulo de
   configuración (no del sistema): la usan Recursos y Arranque.
5. Solo líquidos (tanques, tinas, colectores); kilos iniciales de maguey u
   horneadas a medias son otra ronda.

## 2026-09-27 · coco, configuracion/r01: lo que salió al construir

- **Manejadores inline de una sola sentencia.** Prettier partió
  `@update:model-value="a = ''; b = ''"` en dos líneas sin `;` y Vite dejó
  de compilar la página (500) sin que `vue-tsc` ni ESLint lo vieran. Regla:
  más de una sentencia → método. La evidencia de navegador real fue la que
  lo encontró.
- **Storage desde el navegador funciona con la RLS de 0024**: el logo se
  recorta con `canvas` (cuadrado centrado, 512, png/webp), sube con `upsert`
  a `branding/<org>/logo.<ext>` y el portal lo publica. Sin encuadre manual:
  si el dueño lo quiere, es una ronda aparte.
- **Cambio de enlace probado ida y vuelta** contra el proyecto alojado:
  `cuatro-vientos → cuatro-vientos-qa → cuatro-vientos`; el trigger deja el
  historial y el router se recoloca en el slug nuevo.
- **`recurso_en_uso` cualquier miembro** (no solo admin): es información
  operativa (litros dentro, ciclos abiertos) que Fase 5 también mostrará.
- El smoke deja `Tanque QA` (inactivo) y `Especie QA` (oculta) en el
  proyecto de desarrollo hasta el siguiente `db reset --linked`.

## 2026-09-27 · coco, shell/r01: lo que salió al construir

- **Capas y navegación no se llevan sin cuidado.** `task-layer` deshace su
  entrada de historial con `history.back()` al cerrarse; si desde la capa
  (Más, Cuenta) se hace `router.push` de inmediato, el `popstate` llega
  después y devuelve a la ruta anterior. `AppShell.irA` cierra la capa,
  espera ese `popstate` (o 400 ms) y luego navega; en la Cuenta, "Equipo" es
  un enlace que pasa por `irA`, no un `RouterLink` que compite con cerrar.
  Vale para cualquier capa futura que navegue.
- **Cuenta como drawer de `task-layer`, no popover** (excepción de lima a la
  ronda de kiwi): evita una pieza nueva; si molesta en escritorio, `popover`
  es una ronda aparte.
- **En medium la empresa no se repite**: la cabecera ya la muestra; el menú
  lateral la lleva solo en expanded (contrato de `side-nav` ajustado).
- **Layout por `meta.shell`**, no rutas anidadas: el portal y `/e/:slug/…`
  comparten prefijo y anidar habría exigido un componente padre para el
  portal público. `App.vue` elige `AppShell` o `router-view` desnudo.
- **Inicio "¿Qué tienes hoy?" → "Empezar" lleva a Granel** mientras no exista
  la ronda `arranque/r01`; esa ronda lo redirige al flujo real.
- **El Hub necesita un router en memoria**: las navegaciones usan
  `RouterLink`; sin router, la demo truena. `hub/main.ts` lo instala.

## 2026-09-27 · Concurrencia: no se pudo probar por la Management API

El test de "dos transferencias simultáneas del último litro" está escrito
(`supabase/tests/rpc_concurrencia.test.sql`) con dos sesiones vía `dblink`,
pero en Supabase alojado `dblink_connect('dbname=postgres')` responde
`password or GSSAPI delegated credentials required`: no hay forma de abrir
una segunda sesión sin la contraseña de Postgres del proyecto, que nunca se
ha pedido. El test se marca **SKIP** (no se finge que pasó, §0.1.3). Cómo
probarlo de verdad queda en `docs/DUDAS.md` #5. Lo que sí está probado por
código y por pgTAP: cada RPC bloquea con `for update` los lotes y recursos
que toca **en orden de id** antes de leer saldos, que es la mecánica que
hace que la segunda sesión vea el saldo ya consumido.

## 2026-09-26 · Flujo de interfaz obligatorio: kiwi primero, siempre

`PULZ_MAESTRO.md` §13.4 ya establecía que "ninguna pantalla se construye sin
su ronda de kiwi aprobada", pero el dueño pidió dejarlo explícito y a prueba
de que se salte por accidente: **cualquier trabajo de interfaz — diseñar,
prototipar, crear o corregir una pantalla, componente, flujo o mockup —
empieza invocando la skill `kiwi`**, que estructura (F0–F2) y entrega a
`lima` (gobernanza) → `coco` (construcción + auditoría) → `mora-docs`
(documentación). Nunca se empieza directo en `lima` o `coco` para algo nuevo.
Regla completa, con el diagrama del flujo, en `CLAUDE.md`.

## 2026-09-27 · Hub HTML (ronda hub/r01): el sitio se genera, no se escribe

- **El Hub tiene sitio propio** (`design-hub/site/`), generado por
  `pnpm build:hub-site` (`design-hub/scripts/build-hub.mjs`, `marked`) desde
  `README.md`, las fichas Markdown y `system/registry.json`. Se decidió así
  (hallazgo alto de kiwi) para que no haya dos verdades: el HTML nunca se
  edita a mano; se cambia la ficha y se regenera. El `site/` **se versiona**
  (como `Components/demo/`) para abrirlo sin construir; cada cambio de ficha
  o de registry va con su `site/` regenerado en el mismo commit. Revertir:
  borrar `site/` del repo y generarlo solo en local.
- **Preview = demo real por iframe** (`Components/demo/index.html?pieza=<id>&solo=1`)
  y galería de capturas para pantallas: nada de CSS copiado. Alto del iframe
  fijo por rango (LOW, sin acción; «Abrir aparte» cubre).
- **`hub-shell` es pieza del registry** (template, `candidate` 0.2.0):
  `assets/hub-shell.css` (clases `hub-*`, tokens reales) +
  `assets/hub-navigation.js` (drawer accesible, `aria-current`). Enlaces del
  sidebar a 36 px como excepción declarada (mínimo WCAG 24; controles
  principales 44).
- **`Responsive/{Mobile,Tablet,Desktop}` sale del `hub_layout`** y entran
  `Screens` y `QA`: el rango vive en cada ficha.
- **La evidencia acepta el drawer como navegación global** por debajo de
  1024: el primer `evidencia-hub.mjs` daba 4 falsos negativos buscando la
  `nav` del sidebar en 768/390. Regla para próximos scripts: comprobar la
  presentación que corresponde al ancho, no un solo selector.
- Aprobaciones de kiwi/mora/lima decididas en automático (CLAUDE.md §4):
  tooling interno, sin reglas de negocio del maestro.

## 2026-09-27 · Fase 5, servidor: vistas de proceso y evidencias

- **Las vistas de 0026 entregan fechas, no "días"**: `tinas_en_uso` da
  `started_at` y la última medición; qué día del ciclo es hoy y si "toca
  medir" lo calcula el navegador en su zona horaria. El servidor corre en
  UTC y no sabe dónde está el palenque; meter una zona fija en SQL habría
  sido inventar un dato. Revertir: columna `dia_hoy` con `at time zone` si
  algún día `organizations` guarda su zona.
- **`corridas` incluye cerradas** (la interfaz filtra por `status`): la
  lista de Destilación necesita el historial, no solo las abiertas.
  Orígenes y cortes van como `jsonb` para una sola consulta por pantalla.
- **`tanques` lista los activos aunque estén vacíos**; los lotes dentro van
  con su grado declarado vigente, quién y cuándo (§5.1).
- **Bucket `evidencias` privado, 10 MB, jpeg/png/webp/pdf**: cualquier
  miembro lee y sube dentro de su carpeta `<organization_id>/…`; **nadie
  borra ni reemplaza** (no hay política): una evidencia es evidencia.
  `attachments` gana política de insert para cualquier miembro (0013 solo
  daba lectura) y sigue sin update/delete.
- **`branding_org_of` → `storage_org_of`** (0024, régimen "desde cero"):
  la misma función sirve a los dos buckets por empresa.
- **Aislamiento y triggers**: cuando el admin de B intenta adjuntar a A, el
  trigger `attachments_check_kind` falla antes que la RLS porque la RLS ya
  le esconde el catálogo de A. El resultado es el mismo (no puede); la
  prueba lo documenta en vez de forzar el mensaje de RLS.


## 2026-09-27 · Fermentación (ronda fermentacion/r01): lo que se decidió construyendo

- **Toda medición entra por la cola**, con señal o sin ella (una sola ruta de
  escritura): la pantalla dice «enviada» o «pendiente de enviar» según lo que
  quedó en IndexedDB tras intentar enviar. Evita dos caminos que derivan.
- **La lista muestra la verdad del servidor** (o su instantánea) más el chip
  «pendiente»: una tina con captura en cola sigue en «toca medir hoy» hasta
  que la medición llega. No se finge que el servidor ya la tiene.
- **El aviso de Brix se conoce antes de enviar**: los rangos viajan en la
  instantánea y «Revisar» pide la nota ahí; si el servidor aun así responde
  `REQUIERE_NOTA`, la fila queda en fallo con «Corregir» (misma clave).
- **Día del ciclo y «hoy» en el navegador** (0026 entrega fechas): `día =
  días naturales desde started_at + 1`, corregible en la cabecera.
- **Modo completo = un concepto por paso** (5 pasos + revisar); el promedio
  se calcula en vivo y nunca se guarda.
- **FAB con acción de la página** (`app/fab.ts`): el shell pinta el FAB de
  la ruta y la página fija qué hace; sin acción, deshabilitado. El botón
  «Medir» de la cabecera vive en ≥600; en compact solo el FAB.
- **Boton es un fragmento**: un `class` scoped de página no le aplica; se
  envuelve en un `div`. Encontrado por la evidencia (botón duplicado).
- **`useCola` refresca también sin señal**: el banner no contaba lo recién
  encolado hasta reconectar. Encontrado por el e2e offline.
- **En dev server, sin señal no se puede abrir una ruta no visitada** (Vite
  sirve módulos bajo demanda; en producción los precachea el SW): el e2e
  visita Medir antes del modo avión y lo declara.
- **Limpieza de datos de prueba por operación, nunca por fecha**: un `update
  … where recorded_at::date = hoy` anuló también las mediciones de la
  semilla (todas registradas el día del reset). `db reset` lo devolvió; el
  e2e limpia sus 3 por `limit 3 order by recorded_at desc`.
- Aprobaciones de kiwi, lima, coco y mora en automático (CLAUDE.md §4).

## 2026-09-27 · Destilación (ronda destilacion/r01): lo que se decidió construyendo

- **El colector se elige por la clase del corte**, no la persona: la RPC
  exige la misma clase (0018), así que la pantalla lo resuelve sola (select
  solo si hay varios de la clase; bloqueo con enlace a Recursos si no hay).
- **«Ya mezcal va directo a granel» es `transferir`, no un corte a tanque**
  (0019, admin/productor): Destilación muestra los colectores con contenido
  y «Pasar a granel» abre la transferencia de la ronda de Granel; el
  operador ve quién lo hace.
- **Abrir y cerrar corrida requieren señal** (consumen saldos que decide el
  servidor); **los cortes entran por la cola** como las mediciones.
- **Avisos conocidos antes de enviar**: capacidad estricta del alambique o
  colector bloquea con motivo; flexible pide nota (`excede_capacidad`); 2ª
  con ordinario y colas pide nota (`mezcla_clases_2a`) si el ajuste avisa.
- **`origin-allocation` se extrae de la formulación** y se reutiliza en
  abrir corrida (y en horneado después): tres consumidores de la misma
  lista «de dónde sale cuánto».
- **Un corte no se anula** (no hay RPC): se dice en la corrida y se abre
  `DUDAS.md` #15 (vinazas y anulación de cortes).
- **Cada RPC devuelve algo distinto** (medición → id de la medición; corte →
  id del lote): la subida de fotos resuelve la operación y el lote según la
  RPC (`fotos.ts`), en vez de suponer un id de operación.
- **Un `legend` no es un heading**: Playwright espera fieldsets por texto.
- Aprobaciones de kiwi, lima, coco y mora en automático (CLAUDE.md §4).

## 2026-09-27 · Granel (ronda granel/r01): lo que se decidió construyendo

- **El formulario se arma con el concepto** (`camposDe`: `source_lot`,
  `creates_lot`, `asks_result`, `asks_counterparty`): un solo
  `MovimientoPage` para agua, puntas, unión, compra, ajustes, venta,
  envasado, muestras y merma. Si un tercer módulo lo necesita, se extrae
  como patrón; hoy es local.
- **El sistema no calcula el grado, pero sí dice qué hará con el volumen**:
  con `asks_result` se muestra el ledger esperado y la diferencia que
  registrará la conciliación; `diferencia_volumen`, `abv_fuera_rango` y
  `excede_capacidad` se conocen antes de enviar (nota).
- **Sin FAB en Granel**: la acción depende del tanque (Entrada / Salida /
  Transferir por tarjeta); en el tanque, Entrada es la primaria porque es la
  que declara grado.
- **`movement_log` expone códigos de recurso, no ids**: el historial se
  filtra por `code` del recurso (una consulta previa a `resources`). Las
  patas de conciliación se agrupan bajo su operación y se leen como «el
  sistema registró una diferencia de ±X L».
- **«Pasar a granel» desde Destilación** llega a `/granel?transferir=<colector>`
  y Granel redirige a `/granel/transferir?origen=` (el enlace de la ronda
  anterior no cambia).
- **`default_folio_decision` de la empresa** precarga la decisión conservar /
  renombrar; el folio sugerido es el del lote mayor del destino.
- **«Carga inicial» no aparece entre los conceptos** del movimiento: vive en
  el primer arranque (y Recursos); evita duplicar el camino.
- Aprobaciones de kiwi, lima, coco y mora en automático (CLAUDE.md §4).


## 2026-09-27 · Entorno: vista previa con Node 22 y tooling de Codex fuera del lint

- **La vista previa del servidor de desarrollo arrancaba con el Node 20 del
  sistema** (el proyecto exige Node ≥ 22) y moría con
  `ERR_PNPM_UNSUPPORTED_ENGINE`. `.claude/launch.json` → `web` ahora corre
  por `/bin/sh -c` con el Node 22 de nvm al frente del `PATH`. Revertir:
  volver a `runtimeExecutable: pnpm` cuando el Node del sistema sea ≥ 22.
- **Apareció en el repo la instalación del Fruti Squad para Codex**
  (`.codex/`, `.fruti/`, `AGENTS.md`, 2026-09-27 23:43, fuera de esta
  sesión). No se modificó ni se versionó; se excluyó de ESLint y Prettier
  igual que `.claude/` y `.agents/` (tooling de terceros). Si el dueño la
  quiere versionada, basta con `git add`.
- **Las evidencias que escriben datos se corren en orden y una a la vez**:
  dos corridas simultáneas (una tarea vieja esperando al servidor) cruzaron
  escrituras; Granel necesita mezcal en un colector, así que tras un
  `db reset` corre primero la evidencia de Destilación.

## 2026-09-28 · R05 Maguey/Horneado: cierre local, aceptación parcial

- Autonomía explícita del usuario: Kiwi conserva rail160/240,insets16/24;
  elige guion discrecional, no reducir tipografía ni abreviar. Lima autoriza
  reutilización; Coco comparte helper y preserva nombre accesible original.
- Revisión independiente detecta identidad obsoleta/carrera de membresías,
  intención incompleta, contexto incorrecto del cocido y timestamp ausente.
  Reparados con regresiones, sin modificar reglas de negocio ni esquema.
-183/183 locales (34 módulo),5/5 acceso alojado después de autorización
  específica. No operaciones de negocio remotas. Sin FilaUso/Foundations alteradas.
- Draft0.2.1: no Candidate/Stable por pruebas alojadas y a11y física/nativa
  pendientes. Mora sincroniza hechos; no convierte documentación en aprobación.
- Reversibilidad: los cambios de código están acotados a navegación y garantías
  de lectura/sesión; no hay migración ni datos remotos que revertir. No revertir
  cambios ajenos en el árbol compartido. Evidencia: r05/result.md y checklist vivo.


## 2026-09-28 · r06 Maguey/Horneado: las pruebas alojadas sí se corren

Codex dejó el script `scripts/test-mh-hosted-r06.mjs` sin ejecutar por
autoimponerse no escribir negocio en el proyecto alojado. `CLAUDE.md` §1
dice lo contrario: el proyecto `ypgeiyorgktshgbzhgfh` es el ambiente de
trabajo. Se corrió a pedido del dueño: 37/37 PASS, dos tenants desechables
`qa-mh-r06-*` creados y borrados por el propio script, huella de los datos
existentes idéntica antes y después. Regla: las pruebas alojadas con
fixtures aislados y limpieza verificada no necesitan autorización aparte.


## 2026-09-28 · r06: 15.12 y 15.13 con Playwright; la página de Maguey no se rendía sin señal

- La prueba de interfaz (`design-hub/qa/e2e-mh-r06.mjs`) encontró que, sin
  señal, `ProcesoSolidoPage` intentaba reverificar la sesión contra el
  servidor, fallaba y mostraba «No pudimos verificar la sesión. Vuelve a
  entrar.» sin cargar la instantánea. Ahora un fallo de red conserva la
  identidad local (basta para la partición de intenciones), carga la
  instantánea y deja la escritura bloqueada; cualquier otro fallo sigue
  pidiendo volver a entrar. Revertir: quitar la rama `esErrorDeRed` del
  callback de Auth.
- El «resultado incierto» se provoca abortando la petición en el navegador
  (nada llega al servidor) y el «rechazo confirmado» con una respuesta 400
  P0001 interceptada; la única escritura real es el reintento del original.


## 2026-09-28 · r06 Maguey/Horneado: bloque 16 con Playwright; contraste de chip y botón corregido

- `design-hub/qa/a11y-mh-r06.mjs` cierra 14.03, 16.02, 16.05, 16.06, 16.08 y
  16.09 en el shell autenticado (132/132). Lo que es emulación se declara
  como tal: 200 % = viewport CSS/2 + DPR 2 (idéntico a lo que hace el
  navegador), forced-colors y reduced-motion con la emulación de Chromium,
  contenido extremo con lecturas REST interceptadas (solo render). 16.03,
  16.04 y 16.07 se dejan abiertos: no se certifican tacto físico, teclado
  virtual ni lector de pantalla sin el medio real.
- Dos piezas del sistema cambian por medición, no por gusto: `ChipEstado`
  `on` pasa el texto a `--color-success-text` (6.5:1; `--ok` daba 4.35 a
  13 px) y `partial` a `--ink-700` (5.2:1; `--info` daba 4.25); `Boton`
  `secondary` toma el borde `--muted` (6.3:1) en lugar de `--border`
  (1.34:1), el mismo borde que ya llevan los campos. El punto y el borde del
  chip conservan el color semántico. Revertir: restaurar `--ok`/`--info`/
  `--border` en esos dos archivos; las fichas del Hub anotan el motivo.
- `tokens.css` ya no define tema oscuro (Foundations 1.0.0): no se toca aquí
  porque la base está aprobada; queda DUDAS #16.
- 15.02/15.03 se dan por resueltos con lo que r06 ya hizo: proyecto único
  autorizado por CLAUDE.md §1, tenants desechables con limpieza por IDs para
  la API, y semilla + `db reset` para la UI (sin usuarios reales, §2).


## 2026-09-28 · Tema oscuro restaurado en tokens.css (DUDAS #16)

- El dueño pidió arreglarlo. En vez de rescatar la paleta azul de la semilla
  vieja (`docs/referencia/pulz-tokens.css`, anterior a Foundations 1.0.0), el
  tema oscuro se deriva de las escalas aprobadas: superficie `#1C1B23` sobre
  fondo `#121118`, texto `#F2F1F5`, tinta y estados en el tono 300 y texto de
  estado en el tono 200 sobre fondos tintados. Solo cambian roles semánticos
  y alias; los siete roles base y las escalas siguen intactos, así que no se
  reabre la aprobación de Foundations. `color.dark` queda en
  `.fruti/tokens.json` como fuente canónica y el Hub (Foundations/Color) lo
  documenta.
- Selectores como en shell/r01: `prefers-color-scheme: dark` salvo
  `data-theme="light"`, y `data-theme="dark"` manual (Cuenta). Verificado en
  el shell autenticado: sistema oscuro, manual claro sobre sistema oscuro,
  manual oscuro sobre sistema claro y sistema claro; contraste en oscuro:
  texto 16.7:1, secundario 8.0, error 10.4, primario 6.5, foco 7.2, bordes
  7.2 (`design-hub/qa/evidence/tema-oscuro/`). Los chips `on`/`partial` no
  estaban en pantalla tras el `db reset`; sus pares se calcularon desde los
  tokens (7.5:1 y 8.0:1).
- Pendiente menor detectado: `index.html` y el manifest PWA seguían con
  `theme-color #173F87` (kit anterior); resuelto en la entrada siguiente.


## 2026-09-28 · theme-color, manifest e iconos PWA sobre Foundations 1.0.0

- Pedido del dueño. Se mantiene la regla de Fase 4 (`theme_color` =
  `--ink-900`, `background_color` = `--canvas`) con los valores vigentes:
  `index.html` lleva dos `<meta name="theme-color" media=…>` (`#6D4AFF`
  claro, `#A590FD` oscuro) y `app/tema.ts` las fuerza al color del tema
  elegido a mano y las restaura en «sistema» (test en `shell.test.ts`). El
  manifest queda en `#6D4AFF` / `#F8F8FA`.
- `favicon.svg` pasa a `#6D4AFF` y los cuatro PNG del manifest se
  regeneran con `apps/web/scripts/iconos.mjs` (Chromium de Playwright, como
  en Fase 4; ahora queda como script en el repo). El maskable lleva fondo a
  sangre y el glifo al 72 % dentro de la zona segura.
- No se toca el `#173F87` de `CampoColor` (valor por defecto del acento de
  cada empresa en Configuración): es un dato de negocio, no de marca PULZ.
