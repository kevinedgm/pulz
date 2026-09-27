# Fase 2 · Comandos (RPC)

> Sigue `PULZ_MAESTRO.md` §2, §4, §5, §12, §15 y §16, más `CLAUDE.md`
> (nunca Docker; migraciones "desde cero"; kiwi primero — esta fase no toca
> interfaz). Objetivo: que **toda escritura de producción pase por una RPC**
> transaccional e idempotente con el contrato de §12.1, y que la simulación
> de Cuatro Vientos se construya **llamando a esas RPC** y dé exactamente los
> saldos de §15.1. Todo contra el proyecto alojado, con el mismo ciclo que la
> Fase 1 (`db reset --linked` → `db query --linked -f test`).
>
> **Estado (2026-09-27): aprobado e implementado.** 17 RPC + helpers en
> `0014`–`0021`, semilla por RPC, pgTAP 26/26 + aislamiento 18/18 + saldos
> §15.1 exactos. Único punto no comprobado: la concurrencia con dos sesiones
> reales (SKIP; `docs/DUDAS.md` #5). Detalle de resultados al final.

## Qué ya existe y qué no

Existe (Fase 1): todas las tablas, vistas, RLS y las funciones de
infraestructura (`is_member`, `has_role`, `is_platform_admin`,
`portal_branding`, `member_login_email`, `auth_password_attempt`,
`desbloquear_miembro`, `seed_organization_catalogs`, `propagate_template`,
`assert_catalog_item`).

No existe: ningún cuerpo de las RPC de negocio de §12.2. Hoy la semilla mete
las filas del ledger con `insert` directo; eso es exactamente lo que esta
fase elimina.

## Contrato común (§12.1) — se implementa una sola vez y se reutiliza

Para no repetir el mismo prólogo en 17 funciones, la primera migración de
esta fase crea helpers internos (`security definer`, no expuestos a
`authenticated`):

| Helper | Qué hace |
|---|---|
| `rpc_guard(p_org, roles[])` | `has_role` o excepción `NO_PERMITIDO:` (errcode `P0001`) |
| `rpc_idempotent(p_org, p_key)` | si `idempotency_key` ya existe en `operations` de esa empresa, devuelve el `operation_id` original (la RPC regresa el mismo resultado sin hacer nada más) |
| `rpc_open_operation(...)` | inserta la fila de `operations` con `recorded_by = auth.uid()`, `occurred_at` del parámetro, `recorded_at = now()`; devuelve el id |
| `lock_lots(p_org, uuid[])` / `lock_resources(p_org, uuid[])` | `select … for update` **en orden de id** (§12.1, patrón `lock_bulk_lot` de la rama saas) antes de validar saldos |
| `lot_balance(p_org, p_resource, p_lot)` | saldo vivo de un lote en un recurso, calculado sobre `liquid_movements` dentro de la misma transacción |
| `next_folio(p_org, p_prefix)` | folio consecutivo por empresa y prefijo con bloqueo de fila (patrón `app.next_folio` de la rama saas); tabla `folio_counters(organization_id, prefix, last_no)` |
| `rpc_warn(p_op, p_org, p_code, p_nota)` | aviso blando: exige `p_nota` no vacía o falla con `REQUIERE_NOTA:<codigo>`; inserta en `operation_warnings` |
| `recompute_history(p_org, p_lot)` | recalcula `lots.history` (`completa` / `parcial` / `declarada` / `sin_historia`) recorriendo `lot_lineage` hacia atrás (§6) |

Prefijos de error estables para el cliente: `SALDO_INSUFICIENTE:`,
`CAPACIDAD_EXCEDIDA:`, `NO_PERMITIDO:`, `LIMITE_PLAN:`, `REQUIERE_NOTA:`.
Mensaje en español para la persona después del prefijo.

## Tareas, en orden

1. **`20260927000014_rpc_base.sql`** — los helpers de arriba +
   `folio_counters`. Sin RPC de negocio todavía.
2. **`…0015_rpc_entradas.sql`** — `registrar_recepcion_maguey`,
   `registrar_entrada` (cualquier etapa salvo molienda; `origin`
   `carga_inicial` o `compra`; datos externos opcionales en
   `lot_external_sources`; para `compra` crea `history = 'declarada'`).
3. **`…0016_rpc_horneado_formulacion.sql`** — `abrir_horneado`,
   `cerrar_horneado` (nace `agave_cocido` con linaje a cada maguey; saldo
   sólido no negativo), `registrar_formulacion` (reparto a una o varias tinas:
   abre ciclos y lotes `fermentado`, pata `entrada` en cada tina; regla dura
   "un ciclo abierto por tina" ya la impone el índice parcial).
4. **`…0017_rpc_fermentacion.sql`** — `registrar_medicion` (lecturas como
   filas; solo en ciclos abiertos; aviso `brix_fuera_rango` según
   `organization_settings`), `anular_medicion` (marca `voided_*`, no borra),
   `declarar_tina_lista`, `cerrar_ciclo` (tina vaciada → ciclo `cerrado`).
5. **`…0018_rpc_destilacion.sql`** — `abrir_corrida` (patas
   `carga_alambique` desde tinas o colectores, destino nulo; **capacidad
   `estricta` es regla dura**; aviso `mezcla_clases_2a` si ordinario + colas
   en 2ª pasada, según `warn_mixed_second_pass`), `registrar_corte` (pata
   `corte` al colector; **regla de acumulación §4.5**: se suma al lote vivo
   del colector salvo que ese lote se haya cargado a la misma corrida —
   entonces nace lote nuevo; `puntas` solo si `record_puntas`), `cerrar_corrida`.
6. **`…0019_rpc_granel.sql`** — `transferir` (entre recursos; si el destino
   ya tiene lote: `conservar` o `renombrar`, con `consumo` + `entrada` y
   linaje), `registrar_movimiento_granel` (cualquier concepto del catálogo:
   entradas piden `result_volume_l`/`result_abv`; si el declarado ≠ ledger,
   pata `conciliacion` por la diferencia + aviso `diferencia_volumen`; aviso
   `abv_fuera_rango` según ajustes; salidas no piden resultado; `creates_lot`
   crea lote; `asks_counterparty` exige contraparte).
7. **`…0020_rpc_historia_correccion.sql`** — `completar_historia` (aristas
   `retroactive = true` o datos declarados; recalcula `history`),
   `corregir_operacion` (operación `correccion` que referencia a la original
   con `correction_of_id`; nunca edita ni borra).
8. **`…0021_rpc_provision.sql`** — `provision_organization(nombre, slug, …)`:
   crea empresa, membresía admin, ajustes, suscripción `gratis` y llama
   `seed_organization_catalogs`. Solo `service_role` (la llama
   `signup-company` en Fase 3).
9. **Grants**: `grant execute` de cada RPC de negocio a `authenticated`;
   los helpers y `provision_organization` quedan revocados.
10. **Reescribir `seed.sql`** para que la parte de Cuatro Vientos se
    construya **llamando a las RPC en orden cronológico** (con
    `set local role authenticated` + claims del usuario que registró cada
    operación, para que `recorded_by` y `has_role` sean reales). Los ids de
    lotes/operaciones dejan de ser fijos: se resuelven por folio. **Debe dar
    los mismos saldos de §15.1** — es la prueba de que las RPC hacen lo que
    la simulación hacía a mano.
11. **pgTAP por RPC** en `supabase/tests/rpc_*.test.sql`, mismo runner que la
    Fase 1: camino feliz, **idempotencia** (segunda llamada con la misma
    `idempotency_key` devuelve lo mismo y no duplica patas), **cada regla
    dura** (saldo negativo → `SALDO_INSUFICIENTE`, capacidad estricta →
    `CAPACIDAD_EXCEDIDA`, otra empresa → `NO_PERMITIDO`/RLS, catálogo de otra
    empresa → FK), **cada aviso blando** (sin nota → `REQUIERE_NOTA:`; con
    nota → fila en `operation_warnings`), regla de acumulación de colectores,
    conciliación de volumen.
12. **Prueba de concurrencia** (§16): dos transferencias simultáneas del
    último litro → una pasa y la otra falla con `SALDO_INSUFICIENTE`. Sin
    Docker y por la Management API no hay dos sesiones reales; se hace con
    **`dblink`** desde una sola sesión (extensión disponible en Supabase):
    abre dos conexiones, cada una intenta la transferencia, y se comprueba
    que exactamente una levantó `SALDO_INSUFICIENTE`. Si `dblink` no está
    habilitable en el plan del proyecto, se documenta en `docs/DUDAS.md` y se
    prueba el bloqueo `for update` con una sola sesión (`lock_timeout`).
13. `supabase db reset --linked` + todos los tests en verde + saldos §15.1.

## Archivos que se tocan

- `supabase/migrations/20260927000014…0021_*.sql` (nuevos).
- `supabase/seed.sql` (reescrito para usar RPC).
- `supabase/tests/rpc_*.test.sql` (nuevos), `aislamiento.test.sql` (se
  extiende con "un operador no ejecuta RPC de admin").
- `docs/DECISIONES.md` — cada regla que haya que interpretar (p. ej. qué
  folio sugiere el sistema al unir lotes: "el del lote mayor" según §5.1).
- `docs/DUDAS.md` — lo que §12 no cierra (ver abajo).

## Pruebas que se escriben

pgTAP, por RPC (tarea 11) + concurrencia (tarea 12). Nada de Vitest.

## Cómo se comprueban los criterios de aceptación de §16 (Fase 2)

| Criterio | Cómo | Resultado real (2026-09-27) |
|---|---|---|
| pgTAP por RPC: feliz, idempotencia, duras, blandas | `supabase db query --linked -f supabase/tests/rpc.test.sql` | **26/26 ok** |
| Concurrencia: dos transferencias del último litro → una pasa, otra `SALDO_INSUFICIENTE` | test con `dblink` (tarea 12) | **SKIP**: en Supabase alojado `dblink_connect` exige contraseña; no se declara en verde. Cómo probarlo a mano: `docs/DUDAS.md` #5 |
| La simulación por RPC da §15.1 | tras `db reset --linked` con la semilla nueva, la misma consulta de saldos de la Fase 1 | **Exactos** (y 38 operaciones, 13 lotes, 16 aristas, mismos niveles de historia y avisos que la referencia) |
| Aislamiento sigue en verde | `…/aislamiento.test.sql` | **18/18 ok** |

## Dudas que esta fase va a tener que cerrar (se anotan en `docs/DUDAS.md` al aparecer)

- Formato de folio automático por etapa (`MAG-001`, `HOR-001`, `F-001`,
  `FER-T1-001`, `DES-001`, `G-2609-01`): la simulación mezcla estilos
  (consecutivo simple vs. tina vs. fecha). Supuesto: prefijo por material +
  consecutivo por empresa; el usuario puede dar folio propio.
- `registrar_entrada` para `fermentado` "que ya fermentaba": abre ciclo con
  `formulation_id` nulo (como en la simulación). Confirmar.
- `corregir_operacion`: qué campos son corregibles sin tocar el ledger
  (nota, contraparte, documento, `occurred_at`) vs. los que exigen un
  movimiento de corrección (volúmenes). Supuesto: solo metadatos; los
  volúmenes se corrigen con `registrar_movimiento_granel` de ajuste.

## Riesgo a vigilar

La semilla por RPC es la parte más larga: ~40 llamadas encadenadas cuyos ids
se resuelven por folio. Si una regla dura está mal calibrada, la semilla
falla a mitad y `db reset --linked` deja el proyecto vacío hasta corregirla.
Es el comportamiento deseado (§0.1.3: no declarar listo por optimismo), pero
hay que avisarlo.
