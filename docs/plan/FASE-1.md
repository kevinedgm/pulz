# Fase 1 · Base de datos

> Sigue `PULZ_MAESTRO.md` §0.1, §10, §11.3, §15 y §16, más las tres reglas
> permanentes de `CLAUDE.md` (nunca Docker, migraciones "desde cero" mientras
> no haya lanzamiento, kiwi primero para interfaz — esta fase no toca
> interfaz). Objetivo: el modelo de datos completo de `pulz_esquema.sql`
> aplicado con §10.2, la simulación de Cuatro Vientos + una segunda empresa
> cargando por RPC... **no** — por inserts directos todavía (los RPC son
> Fase 2), y pgTAP de aislamiento en verde. Todo contra el proyecto Supabase
> alojado, nunca local.

## Cómo se hace sin Docker: confirmado con el CLI real, no supuesto

Antes de planear, se probó cada subcomando contra la instalación real de
`supabase` (2.118.0) en esta máquina — no se asume nada:

| Lo que local hacía con Docker | Equivalente confirmado contra el proyecto alojado |
|---|---|
| `supabase start` + migraciones al vuelo | `supabase link --project-ref ypgeiyorgktshgbzhgfh` (una vez) |
| `supabase db reset` | `supabase db reset --linked` — **"Resets the linked project with local migrations"**, existe tal cual en el CLI |
| `supabase test db` (pgTAP) | `supabase test db --linked` — **"Runs pgTAP tests on the linked project"**, existe tal cual |
| Consultar saldos con psql local | `supabase db query --linked "<sql>"` (vía Management API, no necesita cadena de conexión) o `psql` directo (está instalado, viene de Postgres.app) si hace falta |
| Aplicar una migración nueva | `supabase db push` (o `--linked`) |

Es decir: el ciclo completo de la Fase 1 — reset, migrar, sembrar, probar,
consultar — existe en el CLI apuntando al proyecto alojado, sin Docker en
ningún paso. Esto resuelve la duda de `docs/DUDAS.md`.

## Bloqueo antes de poder ejecutar nada de esto

`supabase link` pidió autenticarse:

```
AccessTokenRequiredError: Access token not provided. Supply an access token
by running `supabase login` or setting the SUPABASE_ACCESS_TOKEN environment
variable.
```

Esta sesión no puede completar un login interactivo (abre navegador). Para
desbloquear, el dueño necesita hacer **una** de estas dos cosas:

1. **Recomendado**: correr `supabase login` en su propia terminal (fuera de
   esta sesión) una vez. Con eso el CLI guarda la sesión localmente y esta
   sesión la reutiliza sin que nadie tenga que pegar un token en el chat.
2. Generar un *personal access token* en
   `supabase.com/dashboard/account/tokens` y decírmelo para exportarlo como
   `SUPABASE_ACCESS_TOKEN` en esta sesión. Funciona, pero es un token de
   cuenta (más amplio que una sola API key de proyecto), así que la opción 1
   es más segura.

También es probable que `supabase link`/`db push` pidan la **contraseña de
Postgres del proyecto** (no es el `anon`/`publishable key` que ya tenemos;
está en Project Settings → Database del panel de Supabase). Se resuelve
cuando aparezca el prompt, no hace falta adelantarlo.

**Nada de lo demás en este plan depende de este bloqueo** salvo los pasos que
tocan el proyecto alojado de verdad (tareas 6–9). Las migraciones (1–5) se
pueden escribir y revisar en el repo sin estar enlazado todavía.

## Tareas, en orden

