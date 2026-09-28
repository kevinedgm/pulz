-- 0027 · Evidencias: bucket PRIVADO 'evidencias' para fotos y documentos
-- (PULZ_MAESTRO.md §8.1 "Archivos", §8.3 fotos en la cola offline, tabla
-- attachments de 0008). La ruta del objeto es '<organization_id>/...' y la
-- RLS de storage.objects impone la empresa; leer y subir puede cualquier
-- miembro (una foto de medición la toma el operador); nadie borra ni
-- reemplaza desde el navegador: una evidencia es evidencia.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('evidencias', 'evidencias', false, 10485760,
        array['image/jpeg', 'image/png', 'image/webp', 'application/pdf'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

create policy evidencias_select on storage.objects for select to authenticated
  using (bucket_id = 'evidencias' and (select is_member(storage_org_of(name))));

create policy evidencias_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'evidencias' and (select is_member(storage_org_of(name))));

-- La fila de attachments la crea quien subió el archivo (cualquier miembro:
-- 0013 solo da lectura). La FK compuesta garantiza que la operación y el
-- lote sean de la misma empresa; el trigger de 0008, que el tipo sea
-- 'tipo_adjunto'. No hay update ni delete: una evidencia no se edita.
grant insert on attachments to authenticated;
create policy attachments_insert on attachments for insert to authenticated
  with check ((select is_member(organization_id)));
