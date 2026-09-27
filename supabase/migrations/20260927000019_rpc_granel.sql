-- 0019 · Granel (§5): transferir entre recursos y el catálogo de movimientos
-- de entrada/salida. El sistema NO calcula el grado: en cada entrada quien la
-- hace declara volumen y % Alc. resultantes; si el volumen declarado no
-- cuadra con el ledger, pata 'conciliacion' automática + aviso.

-- Une el lote p_from (que está en p_from_res) al lote p_into (en p_dest):
-- consumo + entrada + linaje. Devuelve nada; es interno.
create function rpc_merge_into(
  p_org uuid, p_op uuid, p_from uuid, p_from_res uuid, p_into uuid, p_dest uuid,
  p_litros numeric, p_abv numeric
) returns void
language plpgsql security definer set search_path = public as $$
begin
  insert into liquid_movements (organization_id, operation_id, movement_type, lot_id, source_resource_id, volume_l)
  values (p_org, p_op, 'consumo', p_from, p_from_res, p_litros);
  insert into liquid_movements (organization_id, operation_id, movement_type, lot_id, dest_resource_id, volume_l, abv)
  values (p_org, p_op, 'entrada', p_into, p_dest, p_litros, p_abv);
  insert into lot_lineage (organization_id, operation_id, child_lot_id, parent_lot_id, quantity, unit, abv)
  values (p_org, p_op, p_into, p_from, p_litros, 'L', p_abv);
end $$;
revoke execute on function rpc_merge_into(uuid, uuid, uuid, uuid, uuid, uuid, numeric, numeric) from public, anon, authenticated;

