# PULZ · Decisiones

> Qué se decidió, cuándo y por qué. Una entrada por decisión, no se borran.

## 2026-09-26 · Reubicación del paquete de documentación

`PULZ_MAESTRO.md` y `referencia/` llegaron en la raíz del repo. Se movieron a
`docs/PULZ_MAESTRO.md` y `docs/referencia/` porque así lo pide §19 del propio
documento maestro (el paquete se descomprime dentro de `docs/`).

## 2026-09-26 · pnpm vía Corepack, versión fijada

Se activó pnpm con `corepack enable` + `corepack prepare pnpm@9.15.9
--activate`, y se fijó `packageManager: "pnpm@9.15.9"` en el `package.json`
raíz. Corepack ya viene con Node y evita depender de una instalación global
aparte.

## 2026-09-26 · Node 22, no 20

El Node del sistema (v20.20.2, instalado vía Homebrew) es incompatible con
`@supabase/supabase-js@2.117.2`, que exige Node ≥ 22 en su `engines`. Se
instaló Node 22.23.3 (LTS "Jod") vía `nvm` y se fijó en `.nvmrc` y en
`engines.node` del `package.json` raíz. El Node 20 de Homebrew se queda
instalado (no se tocó) porque el `PATH` del sistema lo antepone a `nvm`; para
trabajar en este repo hay que activar 22 explícitamente
(`nvm use` o cargar `.nvmrc`).

## 2026-09-26 · Supabase alojado en vez de local, mientras no haya Docker

Ver `docs/DUDAS.md` #1. El dueño dio las credenciales de un proyecto Supabase
nuevo (`https://ypgeiyorgktshgbzhgfh.supabase.co`) para no bloquear el avance
por la falta de Docker/Colima/Podman en la máquina. Se guardaron en
`apps/web/.env.local` (no versionado; `apps/web/.env.example` documenta las
claves esperadas). **No es el proyecto heredado de Istmeño** (regla dura de
§0.3): es un proyecto nuevo, vacío, creado para PULZ. Cuando haya Docker
disponible se retoma `supabase start` para el ciclo de Fase 1 (migraciones +
`db reset` + pgTAP), que necesita poder resetear la base libremente — algo
que no se debe hacer contra un proyecto alojado compartido.

**Superada por la decisión siguiente**: se probó Colima y sí llegó a levantar
el stack completo, pero el dueño pidió explícitamente no usar Docker/Colima
en esta máquina y trabajar contra el proyecto alojado desde su propio panel.

## 2026-09-26 · Se descarta Docker/Colima; todo el trabajo va contra Supabase alojado

Instrucción explícita del dueño ("desinstala colima directamente..., en
supabase en la página se va a trabajar"). Se hizo `supabase stop`,
`colima stop`, `colima delete -f` y `brew uninstall colima` (se limpió
también `lima`, que quedó sin usuarios). El CLI de Supabase se queda
instalado (sirve para generar/editar migraciones y, más adelante, enlazar
con `supabase link` al proyecto alojado), pero **no se vuelve a intentar
`supabase start` local** salvo que el dueño lo pida de nuevo.

Consecuencia para fases futuras: la Fase 1 (`supabase db reset` + pgTAP) va
a necesitar un mecanismo contra el proyecto alojado en vez de un reset local
— por ejemplo, migraciones aplicadas con `supabase db push` y una base de
pruebas separada del proyecto de desarrollo. Se decide el detalle cuando se
llegue a esa fase; queda anotado en `docs/DUDAS.md`.

## 2026-09-26 · Agent-skills de Supabase instalados

`npx skills add supabase/agent-skills`, pedido explícitamente por el dueño.
Instala dos skills (`Supabase`, `Postgres Best Practices`) en
`.agents/skills/`, con symlink hacia `.claude/skills/` para Claude Code. El
propio instalador mostró su evaluación de riesgo ("Safe risk", 0 alertas de
Socket) antes de instalar.
