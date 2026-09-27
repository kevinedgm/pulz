# PULZ · Estado del proyecto

> Lo primero que se lee al retomar una sesión. Se mantiene vivo: fase actual,
> qué pasó, qué falta, qué se decidió y por qué.

## Fase actual

**Fase 0 · Arranque** — en curso. Monorepo, tooling, CI y estructura base
implementados y verificados con comandos reales. Falta: decidir Docker/Colima
y correr Fruti Squad (pendiente de confirmación) antes de poder cerrarla.

## Qué pasó

- 2026-09-26: se leyó completo `PULZ_MAESTRO.md` y los archivos de
  `referencia/` (`pulz_esquema.sql`, `pulz_simulacion_semilla.sql`,
  `pulz_portal_function.ts`, `pulz-tokens.css`). Se escribió el plan de la
  Fase 0 y se mostró para aprobación.
- 2026-09-26: se implementó la mayor parte de la Fase 0 (ver detalle abajo).
  `git init`, monorepo pnpm, `apps/web` (Vue 3 + Vite + TS + Pinia + Router +
  Supabase client), `packages/shared`, ESLint/Prettier, Vitest con prueba de
  humo, Supabase CLI inicializado, CI mínimo. Seis commits, uno por tarea
  coherente (§0.1.5). Verificado con comandos reales:
  - `pnpm install` — verde
  - `pnpm lint` — verde
  - `pnpm format` — verde
  - `pnpm build` — verde (`apps/web` compila y genera `dist/`)
  - `pnpm test` — verde (1 prueba de humo en `apps/web`)
  - `supabase start` — **falla**: no hay Docker/Colima/Podman en esta
    máquina. Documentado en `docs/DUDAS.md`, no se declaró listo por
    optimismo (§0.1.3).
  - CI en un PR real — **no verificado todavía** (no se ha abierto PR).

## Qué falta para cerrar la Fase 0

1. Decidir Docker Desktop vs. Colima (pregunta abierta al dueño) e instalar
   uno para que `supabase start` responda.
2. Confirmar con el dueño antes de correr
   `npx github:kevinedgm/fruti-squad setup --target claude` (descarga y
   ejecuta un script de un repo de GitHub de un tercero) — instalar Fruti
   Squad, hacer el intake de §13.4 y verificar que quede el perfil PULZ y el
   Design Hub inicial.
3. Abrir un PR real y confirmar que `ci.yml` corre en verde ahí.

## Entorno (actualizado 2026-09-26, después de implementar)

| Herramienta | Estado |
|---|---|
| Node | 22.23.3 instalado vía `nvm`, fijado en `.nvmrc` y en `engines` del `package.json` raíz (el Node 20 de Homebrew se quedó instalado pero no se usa para este repo) |
| pnpm | 9.15.9, activado vía Corepack |
| git | 2.50.1 — repo inicializado, rama `main`, 6 commits |
| Supabase CLI | 2.118.0, instalado vía Homebrew; `supabase init` ya corrido |
| Docker / Colima / Podman | **ninguno instalado** — `supabase start` falla con `docker: command not found (podman also not found)` |
| Homebrew | disponible (6.0.15) |

## Decisiones y por qué

Ver `docs/DECISIONES.md` para el detalle de cada una. Resumen:

- `PULZ_MAESTRO.md` y `referencia/` se movieron a `docs/` (lo pide §19).
- pnpm vía Corepack, versión fijada (`pnpm@9.15.9`).
- Node 22, no 20: `@supabase/supabase-js` exige Node ≥ 22 en su `engines`.
- Mientras no haya Docker/Colima/Podman, el desarrollo apunta al proyecto
  Supabase alojado que dio el dueño (`https://ypgeiyorgktshgbzhgfh.supabase.co`,
  credenciales en `apps/web/.env.local`, no versionado) en vez de a
  `supabase start` local. **No es el proyecto heredado de Istmeño** (regla
  dura de §0.3). Esto es temporal: la Fase 1 necesita poder resetear la base
  libremente con `supabase db reset`, algo que no se debe hacer contra un
  proyecto alojado compartido — para esa fase sí hace falta Docker o Colima.

## Pendiente de decidir (ver `docs/DUDAS.md`)

- Docker Desktop vs. Colima — pregunta abierta al dueño, bloquea el criterio
  de aceptación "`supabase start` responde" de la Fase 0.
- Confirmación para correr el instalador de Fruti Squad (script de GitHub de
  un tercero, no paquete de npm) antes de ejecutarlo.

## Próxima fase

Fase 1 · Base de datos (partir `pulz_esquema.sql` en migraciones, aplicar
§10.2, pgTAP de aislamiento) — no empieza hasta cerrar la Fase 0.
