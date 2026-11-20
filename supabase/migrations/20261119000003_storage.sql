-- =====================================================================
-- ACT — Inclusive Solutions | Migración 003: ARCHIVOS (Supabase Storage)
--
-- Bucket PRIVADO 'documentos'. Convención de rutas obligatoria:
--     <organizacion_id>/<carpeta>/<archivo>
--     ej. 6f1c.../diagnosticos/2026-11-20_informe.pdf
-- La primera carpeta decide quién puede ver el archivo.
-- =====================================================================

insert into storage.buckets (id, name, public)
values ('documentos', 'documentos', false)
on conflict (id) do nothing;

-- Devuelve el organizacion_id de una ruta, o null si no empieza con un uuid
create or replace function public.org_de_ruta(ruta text)
returns uuid language sql immutable
set search_path = ''
as $$
  select case
    when split_part(ruta, '/', 1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    then split_part(ruta, '/', 1)::uuid
  end;
$$;

create policy documentos_ver on storage.objects for select to authenticated
  using (bucket_id = 'documentos' and public.tiene_acceso(public.org_de_ruta(name)));

create policy documentos_subir on storage.objects for insert to authenticated
  with check (bucket_id = 'documentos' and public.puede_editar(public.org_de_ruta(name)));

create policy documentos_editar on storage.objects for update to authenticated
  using (bucket_id = 'documentos' and public.puede_editar(public.org_de_ruta(name)))
  with check (bucket_id = 'documentos' and public.puede_editar(public.org_de_ruta(name)));

create policy documentos_borrar on storage.objects for delete to authenticated
  using (bucket_id = 'documentos' and public.puede_editar(public.org_de_ruta(name)));
