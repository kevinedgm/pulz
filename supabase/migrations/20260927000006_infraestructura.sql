-- 0006 · Infraestructura. El recurso es lo físico ("Alambique 1", 250 L);
-- su tipo sale del catálogo ("Alambique de cobre"). Un solo modelo para los
-- seis tipos, con capacity_policy y liquid_class solo en colectores.
-- (PULZ_MAESTRO.md §3, §10.3 "Infraestructura")

create table resources (
  id              uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  kind            resource_kind not null,
  code            text not null,                   -- como le dicen: 'Alambique 1'
  type_item_id    uuid,                            -- catálogo tipo_<kind>
  capacity        numeric(12,2),
  capacity_unit   text not null default 'L',
  capacity_policy capacity_policy not null default 'flexible',
  liquid_class    liquid_class,                    -- solo colectores
  location        text,
  active          boolean not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  unique (organization_id, id),
  unique (organization_id, code),
  foreign key (organization_id, type_item_id) references catalog_items(organization_id, id),
  check ((kind = 'colector') = (liquid_class is not null))
);
create index resources_org_kind on resources (organization_id, kind);
create trigger resources_updated_at before update on resources
  for each row execute function set_updated_at();

-- El catálogo del tipo debe corresponder al kind del recurso (§10.2.5)
create function resource_catalog_for(p_kind resource_kind) returns catalog_kind
language sql immutable set search_path = public as $$
  select case p_kind
    when 'horno'     then 'tipo_horno'::catalog_kind
    when 'molino'    then 'tipo_molino'::catalog_kind
    when 'tina'      then 'tipo_tina'::catalog_kind
    when 'alambique' then 'tipo_alambique'::catalog_kind
    when 'colector'  then 'tipo_colector'::catalog_kind
    when 'tanque'    then 'tipo_tanque'::catalog_kind
  end;
$$;

create function resources_check_type() returns trigger
language plpgsql set search_path = public as $$
begin
  perform assert_catalog_item(new.organization_id, new.type_item_id, resource_catalog_for(new.kind));
  return new;
end $$;
create trigger resources_check_type before insert or update of type_item_id, kind, organization_id on resources
  for each row execute function resources_check_type();
