-- 0016 · Horneado (§4.2) y molienda/formulación (§4.3).

-- abrir_horneado → run_id. Lotes de maguey con kilos de cada uno.
create function abrir_horneado(
  p_org uuid, p_idem uuid, p_fecha timestamptz, p_horno uuid,
  p_lotes uuid[], p_kilos numeric[],
  p_nota text default null, p_folio text default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare v_op uuid; v_run uuid; i integer; l lots; v_rem numeric;
begin
  perform rpc_guard(p_org, array['admin', 'productor']::member_role[]);
  v_op := rpc_existing(p_org, p_idem);
  if v_op is not null then
    return (select id from roasting_runs where operation_id = v_op);
  end if;
  if p_lotes is null or cardinality(p_lotes) = 0 or cardinality(p_lotes) <> cardinality(p_kilos) then
    raise exception 'NO_PERMITIDO: indica los lotes de maguey y los kilos de cada uno' using errcode = 'P0001';
  end if;
  perform rpc_resource(p_org, p_horno, 'horno');
  perform lock_resources(p_org, array[p_horno]);
  perform lock_lots(p_org, p_lotes);

  for i in 1 .. cardinality(p_lotes) loop
    select * into l from lots where organization_id = p_org and id = p_lotes[i];
    if l.material <> 'maguey' then
      raise exception 'NO_PERMITIDO: el lote % no es maguey', l.folio using errcode = 'P0001';
    end if;
    if p_kilos[i] is null or p_kilos[i] <= 0 then
      raise exception 'NO_PERMITIDO: los kilos del lote % deben ser mayores a cero', l.folio using errcode = 'P0001';
    end if;
    v_rem := solid_remaining(p_org, l.id);
    if v_rem < p_kilos[i] then
      raise exception 'SALDO_INSUFICIENTE: el lote % tiene % kg y se piden % kg', l.folio, v_rem, p_kilos[i]
        using errcode = 'P0001';
    end if;
  end loop;

  v_op := rpc_open_operation(p_org, p_idem, 'abrir_horneado', p_fecha, p_nota);
  insert into roasting_runs (organization_id, operation_id, folio, oven_id, status, started_at)
  values (p_org, v_op, coalesce(nullif(btrim(p_folio), ''), next_folio(p_org, 'HOR')), p_horno, 'abierta', p_fecha)
  returning id into v_run;

  for i in 1 .. cardinality(p_lotes) loop
    insert into roasting_run_inputs (run_id, organization_id, lot_id, quantity_kg)
    values (v_run, p_org, p_lotes[i], p_kilos[i]);
    perform refresh_lot_status(p_org, p_lotes[i]);
  end loop;
  return v_run;
end $$;

-- cerrar_horneado → lot_id del agave cocido, con linaje hacia cada maguey.
create function cerrar_horneado(
  p_org uuid, p_idem uuid, p_fecha timestamptz, p_horneado uuid, p_kilos_cocidos numeric,
  p_combustible text default null, p_nota text default null, p_folio text default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare v_op uuid; v_lot uuid; rr roasting_runs; inp record;
begin
  perform rpc_guard(p_org, array['admin', 'productor']::member_role[]);
  v_op := rpc_existing(p_org, p_idem);
  if v_op is not null then
    return (select result_lot_id from operations where id = v_op);
  end if;
  select * into rr from roasting_runs where organization_id = p_org and id = p_horneado for update;
  if not found then
    raise exception 'NO_PERMITIDO: la horneada no existe o no es de esta empresa' using errcode = 'P0001';
  end if;
  if rr.status <> 'abierta' then
    raise exception 'NO_PERMITIDO: la horneada % ya está cerrada', rr.folio using errcode = 'P0001';
  end if;
  if p_kilos_cocidos is null or p_kilos_cocidos <= 0 then
    raise exception 'NO_PERMITIDO: los kilos cocidos deben ser mayores a cero' using errcode = 'P0001';
  end if;

  v_op := rpc_open_operation(p_org, p_idem, 'cerrar_horneado', p_fecha, p_nota);
  insert into lots (organization_id, operation_id, folio, material, origin, status, history, unit, initial_quantity)
  values (p_org, v_op, coalesce(nullif(btrim(p_folio), ''), next_folio(p_org, 'AC')), 'agave_cocido', 'producido',
          'activo', 'sin_historia', 'kg', p_kilos_cocidos)
  returning id into v_lot;

  for inp in select lot_id, quantity_kg from roasting_run_inputs where run_id = rr.id loop
    insert into lot_lineage (organization_id, operation_id, child_lot_id, parent_lot_id, quantity, unit)
    values (p_org, v_op, v_lot, inp.lot_id, inp.quantity_kg, 'kg');
  end loop;

  update roasting_runs
     set status = 'cerrada', ended_at = p_fecha, cooked_kg = p_kilos_cocidos,
         fuel_note = nullif(btrim(p_combustible), ''), output_lot_id = v_lot, closed_operation_id = v_op
   where id = rr.id;

  perform recompute_history(p_org, v_lot);
  perform rpc_set_result(p_org, v_op, v_lot);
  return v_lot;
end $$;

-- registrar_formulacion → formulation_id. Toma agave cocido (kg), agua (L),
-- insumos opcionales y reparte a una o varias tinas: cada tina abre un
-- ciclo con su lote fermentado y linaje hacia la formulación.
create function registrar_formulacion(
  p_org uuid, p_idem uuid, p_fecha timestamptz,
  p_molino uuid, p_lotes_cocido uuid[], p_kilos numeric[], p_agua_l numeric,
  p_tinas uuid[], p_litros numeric[],
  p_insumos uuid[] default null, p_cantidades numeric[] default null,
  p_metodo text default null, p_nota text default null, p_folio text default null,
  p_folios_tina text[] default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_op uuid; v_form uuid; v_lot_f uuid; v_lot_t uuid; v_total numeric := 0;
  i integer; l lots; r resources; v_rem numeric;
begin
  perform rpc_guard(p_org, array['admin', 'productor']::member_role[]);
  v_op := rpc_existing(p_org, p_idem);
  if v_op is not null then
    return (select id from formulations where operation_id = v_op);
  end if;
  if p_lotes_cocido is null or cardinality(p_lotes_cocido) = 0 or cardinality(p_lotes_cocido) <> cardinality(p_kilos) then
    raise exception 'NO_PERMITIDO: indica los lotes de agave cocido y los kilos de cada uno' using errcode = 'P0001';
  end if;
  if p_tinas is null or cardinality(p_tinas) = 0 or cardinality(p_tinas) <> cardinality(p_litros) then
    raise exception 'NO_PERMITIDO: indica las tinas y los litros que van a cada una' using errcode = 'P0001';
  end if;
  if p_insumos is not null and cardinality(p_insumos) <> coalesce(cardinality(p_cantidades), -1) then
    raise exception 'NO_PERMITIDO: cada insumo necesita su cantidad' using errcode = 'P0001';
  end if;
  if p_molino is not null then perform rpc_resource(p_org, p_molino, 'molino'); end if;
  perform lock_resources(p_org, p_tinas || coalesce(array[p_molino], '{}'::uuid[]));
  perform lock_lots(p_org, p_lotes_cocido);

  for i in 1 .. cardinality(p_lotes_cocido) loop
    select * into l from lots where organization_id = p_org and id = p_lotes_cocido[i];
    if l.material <> 'agave_cocido' then
      raise exception 'NO_PERMITIDO: el lote % no es agave cocido', l.folio using errcode = 'P0001';
    end if;
    v_rem := solid_remaining(p_org, l.id);
    if p_kilos[i] is null or p_kilos[i] <= 0 or v_rem < p_kilos[i] then
      raise exception 'SALDO_INSUFICIENTE: el lote % tiene % kg y se piden % kg', l.folio, v_rem, p_kilos[i]
        using errcode = 'P0001';
    end if;
  end loop;
  for i in 1 .. cardinality(p_tinas) loop
    perform rpc_resource(p_org, p_tinas[i], 'tina');
    if p_litros[i] is null or p_litros[i] <= 0 then
      raise exception 'NO_PERMITIDO: los litros de cada tina deben ser mayores a cero' using errcode = 'P0001';
    end if;
    v_total := v_total + p_litros[i];
  end loop;

  v_op := rpc_open_operation(p_org, p_idem, 'formulacion', p_fecha, p_nota);

  insert into lots (organization_id, operation_id, folio, material, origin, status, history, unit, initial_quantity)
  values (p_org, v_op, coalesce(nullif(btrim(p_folio), ''), next_folio(p_org, 'F')), 'formulacion', 'producido',
          'activo', 'sin_historia', 'L', v_total)
  returning id into v_lot_f;

  insert into formulations (organization_id, operation_id, folio, mill_id, method_note, water_l, result_volume_l, output_lot_id)
  values (p_org, v_op, (select folio from lots where id = v_lot_f), p_molino, nullif(btrim(p_metodo), ''),
          p_agua_l, v_total, v_lot_f)
  returning id into v_form;

  for i in 1 .. cardinality(p_lotes_cocido) loop
    insert into formulation_inputs (formulation_id, organization_id, lot_id, quantity_kg)
    values (v_form, p_org, p_lotes_cocido[i], p_kilos[i]);
    insert into lot_lineage (organization_id, operation_id, child_lot_id, parent_lot_id, quantity, unit)
    values (p_org, v_op, v_lot_f, p_lotes_cocido[i], p_kilos[i], 'kg');
    perform refresh_lot_status(p_org, p_lotes_cocido[i]);
  end loop;
  if p_insumos is not null then
    for i in 1 .. cardinality(p_insumos) loop
      insert into formulation_supplies (formulation_id, organization_id, supply_id, quantity)
      values (v_form, p_org, p_insumos[i], p_cantidades[i]);
    end loop;
  end if;
  perform recompute_history(p_org, v_lot_f);

  for i in 1 .. cardinality(p_tinas) loop
    r := rpc_resource(p_org, p_tinas[i], 'tina');
    insert into lots (organization_id, operation_id, folio, material, origin, status, history, unit)
    values (p_org, v_op, coalesce(nullif(btrim(p_folios_tina[i]), ''), next_folio(p_org, 'FER')),
            'fermentado', 'producido', 'activo', 'sin_historia', 'L')
    returning id into v_lot_t;
    insert into lot_lineage (organization_id, operation_id, child_lot_id, parent_lot_id, quantity, unit)
    values (p_org, v_op, v_lot_t, v_lot_f, p_litros[i], 'L');
    insert into liquid_movements (organization_id, operation_id, movement_type, lot_id, dest_resource_id, volume_l)
    values (p_org, v_op, 'entrada', v_lot_t, p_tinas[i], p_litros[i]);
    perform check_capacity(p_org, v_op, p_tinas[i], p_litros[i], p_nota);
    begin
      insert into fermentation_cycles (organization_id, operation_id, tina_id, lot_id, formulation_id, status)
      values (p_org, v_op, p_tinas[i], v_lot_t, v_form, 'fermentando');
    exception when unique_violation then
      raise exception 'NO_PERMITIDO: la tina % ya tiene un ciclo abierto', r.code using errcode = 'P0001';
    end;
    perform recompute_history(p_org, v_lot_t);
  end loop;

  perform rpc_set_result(p_org, v_op, v_lot_f, v_total);
  return v_form;
end $$;
