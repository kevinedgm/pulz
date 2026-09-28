begin;
do $$ begin
  if exists(select 1 from organizations where id='7702ec30-13dc-4e39-b444-84f17edd4e0e' and slug <> 'qa-race-e25af3f1') then raise exception 'Identidad inesperada'; end if;
  if exists(select 1 from auth.users where id='f9d38529-75dc-4908-8ec9-7124938b5321' and email <> 'qa-race-e25af3f1@example.invalid') then raise exception 'Usuario inesperado'; end if;
end $$;
delete from liquid_movements where organization_id='7702ec30-13dc-4e39-b444-84f17edd4e0e';
delete from lot_lineage where organization_id='7702ec30-13dc-4e39-b444-84f17edd4e0e';
delete from operation_warnings where organization_id='7702ec30-13dc-4e39-b444-84f17edd4e0e';
delete from lots where organization_id='7702ec30-13dc-4e39-b444-84f17edd4e0e';
delete from operations where organization_id='7702ec30-13dc-4e39-b444-84f17edd4e0e';
delete from organizations where id='7702ec30-13dc-4e39-b444-84f17edd4e0e' and slug='qa-race-e25af3f1';
delete from auth.users where id='f9d38529-75dc-4908-8ec9-7124938b5321' and email='qa-race-e25af3f1@example.invalid';
commit;
select (select count(*) from organizations where id='7702ec30-13dc-4e39-b444-84f17edd4e0e') + (select count(*) from auth.users where id='f9d38529-75dc-4908-8ec9-7124938b5321') as restantes;