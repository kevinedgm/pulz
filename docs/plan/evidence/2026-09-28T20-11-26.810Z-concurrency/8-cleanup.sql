begin;
do $$ begin
  if exists(select 1 from organizations where id='248fdba3-71f7-4574-8bbd-a315dfc8ca16' and slug <> 'qa-race-4f52b889') then raise exception 'Identidad inesperada'; end if;
  if exists(select 1 from auth.users where id='9f8a6d8e-1708-4d5e-8436-67c27bd0bc16' and email <> 'qa-race-4f52b889@example.invalid') then raise exception 'Usuario inesperado'; end if;
end $$;
delete from liquid_movements where organization_id='248fdba3-71f7-4574-8bbd-a315dfc8ca16';
delete from lot_lineage where organization_id='248fdba3-71f7-4574-8bbd-a315dfc8ca16';
delete from operation_warnings where organization_id='248fdba3-71f7-4574-8bbd-a315dfc8ca16';
delete from lots where organization_id='248fdba3-71f7-4574-8bbd-a315dfc8ca16';
delete from operations where organization_id='248fdba3-71f7-4574-8bbd-a315dfc8ca16';
delete from organizations where id='248fdba3-71f7-4574-8bbd-a315dfc8ca16' and slug='qa-race-4f52b889';
delete from auth.users where id='9f8a6d8e-1708-4d5e-8436-67c27bd0bc16' and email='qa-race-4f52b889@example.invalid';
commit;
select (select count(*) from organizations where id='248fdba3-71f7-4574-8bbd-a315dfc8ca16') + (select count(*) from auth.users where id='9f8a6d8e-1708-4d5e-8436-67c27bd0bc16') as restantes;