-- 0015 · Entradas al sistema: recepción de maguey (§4.1) y entrada directa
-- en cualquier etapa salvo molienda (§2 principio 1, §12.2 registrar_entrada).

-- registrar_recepcion_maguey → lot_id. kg obligatorio; lo demás opcional.
create function registrar_recepcion_maguey(
  p_org uuid, p_idem uuid, p_fecha timestamptz, p_kg numeric,
  p_especie uuid default null, p_predio uuid default null, p_proveedor uuid default null,
  p_pinas integer default null, p_nota text default null, p_folio text default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare v_op uuid; v_lot uuid; v_folio text;
begin
  perform rpc_guard(p_org, array['admin', 'productor']::member_role[]);
  v_op := rpc_existing(p_org, p_idem);
  if v_op is not null then
    return (select result_lot_id from operations where id = v_op);
  end if;
  if p_kg is null or p_kg <= 0 then
    raise exception 'NO_PERMITIDO: los kilos son obligatorios y deben ser mayores a cero' using errcode = 'P0001';
  end if;

  v_op := rpc_open_operation(p_org, p_idem, 'recepcion_maguey', p_fecha, p_nota);
  v_folio := coalesce(nullif(btrim(p_folio), ''), next_folio(p_org, 'MAG'));

  insert into lots (organization_id, operation_id, folio, material, origin, status, history, unit, initial_quantity, notes)
  values (p_org, v_op, v_folio, 'maguey', 'producido', 'activo', 'completa', 'kg', p_kg, nullif(btrim(p_nota), ''))
  returning id into v_lot;

  insert into maguey_receptions (lot_id, organization_id, species_id, predio_id, supplier_id, pina_count, weight_kg, quality_note)
  values (v_lot, p_org, p_especie, p_predio, p_proveedor, p_pinas, p_kg, nullif(btrim(p_nota), ''));

  perform rpc_set_result(p_org, v_op, v_lot);
  return v_lot;
end $$;

-- registrar_entrada → lot_id. Cualquier etapa salvo molienda. Crea el lote
-- con origin 'carga_inicial' (history sin_historia) o 'compra' (declarada,
-- con datos externos opcionales). Un 'fermentado' abre ciclo en la tina.
create function registrar_entrada(
  p_org uuid, p_idem uuid, p_fecha timestamptz,
  p_material material_kind, p_recurso uuid, p_cantidad numeric,
  p_abv numeric default null, p_clase liquid_class default null,
  p_origen lot_origin default 'carga_inicial', p_concepto uuid default null,
  p_proveedor uuid default null, p_proveedor_nombre text default null,
  p_folio_certificado text default null, p_organismo text default null,
  p_especie uuid default null, p_predio_declarado text default null,
  p_contraparte text default null, p_documento text default null,
  p_nota text default null, p_folio text default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_op uuid; v_lot uuid; v_folio text; r resources;
  v_liquid boolean := p_material in ('fermentado', 'destilado', 'granel');
  v_class liquid_class := p_clase;
  v_prefix text;
begin
  perform rpc_guard(p_org, array['admin', 'productor']::member_role[]);
  v_op := rpc_existing(p_org, p_idem);
  if v_op is not null then
    return (select result_lot_id from operations where id = v_op);
  end if;
  if p_material = 'formulacion' then
    raise exception 'NO_PERMITIDO: la molienda no tiene entrada directa; una tina que ya fermentaba entra por fermentación'
      using errcode = 'P0001';
  end if;
  if p_origen not in ('carga_inicial', 'compra') then
    raise exception 'NO_PERMITIDO: una entrada directa solo puede ser carga inicial o compra' using errcode = 'P0001';
  end if;
  if p_cantidad is null or p_cantidad <= 0 then
    raise exception 'NO_PERMITIDO: la cantidad debe ser mayor a cero' using errcode = 'P0001';
  end if;

  if v_liquid then
    if p_recurso is null then
      raise exception 'NO_PERMITIDO: un líquido necesita el recurso donde está' using errcode = 'P0001';
    end if;
    perform lock_resources(p_org, array[p_recurso]);
    r := rpc_resource(p_org, p_recurso);
    if p_material = 'fermentado' and r.kind <> 'tina' then
      raise exception 'NO_PERMITIDO: un fermentado entra en una tina' using errcode = 'P0001';
    elsif p_material = 'destilado' and r.kind <> 'colector' then
      raise exception 'NO_PERMITIDO: un destilado entra en un colector' using errcode = 'P0001';
    elsif p_material = 'granel' and r.kind <> 'tanque' then
      raise exception 'NO_PERMITIDO: el granel entra en un tanque' using errcode = 'P0001';
    end if;
    if p_material = 'destilado' then v_class := r.liquid_class; end if;
    if p_material = 'granel' then v_class := coalesce(v_class, 'mezcal'); end if;
  end if;

  v_op := rpc_open_operation(p_org, p_idem, 'entrada_directa', p_fecha, p_nota, p_concepto,
                             case when v_liquid then p_recurso end,
                             case when v_liquid then p_cantidad end,
                             case when v_liquid then p_abv end,
                             null, p_contraparte, p_documento);

  v_prefix := case p_material when 'maguey' then 'MAG' when 'agave_cocido' then 'AC'
                              when 'fermentado' then 'FER' when 'destilado' then 'DES' else 'G' end;
  v_folio := coalesce(nullif(btrim(p_folio), ''), next_folio(p_org, v_prefix));

  insert into lots (organization_id, operation_id, folio, material, liquid_class, origin, status, history,
                    unit, initial_quantity, declared_origin, notes)
  values (p_org, v_op, v_folio, p_material, v_class, p_origen, 'activo',
          case when p_origen = 'compra' then 'declarada' else 'sin_historia' end::history_level,
          case when v_liquid then 'L' else 'kg' end,
          case when v_liquid then null else p_cantidad end,
          case when p_origen = 'compra' then nullif(btrim(p_predio_declarado), '') end,
          nullif(btrim(p_nota), ''))
  returning id into v_lot;

  if v_liquid then
    insert into liquid_movements (organization_id, operation_id, movement_type, lot_id, dest_resource_id, volume_l, abv)
    values (p_org, v_op, 'entrada', v_lot, p_recurso, p_cantidad, p_abv);
    perform check_capacity(p_org, v_op, p_recurso, p_cantidad, p_nota);
    if p_material = 'fermentado' then
      begin
        insert into fermentation_cycles (organization_id, operation_id, tina_id, lot_id, status)
        values (p_org, v_op, p_recurso, v_lot, 'fermentando');
      exception when unique_violation then
        raise exception 'NO_PERMITIDO: la tina % ya tiene un ciclo abierto', r.code using errcode = 'P0001';
      end;
    end if;
  end if;

  if p_origen = 'compra' then
    insert into lot_external_sources (lot_id, organization_id, supplier_id, supplier_name, certificate_folio,
                                      certifying_body, declared_species_id, declared_predio)
    values (v_lot, p_org, p_proveedor, nullif(btrim(p_proveedor_nombre), ''), nullif(btrim(p_folio_certificado), ''),
            nullif(btrim(p_organismo), ''), p_especie, nullif(btrim(p_predio_declarado), ''));
  end if;

  perform rpc_set_result(p_org, v_op, v_lot);
  return v_lot;
end $$;
