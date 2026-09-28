begin;
do $$ begin
  if exists(select 1 from organizations where id='7cfec3cf-33de-4f4f-9c8a-ed26b0ee35f9' and slug <> 'qa-race-b41e9ba9') then raise exception 'Identidad inesperada'; end if;
  if exists(select 1 from auth.users where id='bbfad14f-0986-4e87-ab05-4f827e386420' and email <> 'qa-race-b41e9ba9@example.invalid') then raise exception 'Usuario inesperado'; end if;
end $$;
delete from liquid_movements where organization_id='7cfec3cf-33de-4f4f-9c8a-ed26b0ee35f9';
delete from lot_lineage where organization_id='7cfec3cf-33de-4f4f-9c8a-ed26b0ee35f9';
delete from operation_warnings where organization_id='7cfec3cf-33de-4f4f-9c8a-ed26b0ee35f9';
delete from lots where organization_id='7cfec3cf-33de-4f4f-9c8a-ed26b0ee35f9';
delete from operations where organization_id='7cfec3cf-33de-4f4f-9c8a-ed26b0ee35f9';
delete from organizations where id='7cfec3cf-33de-4f4f-9c8a-ed26b0ee35f9' and slug='qa-race-b41e9ba9';
delete from auth.users where id='bbfad14f-0986-4e87-ab05-4f827e386420' and email='qa-race-b41e9ba9@example.invalid';
commit;
select (select count(*) from organizations where id='7cfec3cf-33de-4f4f-9c8a-ed26b0ee35f9') + (select count(*) from auth.users where id='bbfad14f-0986-4e87-ab05-4f827e386420') as restantes;