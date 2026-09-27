-- 0013 · Seguridad: RLS en toda tabla, una política por operación (nunca
-- `for all`), grants explícitos por tabla (nunca alter default privileges).
-- Escritura de producción: solo por RPC security definer (Fase 2). Las
-- tablas del núcleo no tienen política de insert/update para authenticated.
-- (PULZ_MAESTRO.md §11.2, §10.1)

-- ---------------------------------------------------------------------
-- Grants explícitos. anon no lee nada por PostgREST: el portal pasa por la
-- función portal_branding (0012). authenticated lee lo que la RLS permita.
-- ---------------------------------------------------------------------
revoke all on all tables in schema public from anon, authenticated;
revoke all on all sequences in schema public from anon, authenticated;

-- Lectura para miembros: todo lo de negocio y de plataforma que la RLS filtra
grant select on
  organizations, organization_slug_history, organization_members, organization_settings,
  profiles, plans, plan_limits, plan_features, subscriptions,
  catalog_items, movement_concepts, species, predios, suppliers, supplies, resources,
  operations, operation_warnings, lots, lot_lineage, lot_external_sources,
  maguey_receptions, liquid_movements, attachments,
  roasting_runs, roasting_run_inputs, formulations, formulation_inputs, formulation_supplies,
  fermentation_cycles, fermentation_measurements, measurement_readings,
  distillation_runs, distillation_run_inputs, distillation_cuts,
  resource_lot_balances, lot_declared_abv, movement_log, solid_lot_balances
to authenticated;

-- Escritura directa por PostgREST solo en lo que no es ledger (§8.2):
-- catálogos propios, infraestructura, predios/proveedores/insumos, ajustes,
-- marca/slug de la empresa, perfil propio, rol/estado de miembros.
grant insert, update on catalog_items, movement_concepts, species to authenticated;
grant insert, update on resources, predios, suppliers, supplies to authenticated;
grant update on organizations, organization_members, organization_settings, profiles to authenticated;

-- Plantillas: las lee cualquiera con sesión; solo el admin de plataforma escribe
grant select on catalog_item_templates, movement_concept_templates, species_templates to authenticated;
grant insert, update on catalog_item_templates, movement_concept_templates, species_templates to authenticated;

-- Auditoría: se lee por empresa; la escribe un trigger (Fase 8)
grant select on audit_events, audit_changes to authenticated;

