-- 0014 · Base de los comandos (RPC): el contrato común de PULZ_MAESTRO.md
-- §12.1 implementado una sola vez. Nada de aquí se expone a authenticated;
-- lo usan las RPC de negocio (0015–0021), que son security definer.
--
-- Prefijos de error estables: SALDO_INSUFICIENTE:, CAPACIDAD_EXCEDIDA:,
-- NO_PERMITIDO:, LIMITE_PLAN:, REQUIERE_NOTA:<codigo>. Siempre errcode P0001.

-- ---------------------------------------------------------------------
-- Folios consecutivos por empresa y prefijo, con bloqueo de fila
-- (patrón app.next_folio de la rama saas, §17).
-- ---------------------------------------------------------------------
create table folio_counters (
  organization_id uuid not null references organizations(id) on delete cascade,
  prefix          text not null,
  last_no         integer not null default 0,
  primary key (organization_id, prefix)
);
alter table folio_counters enable row level security;   -- sin políticas: solo RPC

-- Si el usuario dio folios propios (p. ej. 'MEZ-001' a mano), el contador
-- los salta para no chocar con ellos.
create function next_folio(p_org uuid, p_prefix text) returns text
language plpgsql security definer set search_path = public as $$
declare n integer; f text;
begin
  loop
    insert into folio_counters (organization_id, prefix, last_no)
    values (p_org, p_prefix, 1)
    on conflict (organization_id, prefix) do update
      set last_no = folio_counters.last_no + 1
    returning last_no into n;
    f := p_prefix || '-' || lpad(n::text, 3, '0');
    exit when not exists (select 1 from lots where organization_id = p_org and folio = f)
         and not exists (select 1 from roasting_runs where organization_id = p_org and folio = f)
         and not exists (select 1 from formulations where organization_id = p_org and folio = f)
         and not exists (select 1 from distillation_runs where organization_id = p_org and folio = f);
  end loop;
  return f;
end $$;

-- ---------------------------------------------------------------------
-- Guardias
-- ---------------------------------------------------------------------
create function rpc_guard(p_org uuid, p_roles member_role[]) returns void
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null or not has_role(p_org, p_roles) then
    raise exception 'NO_PERMITIDO: no tienes permiso para esta operación en esta empresa'
      using errcode = 'P0001';
  end if;
end $$;

-- Idempotencia (§12.1): si la llave ya existe, la RPC devuelve el resultado
-- original sin hacer nada más.
create function rpc_existing(p_org uuid, p_idem uuid) returns uuid
language sql stable security definer set search_path = public as $$
  select id from operations where organization_id = p_org and idempotency_key = p_idem;
$$;