1. **Reescribir la sección de catálogos (§10.2)** antes de partir el resto
   del esquema, porque cambia tablas que muchas otras referencian:
   - `catalog_item_templates`, `movement_concept_templates`,
     `species_templates` (sin `organization_id`, solo las edita el admin de
     plataforma).
   - `catalog_items`, `movement_concepts`, `species` pasan a
     `organization_id not null` + `unique(organization_id, id)`, con
     `template_id` para saber de qué plantilla vinieron.
   - `seed_organization_catalogs(org)`: copia las plantillas activas a la
     empresa. Se llama directo desde `seed.sql` para las dos empresas de
     prueba (no desde `provision_organization`, que es RPC de Fase 2).
   - `propagate_template(template_id)`: agrega una plantilla nueva a las
     empresas que no la tengan, sin tocar las que ya la editaron.
   - Se eliminan `catalog_item_hidden`, `movement_concept_hidden`,
     `species_hidden`, `catalog_visible()`, `concept_visible()`,
     `catalog_for_org`, `concepts_for_org`. Ocultar pasa a ser
     `active = false` en la fila de la empresa.
   - Las referencias tipadas (`resources.type_item_id`,
     `suppliers.type_item_id`, `supplies.unit_item_id`,
     `attachments.kind_item_id`) pasan a FK compuestas
     `(organization_id, type_item_id) references catalog_items(organization_id, id)`
     y se les agrega el CHECK/trigger que confirma que el `catalog` del
     elemento corresponde al `kind` del recurso (ya está en
     `pulz_esquema.sql` para `resources`, hay que replicarlo donde falte).
2. **Partir el resto de `pulz_esquema.sql` en migraciones ordenadas**, una
   responsabilidad por archivo, agrupadas como en §10.3:
   - `0001_tipos.sql` — todos los `create type` de la sección 0001.
   - `0002_plataforma.sql` — `reserved_slugs`, `organizations` + trigger de
     slug, `profiles`, `platform_admins`, `organization_members`,
     `member_invitations`, `login_throttle`, `organization_settings`.
   - `0003_cobro.sql` — `plans`, `plan_limits`, `plan_features`,
     `subscriptions`, `stripe_events`.
   - `0004_catalogos.sql` — el resultado de la tarea 1.
   - `0005_predios_proveedores_insumos.sql` — `predios`, `suppliers`,
     `supplies`.
   - `0006_infraestructura.sql` — `resources`.
   - `0007_operaciones.sql` — `operations`, `operation_warnings`.
   - `0008_lotes_y_ledger.sql` — `lots`, el FK diferido de
     `operations.result_lot_id`, `lot_lineage`, `lot_external_sources`,
     `maguey_receptions`, `liquid_movements`, `attachments`.
   - `0009_etapas.sql` — horneado, formulación, fermentación (ciclos +
     mediciones + lecturas), destilación (corridas + insumos + cortes).
   - `0010_auditoria.sql` — `audit_events`, `audit_changes`.
   - `0011_vistas.sql` — `resource_lot_balances`, `lot_declared_abv`,
     `movement_log`, `solid_lot_balances`.
   - `0012_portal.sql` — `portal_branding`, `member_login_email`,
     `auth_password_attempt` + grants al hook, `login_throttle` RLS,
     `desbloquear_miembro`.
   - `0013_seguridad_rls.sql` — `is_member`, `has_role`, `is_platform_admin`,
     todas las políticas de §0010 (una por operación, nunca `for all`).
   - Nombres y números finales pueden ajustarse mientras se escribe; lo que
     importa es que cada archivo tenga una sola responsabilidad y que el
     conjunto se pueda leer de arriba a abajo como una sola historia.
3. **Corregir en el momento cualquier error de Postgres real** (sintaxis,
   orden de creación, tipos) **sin cambiar la intención**, y anotarlo en
   `docs/DECISIONES.md`. Por la regla de `CLAUDE.md` §2: la corrección se
   edita directo en el archivo de migración que tiene el problema — no se
   agrega una migración `0014_fix_tal_cosa.sql` encima. El conjunto de
   migraciones debe leerse siempre como "la implementación correcta desde
   cero", no como un historial de parches.
4. **Adaptar la simulación** (`docs/referencia/pulz_simulacion_semilla.sql`)
   a `supabase/seed.sql`, con los ajustes que pide §10.2 (los `insert` a
   catálogos ya no llevan `organization_id null`; se reemplazan por la
   llamada a `seed_organization_catalogs` + los `insert` propios de cada
   empresa) y se agrega una **segunda empresa mínima** (unas pocas filas:
   organización, un miembro admin, catálogos sembrados, un recurso, nada
   más) para poder probar aislamiento entre dos empresas reales (§11.3).
5. **pgTAP de aislamiento** (§11.3) en `supabase/tests/`: para cada tabla de
   negocio, un usuario de la empresa A no lee/inserta/actualiza/referencia
   filas de la B ni por PostgREST ni por RPC (los RPC de negocio no existen
   todavía — se prueba lo que sí existe en esta fase: las políticas SELECT y
   las de catálogos/recursos/predios/proveedores/insumos que si tienen INSERT
   propio). Un usuario sin membresía activa no ve nada.
