-- 0020 · Completar historia hacia atrás (§6) y corregir operaciones (§12.2).
-- Nada se edita ni se borra en el ledger: se agrega.

-- completar_historia → operation_id. Liga un lote a padres existentes
-- (aristas retroactive = true) o a datos declarados de origen externo.
create function completar_historia(
  p_org uuid, p_idem uuid, p_fecha timestamptz, p_lote uuid,
  p_padres uuid[] default null, p_cantidades numeric[] default null, p_unidad text default null,
  p_proveedor uuid default null, p_proveedor_nombre text default null,
  p_folio_certificado text default null, p_organismo text default null,
  p_especie uuid default null, p_predio_declarado text default null,
  p_nota text default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare v_op uuid; i integer; l lots;
begin
  perform rpc_guard(p_org, array['admin', 'productor']::member_role[]);
  v_op := rpc_existing(p_org, p_idem);
  if v_op is not null then return v_op; end if;
  perform lock_lots(p_org, array[p_lote] || coalesce(p_padres, '{}'::uuid[]));
  select * into l from lots where id = p_lote;
  if p_padres is not null and cardinality(p_padres) <> coalesce(cardinality(p_cantidades), -1) then
    raise exception 'NO_PERMITIDO: cada padre necesita su cantidad' using errcode = 'P0001';
  end if;
  if (p_padres is null or cardinality(p_padres) = 0)
     and p_proveedor is null and nullif(btrim(p_proveedor_nombre), '') is null
     and p_especie is null and nullif(btrim(p_predio_declarado), '') is null
     and nullif(btrim(p_folio_certificado), '') is null then
    raise exception 'NO_PERMITIDO: indica padres o datos declarados de origen' using errcode = 'P0001';
  end if;

  v_op := rpc_open_operation(p_org, p_idem, 'completar_historia', p_fecha, p_nota);

  if p_padres is not null then
    for i in 1 .. cardinality(p_padres) loop
      if p_padres[i] = p_lote then
        raise exception 'NO_PERMITIDO: un lote no puede ser su propio padre' using errcode = 'P0001';
      end if;
      insert into lot_lineage (organization_id, operation_id, child_lot_id, parent_lot_id, quantity, unit, retroactive)
      values (p_org, v_op, p_lote, p_padres[i], p_cantidades[i], coalesce(p_unidad, l.unit), true);
    end loop;
  end if;

  if p_proveedor is not null or nullif(btrim(p_proveedor_nombre), '') is not null
     or p_especie is not null or nullif(btrim(p_predio_declarado), '') is not null
     or nullif(btrim(p_folio_certificado), '') is not null then
    insert into lot_external_sources (lot_id, organization_id, supplier_id, supplier_name, certificate_folio,
                                      certifying_body, declared_species_id, declared_predio)
    values (p_lote, p_org, p_proveedor, nullif(btrim(p_proveedor_nombre), ''), nullif(btrim(p_folio_certificado), ''),
            nullif(btrim(p_organismo), ''), p_especie, nullif(btrim(p_predio_declarado), ''))
    on conflict (lot_id) do update
      set supplier_id         = coalesce(excluded.supplier_id, lot_external_sources.supplier_id),
          supplier_name       = coalesce(excluded.supplier_name, lot_external_sources.supplier_name),
          certificate_folio   = coalesce(excluded.certificate_folio, lot_external_sources.certificate_folio),
          certifying_body     = coalesce(excluded.certifying_body, lot_external_sources.certifying_body),
          declared_species_id = coalesce(excluded.declared_species_id, lot_external_sources.declared_species_id),
          declared_predio     = coalesce(excluded.declared_predio, lot_external_sources.declared_predio);
  end if;

  perform recompute_history(p_org, p_lote);
  -- Los hijos del lote también cambian de nivel
  perform recompute_history(p_org, child_lot_id)
     from (select distinct child_lot_id from lot_lineage where organization_id = p_org and parent_lot_id = p_lote) c;
  perform rpc_set_result(p_org, v_op, p_lote);
  return v_op;
end $$;

-- corregir_operacion → operation_id de la corrección. Solo metadatos (nota,
-- contraparte, documento, fecha en que ocurrió); los volúmenes se corrigen
-- con un movimiento de ajuste, nunca editando el ledger (docs/DUDAS.md).
create function corregir_operacion(
  p_org uuid, p_idem uuid, p_fecha timestamptz, p_operacion uuid, p_motivo text,
  p_nota text default null, p_contraparte text default null, p_documento text default null,
  p_ocurrio timestamptz default null
) returns uuid
language plpgsql security definer set search_path = public as $$
declare v_op uuid; o operations;
begin
  perform rpc_guard(p_org, array['admin', 'productor']::member_role[]);
  v_op := rpc_existing(p_org, p_idem);
  if v_op is not null then return v_op; end if;
  if nullif(btrim(p_motivo), '') is null then
    raise exception 'REQUIERE_NOTA:corregir_operacion' using errcode = 'P0001';
  end if;
  select * into o from operations where organization_id = p_org and id = p_operacion for update;
  if not found then
    raise exception 'NO_PERMITIDO: la operación no existe o no es de esta empresa' using errcode = 'P0001';
  end if;
  if p_nota is null and p_contraparte is null and p_documento is null and p_ocurrio is null then
    raise exception 'NO_PERMITIDO: indica qué se corrige' using errcode = 'P0001';
  end if;

  v_op := rpc_open_operation(p_org, p_idem, 'correccion', p_fecha, p_motivo, null, null, null, null, null,
                             null, null, o.id);
  update operations
     set note         = coalesce(nullif(btrim(p_nota), ''), note),
         counterparty = coalesce(nullif(btrim(p_contraparte), ''), counterparty),
         document_ref = coalesce(nullif(btrim(p_documento), ''), document_ref),
         occurred_at  = coalesce(p_ocurrio, occurred_at)
   where id = o.id;
  return v_op;
end $$;
