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

**Fase 1 · Base de datos** — plan escrito en `docs/plan/FASE-1.md`,
**esperando aprobación del dueño antes de implementar** (regla §0.1.2). Fase
0 quedó cerrada en la práctica (ver abajo).

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

- 2026-09-27: el dueño confirmó usar `supabase db push`/`--linked` directo
  contra el proyecto alojado (es una instancia de desarrollo, no hace falta
  un segundo proyecto). Se probó cada subcomando del CLI real (`db reset
  --linked`, `test db --linked`, `db query --linked`, `db push`) y **todos
  existen y apuntan al proyecto alojado sin Docker** — confirmado con
  `--help`, no supuesto. Se escribió `docs/plan/FASE-1.md` con el esquema
  completo partido en migraciones (§10.2 aplicado), la simulación adaptada +
  segunda empresa, y pgTAP de aislamiento. **Bloqueo real encontrado**:
  `supabase link` pide `supabase login` o `SUPABASE_ACCESS_TOKEN`, y esta
  sesión no puede completar un login interactivo — se le pidió al dueño
  correr `supabase login` en su propia terminal.

## Qué falta

- Aprobación del dueño para `docs/plan/FASE-1.md` antes de tocar el esquema.
- Que el dueño corra `supabase login` (o dé un access token) para poder
  enlazar el proyecto y ejecutar las tareas 6–9 del plan de Fase 1 (link,
  reset, pgTAP, verificación de saldos). Las migraciones (tareas 1–5) se
  pueden escribir sin esto.
- Abrir un PR real y confirmar que `ci.yml` corre en verde ahí (no bloquea
  la Fase 1).

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

- Nada de negocio pendiente para esta fase. Solo el bloqueo operativo de
  `supabase login` de arriba.

## Próxima fase

Ninguna todavía — hay que cerrar la Fase 1 primero. Ver `docs/plan/FASE-1.md`
para el detalle completo de tareas y criterios de aceptación.