6. **`supabase link --project-ref ypgeiyorgktshgbzhgfh`** contra el proyecto
   alojado (requiere que el bloqueo de arriba esté resuelto).
7. **`supabase db reset --linked`** — aplica las migraciones desde cero
   contra el proyecto alojado y corre `seed.sql`. Si falla, se corrige la
   migración correspondiente (tarea 3) y se repite; no se avanza con un
   reset a medias.
8. **`supabase test db --linked`** — corre el pgTAP de la tarea 5 contra el
   mismo proyecto recién reseteado.
9. **Verificar los saldos de §15.1** con
   `supabase db query --linked "select * from resource_lot_balances"` (y las
   consultas equivalentes para `solid_lot_balances` donde aplique) y
   comparar contra la tabla de §15.1.

## Archivos que se tocan

- `supabase/migrations/*.sql` — el esquema completo partido (tarea 2), ya con
  §10.2 aplicado (tarea 1). Se reemplazan los `.gitkeep` actuales.
- `supabase/seed.sql` — la simulación adaptada + segunda empresa (tarea 4).
- `supabase/tests/*.sql` — pgTAP de aislamiento (tarea 5).
- `docs/DECISIONES.md` — cada corrección real de Postgres que aparezca
  (tarea 3), y el resultado de enlazar el proyecto (tarea 6).
- `docs/DUDAS.md` — se cierra la duda de cómo correr pgTAP/reset sin Docker.
- `packages/shared/src/index.ts` — cuando el esquema esté estable, tipos
  generados con `supabase gen types typescript --linked` (si el dueño quiere
  esto ya en esta fase; si no, queda para cuando el front los necesite en
  Fase 4/5).

## Pruebas que se escriben

- pgTAP completo de aislamiento (§11.3) en `supabase/tests/`, corrido con
  `supabase test db --linked` (tarea 5 y 8).
- Nada de Vitest nuevo en esta fase (no hay código de `apps/web` que dependa
  todavía del esquema).

## Cómo se comprueban los criterios de aceptación de §16 (adaptados a "sin Docker")

| Criterio original (§16) | Cómo se comprueba aquí |
|---|---|
| `supabase db reset` sin errores | `supabase db reset --linked` sin errores (tarea 7) |
| Saldos de §15.1 exactos consultando `resource_lot_balances` | `supabase db query --linked` (tarea 9), comparado campo por campo |
| pgTAP de aislamiento en verde | ~~`supabase test db --linked`~~ → **necesita Docker aunque apunte al proyecto alojado** (levanta `pg_prove` en un contenedor). Se corre en su lugar `supabase db query --linked -f supabase/tests/aislamiento.test.sql`, que ejecuta el test como función pgTAP y devuelve todas las líneas TAP. Resultado real: **18/18 ok** (ver `docs/DECISIONES.md`) |
| Ninguna política `for all` | `supabase db query --linked "select * from pg_policies where cmd = 'ALL'"` → cero filas |
| Sin columnas `json`/`jsonb` en `public` | `supabase db query --linked "select table_name, column_name from information_schema.columns where table_schema = 'public' and data_type in ('json','jsonb')"` → cero filas |

Si el bloqueo de autenticación (arriba) sigue sin resolverse cuando se
termine de escribir el esquema, se dice explícitamente en `docs/ESTADO.md`
qué se pudo comprobar localmente (sintaxis, orden de creación revisado a
mano) y qué falta comprobar contra el proyecto real — no se declara la fase
cerrada por optimismo (regla §0.1.3).

## Riesgo a vigilar

`supabase db reset --linked` **borra y reconstruye el proyecto alojado
completo** cada vez que se corre. Es exactamente lo que se quiere mientras el
producto no tenga usuarios (regla de `CLAUDE.md` §2), pero significa que
**ese proyecto Supabase deja de servir para nada que no sea este ciclo de
desarrollo** — no guardar ahí ninguna prueba manual, dato de demo para
enseñarle a alguien, ni nada que no esté en `seed.sql`, porque el siguiente
reset lo borra sin aviso.
