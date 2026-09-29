begin;
set local statement_timeout='20s';
set local lock_timeout='5s';
do $$ begin
if exists(select 1 from organizations where id='cb39a2f1-d607-4b79-b18d-7e9a288ce059' and slug<>'qa-race-ad785404') then raise exception 'Fixture org identity mismatch'; end if;
if exists(select 1 from auth.users where id='20fc34e1-3ca9-41d3-8b8f-b06f1f3186af' and email<>'qa-race-ad785404-a@example.invalid') then raise exception 'Fixture user identity mismatch'; end if;
if exists(select 1 from auth.users where id='a882047a-7a29-46b1-b87b-076e41c8f6a7' and email<>'qa-race-ad785404-b@example.invalid') then raise exception 'Fixture user identity mismatch'; end if;
end $$;
delete from auth.refresh_tokens where user_id in ('20fc34e1-3ca9-41d3-8b8f-b06f1f3186af','a882047a-7a29-46b1-b87b-076e41c8f6a7');
delete from auth.sessions where user_id in ('20fc34e1-3ca9-41d3-8b8f-b06f1f3186af','a882047a-7a29-46b1-b87b-076e41c8f6a7');
delete from public.liquid_movements where organization_id='cb39a2f1-d607-4b79-b18d-7e9a288ce059';
delete from public.lot_lineage where organization_id='cb39a2f1-d607-4b79-b18d-7e9a288ce059';
delete from public.operation_warnings where organization_id='cb39a2f1-d607-4b79-b18d-7e9a288ce059';
delete from public.lots where organization_id='cb39a2f1-d607-4b79-b18d-7e9a288ce059';
delete from public.operations where organization_id='cb39a2f1-d607-4b79-b18d-7e9a288ce059';
delete from organizations where id='cb39a2f1-d607-4b79-b18d-7e9a288ce059';
delete from auth.users where id in ('20fc34e1-3ca9-41d3-8b8f-b06f1f3186af','a882047a-7a29-46b1-b87b-076e41c8f6a7');
commit;
select 'organizations' as entity,count(*)::int as remaining from organizations where id='cb39a2f1-d607-4b79-b18d-7e9a288ce059'
union all select 'users',count(*)::int from auth.users where id in ('20fc34e1-3ca9-41d3-8b8f-b06f1f3186af','a882047a-7a29-46b1-b87b-076e41c8f6a7')
union all select 'profiles',count(*)::int from profiles where id in ('20fc34e1-3ca9-41d3-8b8f-b06f1f3186af','a882047a-7a29-46b1-b87b-076e41c8f6a7')
union all select 'resources',count(*)::int from resources where organization_id='cb39a2f1-d607-4b79-b18d-7e9a288ce059'
union all select 'liquid_movements',count(*)::int from public.liquid_movements where organization_id='cb39a2f1-d607-4b79-b18d-7e9a288ce059'
union all select 'lot_lineage',count(*)::int from public.lot_lineage where organization_id='cb39a2f1-d607-4b79-b18d-7e9a288ce059'
union all select 'operation_warnings',count(*)::int from public.operation_warnings where organization_id='cb39a2f1-d607-4b79-b18d-7e9a288ce059'
union all select 'lots',count(*)::int from public.lots where organization_id='cb39a2f1-d607-4b79-b18d-7e9a288ce059'
union all select 'operations',count(*)::int from public.operations where organization_id='cb39a2f1-d607-4b79-b18d-7e9a288ce059';