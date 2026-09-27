-- 0021 · Alta de empresa (§12.2 provision_organization) y grants de todas
-- las RPC de negocio. La llama signup-company (Fase 3) con service_role;
-- nunca el navegador.

create function provision_organization(
  p_nombre text, p_slug text, p_admin uuid, p_admin_nombre text,
  p_estado text default null, p_color text default null, p_mensaje text default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare v_org uuid; v_plan uuid;
begin
  if coalesce(auth.role(), current_setting('request.jwt.claim.role', true), '') <> 'service_role'
     and session_user <> 'postgres' then
    raise exception 'NO_PERMITIDO: el alta de empresas la hace el servidor' using errcode = 'P0001';
  end if;
  if p_admin is null or nullif(btrim(p_nombre), '') is null or nullif(btrim(p_slug), '') is null then
    raise exception 'NO_PERMITIDO: faltan nombre, portal o titular' using errcode = 'P0001';
  end if;

  insert into organizations (name, slug, state, brand_color, welcome_message, created_by)
  values (btrim(p_nombre), lower(btrim(p_slug)), p_estado, p_color, p_mensaje, p_admin)
  returning id into v_org;

  insert into profiles (id, full_name) values (p_admin, coalesce(nullif(btrim(p_admin_nombre), ''), 'Titular'))
  on conflict (id) do nothing;

  insert into organization_members (organization_id, user_id, role, status)
  values (v_org, p_admin, 'admin', 'activo');

  insert into organization_settings (organization_id) values (v_org);

  select id into v_plan from plans where code = 'gratis';
  if v_plan is null then
    raise exception 'NO_PERMITIDO: no existe el plan gratis en la tabla plans' using errcode = 'P0001';
  end if;
  insert into subscriptions (organization_id, plan_id, status) values (v_org, v_plan, 'gratis');

  perform seed_organization_catalogs(v_org);
  return v_org;
end $$;
revoke execute on function provision_organization(text, text, uuid, text, text, text, text) from public, anon, authenticated;
grant execute on function provision_organization(text, text, uuid, text, text, text, text) to service_role;

-- ---------------------------------------------------------------------
-- Las RPC de negocio se llaman desde el navegador con sesión (§8.2). El rol
-- se verifica dentro de cada una (rpc_guard), no aquí.
-- ---------------------------------------------------------------------
revoke execute on function
  registrar_recepcion_maguey(uuid, uuid, timestamptz, numeric, uuid, uuid, uuid, integer, text, text),
  registrar_entrada(uuid, uuid, timestamptz, material_kind, uuid, numeric, numeric, liquid_class, lot_origin, uuid, uuid, text, text, text, uuid, text, text, text, text, text),
  abrir_horneado(uuid, uuid, timestamptz, uuid, uuid[], numeric[], text, text),
  cerrar_horneado(uuid, uuid, timestamptz, uuid, numeric, text, text, text),
  registrar_formulacion(uuid, uuid, timestamptz, uuid, uuid[], numeric[], numeric, uuid[], numeric[], uuid[], numeric[], text, text, text, text[]),
  registrar_medicion(uuid, uuid, timestamptz, uuid, integer, measurement_mode, integer, reading_variable[], reading_zone[], integer[], numeric[], text),
  anular_medicion(uuid, uuid, timestamptz, uuid, text),
  declarar_tina_lista(uuid, uuid, timestamptz, uuid, text),
  cerrar_ciclo(uuid, uuid, timestamptz, uuid, text),
  abrir_corrida(uuid, uuid, timestamptz, uuid, distillation_pass, uuid[], uuid[], numeric[], text, text),
  registrar_corte(uuid, uuid, timestamptz, uuid, liquid_class, numeric, numeric, uuid, text, text),
  cerrar_corrida(uuid, uuid, timestamptz, uuid, text),
  transferir(uuid, uuid, timestamptz, uuid, uuid, uuid, numeric, numeric, folio_decision, text, text),
  registrar_movimiento_granel(uuid, uuid, timestamptz, uuid, uuid, numeric, uuid, uuid, uuid, numeric, numeric, numeric, folio_decision, text, text, text, uuid, text, text, text, uuid, text, text),
  completar_historia(uuid, uuid, timestamptz, uuid, uuid[], numeric[], text, uuid, text, text, text, uuid, text, text),
  corregir_operacion(uuid, uuid, timestamptz, uuid, text, text, text, text, timestamptz),
  desbloquear_miembro(uuid, uuid)
from public, anon;

grant execute on function
  registrar_recepcion_maguey(uuid, uuid, timestamptz, numeric, uuid, uuid, uuid, integer, text, text),
  registrar_entrada(uuid, uuid, timestamptz, material_kind, uuid, numeric, numeric, liquid_class, lot_origin, uuid, uuid, text, text, text, uuid, text, text, text, text, text),
  abrir_horneado(uuid, uuid, timestamptz, uuid, uuid[], numeric[], text, text),
  cerrar_horneado(uuid, uuid, timestamptz, uuid, numeric, text, text, text),
  registrar_formulacion(uuid, uuid, timestamptz, uuid, uuid[], numeric[], numeric, uuid[], numeric[], uuid[], numeric[], text, text, text, text[]),
  registrar_medicion(uuid, uuid, timestamptz, uuid, integer, measurement_mode, integer, reading_variable[], reading_zone[], integer[], numeric[], text),
  anular_medicion(uuid, uuid, timestamptz, uuid, text),
  declarar_tina_lista(uuid, uuid, timestamptz, uuid, text),
  cerrar_ciclo(uuid, uuid, timestamptz, uuid, text),
  abrir_corrida(uuid, uuid, timestamptz, uuid, distillation_pass, uuid[], uuid[], numeric[], text, text),
  registrar_corte(uuid, uuid, timestamptz, uuid, liquid_class, numeric, numeric, uuid, text, text),
  cerrar_corrida(uuid, uuid, timestamptz, uuid, text),
  transferir(uuid, uuid, timestamptz, uuid, uuid, uuid, numeric, numeric, folio_decision, text, text),
  registrar_movimiento_granel(uuid, uuid, timestamptz, uuid, uuid, numeric, uuid, uuid, uuid, numeric, numeric, numeric, folio_decision, text, text, text, uuid, text, text, text, uuid, text, text),
  completar_historia(uuid, uuid, timestamptz, uuid, uuid[], numeric[], text, uuid, text, text, text, uuid, text, text),
  corregir_operacion(uuid, uuid, timestamptz, uuid, text, text, text, text, timestamptz),
  desbloquear_miembro(uuid, uuid)
to authenticated;
