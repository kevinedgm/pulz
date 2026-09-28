begin;
set local application_name='qa-race-e25af3f1-first';
set local statement_timeout='40s';
create temporary table resultado(pid int, resultado text, inicio timestamptz, fin timestamptz);
do $$ declare v text := 'OK'; inicio timestamptz := clock_timestamp(); lote uuid;
begin
  select id into lote from lots where organization_id='7702ec30-13dc-4e39-b444-84f17edd4e0e' and folio='QA-ULTIMO-LITRO';
  begin
    execute 'set local role authenticated';
    perform set_config('request.jwt.claims','{"sub":"f9d38529-75dc-4908-8ec9-7124938b5321","role":"authenticated"}',true);
    perform transferir('7702ec30-13dc-4e39-b444-84f17edd4e0e',gen_random_uuid(),now(),'6caae69a-5e0c-46bf-b339-751035d6cf6f','ceda0450-bfd4-47e0-9907-7e615c8f88a7',lote,1);
  exception when others then v := sqlerrm; end;
  execute 'reset role';
  insert into resultado values(pg_backend_pid(),v,inicio,clock_timestamp());
  if v='OK' then perform pg_sleep(20); end if;
end $$;
commit;
select * from resultado;