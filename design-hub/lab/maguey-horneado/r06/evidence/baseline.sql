begin;
create function pg_temp.fixture_baseline() returns table(entity text, rows bigint, hash text) language plpgsql as $$
declare t record; condition text; begin
for t in select tablename from pg_tables where schemaname='public' order by tablename loop
 condition := case when t.tablename='organizations' then 'id not in (''398d6578-f039-4d13-9a32-ae13d555bbaf'',''63e2bb9e-a3b9-4e3e-943b-c633cf326106'')'
 when t.tablename='profiles' then 'id not in (''e59ea9a8-4d41-4a99-8e73-a64b357ad723'',''08ff0bc4-be32-455c-8514-ca7ac7327593'',''68c28a14-a765-4df0-9171-48ae891009d6'',''b8254966-588f-4e25-9dbf-21c78c6bbc8a'')'
 when exists(select 1 from information_schema.columns where table_schema='public' and table_name=t.tablename and column_name='organization_id') then 'organization_id not in (''398d6578-f039-4d13-9a32-ae13d555bbaf'',''63e2bb9e-a3b9-4e3e-943b-c633cf326106'') or organization_id is null'
 else 'true' end;
 return query execute format('select %L,count(*),md5(coalesce(string_agg(to_jsonb(x)::text,''|'' order by to_jsonb(x)::text),'''')) from public.%I x where %s',t.tablename,t.tablename,condition);
end loop; end $$;
select * from pg_temp.fixture_baseline();
rollback;