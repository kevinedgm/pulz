# PULZ

SaaS de producción y trazabilidad de mezcal. Ver [`docs/PULZ_MAESTRO.md`](docs/PULZ_MAESTRO.md)
para la especificación completa, [`docs/ESTADO.md`](docs/ESTADO.md) para el
estado actual y [`docs/plan/`](docs/plan/) para el plan de cada fase.

## Requisitos

- Node 22 (fijado en `.nvmrc`; con `nvm` basta `nvm use`).
- pnpm, activado vía Corepack: `corepack enable`.
- Un proyecto Supabase (alojado, gestionado desde
  [supabase.com](https://supabase.com)). El desarrollo **no** corre contra
  `supabase start` local — ver `docs/DUDAS.md` y `docs/DECISIONES.md` para el
  porqué. El Supabase CLI sigue instalado para migraciones.

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
