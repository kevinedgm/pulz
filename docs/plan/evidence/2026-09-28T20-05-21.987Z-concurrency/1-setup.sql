begin;
insert into auth.users(id,aud,role,email) values('f9d38529-75dc-4908-8ec9-7124938b5321','authenticated','authenticated','qa-race-e25af3f1@example.invalid');
insert into profiles(id,full_name) values('f9d38529-75dc-4908-8ec9-7124938b5321','QA concurrencia');
insert into organizations(id,name,slug,created_by) values('7702ec30-13dc-4e39-b444-84f17edd4e0e','QA concurrencia','qa-race-e25af3f1','f9d38529-75dc-4908-8ec9-7124938b5321');
insert into organization_members(organization_id,user_id,role,status) values('7702ec30-13dc-4e39-b444-84f17edd4e0e','f9d38529-75dc-4908-8ec9-7124938b5321','admin','activo');
insert into organization_settings(organization_id) values('7702ec30-13dc-4e39-b444-84f17edd4e0e');
insert into subscriptions(organization_id,plan_id,status) select '7702ec30-13dc-4e39-b444-84f17edd4e0e',id,'gratis' from plans where code='gratis';
insert into resources(id,organization_id,kind,code,capacity_policy) values
('6caae69a-5e0c-46bf-b339-751035d6cf6f','7702ec30-13dc-4e39-b444-84f17edd4e0e','tanque','Origen','libre'),('ceda0450-bfd4-47e0-9907-7e615c8f88a7','7702ec30-13dc-4e39-b444-84f17edd4e0e','tanque','Destino 1','libre'),('74dde496-ea17-4564-b287-ec7363844921','7702ec30-13dc-4e39-b444-84f17edd4e0e','tanque','Destino 2','libre');
set local role authenticated;
set local request.jwt.claims='{"sub":"f9d38529-75dc-4908-8ec9-7124938b5321","role":"authenticated"}';
select registrar_entrada('7702ec30-13dc-4e39-b444-84f17edd4e0e',gen_random_uuid(),now(),'granel','6caae69a-5e0c-46bf-b339-751035d6cf6f',1,47,p_folio=>'QA-ULTIMO-LITRO');
reset role;
commit;
select id from organizations where id='7702ec30-13dc-4e39-b444-84f17edd4e0e';