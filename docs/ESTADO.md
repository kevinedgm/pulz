# PULZ · Estado del proyecto

> Lo primero que se lee al retomar una sesión. Se mantiene vivo: fase actual,
> qué pasó, qué falta, qué se decidió y por qué.

## Fase actual

**Fase 0 · Arranque** — en planeación. Aún no se ha implementado nada de código.

## Qué pasó

- 2026-09-26: se leyó completo `PULZ_MAESTRO.md` y los archivos de
  `referencia/` (`pulz_esquema.sql`, `pulz_simulacion_semilla.sql`,
  `pulz_portal_function.ts`, `pulz-tokens.css`). Se inspeccionó el entorno
  local (ver "Entorno" abajo).
- Se escribió `docs/plan/FASE-0.md` con las tareas de arranque y se espera
  aprobación del dueño antes de tocar código.

## Qué falta

- Aprobación del plan de Fase 0.
- Todo lo demás: el repositorio no tiene una sola línea de código todavía.

## Entorno detectado (2026-09-26)

| Herramienta | Estado |
|---|---|
| Node | v20.20.2 — suficiente |
| npm | 10.8.2 |
| pnpm | no instalado; `corepack` sí está disponible (v0.34.6) para activarlo |
| git | 2.50.1 — el directorio **no es un repo git todavía** (`git init` pendiente) |
| Supabase CLI | no instalado |
| Docker / Colima / Podman | **ninguno instalado** — `supabase start` los necesita |
| Homebrew | disponible (6.0.15) |

## Decisiones y por qué

- Aún no hay decisiones de negocio tomadas fuera del documento maestro: todas
  las de §2, §7, §10.2 y §18 de `PULZ_MAESTRO.md` se toman como finales según
  su orden de autoridad (§0.2).
- El repo se inicializará con `git init` en Fase 0 (no existía como
  repositorio git al empezar).

## Pendiente de decidir (ver `docs/DUDAS.md`)

- Cómo correr Supabase local sin Docker Desktop instalado (alternativas:
  Docker Desktop vs. Colima vía Homebrew). Bloquea el criterio de aceptación
  "`supabase start` responde" de la Fase 0; se preguntará al dueño antes de
  instalar nada pesado en su máquina.

## Próxima fase

Fase 1 · Base de datos (partir `pulz_esquema.sql` en migraciones, aplicar
§10.2, pgTAP de aislamiento) — no empieza hasta cerrar Fase 0.
