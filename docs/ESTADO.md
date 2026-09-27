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

**Fase 3 · Portal, acceso y equipo — servidor terminado y verificado;
interfaz detenida en la compuerta de `kiwi`.** Las tres Edge Functions
(`signup-company`, `manage-member`, `set-password`) están desplegadas y
probadas de punta a punta; la Pages Function del portal pasa sus pruebas
reales; el login con usuario simple y con correo funciona contra GoTrue.
**Siguiente paso**: ronda de `kiwi` (brief, flujo, wireframes F0–F2) para
las pantallas de acceso y equipo → **el dueño la aprueba** → lima → coco →
mora-docs. Nada de interfaz se construye antes (`CLAUDE.md` §3).

## Qué pasó

- 2026-09-26: Fase 0 (monorepo, tooling, Fruti Squad, repo en GitHub) y
  reglas permanentes en `CLAUDE.md`.
- 2026-09-27: Fase 1 (esquema en 13 migraciones, aislamiento 18/18, saldos
  §15.1) y Fase 2 (17 RPC, semilla por RPC, pgTAP 26/26) contra el proyecto
  alojado, sin Docker.
- 2026-09-27: Fase 3, mitad de servidor:
  - `0022_acceso.sql`: vista `mis_membresias` para las guardias del router.
  - Contraseñas de desarrollo en la semilla (bcrypt vía `extensions.crypt`).
  - Edge Functions con `@supabase/server` (`withSupabase`), desplegadas con
    `--use-api`. Smoke real con `curl`: 13 casos, todos como se diseñaron
    (alta por enlace y dictada, canje de un solo uso, cambio obligatorio,
    duplicado 409, operador 403, sin sesión 401, alta de empresa, slug
    reservado).
  - Hook de intentos: **402, no está en el plan del proyecto** (§18 #9
    respondido). Queda apagado y documentado; el criterio "5 fallos
    bloquean" no es comprobable en este plan.
  - `config push` acotado: `config.toml` deja sin declarar todo lo que no
    queremos que mande (15 diferencias que el template habría empujado).
  - Pages Function copiada a `apps/web/functions/e/[slug]/[[path]].ts`,
    `wrangler.toml`, prueba e2e con `wrangler pages dev` (5/5) y pgTAP del
    portal (11/11).
  - Advisors: corregidos `search_path`, revokes a `anon`, `(select
    auth.uid())` en `profiles`. 0 errores.
  - Lint/format del repo en verde (se ignoran `.claude/`, `.agents/`,
    `design-hub/` — tooling de terceros).

## Criterios de aceptación de la Fase 3 (§16) — estado

Ver tabla completa en `docs/plan/FASE-3.md` ("Resultados reales"). Resumen:
login por usuario y por correo **OK**; rechazos idénticos **OK** en GoTrue
(el texto único lo pone la pantalla); slug 301 **OK**; vencida/cancelada
**OK** (pgTAP); función del portal **5/5**; título "Mezcal Cuatro Vientos ·
PULZ" **OK**; altas/canje/cambio obligatorio **OK**; **5 fallos bloquean: no
comprobable en este plan**; **pantallas: pendientes de la ronda de kiwi**.

## Qué falta

1. **Ronda de `kiwi` r01 escrita, esperando aprobación del dueño**:
   `design-hub/lab/acceso/r01/` (`brief.md` con 3 user flows, `index.html`
   wireframe F2 de las 4 pantallas × 3 espacios × 13 estados, `hallazgos.md`,
   `declaracion.md`). Verificado: `check_artifact.py` 0/0, 156 combinaciones
   sin desborde y con una sola primaria, 0 errores JS. Dos hallazgos altos
   para decidir en la aprobación: el admin no puede leer hoy "bloqueado" ni
   "enlace vigente" (falta una vista solo-admin), y el hook de intentos no
   está en el plan. → aprobación → `lima` → `coco` (implementación en
   `apps/web/src/modules/acceso/` y guardias en `apps/web/src/app/router.ts`)
   → `mora-docs`. Cambios pedidos → `r02`, nunca se sobrescribe r01.
2. Vitest de integración del cliente de acceso (mensaje único en los cuatro
   rechazos, guardias) cuando exista la pantalla.
3. Que el dueño decida sobre `docs/DUDAS.md` #9 (subir de plan para el hook)
   y #10 (protección de contraseñas filtradas). No bloquean.
4. Sigue abierto de fases anteriores: concurrencia a mano (#5), escala 1–6
   (#4), folios/entrada de tina/corregir_operacion (#6–#8). No bloquean.
5. Abrir un PR real y confirmar `ci.yml` (no bloquea).

## Entorno (actualizado 2026-09-27)

| Herramienta | Estado |
|---|---|
| Node / pnpm | 22.23.3 vía `nvm` · pnpm 9.15.9 vía Corepack |
| git | `github.com/kevinedgm/pulz`, rama `main` |
| Supabase CLI | 2.118.0, enlazado a `ypgeiyorgktshgbzhgfh`. Nunca `supabase start` ni `test db` (Docker); pgTAP por `db query --linked -f`; funciones con `deploy --use-api`; **`config diff` antes de cualquier `config push`** |
| Proyecto Supabase | 22 migraciones + semilla por RPC; 3 Edge Functions desplegadas; hook de intentos no disponible (plan); **cada `db reset --linked` lo reconstruye** |
| Cloudflare | `apps/web/wrangler.toml` (Pages, `dist/`); la Pages Function se prueba con `pnpm --filter @pulz/web test:portal` (requiere `pnpm build` antes) |
| Docker / Colima / Podman | desinstalados a propósito, regla permanente |
| Fruti Squad | `.claude/skills/{kiwi,lima,coco,mora-docs}`, perfil `.claude/skills/lima/profiles/pulz.md` |

## Regla de seguridad que hay que recordar

`supabase projects list` muestra también **TRAKER-PALENQUE**
(`thpoahtohyofjndauvix`): es el sistema heredado de Istmeño. **Nunca se
enlaza ni se toca** (`PULZ_MAESTRO.md` §0.3). Solo `ypgeiyorgktshgbzhgfh`.

## Decisiones y por qué

Ver `docs/DECISIONES.md` (historial completo) y `CLAUDE.md` (las que rigen
hacia adelante).

## Pendiente de decidir (ver `docs/DUDAS.md`)

- #9 hook de intentos (plan) · #10 contraseñas filtradas · #5 concurrencia
  a mano · #4 escala 1–6 · #6–#8 supuestos de negocio de la Fase 2.

## Próxima fase

No hay siguiente fase hasta cerrar la Fase 3: falta la interfaz, que empieza
por `kiwi` y la aprobación del dueño.
