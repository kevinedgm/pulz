begin;
set local application_name='qa-race-4f52b889-first';
set local statement_timeout='40s';
create temporary table resultado(pid int, resultado text, inicio timestamptz, fin timestamptz);
do $$ declare v text := 'OK'; inicio timestamptz := clock_timestamp(); lote uuid;
begin
  select id into lote from lots where organization_id='248fdba3-71f7-4574-8bbd-a315dfc8ca16' and folio='QA-ULTIMO-LITRO';
  begin
    execute 'set local role authenticated';
    perform set_config('request.jwt.claims','{"sub":"9f8a6d8e-1708-4d5e-8436-67c27bd0bc16","role":"authenticated"}',true);
    perform transferir('248fdba3-71f7-4574-8bbd-a315dfc8ca16',gen_random_uuid(),now(),'02c58e16-63cf-48e9-b154-b3c60419dc41','e08fe84e-ad51-41ba-b6a8-15e522d93aeb',lote,1);
  exception when others then v := sqlerrm; end;
  execute 'reset role';
  insert into resultado values(pg_backend_pid(),v,inicio,clock_timestamp());
  if v='OK' then perform pg_sleep(20); end if;
end $$;
commit;
select * from resultado;