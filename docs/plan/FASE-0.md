# Fase 0 · Arranque

> Sigue `PULZ_MAESTRO.md` §0.1, §9 y §16. Objetivo: dejar el monorepo, el
> tooling y el design system instalados y verificables — **sin lógica de
> negocio todavía**. Esta fase no toca el esquema ni las RPC (eso es Fase 1
> y 2).

## Objetivo

Que `pnpm install && pnpm build && pnpm test` corra en verde, que
`supabase start` responda, que exista CI mínimo corriendo en un PR, y que el
perfil de identidad de PULZ (§13.4) esté cargado en Fruti Squad con el
Design Hub inicial creado.

## Bloqueo detectado antes de empezar

El entorno **no tiene Docker, Colima ni Podman** instalados, y `supabase
start` los necesita para levantar Postgres local. Antes de instalar nada
pesado (Docker Desktop u otra alternativa) se pregunta al dueño cuál prefiere
— ver pregunta al final de este documento. El resto de la Fase 0 no depende
de esto y puede completarse mientras se decide.

## Tareas, en orden

1. **Reubicar el paquete de documentación** según §19: mover
   `PULZ_MAESTRO.md` → `docs/PULZ_MAESTRO.md` y `referencia/` →
   `docs/referencia/` (son los archivos que ya están en la raíz de
   `/Users/datateamconsulting/Downloads/PULZ`).
2. **Inicializar git**: `git init`, rama por defecto, `.gitignore` (node_modules,
   dist, .env*, supabase/.branches, supabase/.temp).
3. **Crear `docs/DUDAS.md` y `docs/DECISIONES.md`** (junto con `docs/ESTADO.md`,
   ya creado). `DUDAS.md` arranca con la pregunta del bloqueo de Docker y las
   9 preguntas abiertas de §18 (referenciadas, no copiadas). `DECISIONES.md`
   arranca con la decisión de mover el paquete a `docs/` y activar pnpm con
   corepack.
4. **Monorepo pnpm**: `corepack enable`, `corepack prepare pnpm@latest
   --activate`, `pnpm-workspace.yaml` (`apps/*`, `packages/*`), `package.json`
   raíz con `packageManager` fijado, scripts (`build`, `test`, `lint`,
   `format`) que delegan a los workspaces.
5. **`apps/web`**: scaffold Vite + Vue 3 + TypeScript (`vue-ts`), agregar
   `vite-plugin-pwa`, Pinia, Vue Router. Estructura de carpetas de §9
   (`app/`, `modules/` vacíos con `.gitkeep` o un módulo `inicio` mínimo,
   `shared/ui`, `shared/offline`, `shared/supabase`, `shared/utils`).
   `index.html` con las etiquetas genéricas que pide §7.7 / el comentario
   final de `pulz_portal_function.ts` (title, meta tags, link manifest,
   apple-touch-icon) para que el portal las pueda reescribir después.
6. **`packages/shared`**: paquete mínimo (tipos y constantes compartidas),
   vacío salvo un `index.ts` de arranque — se llena en fases posteriores.
7. **ESLint + Prettier** en la raíz, configuración compartida para
   `apps/web` y `packages/shared`.
8. **Vitest** configurado en `apps/web` (y `packages/shared` si aplica), con
   una prueba trivial de humo para confirmar que el runner funciona.
9. **Supabase CLI**: instalar (`brew install supabase/tap/supabase`),
   `supabase init` dentro de `supabase/`, con `config.toml`,
   `migrations/` (vacío, listo para Fase 1), `functions/` (vacío),
   `seed.sql` (vacío, se llena en Fase 1), `tests/` (vacío, pgTAP en Fase 1).
10. **wrangler**: agregarlo como dependencia de desarrollo (`apps/web` o raíz)
    para tenerlo disponible; la Pages Function del portal es de la Fase 3, no
    se implementa aquí.
