-- 0017 · Fermentación y medición diaria (§4.4). Cada lectura es una fila;
-- una medición no se borra, se anula con motivo; la tina se libera solo al
-- cerrar el ciclo.

-- registrar_medicion → measurement_id. Solo en ciclos abiertos. Offline.
-- Lecturas como cuatro arreglos paralelos (variable, zona, número, valor).
-- (día, actividad y número de lectura van como integer para que un JSON
-- numérico o un literal resuelvan la firma sin casts; se guardan como smallint)
create function registrar_medicion(
  p_org uuid, p_idem uuid, p_fecha timestamptz, p_ciclo uuid,
  p_dia integer, p_modo measurement_mode, p_actividad integer default null,
  p_variables reading_variable[] default null, p_zonas reading_zone[] default null,
  p_numeros integer[] default null, p_valores numeric[] default null,
  p_nota text default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare v_op uuid; v_m uuid; c fermentation_cycles; s organization_settings; i integer; n integer;
begin
  perform rpc_guard(p_org, array['admin', 'productor', 'operador']::member_role[]);
  v_op := rpc_existing(p_org, p_idem);
  if v_op is not null then
    return (select id from fermentation_measurements where operation_id = v_op);
  end if;
  select * into c from fermentation_cycles where organization_id = p_org and id = p_ciclo for update;
  if not found then
    raise exception 'NO_PERMITIDO: el ciclo no existe o no es de esta empresa' using errcode = 'P0001';
  end if;
  if c.status not in ('fermentando', 'lista') then
    raise exception 'NO_PERMITIDO: el ciclo ya no está abierto (%)', c.status using errcode = 'P0001';
  end if;
  n := coalesce(cardinality(p_variables), 0);
  if n <> coalesce(cardinality(p_zonas), 0) or n <> coalesce(cardinality(p_numeros), 0) or n <> coalesce(cardinality(p_valores), 0) then
    raise exception 'NO_PERMITIDO: las lecturas vienen incompletas' using errcode = 'P0001';
  end if;

  v_op := rpc_open_operation(p_org, p_idem, 'medicion', p_fecha, p_nota);
  insert into fermentation_measurements (organization_id, operation_id, cycle_id, day_no, mode, activity, notes)
  values (p_org, v_op, p_ciclo, p_dia, p_modo, p_actividad, nullif(btrim(p_nota), ''))
  returning id into v_m;

  for i in 1 .. n loop
    insert into measurement_readings (measurement_id, organization_id, variable, zone, reading_no, value)
    values (v_m, p_org, p_variables[i], p_zonas[i], p_numeros[i], p_valores[i]);
  end loop;

  -- Brix inicial fuera de rango: avisa y pide nota (§2.1). "Inicial" = día 0 o 1.
  if p_dia <= 1 then
    select * into s from organization_settings where organization_id = p_org;
    if exists (select 1 from unnest(p_variables, p_valores) as x(v, val)
                where x.v = 'brix' and (x.val < s.brix_warn_min or x.val > s.brix_warn_max)) then
      perform rpc_warn(p_org, v_op, 'brix_fuera_rango', p_nota);
    end if;
  end if;
  return v_m;
end $$;

-- anular_medicion → operation_id de la anulación. Marca, no borra.
create function anular_medicion(
  p_org uuid, p_idem uuid, p_fecha timestamptz, p_medicion uuid, p_motivo text
) returns uuid
language plpgsql security definer set search_path = public as $$
declare v_op uuid; m fermentation_measurements;
begin
  perform rpc_guard(p_org, array['admin', 'productor']::member_role[]);
  v_op := rpc_existing(p_org, p_idem);
  if v_op is not null then return v_op; end if;
  if nullif(btrim(p_motivo), '') is null then
    raise exception 'REQUIERE_NOTA:anular_medicion' using errcode = 'P0001';
  end if;
  select * into m from fermentation_measurements where organization_id = p_org and id = p_medicion for update;
  if not found then
    raise exception 'NO_PERMITIDO: la medición no existe o no es de esta empresa' using errcode = 'P0001';
  end if;
  if m.voided_at is not null then
    raise exception 'NO_PERMITIDO: la medición ya estaba anulada' using errcode = 'P0001';
  end if;
  v_op := rpc_open_operation(p_org, p_idem, 'anular_medicion', p_fecha, p_motivo, null, null, null, null, null, null, null, m.operation_id);
  update fermentation_measurements
     set voided_at = p_fecha, voided_by = auth.uid(), void_reason = btrim(p_motivo)
   where id = m.id;
  return v_op;
end $$;

-- declarar_tina_lista → operation_id. El productor decide cuándo está.
create function declarar_tina_lista(
  p_org uuid, p_idem uuid, p_fecha timestamptz, p_ciclo uuid, p_nota text default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare v_op uuid; c fermentation_cycles;
begin
  perform rpc_guard(p_org, array['admin', 'productor']::member_role[]);
  v_op := rpc_existing(p_org, p_idem);
  if v_op is not null then return v_op; end if;
  select * into c from fermentation_cycles where organization_id = p_org and id = p_ciclo for update;
  if not found then
    raise exception 'NO_PERMITIDO: el ciclo no existe o no es de esta empresa' using errcode = 'P0001';
  end if;
  if c.status <> 'fermentando' then
    raise exception 'NO_PERMITIDO: el ciclo no está fermentando (%)', c.status using errcode = 'P0001';
  end if;
  v_op := rpc_open_operation(p_org, p_idem, 'tina_lista', p_fecha, p_nota);
  update fermentation_cycles set status = 'lista', ready_operation_id = v_op where id = c.id;
  return v_op;
end $$;

-- cerrar_ciclo → operation_id. Tina vaciada: ciclo 'cerrado', tina liberada.
-- Si aún queda saldo en la tina, avisa y pide nota (blanda).
create function cerrar_ciclo(
  p_org uuid, p_idem uuid, p_fecha timestamptz, p_ciclo uuid, p_nota text default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare v_op uuid; c fermentation_cycles;
begin
  perform rpc_guard(p_org, array['admin', 'productor', 'operador']::member_role[]);
  v_op := rpc_existing(p_org, p_idem);
  if v_op is not null then return v_op; end if;
  select * into c from fermentation_cycles where organization_id = p_org and id = p_ciclo for update;
  if not found then
    raise exception 'NO_PERMITIDO: el ciclo no existe o no es de esta empresa' using errcode = 'P0001';
  end if;
  if c.status = 'cerrado' then
    raise exception 'NO_PERMITIDO: el ciclo ya estaba cerrado' using errcode = 'P0001';
  end if;
  perform lock_resources(p_org, array[c.tina_id]);
  v_op := rpc_open_operation(p_org, p_idem, 'cerrar_ciclo', p_fecha, p_nota);
  if lot_balance(p_org, c.tina_id, c.lot_id) > 0 then
    perform rpc_warn(p_org, v_op, 'cierre_con_saldo', p_nota);
  end if;
  update fermentation_cycles set status = 'cerrado' where id = c.id;
  return v_op;
end $$;