-- ---------------------------------------------------------------------
-- RLS: activar en TODAS las tablas de public
-- ---------------------------------------------------------------------
do $$
declare t text;
begin
  for t in select tablename from pg_tables where schemaname = 'public' loop
    execute format('alter table %I enable row level security', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- Lectura por membresía: tablas de negocio (una política select cada una).
-- (select is_member(...)) para que el planificador la evalúe una vez (§11.2).
-- ---------------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array[
    'catalog_items','movement_concepts','species',
    'predios','suppliers','supplies','resources','operations','operation_warnings',
    'lots','lot_lineage','lot_external_sources','maguey_receptions','liquid_movements',
    'attachments','roasting_runs','roasting_run_inputs','formulations','formulation_inputs',
    'formulation_supplies','fermentation_cycles','fermentation_measurements',
    'measurement_readings','distillation_runs','distillation_run_inputs','distillation_cuts',
    'audit_events']
  loop
    execute format('create policy %I on %I for select to authenticated using ((select is_member(organization_id)))',
                   t || '_select', t);
  end loop;
end $$;

-- audit_changes no tiene organization_id: hereda por su evento
create policy audit_changes_select on audit_changes for select to authenticated
  using (exists (select 1 from audit_events e
                  where e.id = audit_changes.event_id and (select is_member(e.organization_id))));

-- ---------------------------------------------------------------------
-- Plantillas de plataforma
-- ---------------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array['catalog_item_templates','movement_concept_templates','species_templates'] loop
    execute format('create policy %I on %I for select to authenticated using (true)', t || '_select', t);
    execute format('create policy %I on %I for insert to authenticated with check ((select is_platform_admin()))', t || '_insert', t);
    execute format('create policy %I on %I for update to authenticated using ((select is_platform_admin())) with check ((select is_platform_admin()))', t || '_update', t);
    -- sin delete: se desactiva, no se borra
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- Catálogos propios de la empresa: el admin agrega y edita (ocultar = active=false)
-- ---------------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array['catalog_items','movement_concepts','species'] loop
    execute format('create policy %I on %I for insert to authenticated with check ((select has_role(organization_id, array[''admin'']::member_role[])))', t || '_insert', t);
    execute format('create policy %I on %I for update to authenticated using ((select has_role(organization_id, array[''admin'']::member_role[]))) with check ((select has_role(organization_id, array[''admin'']::member_role[])))', t || '_update', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- Infraestructura (admin) y predios/proveedores/insumos (admin, productor)
-- La FK compuesta + trigger garantizan que el tipo sea de la misma empresa.
-- ---------------------------------------------------------------------
create policy resources_insert on resources for insert to authenticated
  with check ((select has_role(organization_id, array['admin']::member_role[])));
create policy resources_update on resources for update to authenticated
  using ((select has_role(organization_id, array['admin']::member_role[])))
  with check ((select has_role(organization_id, array['admin']::member_role[])));

do $$
declare t text;
begin
  foreach t in array array['predios','suppliers','supplies'] loop
    execute format('create policy %I on %I for insert to authenticated with check ((select has_role(organization_id, array[''admin'',''productor'']::member_role[])))', t || '_insert', t);
    execute format('create policy %I on %I for update to authenticated using ((select has_role(organization_id, array[''admin'',''productor'']::member_role[]))) with check ((select has_role(organization_id, array[''admin'',''productor'']::member_role[])))', t || '_update', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- Plataforma
-- ---------------------------------------------------------------------
create policy org_select on organizations for select to authenticated
  using ((select is_member(id)) or (select is_platform_admin()));
-- El admin edita nombre, marca y slug del portal (el trigger guarda el historial)
create policy org_update on organizations for update to authenticated
  using ((select has_role(id, array['admin']::member_role[])))
  with check ((select has_role(id, array['admin']::member_role[])));

create policy slug_history_select on organization_slug_history for select to authenticated
  using ((select is_member(organization_id)));

create policy members_select on organization_members for select to authenticated
  using ((select is_member(organization_id)));
-- Altas de miembros: solo por la función manage-member (Fase 3, service_role).
-- Aquí el admin solo cambia rol o estado.
create policy members_update on organization_members for update to authenticated
  using ((select has_role(organization_id, array['admin']::member_role[])))
  with check ((select has_role(organization_id, array['admin']::member_role[])));

create policy settings_select on organization_settings for select to authenticated
  using ((select is_member(organization_id)));
create policy settings_update on organization_settings for update to authenticated
  using ((select has_role(organization_id, array['admin']::member_role[])))
  with check ((select has_role(organization_id, array['admin']::member_role[])));

create policy subs_select on subscriptions for select to authenticated
  using ((select is_member(organization_id)));

-- Nombres de compañeros de empresa visibles (para "quién lo hizo")
create policy profile_select on profiles for select to authenticated
  using (id = auth.uid() or exists (
    select 1 from organization_members a join organization_members b
      on a.organization_id = b.organization_id
     where a.user_id = auth.uid() and a.status = 'activo' and b.user_id = profiles.id));
create policy profile_update on profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

create policy plans_select    on plans         for select to authenticated using (is_public or (select is_platform_admin()));
create policy limits_select   on plan_limits   for select to authenticated using (true);
create policy features_select on plan_features for select to authenticated using (true);

-- member_invitations, stripe_events, platform_admins, reserved_slugs:
-- RLS activada y SIN políticas para authenticated. Solo service_role (bypass)
-- o funciones security definer los tocan.

-- login_throttle: solo el hook de Auth (0012 ya dio los grants a supabase_auth_admin)
create policy throttle_auth_select on login_throttle for select to supabase_auth_admin using (true);
create policy throttle_auth_insert on login_throttle for insert to supabase_auth_admin with check (true);
create policy throttle_auth_update on login_throttle for update to supabase_auth_admin using (true);
create policy throttle_auth_delete on login_throttle for delete to supabase_auth_admin using (true);
