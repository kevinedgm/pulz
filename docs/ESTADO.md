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

**Fase 1 · Base de datos — cerrada** (2026-09-27). Todos los criterios de
aceptación de `PULZ_MAESTRO.md` §16 comprobados con comandos reales contra el
proyecto alojado (abajo). **Fase 2 · Comandos (RPC)** es la siguiente: falta
escribir `docs/plan/FASE-2.md` y mostrarlo para aprobación antes de tocar
código (§0.1.2).

## Qué pasó

- 2026-09-26: Fase 0 completa (monorepo, tooling, CI, Fruti Squad,
  agent-skills de Supabase, repo en `github.com/kevinedgm/pulz`). Detalle en
  `docs/plan/FASE-0.md`.
- 2026-09-26: el dueño fijó tres reglas permanentes (`CLAUDE.md`): nunca
  Docker, migraciones "desde cero" pre-lanzamiento, kiwi primero en interfaz.
- 2026-09-27: el dueño aprobó `docs/plan/FASE-1.md`, corrió `supabase login`
  y confirmó usar `supabase db push`/`--linked` directo contra el proyecto
  alojado `ypgeiyorgktshgbzhgfh` (instancia de desarrollo). Se enlazó y se
  implementó la Fase 1 completa:
  - 13 migraciones en `supabase/migrations/` (tipos → plataforma → cobro →
    catálogos con §10.2 → predios/proveedores/insumos → infraestructura →
    operaciones → lotes y ledger → etapas → auditoría → vistas → portal →
    RLS). Nombres con timestamp secuencial `20260927000001…13`, que es el
    patrón que exige el CLI.
  - `supabase/seed.sql`: la simulación de Cuatro Vientos adaptada a §10.2
    (plantillas + `seed_organization_catalogs`) y una segunda empresa mínima
    ("Palenque Prueba B") para probar aislamiento.
  - `supabase/tests/aislamiento.test.sql`: pgTAP de aislamiento (§11.3) y de
    los criterios de aceptación, como función que corre por la Management
    API (Docker no se usa en ningún paso).

## Criterios de aceptación de la Fase 1 (§16) — comprobados

| Criterio | Comando real | Resultado |
|---|---|---|
| `supabase db reset` sin errores | `supabase db reset --linked --yes` | **13/13 migraciones + semilla aplicadas sin un solo error** de Postgres (la referencia anticipaba errores; no hubo) |
| Saldos de §15.1 exactos en `resource_lot_balances` | `supabase db query --linked "select … from resource_lot_balances …"` | **Exactos**: COL-002 16 · G-COMPRA-01 250 · G-INI-01 341.8 · FER-T1-001 870 · FER-T2-001 1400 · FER-T3-INI 1300 |
| pgTAP de aislamiento en verde | `supabase db query --linked -f supabase/tests/aislamiento.test.sql` | **18/18 ok** (dos empresas reales, usuario sin membresía, operador vs. admin, FK compuesta, RLS) |
| Ninguna política `for all` | `select count(*) from pg_policies where cmd='ALL'` | **0** |
| Sin columnas `json`/`jsonb` en `public` | `information_schema.columns` | **0** (45 tablas, todas con RLS activada) |
| Semilla por empresa (§10.2) | conteos | 29 plantillas → 29 copias en B; 30 en A (29 + 1 propia), 2 ocultas con `active=false` |

Lo que NO se pudo comprobar tal como lo pedía el plan: `supabase test db
--linked` — necesita Docker aunque apunte al proyecto alojado. Se sustituyó
por el runner de la Management API con el mismo test; no es una omisión, es
una vía equivalente (ver `docs/DECISIONES.md`).

## Qué falta

- Escribir y aprobar `docs/plan/FASE-2.md` (cuerpos de las RPC de §12 con
  el contrato de §12.1; reescribir la simulación para que se construya
  llamando a las RPC; pgTAP por RPC y prueba de concurrencia).
- Confirmar con el dueño la escala 1–6 de actividad/dulzor/acidez (§18 #1,
  `docs/DUDAS.md` #4). No bloquea.
- Abrir un PR real y confirmar que `ci.yml` corre en verde (no bloquea).
- Cuando el front lo necesite (Fase 4/5): `supabase gen types typescript
  --linked` hacia `packages/shared`.

## Entorno (actualizado 2026-09-27)

| Herramienta | Estado |
|---|---|
| Node | 22.23.3 vía `nvm` (`.nvmrc`, `engines`) |
| pnpm | 9.15.9 vía Corepack |
| git | `github.com/kevinedgm/pulz`, rama `main` |
| Supabase CLI | 2.118.0, **enlazado** a `ypgeiyorgktshgbzhgfh` ("pulz", instancia de desarrollo). Nunca `supabase start`, nunca `supabase test db` (ambos piden Docker) |
| Proyecto Supabase | esquema completo de la Fase 1 aplicado; **cada `db reset --linked` lo borra y reconstruye** — no guardar ahí nada que no esté en `seed.sql` |
| Docker / Colima / Podman | desinstalados a propósito, regla permanente |
| Fruti Squad | `.claude/skills/{kiwi,lima,coco,mora-docs}`, perfil `.claude/skills/lima/profiles/pulz.md`, Design Hub en `design-hub/` |
| Agent-skills de Supabase | `.agents/skills/{supabase,supabase-postgres-best-practices}` |

## Regla de seguridad que hay que recordar

`supabase projects list` muestra también el proyecto **TRAKER-PALENQUE**
(`thpoahtohyofjndauvix`): es el sistema heredado de Istmeño. **Nunca se
enlaza ni se toca** (`PULZ_MAESTRO.md` §0.3). Solo `ypgeiyorgktshgbzhgfh`.

## Decisiones y por qué

Ver `docs/DECISIONES.md` (historial completo, no se borra nada) y `CLAUDE.md`
(las que rigen hacia adelante).

## Pendiente de decidir (ver `docs/DUDAS.md`)

- Escala 1–6 vs. 1–10 para actividad/dulzor/acidez (#4). Implementado 1–6.

## Próxima fase

Fase 2 · Comandos (RPC). Toca escribir `docs/plan/FASE-2.md` y mostrarlo
para aprobación.
