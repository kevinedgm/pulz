-- 0025 · recurso_en_uso: lo que Configuración necesita saber antes de
-- desactivar un recurso (ronda configuracion/r01, hallazgo alto #1): cuántos
-- litros hay en él ahora y cuántos ciclos de fermentación siguen abiertos.
-- Solo lectura; la RLS de resources no cambia. Un miembro activo de la
-- empresa (cualquier rol) puede consultarla: es información operativa, no
-- de cobro ni de acceso.

create function recurso_en_uso(p_org uuid)
returns table (resource_id uuid, saldo_l numeric, ciclos_abiertos integer)
language sql stable security definer set search_path = public as $$
  select r.id,
         coalesce((select sum(case when m.dest_resource_id = r.id then m.volume_l else -m.volume_l end)
                     from liquid_movements m
                    where m.organization_id = p_org
                      and (m.dest_resource_id = r.id or m.source_resource_id = r.id)), 0)::numeric,
         (select count(*) from fermentation_cycles c
           where c.organization_id = p_org and c.tina_id = r.id and c.status <> 'cerrado')::integer
    from resources r
   where r.organization_id = p_org
     and is_member(p_org);
$$;

revoke execute on function recurso_en_uso(uuid) from public, anon;
grant execute on function recurso_en_uso(uuid) to authenticated;
