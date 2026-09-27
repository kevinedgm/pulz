-- 0012 · Portal por empresa y acceso: lo único que ve alguien sin sesión,
-- correo sintético de colaboradores, freno de intentos, desbloqueo.
-- También las funciones que usa la RLS (0013). (PULZ_MAESTRO.md §7, §11)

-- ---------------------------------------------------------------------
-- Funciones de membresía (las usa toda la RLS)
-- ---------------------------------------------------------------------
create function is_member(org uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from organization_members
                  where organization_id = org and user_id = auth.uid() and status = 'activo');
$$;

-- has_role también rechaza escrituras cuando la suscripción está vencida
-- (§11.2: "vencida → has_role() rechaza escrituras; la lectura sigue").
create function has_role(org uuid, roles member_role[]) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from organization_members m
                  where m.organization_id = org and m.user_id = auth.uid()
                    and m.status = 'activo' and m.role = any(roles))
     and not exists (select 1 from subscriptions s
                      where s.organization_id = org and s.status in ('vencida', 'cancelada'));
$$;

create function is_platform_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from platform_admins where user_id = auth.uid());
$$;

-- ---------------------------------------------------------------------
-- Estado del portal según la suscripción (§7.4):
--   gratis, prueba, activa  -> abierto
--   vencida                 -> abierto en solo lectura (no se secuestran datos)
--   cancelada o inexistente -> 404 idéntico (no revela qué empresas existen)
-- ---------------------------------------------------------------------
create function portal_branding(p_slug text)
returns table (organization_id uuid, slug text, name text, logo_path text,
               brand_color text, welcome_message text, read_only boolean,
               redirect_to text)
language sql stable security definer set search_path = public as $$
  with target as (
    select o.* from organizations o where o.slug = lower(p_slug)
    union all
    select o.* from organization_slug_history h
      join organizations o on o.id = h.organization_id
     where h.slug = lower(p_slug)
  )
  select t.id, t.slug, t.name, t.logo_path, t.brand_color, t.welcome_message,
         s.status = 'vencida',
         case when t.slug <> lower(p_slug) then t.slug end
    from target t
    join subscriptions s on s.organization_id = t.id
   where s.status <> 'cancelada'
   limit 1;
$$;
revoke execute on function portal_branding(text) from public;
grant execute on function portal_branding(text) to anon, authenticated;

-- Correo sintético de un colaborador (§7.2). No es secreto: el portal ya
-- publica su organization_id y el usuario lo teclea la persona. Por eso el
-- navegador inicia sesión DIRECTO contra Supabase Auth, sin función intermedia.
-- La función manage-member (Fase 3) lo usa al crear la cuenta.
create function member_login_email(p_org uuid, p_username text) returns text
language sql immutable as $$
  select lower(p_username) || '@' || p_org::text || '.usuarios.pulz.mx';
$$;

-- ---------------------------------------------------------------------
-- Hook de Auth «Password verification attempt» (§7.5): 5 fallos en una hora
-- bloquean 15 minutos (30 si reincide). Un acierto limpia el contador.
-- La interfaz del hook es jsonb por contrato de Supabase; no se guarda nada
-- en jsonb (§0.3). Habilitarlo en config.toml y confirmar que el plan lo
-- incluye (§18 #9).
-- ---------------------------------------------------------------------
create function auth_password_attempt(event jsonb) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  uid   uuid := (event->>'user_id')::uuid;
  ok    boolean := (event->>'valid')::boolean;
  t     login_throttle%rowtype;
begin
  select * into t from login_throttle where user_id = uid for update;
  if found and t.locked_until > now() then
    return jsonb_build_object('decision', 'reject', 'should_logout_user', false,
      'message', 'Demasiados intentos. Espera unos minutos o pide a tu encargado que te desbloquee.');
  end if;
  if ok then
    delete from login_throttle where user_id = uid;
    return jsonb_build_object('decision', 'continue');
  end if;
  insert into login_throttle (user_id, failed_count, last_failed_at)
  values (uid, 1, now())
  on conflict (user_id) do update
    set failed_count   = case when login_throttle.last_failed_at < now() - interval '1 hour'
                              then 1 else login_throttle.failed_count + 1 end,
        last_failed_at = now(),
        locked_until   = case when (case when login_throttle.last_failed_at < now() - interval '1 hour'
                                         then 1 else login_throttle.failed_count + 1 end) >= 5
                              then now() + case when login_throttle.locked_until is not null
                                                then interval '30 minutes' else interval '15 minutes' end
                              end;
  return jsonb_build_object('decision', 'continue');
end $$;
grant execute on function auth_password_attempt(jsonb) to supabase_auth_admin;
revoke execute on function auth_password_attempt(jsonb) from authenticated, anon, public;
grant select, insert, update, delete on login_throttle to supabase_auth_admin;

-- El encargado desbloquea a alguien de su empresa sin esperar (§7.5)
create function desbloquear_miembro(p_org uuid, p_user uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not has_role(p_org, array['admin']::member_role[]) then
    raise exception 'NO_PERMITIDO: Solo el administrador puede desbloquear' using errcode = 'P0001';
  end if;
  delete from login_throttle t
   using organization_members m
   where t.user_id = p_user and m.user_id = p_user and m.organization_id = p_org;
end $$;
revoke execute on function desbloquear_miembro(uuid, uuid) from public, anon;
