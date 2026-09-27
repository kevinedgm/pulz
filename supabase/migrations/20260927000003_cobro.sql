-- 0003 · Cobro y planes (PULZ_MAESTRO.md §14, §10.3 "Cobro").
-- Los límites son filas (plan_limits), nunca listas en columnas (§10.1).
-- Los valores concretos (precio, límites) viven en la semilla, no en código (§18 #2, #3).

create table plans (
  id               uuid primary key default gen_random_uuid(),
  code             text not null unique,
  name             text not null,
  price_mxn_month  numeric(10,2) not null default 0,
  stripe_price_id  text unique,
  is_public        boolean not null default true
);

create table plan_limits (
  plan_id     uuid not null references plans(id) on delete cascade,
  limit_key   text not null,
  limit_value integer,                             -- null = ilimitado
  primary key (plan_id, limit_key)
);

create table plan_features (
  plan_id     uuid not null references plans(id) on delete cascade,
  feature_key text not null,
  primary key (plan_id, feature_key)
);

create table subscriptions (
  organization_id        uuid primary key references organizations(id) on delete cascade,
  plan_id                uuid not null references plans(id),
  status                 subscription_status not null default 'gratis',
  stripe_customer_id     text unique,
  stripe_subscription_id text unique,
  current_period_end     timestamptz,
  updated_at             timestamptz not null default now()
);
create trigger subscriptions_updated_at before update on subscriptions
  for each row execute function set_updated_at();

-- Idempotencia del webhook: un evento de Stripe se procesa una sola vez (§14)
create table stripe_events (
  id           text primary key,
  type         text not null,
  received_at  timestamptz not null default now()
);