create function rpc_open_operation(
  p_org uuid, p_idem uuid, p_kind operation_kind, p_fecha timestamptz,
  p_note text default null, p_concept uuid default null,
  p_result_resource uuid default null, p_result_volume numeric default null,
  p_result_abv numeric default null, p_folio_decision folio_decision default null,
  p_counterparty text default null, p_document_ref text default null,
  p_correction_of uuid default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if p_fecha is null then
    raise exception 'NO_PERMITIDO: falta la fecha en que ocurrió' using errcode = 'P0001';
  end if;
  insert into operations (organization_id, kind, concept_id, occurred_at, recorded_at, recorded_by,
                          idempotency_key, result_resource_id, result_volume_l, result_abv,
                          folio_decision, counterparty, document_ref, correction_of_id, note)
  values (p_org, p_kind, p_concept, p_fecha, now(), auth.uid(),
          p_idem, p_result_resource, p_result_volume, p_result_abv,
          p_folio_decision, nullif(btrim(p_counterparty), ''), nullif(btrim(p_document_ref), ''),
          p_correction_of, nullif(btrim(p_note), ''))
  returning id into v_id;
  return v_id;
end $$;

create function rpc_set_result(p_org uuid, p_op uuid, p_lot uuid,
                               p_volume numeric default null, p_abv numeric default null) returns void
language sql security definer set search_path = public as $$
  update operations
     set result_lot_id   = p_lot,
         result_volume_l = coalesce(p_volume, result_volume_l),
         result_abv      = coalesce(p_abv, result_abv)
   where organization_id = p_org and id = p_op;
$$;

-- Avisos blandos (§2.1, §12.1): no fallan, pero exigen nota. Si la RPC
-- tiene una nota automática (p. ej. diferencia de volumen), la usa.
create function rpc_warn(p_org uuid, p_op uuid, p_code text, p_nota text, p_auto text default null) returns void
language plpgsql security definer set search_path = public as $$
declare v_note text := coalesce(nullif(btrim(p_nota), ''), p_auto);
begin
  if v_note is null then
    raise exception 'REQUIERE_NOTA:%', p_code using errcode = 'P0001';
  end if;
  insert into operation_warnings (operation_id, organization_id, code, note)
  values (p_op, p_org, p_code, v_note)
  on conflict (operation_id, code) do nothing;
end $$;

-- ---------------------------------------------------------------------
-- Bloqueos en orden de id (§12.1) antes de validar saldos
-- ---------------------------------------------------------------------
create function lock_lots(p_org uuid, p_ids uuid[]) returns void
language plpgsql security definer set search_path = public as $$
declare n integer;
begin
  if p_ids is null or cardinality(p_ids) = 0 then return; end if;
  select count(*) into n
    from (select id from lots where organization_id = p_org and id = any(p_ids) order by id for update) l;
  if n <> (select count(distinct x) from unnest(p_ids) x) then
    raise exception 'NO_PERMITIDO: algún lote no existe o no es de esta empresa' using errcode = 'P0001';
  end if;
end $$;

create function lock_resources(p_org uuid, p_ids uuid[]) returns void
language plpgsql security definer set search_path = public as $$
declare n integer;
begin
  if p_ids is null or cardinality(p_ids) = 0 then return; end if;
  select count(*) into n
    from (select id from resources where organization_id = p_org and id = any(p_ids) and active
           order by id for update) r;
  if n <> (select count(distinct x) from unnest(p_ids) x) then
    raise exception 'NO_PERMITIDO: algún recurso no existe, está inactivo o no es de esta empresa'
      using errcode = 'P0001';
  end if;
end $$;

create function rpc_resource(p_org uuid, p_id uuid, p_kind resource_kind default null) returns resources
language plpgsql stable security definer set search_path = public as $$
declare r resources;
begin
  select * into r from resources where organization_id = p_org and id = p_id;
  if not found then
    raise exception 'NO_PERMITIDO: el recurso no existe o no es de esta empresa' using errcode = 'P0001';
  end if;
  if p_kind is not null and r.kind <> p_kind then
    raise exception 'NO_PERMITIDO: el recurso % no es un %', r.code, p_kind using errcode = 'P0001';
  end if;
  return r;
end $$;

-- ---------------------------------------------------------------------
-- Saldos (siempre del ledger, dentro de la transacción)
-- ---------------------------------------------------------------------
create function lot_balance(p_org uuid, p_resource uuid, p_lot uuid) returns numeric
language sql stable security definer set search_path = public as $$
  select coalesce(sum(case when dest_resource_id = p_resource then volume_l
                           when source_resource_id = p_resource then -volume_l end), 0)
    from liquid_movements
   where organization_id = p_org and lot_id = p_lot
     and (dest_resource_id = p_resource or source_resource_id = p_resource);
$$;

create function lot_total_balance(p_org uuid, p_lot uuid) returns numeric
language sql stable security definer set search_path = public as $$
  select coalesce(sum(case when dest_resource_id is not null then volume_l else 0 end)
                - sum(case when source_resource_id is not null then volume_l else 0 end), 0)
    from liquid_movements
   where organization_id = p_org and lot_id = p_lot;
$$;

create function resource_balance(p_org uuid, p_resource uuid) returns numeric
language sql stable security definer set search_path = public as $$
  select coalesce(sum(case when dest_resource_id = p_resource then volume_l else -volume_l end), 0)
    from liquid_movements
   where organization_id = p_org
     and (dest_resource_id = p_resource or source_resource_id = p_resource);
$$;

-- El lote vivo de un recurso: el que tiene saldo (>0) ahí. Un colector o
-- tanque normalmente tiene uno; si hubiera varios, el mayor.
create function live_lot(p_org uuid, p_resource uuid) returns uuid
language sql stable security definer set search_path = public as $$
  select lot_id
    from resource_lot_balances
   where organization_id = p_org and resource_id = p_resource and volume_l > 0
   order by volume_l desc limit 1;
$$;

create function solid_remaining(p_org uuid, p_lot uuid) returns numeric
language sql stable security definer set search_path = public as $$
  select remaining_kg from solid_lot_balances where organization_id = p_org and lot_id = p_lot;
$$;

-- Un lote líquido sin saldo en ningún recurso queda 'agotado' (y revive si
-- vuelve a tener saldo). Los sólidos se agotan cuando su remanente es 0.
create function refresh_lot_status(p_org uuid, p_lot uuid) returns void
language plpgsql security definer set search_path = public as $$
declare l lots; v numeric;
begin
  select * into l from lots where organization_id = p_org and id = p_lot;
  if not found or l.status = 'cerrado' then return; end if;
  v := case when l.unit = 'L' then lot_total_balance(p_org, p_lot) else solid_remaining(p_org, p_lot) end;
  update lots set status = case when v <= 0 then 'agotado' else 'activo' end::lot_status
   where id = p_lot and status <> (case when v <= 0 then 'agotado' else 'activo' end)::lot_status;
end $$;

-- ---------------------------------------------------------------------
-- Capacidad (§2.1): 'estricta' bloquea; 'flexible' avisa y pide nota;
-- 'libre' no revisa.
-- ---------------------------------------------------------------------
create function check_capacity(p_org uuid, p_op uuid, p_resource uuid, p_added numeric, p_nota text) returns void
language plpgsql security definer set search_path = public as $$
declare r resources; v_after numeric;
begin
  r := rpc_resource(p_org, p_resource);
  if r.capacity is null or r.capacity_policy = 'libre' or r.capacity_unit <> 'L' then return; end if;
  v_after := resource_balance(p_org, p_resource);    -- ya incluye la pata recién insertada
  if v_after > r.capacity then
    if r.capacity_policy = 'estricta' then
      raise exception 'CAPACIDAD_EXCEDIDA: % admite % L y quedarían % L', r.code, r.capacity, v_after
        using errcode = 'P0001';
    end if;
    perform rpc_warn(p_org, p_op, 'excede_capacidad', p_nota);
  end if;
end $$;

-- ---------------------------------------------------------------------
-- Nivel de historia (§6): se recalcula cuando cambia el linaje.
--   completa     todo el árbol hacia atrás llega al maguey
--   parcial      una parte llega y otra nace de carga inicial / compra
--   declarada    origen externo (compra) sin historia propia
--   sin_historia carga inicial sin nada atrás
-- ---------------------------------------------------------------------
create function recompute_history(p_org uuid, p_lot uuid) returns void
language plpgsql security definer set search_path = public as $$
declare v_maguey boolean; v_gap boolean; v_self lots; v_level history_level;
begin
  select * into v_self from lots where organization_id = p_org and id = p_lot;
  if not found then return; end if;

  with recursive up as (
    select v_self.id as lot_id
    union
    select ll.parent_lot_id
      from lot_lineage ll join up on ll.child_lot_id = up.lot_id
     where ll.organization_id = p_org
  )
  select bool_or(l.material = 'maguey'),
         bool_or(l.origin in ('carga_inicial', 'compra'))
    into v_maguey, v_gap
    from up join lots l on l.id = up.lot_id;

  v_level := case
    when coalesce(v_maguey, false) and not coalesce(v_gap, false) then 'completa'
    when coalesce(v_maguey, false) then 'parcial'
    when v_self.origin = 'compra' or exists (select 1 from lot_external_sources where lot_id = p_lot) then 'declarada'
    else 'sin_historia' end;

  update lots set history = v_level where id = p_lot and history <> v_level;
end $$;

-- Ninguna de estas funciones es para el navegador
revoke execute on function next_folio(uuid, text), rpc_guard(uuid, member_role[]), rpc_existing(uuid, uuid),
  rpc_open_operation(uuid, uuid, operation_kind, timestamptz, text, uuid, uuid, numeric, numeric, folio_decision, text, text, uuid),
  rpc_set_result(uuid, uuid, uuid, numeric, numeric), rpc_warn(uuid, uuid, text, text, text),
  lock_lots(uuid, uuid[]), lock_resources(uuid, uuid[]), rpc_resource(uuid, uuid, resource_kind),
  lot_balance(uuid, uuid, uuid), lot_total_balance(uuid, uuid), resource_balance(uuid, uuid),
  live_lot(uuid, uuid), solid_remaining(uuid, uuid), refresh_lot_status(uuid, uuid),
  check_capacity(uuid, uuid, uuid, numeric, text), recompute_history(uuid, uuid)
from public, anon, authenticated;
