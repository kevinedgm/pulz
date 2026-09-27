# PULZ · Estado del proyecto

> Lo primero que se lee al retomar una sesión. Se mantiene vivo: fase actual,
> qué pasó, qué falta, qué se decidió y por qué.
>
> **Antes de leer el resto, lee `CLAUDE.md` en la raíz del repo.** Trae las
> reglas que se decidieron después de `PULZ_MAESTRO.md` y que valen para
> todas las fases: nunca Docker/Supabase local, migraciones "desde cero"
> mientras no haya lanzamiento, y que toda interfaz empieza por la skill
> `kiwi`.

## Fase actual

**Fase 2 · Comandos (RPC) — cerrada salvo un punto** (2026-09-27). Las 17
RPC de §12 existen con el contrato de §12.1; la simulación se construye
llamando a las RPC y da exactamente §15.1; pgTAP por RPC 26/26. **Lo único
no comprobado**: la prueba de concurrencia con dos sesiones reales (queda en
SKIP porque la Management API no puede abrir una segunda sesión sin la
contraseña de Postgres — ver `docs/DUDAS.md` #5, con el comando para que el
dueño la corra en dos terminales). **Fase 3 · Portal, acceso y equipo** es
la siguiente: falta escribir `docs/plan/FASE-3.md` y mostrarlo para
aprobación (§0.1.2).

## Qué pasó

- 2026-09-26: Fase 0 completa; reglas permanentes en `CLAUDE.md`; repo en
  `github.com/kevinedgm/pulz`.
- 2026-09-27: Fase 1 completa (13 migraciones, semilla, pgTAP de
  aislamiento 18/18, saldos §15.1) contra el proyecto alojado, sin Docker.
- 2026-09-27: el dueño aprobó `docs/plan/FASE-2.md`. Se implementó:
  - `0014_rpc_base`: helpers del contrato §12.1 (guard, idempotencia,
    bloqueo en orden de id, saldos del ledger, capacidad, avisos con nota,
    estado agotado, nivel de historia, folios por empresa).
  - `0015`–`0020`: las 17 RPC de negocio (`registrar_recepcion_maguey`,
    `registrar_entrada`, `abrir/cerrar_horneado`, `registrar_formulacion`,
    `registrar_medicion`, `anular_medicion`, `declarar_tina_lista`,
    `cerrar_ciclo`, `abrir_corrida`, `registrar_corte`, `cerrar_corrida`,
    `transferir`, `registrar_movimiento_granel`, `completar_historia`,
    `corregir_operacion`) + `desbloquear_miembro` de la Fase 1.
  - `0021`: `provision_organization` (solo `service_role`) y los grants:
    17 RPC ejecutables por `authenticated`, ninguna función interna expuesta.
  - `seed.sql` reescrito: la producción de Cuatro Vientos se construye con
    38 llamadas a RPC en orden cronológico, con el usuario que registró cada
    cosa (salvo `abrir_horneado`, que lo hace Aurelia porque §11.1 no se lo
    permite al operador).
  - `supabase/tests/rpc.test.sql` (26 aserciones) y
    `rpc_concurrencia.test.sql` (dblink; SKIP en alojado).
  - Dos correcciones "desde cero" (editadas en su migración, no encimadas):
    `operation_kind` gana `anular_medicion`/`cerrar_ciclo` (`0001`) y
    `registrar_medicion` recibe enteros, no smallint (`0017`).

## Criterios de aceptación de la Fase 2 (§16) — comprobados

| Criterio | Comando real | Resultado |
|---|---|---|
| pgTAP por RPC: feliz, idempotencia, duras, blandas | `supabase db query --linked -f supabase/tests/rpc.test.sql` | **26/26 ok**: idempotencia (misma llave → mismo lote, ledger intacto), `SALDO_INSUFICIENTE`, `CAPACIDAD_EXCEDIDA`, `NO_PERMITIDO` (otra empresa; operador en RPC de productor), `REQUIERE_NOTA` sin nota / aviso registrado con nota, regla de acumulación (3 casos), transferir con `conservar` + linaje, conciliación exacta, estado agotado, niveles de historia |
| La simulación por RPC da §15.1 | `supabase db reset --linked` + saldos | **Exactos**; además 38 operaciones, 13 lotes, 16 aristas de linaje y los mismos niveles de historia que la simulación de referencia, y los dos avisos blandos |
| Aislamiento sigue en verde con la semilla por RPC | `…/aislamiento.test.sql` | **18/18 ok** |
| Concurrencia: dos transferencias del último litro | `…/rpc_concurrencia.test.sql` | **SKIP** — dblink pide contraseña en alojado. No se declara en verde. Instrucciones para probarlo a mano en `docs/DUDAS.md` #5 |

## Qué falta

- (Opcional, no bloquea) Que el dueño corra la prueba de concurrencia en dos
  terminales `psql` (`docs/DUDAS.md` #5) o dé la contraseña de Postgres del
  proyecto para que el test con `dblink` la use.
- Confirmar tres supuestos de negocio de la Fase 2 (`docs/DUDAS.md` #6–#8:
  formato de folios, entrada de tina que ya fermentaba, alcance de
  `corregir_operacion`) y la escala 1–6 (#4). No bloquean.
- Escribir y aprobar `docs/plan/FASE-3.md` (portal, acceso y equipo:
  `signup-company`, `manage-member`, hook de intentos, pantallas de acceso,
  guardias del router, Pages Function del portal). **Ojo**: es la primera
  fase con interfaz → empieza por `kiwi` (`CLAUDE.md` §3).
- Abrir un PR real y confirmar que `ci.yml` corre en verde (no bloquea).

## Entorno (actualizado 2026-09-27)

| Herramienta | Estado |
|---|---|
| Node / pnpm | 22.23.3 vía `nvm` · pnpm 9.15.9 vía Corepack |
| git | `github.com/kevinedgm/pulz`, rama `main` |
| Supabase CLI | 2.118.0, enlazado a `ypgeiyorgktshgbzhgfh` ("pulz", desarrollo). Nunca `supabase start` ni `supabase test db` (piden Docker); pgTAP va por `supabase db query --linked -f` |
| Proyecto Supabase | 21 migraciones + semilla por RPC aplicadas; **cada `db reset --linked` lo borra y reconstruye** |
| Docker / Colima / Podman | desinstalados a propósito, regla permanente |
| Fruti Squad | `.claude/skills/{kiwi,lima,coco,mora-docs}`, perfil `.claude/skills/lima/profiles/pulz.md` |
| Agent-skills de Supabase | `.agents/skills/{supabase,supabase-postgres-best-practices}` |

## Regla de seguridad que hay que recordar

`supabase projects list` muestra también **TRAKER-PALENQUE**
(`thpoahtohyofjndauvix`): es el sistema heredado de Istmeño. **Nunca se
enlaza ni se toca** (`PULZ_MAESTRO.md` §0.3). Solo `ypgeiyorgktshgbzhgfh`.

## Decisiones y por qué

Ver `docs/DECISIONES.md` (historial completo) y `CLAUDE.md` (las que rigen
hacia adelante).

## Pendiente de decidir (ver `docs/DUDAS.md`)

- #4 escala 1–6 vs 1–10 · #5 cómo correr la concurrencia · #6 formato de
  folios · #7 entrada de tina que ya fermentaba · #8 alcance de
  `corregir_operacion`. Todo implementado con un supuesto razonable.

## Próxima fase

Fase 3 · Portal, acceso y equipo. Toca escribir `docs/plan/FASE-3.md` y
mostrarlo para aprobación. Las pantallas de acceso pasan primero por `kiwi`.
