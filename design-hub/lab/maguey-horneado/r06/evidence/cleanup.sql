begin;
set local statement_timeout='20s';
set local lock_timeout='5s';
do $$ begin
if exists(select 1 from organizations where id='398d6578-f039-4d13-9a32-ae13d555bbaf' and slug<>'qa-mh-r06-07b86b6b-a') then raise exception 'Fixture org identity mismatch'; end if;
if exists(select 1 from organizations where id='63e2bb9e-a3b9-4e3e-943b-c633cf326106' and slug<>'qa-mh-r06-07b86b6b-b') then raise exception 'Fixture org identity mismatch'; end if;
if exists(select 1 from auth.users where id='e59ea9a8-4d41-4a99-8e73-a64b357ad723' and email<>'qa-mh-r06-07b86b6b-admin@example.invalid') then raise exception 'Fixture user identity mismatch'; end if;
if exists(select 1 from auth.users where id='08ff0bc4-be32-455c-8514-ca7ac7327593' and email<>'qa-mh-r06-07b86b6b-productor@example.invalid') then raise exception 'Fixture user identity mismatch'; end if;
if exists(select 1 from auth.users where id='68c28a14-a765-4df0-9171-48ae891009d6' and email<>'qa-mh-r06-07b86b6b-operador@example.invalid') then raise exception 'Fixture user identity mismatch'; end if;
if exists(select 1 from auth.users where id='b8254966-588f-4e25-9dbf-21c78c6bbc8a' and email<>'qa-mh-r06-07b86b6b-admin-b@example.invalid') then raise exception 'Fixture user identity mismatch'; end if;
end $$;
delete from auth.refresh_tokens where user_id in ('e59ea9a8-4d41-4a99-8e73-a64b357ad723','08ff0bc4-be32-455c-8514-ca7ac7327593','68c28a14-a765-4df0-9171-48ae891009d6','b8254966-588f-4e25-9dbf-21c78c6bbc8a');
delete from auth.sessions where user_id in ('e59ea9a8-4d41-4a99-8e73-a64b357ad723','08ff0bc4-be32-455c-8514-ca7ac7327593','68c28a14-a765-4df0-9171-48ae891009d6','b8254966-588f-4e25-9dbf-21c78c6bbc8a');
delete from public.fermentation_cycles where organization_id in ('398d6578-f039-4d13-9a32-ae13d555bbaf','63e2bb9e-a3b9-4e3e-943b-c633cf326106');
delete from public.formulation_supplies where organization_id in ('398d6578-f039-4d13-9a32-ae13d555bbaf','63e2bb9e-a3b9-4e3e-943b-c633cf326106');
delete from public.formulation_inputs where organization_id in ('398d6578-f039-4d13-9a32-ae13d555bbaf','63e2bb9e-a3b9-4e3e-943b-c633cf326106');
delete from public.formulations where organization_id in ('398d6578-f039-4d13-9a32-ae13d555bbaf','63e2bb9e-a3b9-4e3e-943b-c633cf326106');
delete from public.roasting_run_inputs where organization_id in ('398d6578-f039-4d13-9a32-ae13d555bbaf','63e2bb9e-a3b9-4e3e-943b-c633cf326106');
delete from public.roasting_runs where organization_id in ('398d6578-f039-4d13-9a32-ae13d555bbaf','63e2bb9e-a3b9-4e3e-943b-c633cf326106');
delete from public.liquid_movements where organization_id in ('398d6578-f039-4d13-9a32-ae13d555bbaf','63e2bb9e-a3b9-4e3e-943b-c633cf326106');
delete from public.lot_lineage where organization_id in ('398d6578-f039-4d13-9a32-ae13d555bbaf','63e2bb9e-a3b9-4e3e-943b-c633cf326106');
delete from public.operation_warnings where organization_id in ('398d6578-f039-4d13-9a32-ae13d555bbaf','63e2bb9e-a3b9-4e3e-943b-c633cf326106');
delete from public.maguey_receptions where organization_id in ('398d6578-f039-4d13-9a32-ae13d555bbaf','63e2bb9e-a3b9-4e3e-943b-c633cf326106');
delete from public.lot_external_sources where organization_id in ('398d6578-f039-4d13-9a32-ae13d555bbaf','63e2bb9e-a3b9-4e3e-943b-c633cf326106');
delete from public.lots where organization_id in ('398d6578-f039-4d13-9a32-ae13d555bbaf','63e2bb9e-a3b9-4e3e-943b-c633cf326106');
delete from public.operations where organization_id in ('398d6578-f039-4d13-9a32-ae13d555bbaf','63e2bb9e-a3b9-4e3e-943b-c633cf326106');
delete from organizations where id in ('398d6578-f039-4d13-9a32-ae13d555bbaf','63e2bb9e-a3b9-4e3e-943b-c633cf326106');
delete from auth.users where id in ('e59ea9a8-4d41-4a99-8e73-a64b357ad723','08ff0bc4-be32-455c-8514-ca7ac7327593','68c28a14-a765-4df0-9171-48ae891009d6','b8254966-588f-4e25-9dbf-21c78c6bbc8a');
commit;
select 'organizations' as entity,count(*)::int as remaining from organizations where id in ('398d6578-f039-4d13-9a32-ae13d555bbaf','63e2bb9e-a3b9-4e3e-943b-c633cf326106')
union all select 'users',count(*)::int from auth.users where id in ('e59ea9a8-4d41-4a99-8e73-a64b357ad723','08ff0bc4-be32-455c-8514-ca7ac7327593','68c28a14-a765-4df0-9171-48ae891009d6','b8254966-588f-4e25-9dbf-21c78c6bbc8a')
union all select 'profiles',count(*)::int from profiles where id in ('e59ea9a8-4d41-4a99-8e73-a64b357ad723','08ff0bc4-be32-455c-8514-ca7ac7327593','68c28a14-a765-4df0-9171-48ae891009d6','b8254966-588f-4e25-9dbf-21c78c6bbc8a')
union all select 'sessions',count(*)::int from auth.sessions where user_id in ('e59ea9a8-4d41-4a99-8e73-a64b357ad723','08ff0bc4-be32-455c-8514-ca7ac7327593','68c28a14-a765-4df0-9171-48ae891009d6','b8254966-588f-4e25-9dbf-21c78c6bbc8a')
union all select 'refresh_tokens',count(*)::int from auth.refresh_tokens where user_id in ('e59ea9a8-4d41-4a99-8e73-a64b357ad723','08ff0bc4-be32-455c-8514-ca7ac7327593','68c28a14-a765-4df0-9171-48ae891009d6','b8254966-588f-4e25-9dbf-21c78c6bbc8a')
union all select 'fermentation_cycles',count(*)::int from public.fermentation_cycles where organization_id in ('398d6578-f039-4d13-9a32-ae13d555bbaf','63e2bb9e-a3b9-4e3e-943b-c633cf326106')
union all select 'formulation_supplies',count(*)::int from public.formulation_supplies where organization_id in ('398d6578-f039-4d13-9a32-ae13d555bbaf','63e2bb9e-a3b9-4e3e-943b-c633cf326106')
union all select 'formulation_inputs',count(*)::int from public.formulation_inputs where organization_id in ('398d6578-f039-4d13-9a32-ae13d555bbaf','63e2bb9e-a3b9-4e3e-943b-c633cf326106')
union all select 'formulations',count(*)::int from public.formulations where organization_id in ('398d6578-f039-4d13-9a32-ae13d555bbaf','63e2bb9e-a3b9-4e3e-943b-c633cf326106')
union all select 'roasting_run_inputs',count(*)::int from public.roasting_run_inputs where organization_id in ('398d6578-f039-4d13-9a32-ae13d555bbaf','63e2bb9e-a3b9-4e3e-943b-c633cf326106')
union all select 'roasting_runs',count(*)::int from public.roasting_runs where organization_id in ('398d6578-f039-4d13-9a32-ae13d555bbaf','63e2bb9e-a3b9-4e3e-943b-c633cf326106')
union all select 'liquid_movements',count(*)::int from public.liquid_movements where organization_id in ('398d6578-f039-4d13-9a32-ae13d555bbaf','63e2bb9e-a3b9-4e3e-943b-c633cf326106')
union all select 'lot_lineage',count(*)::int from public.lot_lineage where organization_id in ('398d6578-f039-4d13-9a32-ae13d555bbaf','63e2bb9e-a3b9-4e3e-943b-c633cf326106')
union all select 'operation_warnings',count(*)::int from public.operation_warnings where organization_id in ('398d6578-f039-4d13-9a32-ae13d555bbaf','63e2bb9e-a3b9-4e3e-943b-c633cf326106')
union all select 'maguey_receptions',count(*)::int from public.maguey_receptions where organization_id in ('398d6578-f039-4d13-9a32-ae13d555bbaf','63e2bb9e-a3b9-4e3e-943b-c633cf326106')
union all select 'lot_external_sources',count(*)::int from public.lot_external_sources where organization_id in ('398d6578-f039-4d13-9a32-ae13d555bbaf','63e2bb9e-a3b9-4e3e-943b-c633cf326106')
union all select 'lots',count(*)::int from public.lots where organization_id in ('398d6578-f039-4d13-9a32-ae13d555bbaf','63e2bb9e-a3b9-4e3e-943b-c633cf326106')
union all select 'operations',count(*)::int from public.operations where organization_id in ('398d6578-f039-4d13-9a32-ae13d555bbaf','63e2bb9e-a3b9-4e3e-943b-c633cf326106');