-- 0002 · Plataforma: empresas, miembros, portal por slug, freno de intentos,
-- ajustes por empresa. (PULZ_MAESTRO.md §7, §10.3 "Plataforma")

-- Nombres de portal que ninguna empresa puede tomar (tabla, no CHECK: §7.3)
create table reserved_slugs (
  slug    text primary key,
  reason  text not null
);
insert into reserved_slugs (slug, reason) values
  ('admin','panel de plataforma'), ('api','infraestructura'), ('app','infraestructura'),
  ('www','infraestructura'), ('e','prefijo de portales'), ('acceso','ruta pública'),
  ('login','ruta pública'), ('registro','ruta pública'), ('bienvenida','ruta pública'),
  ('soporte','operación'), ('ayuda','operación'), ('precios','sitio'), ('blog','sitio'),
  ('static','infraestructura'), ('assets','infraestructura'), ('cdn','infraestructura'),
  ('mail','infraestructura'), ('usuarios','subdominio de correos sintéticos'),
  ('pulz','marca'), ('demo','empresa de demostración');

-- Cada empresa tiene su portal: pulz.mx/e/<slug>
create table organizations (
  id              uuid primary key default gen_random_uuid(),
  name            text not null,                   -- nombre comercial, cambia cuando quieran
  slug            text not null unique
                    check (slug ~ '^[a-z0-9]([a-z0-9-]{1,38}[a-z0-9])$' and slug !~ '-{2}'),
  state           text,
  -- Marca del portal (lo único que se ve antes de iniciar sesión)
  brand_color     text check (brand_color ~ '^#[0-9A-Fa-f]{6}$'),
  logo_path       text,                            -- bucket público 'branding/<org_id>/…'
  welcome_message text check (length(welcome_message) <= 140),
  created_at      timestamptz not null default now(),
  created_by      uuid references auth.users(id)
);

-- El slug SÍ se puede cambiar: el viejo redirige para siempre y nadie más
-- puede tomarlo (evita que otro se quede con enlaces e iconos instalados).
create table organization_slug_history (
  slug            text primary key,
  organization_id uuid not null references organizations(id) on delete cascade,
  retired_at      timestamptz not null default now(),
  retired_by      uuid references auth.users(id)
);

create function organizations_slug_guard() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'UPDATE' and new.slug is not distinct from old.slug then
    return new;
  end if;
  if exists (select 1 from reserved_slugs where slug = new.slug) then
    raise exception 'Ese nombre de portal está reservado' using errcode = 'P0001';
  end if;
  if exists (select 1 from organization_slug_history
              where slug = new.slug and organization_id <> new.id) then
    raise exception 'Ese nombre de portal ya no está disponible' using errcode = 'P0001';
  end if;
  if tg_op = 'UPDATE' then
    insert into organization_slug_history (slug, organization_id, retired_by)
    values (old.slug, old.id, auth.uid())
    on conflict (slug) do nothing;
    delete from organization_slug_history      -- regresar a un nombre propio anterior
     where slug = new.slug and organization_id = new.id;
  end if;
  return new;
end $$;
create trigger organizations_slug_guard before insert or update of slug on organizations
  for each row execute function organizations_slug_guard();

create table profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  full_name   text not null,
  phone       text,
  created_at  timestamptz not null default now()
);

create table platform_admins (
  user_id     uuid primary key references auth.users(id) on delete cascade,
  created_at  timestamptz not null default now()
);

-- Dos clases de persona (§7.2):
--   titular      entra con su correo real; recupera acceso por correo.
--   colaborador  entra con usuario simple ('ana.lopez') en el portal de su
--                empresa. En Auth su correo es sintético y nunca recibe nada:
--                ana.lopez@<organization_id>.usuarios.pulz.mx
--                (con el id y no el slug: renombrar el portal no toca cuentas).
create table organization_members (
  organization_id      uuid not null references organizations(id) on delete cascade,
  user_id              uuid not null references auth.users(id) on delete cascade,
  role                 member_role not null,
  status               member_status not null default 'invitado',
  username             text check (username ~ '^[a-z0-9]([a-z0-9._-]{1,28}[a-z0-9])$'),
  must_change_password boolean not null default false, -- la baja el servidor
  created_at           timestamptz not null default now(),
  primary key (organization_id, user_id),
  unique (organization_id, username)               -- una 'ana.lopez' por palenque
);
-- Índice para (select is_member(organization_id)) en RLS (§11.2)
create index organization_members_user_org on organization_members (user_id, organization_id);

-- Bienvenida por enlace: un solo uso, 72 h; se guarda solo el hash (§7.6)
create table member_invitations (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  user_id         uuid not null,
  token_hash      text not null unique,            -- sha256; el token nunca se guarda
  expires_at      timestamptz not null default now() + interval '72 hours',
  used_at         timestamptz,
  created_by      uuid not null references auth.users(id),
  created_at      timestamptz not null default now(),
  foreign key (organization_id, user_id)
    references organization_members(organization_id, user_id) on delete cascade
);

-- Freno a quien adivina contraseñas: por cuenta, dentro de Postgres (§7.5).
-- Lo escribe solo el hook de verificación de contraseña de Auth (0012).
create table login_throttle (
  user_id         uuid primary key references auth.users(id) on delete cascade,
  failed_count    smallint not null default 0,
  last_failed_at  timestamptz,
  locked_until    timestamptz
);

create table organization_settings (
  organization_id            uuid primary key references organizations(id) on delete cascade,
  record_puntas              boolean not null default false,  -- casi nadie las captura (<300 mL)
  measurement_mode           measurement_mode not null default 'minimo',
  warn_mixed_second_pass     boolean not null default true,   -- avisa y pide nota; nunca bloquea
  fermentation_expected_days smallint not null default 7,     -- solo referencia visual
  measurement_reminder_hour  smallint not null default 9 check (measurement_reminder_hour between 0 and 23),
  default_folio_decision     folio_decision not null default 'conservar',
  -- Rangos "habituales" para avisos blandos (§18 #5 y #6): ajuste de empresa
  abv_warn_min               numeric(5,2) not null default 35,
  abv_warn_max               numeric(5,2) not null default 55,
  brix_warn_min              numeric(6,2) not null default 12,
  brix_warn_max              numeric(6,2) not null default 14,
  updated_at                 timestamptz not null default now(),
  check (abv_warn_min < abv_warn_max),
  check (brix_warn_min < brix_warn_max)
);
create trigger organization_settings_updated_at before update on organization_settings
  for each row execute function set_updated_at();
