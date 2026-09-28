-- 0024 · Marca del portal: bucket público 'branding' para los logos
-- (PULZ_MAESTRO.md §7.1, §8.1 "Archivos"). organizations.logo_path guarda
-- '<organization_id>/<archivo>' y portal_branding lo publica.
--
-- Lectura: pública (el portal se ve antes de iniciar sesión).
-- Escritura: solo el administrador de la empresa, solo bajo su carpeta
-- '<organization_id>/' (la RLS de storage.objects lo impone; el navegador no
-- decide). Tamaño ≤ 2 MB y solo mapas de bits (nada de SVG: puede llevar
-- script y se sirve público).

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('branding', 'branding', true, 2097152, array['image/png', 'image/jpeg', 'image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- La carpeta raíz del objeto es la empresa: 'b66cf468-…/logo.png'
create function branding_org_of(p_name text) returns uuid
language sql immutable set search_path = public as $$
  select case when (storage.foldername(p_name))[1] ~ '^[0-9a-f-]{36}$'
              then (storage.foldername(p_name))[1]::uuid end;
$$;

create policy branding_select on storage.objects for select to public
  using (bucket_id = 'branding');

create policy branding_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'branding'
              and (select has_role(branding_org_of(name), array['admin']::member_role[])));

create policy branding_update on storage.objects for update to authenticated
  using (bucket_id = 'branding'
         and (select has_role(branding_org_of(name), array['admin']::member_role[])))
  with check (bucket_id = 'branding'
              and (select has_role(branding_org_of(name), array['admin']::member_role[])));

create policy branding_delete on storage.objects for delete to authenticated
  using (bucket_id = 'branding'
         and (select has_role(branding_org_of(name), array['admin']::member_role[])));