11. **CI mínimo** (`.github/workflows/ci.yml`): en cada PR, `pnpm install`,
    `pnpm lint`, `pnpm build`, `pnpm test`. Los pasos de Supabase/pgTAP se
    agregan en Fase 1, cuando haya esquema que probar.
12. **Fruti Squad**: instalar con
    `npx github:kevinedgm/fruti-squad setup --target claude`, correr el
    intake de `setup` con los valores exactos de §13.4 (nombre, `color_law`,
    `type_law`, `tokens_source`, framework/styling/iconos, `a11y_target`,
    `breakpoints`). Sembrar `apps/web/src/shared/ui/tokens.css` con
    `docs/referencia/pulz-tokens.css` y copiar `docs/referencia/pulz-iconos.svg`
    como sprite del proyecto. Confirmar que queda un Design Hub inicial.
    **Nota de seguridad**: este paso descarga y ejecuta un script de un
    repositorio de GitHub de un tercero (no es un paquete de npm firmado).
    Está pedido explícitamente en `PULZ_MAESTRO.md` §13.4/§16, pero lo
    marco aquí para que quede visible antes de ejecutarlo — avisa si prefieres
    revisarlo tú mismo primero.
13. **`README.md`** raíz breve: cómo levantar el entorno local (pnpm, supabase
    start, variables de entorno esperadas).

## Archivos que se tocan

- Raíz: `package.json`, `pnpm-workspace.yaml`, `.gitignore`, `.npmrc`,
  `README.md`, ESLint/Prettier config, `.github/workflows/ci.yml`.
- `docs/`: mueve `PULZ_MAESTRO.md` y `referencia/` aquí; agrega `DUDAS.md`,
  `DECISIONES.md` (y ya está `ESTADO.md`, `plan/FASE-0.md`).
- `apps/web/`: proyecto Vite completo según §9.
- `packages/shared/`: paquete mínimo.
- `supabase/`: `config.toml`, carpetas vacías `migrations/`, `functions/`,
  `tests/`, archivo `seed.sql` vacío.
- `.claude/` y `design-hub/`: los crea el instalador de Fruti Squad.

## Pruebas que se escriben

- Una prueba de humo en Vitest (`apps/web`) que monta el shell vacío y no
  truena — solo para confirmar que el runner y la config están bien, no
  prueba negocio (no hay negocio todavía).
- Nada de pgTAP en esta fase (no hay esquema).

## Cómo se comprueban los criterios de aceptación de §16

| Criterio | Comando / verificación |
|---|---|
| `pnpm install && pnpm build && pnpm test` en verde | correrlos en la raíz del monorepo, código de salida 0 |
| `supabase start` responde | `supabase start` desde la raíz; si Docker no está disponible, se documenta el bloqueo en `docs/DUDAS.md` y se avisa en vez de fingir que pasó |
| CI corre en un PR | abrir un PR de prueba (o revisar un run de Actions) y confirmar que `ci.yml` se dispara y termina en verde |
| Existe el perfil PULZ de lima con los valores de §13.4 y el Design Hub inicial | revisar el archivo de perfil que genera Fruti Squad (dentro de `.claude/` o `design-hub/`, según lo que instale) y comparar campo por campo contra la tabla de §13.4 |

Si algún criterio no se puede comprobar con un comando real (p. ej. `supabase
start` sin Docker), se dice explícitamente en `docs/ESTADO.md` — no se declara
la fase cerrada por optimismo (regla §0.1.3).

## Pregunta abierta antes de implementar

No hay Docker, Colima ni Podman en esta máquina. `supabase start` los
necesita para levantar Postgres, Auth, Storage, etc. localmente. Opciones:

1. Instalar **Docker Desktop** (más pesado, interfaz gráfica, requiere
   aceptar su licencia).
2. Instalar **Colima** vía Homebrew (`brew install colima docker`) — más
   ligero, solo línea de comandos, sin licencia de Docker Desktop.

¿Cuál prefieres, o ya tienes uno de los dos en camino? Mientras se decide,
el resto de la Fase 0 (tareas 1–8, 10–13) no depende de esto.
