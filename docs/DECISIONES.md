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
