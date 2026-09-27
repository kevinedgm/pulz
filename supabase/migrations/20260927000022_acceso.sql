-- 0022 · Acceso (PULZ_MAESTRO.md §7.5–§7.6): lo que el router necesita
-- después de iniciar sesión, en una sola consulta. security_invoker: la RLS
-- de organization_members / organizations / subscriptions aplica.
--
-- Las altas de colaboradores, el canje del enlace de bienvenida y "bajar la
-- bandera must_change_password" los hace el servidor (Edge Functions con
-- llave secreta, supabase/functions/), no el navegador.

create view mis_membresias with (security_invoker = true) as
select o.id   as organization_id,
       o.slug,
       o.name,
       o.brand_color,
       o.logo_path,
       m.role,
       m.status,
       m.username,
       m.must_change_password,
       s.status = 'vencida'    as read_only,
       s.status = 'cancelada'  as cancelled
  from organization_members m
  join organizations o  on o.id = m.organization_id
  join subscriptions  s on s.organization_id = o.id
 where m.user_id = auth.uid();

grant select on mis_membresias to authenticated;
