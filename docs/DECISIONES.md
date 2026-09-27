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

## 2026-09-26 · GitHub: repo creado y sincronizado

El dueño creó `github.com/kevinedgm/pulz` y pidió subir los cambios. El repo
local ya tenía `origin` apuntando ahí (se sincronizó solo tras los commits
anteriores de esta sesión); se confirmó con `git ls-remote` que coincide con
`HEAD` y se empujó el resto de los commits sin pedir nada más — no hacía
falta crear el remoto a mano.

## 2026-09-26 · "Nunca Docker" pasa de ser una solución de Fase 0 a regla permanente del proyecto

El dueño pidió explícitamente reestructurar **todo el plan**, no solo la
Fase 0, para que Docker/Colima/Podman queden fuera para siempre: todo el
trabajo de base de datos va contra el proyecto Supabase alojado. Se escribió
como regla dura en `CLAUDE.md` (nuevo, raíz del repo) en vez de repetirla en
cada `docs/plan/FASE-N.md`, para que cualquier sesión futura la lea sin tener
que releer todo el historial de decisiones.

## 2026-09-26 · Migraciones pre-lanzamiento: "desde cero", no capas históricas

El dueño aclaró el criterio para cuando el esquema cambie durante el
desarrollo (por ejemplo, al corregir los errores que `PULZ_MAESTRO.md` §10.2
ya anticipa que va a tener `pulz_esquema.sql` al aplicarse a Postgres real):
como el producto no está lanzado y no hay datos reales que proteger, **lo que
importa es el estado final correcto del esquema, no el historial de cómo se
llegó ahí**. En vez de apilar una migración nueva de "fix" arriba de otra con
el error, se edita/reescribe la migración correspondiente para que el
conjunto siga siendo, en todo momento, "la implementación desde cero"
correcta — y se vuelve a aplicar contra el proyecto alojado (rehacer el
esquema ahí no arriesga nada porque no hay usuarios todavía).

Esto es lo opuesto de la práctica normal en producción (migraciones aditivas
e inmutables) a propósito: es una decisión explícita para la etapa
pre-lanzamiento. **Cuando el producto tenga usuarios reales, este régimen
cambia** — a partir de ahí las migraciones sí se vuelven aditivas, como pide
cualquier base de datos con datos que no se pueden perder. Regla completa en
`CLAUDE.md`.

Consecuencia práctica para la Fase 1: no tiene sentido escribir muchas
migraciones numeradas 0001, 0002, 0003... que documenten cada corrección
como si fueran commits separados de un historial de producción. Se escribe
el número mínimo de migraciones que representen el esquema correcto de una
vez, y se corrigen in situ cuando haga falta.

## 2026-09-26 · Fase 1 va con `supabase db push`/`--linked` directo, sin segundo proyecto

El dueño confirmó: "usa directo supabase db push contra el proyecto alojado,
esa es una instancia de desarrollo". Se descarta la opción de un segundo
proyecto Supabase separado para pruebas — el mismo proyecto
(`ypgeiyorgktshgbzhgfh`) sirve para desarrollo y para el ciclo de
reset/prueba de la Fase 1.

Se confirmó contra el CLI real (2.118.0), no por documentación externa, que
`supabase db reset --linked` y `supabase test db --linked` existen y hacen
justo lo que hacían sus equivalentes locales pero contra el proyecto
enlazado — o sea que **todo** el ciclo de Fase 1 (link, reset, seed, pgTAP,
consultas de verificación) se puede hacer sin Docker. Detalle completo en
`docs/plan/FASE-1.md`.

Efecto colateral importante: `supabase db reset --linked` borra y reconstruye
el proyecto alojado por completo cada vez. Mientras dure este régimen (antes
del lanzamiento), ese proyecto no debe usarse para nada que no esté en
`seed.sql` — ninguna prueba manual ni dato de demo sobrevive al siguiente
reset.

## 2026-09-26 · Flujo de interfaz obligatorio: kiwi primero, siempre

`PULZ_MAESTRO.md` §13.4 ya establecía que "ninguna pantalla se construye sin
su ronda de kiwi aprobada", pero el dueño pidió dejarlo explícito y a prueba
de que se salte por accidente: **cualquier trabajo de interfaz — diseñar,
prototipar, crear o corregir una pantalla, componente, flujo o mockup —
empieza invocando la skill `kiwi`**, que estructura (F0–F2) y entrega a
`lima` (gobernanza) → `coco` (construcción + auditoría) → `mora-docs`
(documentación). Nunca se empieza directo en `lima` o `coco` para algo nuevo.
Regla completa, con el diagrama del flujo, en `CLAUDE.md`.
