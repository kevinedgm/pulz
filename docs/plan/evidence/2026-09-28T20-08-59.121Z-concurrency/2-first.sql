begin;
set local application_name='qa-race-b41e9ba9-first';
set local statement_timeout='40s';
create temporary table resultado(pid int, resultado text, inicio timestamptz, fin timestamptz);
do $$ declare v text := 'OK'; inicio timestamptz := clock_timestamp(); lote uuid;
begin
  select id into lote from lots where organization_id='7cfec3cf-33de-4f4f-9c8a-ed26b0ee35f9' and folio='QA-ULTIMO-LITRO';
  begin
    execute 'set local role authenticated';
    perform set_config('request.jwt.claims','{"sub":"bbfad14f-0986-4e87-ab05-4f827e386420","role":"authenticated"}',true);
    perform transferir('7cfec3cf-33de-4f4f-9c8a-ed26b0ee35f9',gen_random_uuid(),now(),'d750d370-d961-47c1-910f-53694d0cd7b3','cecef1a6-011a-40b2-b82b-38556546a432',lote,1);
  exception when others then v := sqlerrm; end;
  execute 'reset role';
  insert into resultado values(pg_backend_pid(),v,inicio,clock_timestamp());
  if v='OK' then perform pg_sleep(20); end if;
end $$;
commit;
select * from resultado;