# PULZ · Estado del proyecto

> Lo primero que se lee al retomar una sesión. Se mantiene vivo: fase actual,
> qué pasó, qué falta, qué se decidió y por qué.

## Fase actual

**Fase 0 · Arranque** — casi cerrada. Monorepo, tooling, CI, estructura base,
Fruti Squad y los agent-skills de Supabase implementados y verificados con
comandos reales. Solo falta abrir un PR real para confirmar que `ci.yml`
corre en verde ahí (ver "Qué falta" abajo).

## Qué pasó

- 2026-09-26: se leyó completo `PULZ_MAESTRO.md` y los archivos de
  `referencia/` (`pulz_esquema.sql`, `pulz_simulacion_semilla.sql`,
  `pulz_portal_function.ts`, `pulz-tokens.css`). Se escribió el plan de la
  Fase 0.
- 2026-09-26: se implementó casi toda la Fase 0. `git init`, monorepo pnpm,
  `apps/web` (Vue 3 + Vite + TS + Pinia + Router + cliente Supabase),
  `packages/shared`, ESLint/Prettier, Vitest con prueba de humo, Supabase CLI
  inicializado, CI mínimo, Fruti Squad instalado con el perfil PULZ completo
  (§13.4) y los agent-skills de Supabase. Ocho commits, uno por tarea
  coherente (§0.1.5). Verificado con comandos reales:
  - `pnpm install`, `pnpm lint`, `pnpm format`, `pnpm build`, `pnpm test` —
    **verde**.
  - `supabase start` — se instaló Colima, se le subieron los recursos (4
    CPU / 6 GiB; con 2/2 por defecto fallaba por memoria) y **sí llegó a
    levantar el stack completo** (Postgres, Auth, Storage, Studio, etc. en
    `127.0.0.1`). Luego, por instrucción explícita del dueño, se detuvo todo
    y se desinstaló Colima — el proyecto ya no usa Supabase local, ver
    "Decisiones" abajo.
  - CI en un PR real — **no verificado todavía** (no se ha abierto PR; este
    repo no tiene remoto configurado).
  - Design Hub inicial y perfil de lima — verificado: registro sembrado en
    `design-hub/system/registry.json` (JSON válido) y
    `.claude/skills/lima/profiles/pulz.md` completo con los valores de §13.4
    (color_law, type_law, truth_sources, stack de producción, accesibilidad).

## Qué falta para cerrar la Fase 0

1. Abrir un PR real (necesita un remoto de git, que este repo no tiene
   todavía) y confirmar que `ci.yml` corre en verde ahí.
2. Nada más queda pendiente de lo que pedía el plan original.

## Entorno (actualizado 2026-09-26, después de implementar)

| Herramienta | Estado |
|---|---|
| Node | 22.23.3 instalado vía `nvm`, fijado en `.nvmrc` y en `engines` del `package.json` raíz (el Node 20 de Homebrew se quedó instalado pero no se usa para este repo) |
| pnpm | 9.15.9, activado vía Corepack |
| git | 2.50.1 — repo inicializado, rama `main`, 8 commits, sin remoto |
| Supabase CLI | 2.118.0, instalado vía Homebrew; `supabase init` ya corrido; se usa contra el proyecto alojado, no local |
| Docker / Colima / Podman | **desinstalados a propósito** — el dueño decidió no usar Supabase local (ver Decisiones) |
| Fruti Squad | instalado en `.claude/skills/{kiwi,lima,coco,mora-docs}`; perfil en `.claude/skills/lima/profiles/pulz.md`; Design Hub vacío en `design-hub/` |
| Agent-skills de Supabase | instalados en `.agents/skills/{supabase,supabase-postgres-best-practices}`, symlink en `.claude/skills/` |
| Homebrew | disponible (6.0.15) |

## Decisiones y por qué

Ver `docs/DECISIONES.md` para el detalle de cada una. Resumen:

- `PULZ_MAESTRO.md` y `referencia/` se movieron a `docs/` (lo pide §19).
- pnpm vía Corepack, versión fijada (`pnpm@9.15.9`).
- Node 22, no 20: `@supabase/supabase-js` exige Node ≥ 22 en su `engines`.
- **Supabase local descartado por decisión del dueño**, no por falta de
  Docker: Colima sí funcionó (con más recursos), pero se pidió explícitamente
  desinstalarlo y trabajar contra el proyecto alojado
  (`https://ypgeiyorgktshgbzhgfh.supabase.co`, credenciales en
  `apps/web/.env.local`, no versionado) gestionado desde su panel web.
  **No es el proyecto heredado de Istmeño** (regla dura de §0.3): es un
  proyecto nuevo, vacío, creado para PULZ. Esto deja abierto cómo se va a
  hacer el ciclo de `db reset` + pgTAP de la Fase 1 sin Postgres local — ver
  `docs/DUDAS.md`.
- Se instalaron los agent-skills de Supabase (`npx skills add
  supabase/agent-skills`) a pedido explícito del dueño.

## Pendiente de decidir (ver `docs/DUDAS.md`)

- Cómo va a probar la Fase 1 (`db reset` + pgTAP) sin un Postgres local
  reseteable, ahora que se descartó Colima/Docker.

## Próxima fase

Fase 1 · Base de datos (partir `pulz_esquema.sql` en migraciones, aplicar
§10.2, pgTAP de aislamiento) — no empieza hasta cerrar la Fase 0 (solo falta
el punto 1 de "Qué falta" arriba).
