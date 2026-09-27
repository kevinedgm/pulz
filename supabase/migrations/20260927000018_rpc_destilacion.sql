-- 0018 · Destilación (§4.5). Se abre una corrida cuando hay olla libre, con
-- lo que haya en el origen. La carga CONSUME el líquido (el alambique no
-- guarda saldo); la capacidad del alambique es regla dura.

-- abrir_corrida → run_id. Orígenes: tinas o colectores, con volumen de cada
-- uno (tres arreglos paralelos: recurso, lote, litros).
create function abrir_corrida(
  p_org uuid, p_idem uuid, p_fecha timestamptz,
  p_alambique uuid, p_pasada distillation_pass,
  p_recursos uuid[], p_lotes uuid[], p_litros numeric[],
  p_nota text default null, p_folio text default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_op uuid; v_run uuid; v_mv uuid; i integer; st resources; r resources; l lots;
  v_total numeric := 0; v_bal numeric; s organization_settings;
  v_has_ord boolean := false; v_has_col boolean := false;
begin
  perform rpc_guard(p_org, array['admin', 'productor', 'operador']::member_role[]);
  v_op := rpc_existing(p_org, p_idem);
  if v_op is not null then
    return (select id from distillation_runs where operation_id = v_op);
  end if;
  if p_recursos is null or cardinality(p_recursos) = 0
     or cardinality(p_recursos) <> cardinality(p_lotes) or cardinality(p_recursos) <> cardinality(p_litros) then
    raise exception 'NO_PERMITIDO: indica de dónde sale cada carga (recurso, lote y litros)' using errcode = 'P0001';
  end if;
  st := rpc_resource(p_org, p_alambique, 'alambique');
  perform lock_resources(p_org, array[p_alambique] || p_recursos);
  perform lock_lots(p_org, p_lotes);

  for i in 1 .. cardinality(p_recursos) loop
    r := rpc_resource(p_org, p_recursos[i]);
    if r.kind not in ('tina', 'colector') then
      raise exception 'NO_PERMITIDO: una corrida se carga desde tinas o colectores, no desde %', r.code using errcode = 'P0001';
    end if;
    if p_litros[i] is null or p_litros[i] <= 0 then
      raise exception 'NO_PERMITIDO: los litros de cada carga deben ser mayores a cero' using errcode = 'P0001';
    end if;
    v_bal := lot_balance(p_org, p_recursos[i], p_lotes[i]);
    select * into l from lots where id = p_lotes[i];
    if v_bal < p_litros[i] then
      raise exception 'SALDO_INSUFICIENTE: % tiene % L del lote % y se piden % L', r.code, v_bal, l.folio, p_litros[i]
        using errcode = 'P0001';
    end if;
    v_total := v_total + p_litros[i];
    if l.liquid_class = 'ordinario' then v_has_ord := true; end if;
    if l.liquid_class = 'colas' then v_has_col := true; end if;
  end loop;

  -- Capacidad del alambique (dura si es estricta)
  if st.capacity is not null and st.capacity_policy <> 'libre' and v_total > st.capacity then
    if st.capacity_policy = 'estricta' then
      raise exception 'CAPACIDAD_EXCEDIDA: % admite % L y se quieren cargar % L', st.code, st.capacity, v_total
        using errcode = 'P0001';
    end if;
  end if;

  v_op := rpc_open_operation(p_org, p_idem, 'abrir_corrida', p_fecha, p_nota);
  if st.capacity is not null and st.capacity_policy = 'flexible' and v_total > st.capacity then
    perform rpc_warn(p_org, v_op, 'excede_capacidad', p_nota);
  end if;
  -- Ordinario y colas juntos en la 2ª pasada: se permite con aviso y nota
  select * into s from organization_settings where organization_id = p_org;
  if p_pasada = 'segunda' and v_has_ord and v_has_col and coalesce(s.warn_mixed_second_pass, true) then
    perform rpc_warn(p_org, v_op, 'mezcla_clases_2a', p_nota);
  end if;

  insert into distillation_runs (organization_id, operation_id, folio, still_id, pass, status)
  values (p_org, v_op, coalesce(nullif(btrim(p_folio), ''), next_folio(p_org, 'DES')), p_alambique, p_pasada, 'abierta')
  returning id into v_run;

  for i in 1 .. cardinality(p_recursos) loop
    insert into liquid_movements (organization_id, operation_id, movement_type, lot_id, source_resource_id, volume_l)
    values (p_org, v_op, 'carga_alambique', p_lotes[i], p_recursos[i], p_litros[i])
    returning id into v_mv;
    insert into distillation_run_inputs (run_id, organization_id, movement_id) values (v_run, p_org, v_mv);
    -- Una tina cargada pasa a 'en_vaciado' (§4.4)
    update fermentation_cycles set status = 'en_vaciado'
     where organization_id = p_org and tina_id = p_recursos[i] and lot_id = p_lotes[i]
       and status in ('fermentando', 'lista');
    perform refresh_lot_status(p_org, p_lotes[i]);
  end loop;
  return v_run;
end $$;

-- registrar_corte → lot_id del corte. Pata 'corte' al colector. Regla de
-- acumulación (§4.5): se suma al lote vivo del colector, salvo que ese lote
-- se haya cargado a la misma corrida; entonces nace un lote nuevo.
-- Linaje: el corte se reparte entre las cargas de la corrida en proporción
-- al volumen cargado (así se reproduce §15.1).
create function registrar_corte(
  p_org uuid, p_idem uuid, p_fecha timestamptz, p_corrida uuid,
  p_clase liquid_class, p_litros numeric, p_abv numeric, p_colector uuid,
  p_nota text default null, p_folio text default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_op uuid; v_lot uuid; v_live uuid; v_loaded boolean; dr distillation_runs; col resources;
  s organization_settings; v_in_total numeric; inp record; v_q numeric; v_prefix text;
begin
  perform rpc_guard(p_org, array['admin', 'productor', 'operador']::member_role[]);
  v_op := rpc_existing(p_org, p_idem);
  if v_op is not null then
    return (select result_lot_id from operations where id = v_op);
  end if;
  select * into dr from distillation_runs where organization_id = p_org and id = p_corrida for update;
  if not found then
    raise exception 'NO_PERMITIDO: la corrida no existe o no es de esta empresa' using errcode = 'P0001';
  end if;
  if dr.status <> 'abierta' then
    raise exception 'NO_PERMITIDO: la corrida % ya está cerrada', dr.folio using errcode = 'P0001';
  end if;
  if p_litros is null or p_litros <= 0 then
    raise exception 'NO_PERMITIDO: los litros del corte deben ser mayores a cero' using errcode = 'P0001';
  end if;
  col := rpc_resource(p_org, p_colector, 'colector');
  if col.liquid_class <> p_clase then
    raise exception 'NO_PERMITIDO: % es un colector de % y el corte es %', col.code, col.liquid_class, p_clase
      using errcode = 'P0001';
  end if;
  select * into s from organization_settings where organization_id = p_org;
  if p_clase = 'puntas' and not coalesce(s.record_puntas, false) then
    raise exception 'NO_PERMITIDO: la captura de puntas está apagada en los ajustes de la empresa' using errcode = 'P0001';
  end if;
  perform lock_resources(p_org, array[p_colector]);

  -- Lote vivo del colector y si fue cargado a esta corrida
  v_live := live_lot(p_org, p_colector);
  if v_live is not null then
    perform lock_lots(p_org, array[v_live]);
    v_loaded := exists (
      select 1 from distillation_run_inputs dri
        join liquid_movements m on m.id = dri.movement_id
       where dri.run_id = dr.id and m.lot_id = v_live);
  end if;

  v_op := rpc_open_operation(p_org, p_idem, 'corte', p_fecha, p_nota);

  if v_live is not null and not v_loaded then
    v_lot := v_live;                              -- se acumula
  else
    v_prefix := case p_clase when 'mezcal' then 'MEZ' when 'ordinario' then 'ORD'
                             when 'colas' then 'COL' else 'PUN' end;
    insert into lots (organization_id, operation_id, folio, material, liquid_class, origin, status, history, unit)
    values (p_org, v_op, coalesce(nullif(btrim(p_folio), ''), next_folio(p_org, v_prefix)),
            'destilado', p_clase, 'producido', 'activo', 'sin_historia', 'L')
    returning id into v_lot;
  end if;

  insert into liquid_movements (organization_id, operation_id, movement_type, lot_id, dest_resource_id, volume_l, abv)
  values (p_org, v_op, 'corte', v_lot, p_colector, p_litros, p_abv);
  insert into distillation_cuts (run_id, organization_id, movement_id, cut_class)
  values (dr.id, p_org, (select id from liquid_movements where operation_id = v_op limit 1), p_clase);
  perform check_capacity(p_org, v_op, p_colector, p_litros, p_nota);

  -- Linaje proporcional a las cargas de la corrida
  select coalesce(sum(m.volume_l), 0) into v_in_total
    from distillation_run_inputs dri join liquid_movements m on m.id = dri.movement_id
   where dri.run_id = dr.id;
  if v_in_total > 0 then
    for inp in select m.lot_id, m.volume_l
                 from distillation_run_inputs dri join liquid_movements m on m.id = dri.movement_id
                where dri.run_id = dr.id loop
      v_q := round(p_litros * inp.volume_l / v_in_total, 3);
      if v_q > 0 and inp.lot_id <> v_lot then
        insert into lot_lineage (organization_id, operation_id, child_lot_id, parent_lot_id, quantity, unit)
        values (p_org, v_op, v_lot, inp.lot_id, v_q, 'L');
      end if;
    end loop;
  end if;

  perform recompute_history(p_org, v_lot);
  perform refresh_lot_status(p_org, v_lot);
  perform rpc_set_result(p_org, v_op, v_lot);
  return v_lot;
end $$;

-- cerrar_corrida → operation_id.
create function cerrar_corrida(
  p_org uuid, p_idem uuid, p_fecha timestamptz, p_corrida uuid, p_nota text default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare v_op uuid; dr distillation_runs;
begin
  perform rpc_guard(p_org, array['admin', 'productor', 'operador']::member_role[]);
  v_op := rpc_existing(p_org, p_idem);
  if v_op is not null then return v_op; end if;
  select * into dr from distillation_runs where organization_id = p_org and id = p_corrida for update;
  if not found then
    raise exception 'NO_PERMITIDO: la corrida no existe o no es de esta empresa' using errcode = 'P0001';
  end if;
  if dr.status <> 'abierta' then
    raise exception 'NO_PERMITIDO: la corrida % ya estaba cerrada', dr.folio using errcode = 'P0001';
  end if;
  v_op := rpc_open_operation(p_org, p_idem, 'cerrar_corrida', p_fecha, p_nota);
  update distillation_runs set status = 'cerrada', closed_operation_id = v_op where id = dr.id;
  return v_op;
end $$;
