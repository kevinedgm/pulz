begin;
insert into auth.users(id,aud,role,email) values('bbfad14f-0986-4e87-ab05-4f827e386420','authenticated','authenticated','qa-race-b41e9ba9@example.invalid');
insert into profiles(id,full_name) values('bbfad14f-0986-4e87-ab05-4f827e386420','QA concurrencia');
insert into organizations(id,name,slug,created_by) values('7cfec3cf-33de-4f4f-9c8a-ed26b0ee35f9','QA concurrencia','qa-race-b41e9ba9','bbfad14f-0986-4e87-ab05-4f827e386420');
insert into organization_members(organization_id,user_id,role,status) values('7cfec3cf-33de-4f4f-9c8a-ed26b0ee35f9','bbfad14f-0986-4e87-ab05-4f827e386420','admin','activo');
insert into organization_settings(organization_id) values('7cfec3cf-33de-4f4f-9c8a-ed26b0ee35f9');
insert into subscriptions(organization_id,plan_id,status) select '7cfec3cf-33de-4f4f-9c8a-ed26b0ee35f9',id,'gratis' from plans where code='gratis';
insert into resources(id,organization_id,kind,code,capacity_policy) values
('d750d370-d961-47c1-910f-53694d0cd7b3','7cfec3cf-33de-4f4f-9c8a-ed26b0ee35f9','tanque','Origen','libre'),('cecef1a6-011a-40b2-b82b-38556546a432','7cfec3cf-33de-4f4f-9c8a-ed26b0ee35f9','tanque','Destino 1','libre'),('b783c7a7-cd52-43f0-baf6-5e6be22abfd4','7cfec3cf-33de-4f4f-9c8a-ed26b0ee35f9','tanque','Destino 2','libre');
set local role authenticated;
set local request.jwt.claims='{"sub":"bbfad14f-0986-4e87-ab05-4f827e386420","role":"authenticated"}';
select registrar_entrada('7cfec3cf-33de-4f4f-9c8a-ed26b0ee35f9',gen_random_uuid(),now(),'granel','d750d370-d961-47c1-910f-53694d0cd7b3',1,47,p_folio=>'QA-ULTIMO-LITRO');
reset role;
commit;
select id from organizations where id='7cfec3cf-33de-4f4f-9c8a-ed26b0ee35f9';