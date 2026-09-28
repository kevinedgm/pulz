begin;
insert into auth.users(id,aud,role,email) values('9f8a6d8e-1708-4d5e-8436-67c27bd0bc16','authenticated','authenticated','qa-race-4f52b889@example.invalid');
insert into profiles(id,full_name) values('9f8a6d8e-1708-4d5e-8436-67c27bd0bc16','QA concurrencia');
insert into organizations(id,name,slug,created_by) values('248fdba3-71f7-4574-8bbd-a315dfc8ca16','QA concurrencia','qa-race-4f52b889','9f8a6d8e-1708-4d5e-8436-67c27bd0bc16');
insert into organization_members(organization_id,user_id,role,status) values('248fdba3-71f7-4574-8bbd-a315dfc8ca16','9f8a6d8e-1708-4d5e-8436-67c27bd0bc16','admin','activo');
insert into organization_settings(organization_id) values('248fdba3-71f7-4574-8bbd-a315dfc8ca16');
insert into subscriptions(organization_id,plan_id,status) select '248fdba3-71f7-4574-8bbd-a315dfc8ca16',id,'gratis' from plans where code='gratis';
insert into resources(id,organization_id,kind,code,capacity_policy) values
('02c58e16-63cf-48e9-b154-b3c60419dc41','248fdba3-71f7-4574-8bbd-a315dfc8ca16','tanque','Origen','libre'),('e08fe84e-ad51-41ba-b6a8-15e522d93aeb','248fdba3-71f7-4574-8bbd-a315dfc8ca16','tanque','Destino 1','libre'),('82b5462f-07dc-4c59-8d58-71f0ad4587a9','248fdba3-71f7-4574-8bbd-a315dfc8ca16','tanque','Destino 2','libre');
set local role authenticated;
set local request.jwt.claims='{"sub":"9f8a6d8e-1708-4d5e-8436-67c27bd0bc16","role":"authenticated"}';
select registrar_entrada('248fdba3-71f7-4574-8bbd-a315dfc8ca16',gen_random_uuid(),now(),'granel','02c58e16-63cf-48e9-b154-b3c60419dc41',1,47,p_folio=>'QA-ULTIMO-LITRO');
reset role;
commit;
select id from organizations where id='248fdba3-71f7-4574-8bbd-a315dfc8ca16';