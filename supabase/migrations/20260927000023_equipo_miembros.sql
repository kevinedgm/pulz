-- 0023 · Equipo (aprobado por el dueño en la ronda acceso/r01, hallazgo #1):
-- lo que el administrador necesita ver de su gente y que hoy no podía leer,
-- porque login_throttle y member_invitations no tienen política para
-- authenticated (y no deben tenerla: el token de bienvenida solo vive como hash).
--
-- Se entrega como función que devuelve filas (security definer con la
-- verificación del rol adentro, igual que las RPC de §8.2) y no como vista
-- security definer, que expondría las tablas sin filtro por rol.
-- El administrador la puede leer aunque la suscripción esté vencida (solo
-- lectura, §7.4): por eso se comprueba la membresía admin directamente y no
-- con has_role(), que rechaza en 'vencida'.

create function equipo_miembros(p_org uuid)
returns table (
  organization_id       uuid,
  user_id               uuid,
  full_name             text,
  username              text,
  role                  member_role,
  status                member_status,
  must_change_password  boolean,
  locked_until          timestamptz,
  invitation_expires_at timestamptz,
  invitation_used       boolean
)
language plpgsql stable security definer set search_path = public as $$
begin
  if auth.uid() is null or not exists (
    select 1 from organization_members m
     where m.organization_id = p_org and m.user_id = auth.uid()
       and m.status = 'activo' and m.role = 'admin') then
    raise exception 'NO_PERMITIDO: solo el administrador de la empresa puede ver el equipo'
      using errcode = 'P0001';
  end if;

  return query
  select m.organization_id, m.user_id, p.full_name, m.username, m.role, m.status,
         m.must_change_password,
         case when t.locked_until > now() then t.locked_until end,
         inv.expires_at,
         (inv.used_at is not null)
    from organization_members m
    join profiles p on p.id = m.user_id
    left join login_throttle t on t.user_id = m.user_id
    left join lateral (
      select i.expires_at, i.used_at
        from member_invitations i
       where i.organization_id = m.organization_id and i.user_id = m.user_id
       order by i.created_at desc limit 1) inv on true
   where m.organization_id = p_org
   order by (m.role = 'admin') desc, p.full_name;
end $$;

revoke execute on function equipo_miembros(uuid) from public, anon;
grant execute on function equipo_miembros(uuid) to authenticated;