-- transferir → lot_id resultante. Si el destino ya tiene lote, el usuario
-- decide: 'conservar' un folio (por defecto, el del destino) o 'renombrar'
-- (folio nuevo). En ambos casos se guarda el aporte de cada uno.
create function transferir(
  p_org uuid, p_idem uuid, p_fecha timestamptz,
  p_origen uuid, p_destino uuid, p_lote uuid, p_litros numeric,
  p_abv numeric default null, p_decision folio_decision default null,
  p_folio_nuevo text default null, p_nota text default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_op uuid; v_res uuid; v_live uuid; v_live_bal numeric; v_bal numeric; v_abv numeric;
  src resources; dst resources; l lots; s organization_settings; v_dec folio_decision;
  v_material material_kind;
begin
  perform rpc_guard(p_org, array['admin', 'productor']::member_role[]);
  v_op := rpc_existing(p_org, p_idem);
  if v_op is not null then
    return (select result_lot_id from operations where id = v_op);
  end if;
  if p_litros is null or p_litros <= 0 then
    raise exception 'NO_PERMITIDO: los litros deben ser mayores a cero' using errcode = 'P0001';
  end if;
  if p_origen = p_destino then
    raise exception 'NO_PERMITIDO: origen y destino son el mismo recurso' using errcode = 'P0001';
  end if;
  src := rpc_resource(p_org, p_origen);
  dst := rpc_resource(p_org, p_destino);
  if dst.kind not in ('tanque', 'colector') then
    raise exception 'NO_PERMITIDO: solo se transfiere hacia un tanque o un colector' using errcode = 'P0001';
  end if;
  perform lock_resources(p_org, array[p_origen, p_destino]);
  perform lock_lots(p_org, array[p_lote]);
  select * into l from lots where id = p_lote;
  if dst.kind = 'colector' and dst.liquid_class is distinct from l.liquid_class then
    raise exception 'NO_PERMITIDO: % es un colector de % y el lote es %', dst.code, dst.liquid_class, l.liquid_class
      using errcode = 'P0001';
  end if;
  v_bal := lot_balance(p_org, p_origen, p_lote);
  if v_bal < p_litros then
    raise exception 'SALDO_INSUFICIENTE: % tiene % L del lote % y se piden % L', src.code, v_bal, l.folio, p_litros
      using errcode = 'P0001';
  end if;

  select * into s from organization_settings where organization_id = p_org;
  v_dec := coalesce(p_decision, s.default_folio_decision, 'conservar');
  v_abv := coalesce(p_abv, (select abv from lot_declared_abv where organization_id = p_org and lot_id = p_lote));
  v_live := live_lot(p_org, p_destino);
  if v_live is not null then
    perform lock_lots(p_org, array[v_live]);
    v_live_bal := lot_balance(p_org, p_destino, v_live);
  end if;
  v_material := case when dst.kind = 'tanque' then 'granel' else l.material end;

  v_op := rpc_open_operation(p_org, p_idem, 'transferencia', p_fecha, p_nota, null, p_destino, null, p_abv, v_dec);

  if v_live is null or v_live = p_lote then
    if v_dec = 'renombrar' or (v_live is null and dst.kind = 'tanque' and l.material <> 'granel') then
      -- Nace folio nuevo (al entrar a granel el destilado se vuelve granel)
      insert into lots (organization_id, operation_id, folio, material, liquid_class, origin, status, history, unit)
      values (p_org, v_op, coalesce(nullif(btrim(p_folio_nuevo), ''), next_folio(p_org, 'G')),
              v_material, l.liquid_class, 'producido', 'activo', 'sin_historia', 'L')
      returning id into v_res;
      perform rpc_merge_into(p_org, v_op, p_lote, p_origen, v_res, p_destino, p_litros, v_abv);
    else
      -- Mismo lote cambia de recurso
      insert into liquid_movements (organization_id, operation_id, movement_type, lot_id, source_resource_id, dest_resource_id, volume_l, abv)
      values (p_org, v_op, 'transferencia', p_lote, p_origen, p_destino, p_litros, v_abv);
      v_res := p_lote;
    end if;
  elsif v_dec = 'conservar' then
    -- Se conserva el folio del lote que ya está en el destino
    v_res := v_live;
    perform rpc_merge_into(p_org, v_op, p_lote, p_origen, v_res, p_destino, p_litros, v_abv);
  else
    -- Renombrar: los dos se consumen y nace uno nuevo con el aporte de cada uno
    insert into lots (organization_id, operation_id, folio, material, liquid_class, origin, status, history, unit)
    values (p_org, v_op, coalesce(nullif(btrim(p_folio_nuevo), ''), next_folio(p_org, 'G')),
            v_material, l.liquid_class, 'mezcla', 'activo', 'sin_historia', 'L')
    returning id into v_res;
    perform rpc_merge_into(p_org, v_op, p_lote, p_origen, v_res, p_destino, p_litros, v_abv);
    perform rpc_merge_into(p_org, v_op, v_live, p_destino, v_res, p_destino, v_live_bal,
                           (select abv from lot_declared_abv where organization_id = p_org and lot_id = v_live));
    perform refresh_lot_status(p_org, v_live);
  end if;

  perform check_capacity(p_org, v_op, p_destino, p_litros, p_nota);
  perform refresh_lot_status(p_org, p_lote);
  perform refresh_lot_status(p_org, v_res);
  perform recompute_history(p_org, v_res);
  perform rpc_set_result(p_org, v_op, v_res, lot_balance(p_org, p_destino, v_res), p_abv);
  return v_res;
end $$;

-- registrar_movimiento_granel → lot_id afectado o creado. Cualquier
-- concepto del catálogo de la empresa (§5.2): su comportamiento
-- (source_lot, creates_lot, asks_result, asks_counterparty) manda.
create function registrar_movimiento_granel(
  p_org uuid, p_idem uuid, p_fecha timestamptz,
  p_concepto uuid, p_tanque uuid, p_litros numeric,
  p_lote uuid default null,
  p_lote_origen uuid default null, p_recurso_origen uuid default null,
  p_resultado_l numeric default null, p_resultado_abv numeric default null,
  p_abv numeric default null,
  p_decision folio_decision default null, p_folio_nuevo text default null,
  p_contraparte text default null, p_documento text default null,
  p_proveedor uuid default null, p_proveedor_nombre text default null,
  p_folio_certificado text default null, p_organismo text default null,
  p_especie uuid default null, p_predio_declarado text default null,
  p_nota text default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_op uuid; v_target uuid; v_live uuid; v_live_bal numeric; v_bal numeric; v_ledger numeric; v_diff numeric;
  c movement_concepts; tk resources; s organization_settings; v_dec folio_decision; v_abv numeric; lf lots;
begin
  perform rpc_guard(p_org, array['admin', 'productor']::member_role[]);
  v_op := rpc_existing(p_org, p_idem);
  if v_op is not null then
    return (select result_lot_id from operations where id = v_op);
  end if;
  select * into c from movement_concepts where organization_id = p_org and id = p_concepto and active;
  if not found then
    raise exception 'NO_PERMITIDO: el concepto no existe, está desactivado o no es de esta empresa' using errcode = 'P0001';
  end if;
  if p_litros is null or p_litros <= 0 then
    raise exception 'NO_PERMITIDO: los litros deben ser mayores a cero' using errcode = 'P0001';
  end if;
  if c.asks_counterparty and nullif(btrim(p_contraparte), '') is null then
    raise exception 'REQUIERE_NOTA:contraparte' using errcode = 'P0001';
  end if;
  if c.direction = 'entrada' and c.asks_result and p_resultado_l is null then
    raise exception 'NO_PERMITIDO: este concepto pide declarar el volumen resultante' using errcode = 'P0001';
  end if;
  tk := rpc_resource(p_org, p_tanque, 'tanque');
  perform lock_resources(p_org, array[p_tanque] || coalesce(array[p_recurso_origen], '{}'::uuid[]));
  select * into s from organization_settings where organization_id = p_org;
  v_dec := coalesce(p_decision, s.default_folio_decision, 'conservar');

  v_op := rpc_open_operation(p_org, p_idem, 'movimiento_granel', p_fecha, p_nota, c.id, p_tanque,
                             p_resultado_l, p_resultado_abv, case when c.source_lot = 'requerido' then v_dec end,
                             p_contraparte, p_documento);

  if c.direction = 'salida' then
    v_target := coalesce(p_lote, live_lot(p_org, p_tanque));
    if v_target is null then
      raise exception 'NO_PERMITIDO: el tanque % está vacío', tk.code using errcode = 'P0001';
    end if;
    perform lock_lots(p_org, array[v_target]);
    v_bal := lot_balance(p_org, p_tanque, v_target);
    if v_bal < p_litros then
      raise exception 'SALDO_INSUFICIENTE: % tiene % L y se quieren sacar % L', tk.code, v_bal, p_litros
        using errcode = 'P0001';
    end if;
    insert into liquid_movements (organization_id, operation_id, movement_type, lot_id, source_resource_id, volume_l)
    values (p_org, v_op, 'salida', v_target, p_tanque, p_litros);

  elsif c.creates_lot then
    -- Compra de granel o carga inicial: nace un lote en el tanque
    insert into lots (organization_id, operation_id, folio, material, liquid_class, origin, status, history, unit, declared_origin)
    values (p_org, v_op, coalesce(nullif(btrim(p_folio_nuevo), ''), next_folio(p_org, 'G')), 'granel', 'mezcal',
            case when c.asks_counterparty then 'compra' else 'carga_inicial' end::lot_origin, 'activo',
            case when c.asks_counterparty then 'declarada' else 'sin_historia' end::history_level, 'L',
            nullif(btrim(p_predio_declarado), ''))
    returning id into v_target;
    insert into liquid_movements (organization_id, operation_id, movement_type, lot_id, dest_resource_id, volume_l, abv)
    values (p_org, v_op, 'entrada', v_target, p_tanque, p_litros, coalesce(p_abv, p_resultado_abv));
    if c.asks_counterparty then
      insert into lot_external_sources (lot_id, organization_id, supplier_id, supplier_name, certificate_folio,
                                        certifying_body, declared_species_id, declared_predio)
      values (v_target, p_org, p_proveedor, coalesce(nullif(btrim(p_proveedor_nombre), ''), nullif(btrim(p_contraparte), '')),
              nullif(btrim(p_folio_certificado), ''), nullif(btrim(p_organismo), ''), p_especie,
              nullif(btrim(p_predio_declarado), ''));
    end if;

  elsif c.source_lot = 'requerido' or (c.source_lot = 'opcional' and p_lote_origen is not null) then
    -- Unión con otro lote (o puntas que sí vienen de un lote)
    if p_lote_origen is null or p_recurso_origen is null then
      raise exception 'NO_PERMITIDO: este concepto pide el lote de origen y dónde está' using errcode = 'P0001';
    end if;
    perform lock_lots(p_org, array[p_lote_origen]);
    v_bal := lot_balance(p_org, p_recurso_origen, p_lote_origen);
    if v_bal < p_litros then
      raise exception 'SALDO_INSUFICIENTE: el lote de origen tiene % L y se piden % L', v_bal, p_litros
        using errcode = 'P0001';
    end if;
    v_abv := coalesce(p_abv, (select abv from lot_declared_abv where organization_id = p_org and lot_id = p_lote_origen));
    v_live := coalesce(p_lote, live_lot(p_org, p_tanque));
    if v_live is not null then perform lock_lots(p_org, array[v_live]); end if;
    if v_live is null or v_dec = 'conservar' then
      if v_live is null then
        -- tanque vacío: el lote de origen simplemente entra con folio nuevo (o el suyo)
        select * into lf from lots where id = p_lote_origen;
        insert into lots (organization_id, operation_id, folio, material, liquid_class, origin, status, history, unit)
        values (p_org, v_op, coalesce(nullif(btrim(p_folio_nuevo), ''), next_folio(p_org, 'G')), 'granel',
                lf.liquid_class, 'producido', 'activo', 'sin_historia', 'L')
        returning id into v_target;
      else
        v_target := v_live;
      end if;
      perform rpc_merge_into(p_org, v_op, p_lote_origen, p_recurso_origen, v_target, p_tanque, p_litros, v_abv);
    else
      v_live_bal := lot_balance(p_org, p_tanque, v_live);
      insert into lots (organization_id, operation_id, folio, material, liquid_class, origin, status, history, unit)
      values (p_org, v_op, coalesce(nullif(btrim(p_folio_nuevo), ''), next_folio(p_org, 'G')), 'granel', 'mezcal',
              'mezcla', 'activo', 'sin_historia', 'L')
      returning id into v_target;
      perform rpc_merge_into(p_org, v_op, p_lote_origen, p_recurso_origen, v_target, p_tanque, p_litros, v_abv);
      perform rpc_merge_into(p_org, v_op, v_live, p_tanque, v_target, p_tanque, v_live_bal,
                             (select abv from lot_declared_abv where organization_id = p_org and lot_id = v_live));
      perform refresh_lot_status(p_org, v_live);
    end if;
    perform refresh_lot_status(p_org, p_lote_origen);

  else
    -- Agua, puntas sin lote, ajuste (+): entra al lote que está en el tanque
    v_target := coalesce(p_lote, live_lot(p_org, p_tanque));
    if v_target is null then
      raise exception 'NO_PERMITIDO: el tanque % está vacío; usa carga inicial o compra', tk.code using errcode = 'P0001';
    end if;
    perform lock_lots(p_org, array[v_target]);
    insert into liquid_movements (organization_id, operation_id, movement_type, lot_id, dest_resource_id, volume_l, abv)
    values (p_org, v_op, 'entrada', v_target, p_tanque, p_litros, p_abv);
  end if;

  -- Entradas: conciliar el volumen declarado con el ledger (§5.1)
  if c.direction = 'entrada' and p_resultado_l is not null then
    v_ledger := lot_balance(p_org, p_tanque, v_target);
    v_diff := round(p_resultado_l - v_ledger, 3);
    if abs(v_diff) >= 0.001 then
      if v_diff > 0 then
        insert into liquid_movements (organization_id, operation_id, movement_type, lot_id, dest_resource_id, volume_l)
        values (p_org, v_op, 'conciliacion', v_target, p_tanque, v_diff);
      else
        insert into liquid_movements (organization_id, operation_id, movement_type, lot_id, source_resource_id, volume_l)
        values (p_org, v_op, 'conciliacion', v_target, p_tanque, -v_diff);
      end if;
      perform rpc_warn(p_org, v_op, 'diferencia_volumen', p_nota,
                       format('Declarado %s L; ledger %s L.', p_resultado_l, v_ledger));
    end if;
    if p_resultado_abv is not null and (p_resultado_abv < s.abv_warn_min or p_resultado_abv > s.abv_warn_max) then
      perform rpc_warn(p_org, v_op, 'abv_fuera_rango', p_nota);
    end if;
    perform check_capacity(p_org, v_op, p_tanque, p_litros, p_nota);
  end if;

  perform refresh_lot_status(p_org, v_target);
  perform recompute_history(p_org, v_target);
  perform rpc_set_result(p_org, v_op, v_target);
  return v_target;
end $$;
