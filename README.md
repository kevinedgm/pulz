# PULZ

SaaS de producción y trazabilidad de mezcal. Ver [`docs/PULZ_MAESTRO.md`](docs/PULZ_MAESTRO.md)
para la especificación completa, [`docs/ESTADO.md`](docs/ESTADO.md) para el
estado actual y [`docs/plan/`](docs/plan/) para el plan de cada fase.

## Requisitos

- Node 22 (fijado en `.nvmrc`; con `nvm` basta `nvm use`).
- pnpm, activado vía Corepack: `corepack enable`.
- Supabase CLI (`brew install supabase/tap/supabase`) y Docker o Colima para
  correr `supabase start` en local (ver `docs/DUDAS.md` si no los tienes
  todavía).

## Arrancar

```bash
corepack enable
pnpm install
cp apps/web/.env.example apps/web/.env.local   # completa con tu proyecto Supabase
pnpm --filter @pulz/web dev
```

## Comandos comunes

```bash
pnpm build   # build de todos los workspaces
pnpm test    # pruebas de todos los workspaces
pnpm lint    # ESLint
pnpm format  # revisa formato con Prettier
```

## Estructura

Monorepo con pnpm workspaces: `apps/web` (PWA Vue 3 + TypeScript),
`packages/shared` (tipos y constantes compartidas), `supabase/` (migraciones,
funciones y pruebas de la base). Detalle completo en
`docs/PULZ_MAESTRO.md` §9.
