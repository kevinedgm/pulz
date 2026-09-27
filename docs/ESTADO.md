# PULZ · Estado del proyecto

> Lo primero que se lee al retomar una sesión. Se mantiene vivo: fase actual,
> qué pasó, qué falta, qué se decidió y por qué.
>
> **Antes de leer el resto, lee `CLAUDE.md` en la raíz del repo.** Trae las
> reglas que se decidieron después de `PULZ_MAESTRO.md` y que valen para
> todas las fases, no solo para la Fase 0: nunca Docker/Supabase local,
> migraciones "desde cero" mientras no haya lanzamiento, y que toda interfaz
> empieza por la skill `kiwi`.

## Fase actual

**Fase 0 · Arranque** — cerrada en la práctica. Monorepo, tooling, CI,
estructura base, Fruti Squad y los agent-skills de Supabase implementados y
verificados con comandos reales; repo en GitHub y sincronizado. Solo falta
confirmar `ci.yml` en un PR real cuando exista uno (no bloquea empezar la
Fase 1).

## Qué pasó

- 2026-09-26: se leyó completo `PULZ_MAESTRO.md` y los archivos de
  `referencia/`. Se escribió y aprobó el plan de la Fase 0.
- 2026-09-26: se implementó casi toda la Fase 0 — monorepo pnpm, `apps/web`
  (Vue 3 + Vite + TS + Pinia + Router + cliente Supabase), `packages/shared`,
  ESLint/Prettier, Vitest, Supabase CLI inicializado, CI mínimo, Fruti Squad
  con el perfil PULZ completo (§13.4) y los agent-skills de Supabase.
  Verificado con comandos reales: `pnpm install/lint/format/build/test` en
  verde; `supabase start` **sí llegó a funcionar** con Colima (dándole más
  CPU/memoria); la skill `lima` respondió correctamente a una prueba directa
  leyendo su perfil.
- 2026-09-26 (mismo día, sesión continuada): el dueño creó
  `github.com/kevinedgm/pulz` y se subieron los commits. Después pidió
  reestructurar el plan sobre tres puntos permanentes, ya escritos en
  `CLAUDE.md` (raíz del repo) y en `docs/DECISIONES.md` con el detalle
  completo:
  1. **Nunca Docker/Colima/Podman**, ni siquiera temporalmente — se
     desinstaló Colima. Todo el trabajo de base de datos va directo contra
     el proyecto Supabase alojado (`apps/web/.env.local`).
  2. **Migraciones "desde cero" mientras no haya lanzamiento**: el esquema se
     trata como una sola implementación limpia y correcta, no como una pila
     de parches históricos. Se edita/reescribe la migración que haga falta en
     vez de apilar una de "fix" arriba de otra. Esto cambia el día que el
     producto tenga usuarios reales (ahí sí, migraciones aditivas e
     inmutables).
  3. **Cualquier trabajo de interfaz empieza por la skill `kiwi`** (ya lo
     decía `PULZ_MAESTRO.md` §13.4; ahora es una regla explícita en
     `CLAUDE.md` para que no se salte por accidente): kiwi (estructura) →
     lima (gobernanza) → coco (construcción + auditoría) → mora-docs
     (documentación).

## Qué falta

- Abrir un PR real y confirmar que `ci.yml` corre en verde ahí (no bloquea
  empezar la Fase 1).
- Fase 1 todavía no arranca: falta escribir y aprobar
  `docs/plan/FASE-1.md` con las tres reglas nuevas ya incorporadas
  (especialmente la estrategia de migraciones "desde cero" y cómo se aplica
  el esquema contra el proyecto alojado sin `supabase db reset` local).

## Entorno (actualizado 2026-09-26)

| Herramienta | Estado |
|---|---|
| Node | 22.23.3 vía `nvm`, fijado en `.nvmrc` y `engines` del `package.json` raíz |
| pnpm | 9.15.9, activado vía Corepack |
| git | repo en `github.com/kevinedgm/pulz`, rama `main`, sincronizado |
| Supabase CLI | 2.118.0 (Homebrew); se usa solo contra el proyecto alojado, nunca `supabase start` |
| Docker / Colima / Podman | **desinstalados a propósito, regla permanente** (ver `CLAUDE.md`) |
| Fruti Squad | `.claude/skills/{kiwi,lima,coco,mora-docs}`; perfil en `.claude/skills/lima/profiles/pulz.md`; Design Hub en `design-hub/`; probado con una invocación real de `lima` |
| Agent-skills de Supabase | `.agents/skills/{supabase,supabase-postgres-best-practices}`, symlink en `.claude/skills/` |

## Decisiones y por qué

Ver `docs/DECISIONES.md` para el historial completo (no se borra nada, se
agregan entradas nuevas cuando una decisión reemplaza a otra). Las que rigen
hacia adelante están resumidas en `CLAUDE.md`.

## Pendiente de decidir (ver `docs/DUDAS.md`)

- Mecánica exacta para aplicar el esquema de la Fase 1 contra el proyecto
  alojado sin Postgres local (¿`supabase db push` directo?, ¿un segundo
  proyecto Supabase para pruebas separado del de desarrollo?). Se decide al
  escribir `docs/plan/FASE-1.md`.

## Próxima fase

Fase 1 · Base de datos (partir `pulz_esquema.sql` en migraciones, aplicar
§10.2, migraciones "desde cero" per `CLAUDE.md`, pgTAP de aislamiento). Toca
escribir `docs/plan/FASE-1.md` y mostrarlo para aprobación antes de tocar el
esquema.
