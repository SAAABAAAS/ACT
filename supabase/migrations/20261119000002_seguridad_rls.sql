-- =====================================================================
-- ACT — Inclusive Solutions | Migración 002: SEGURIDAD (RLS)
--
-- En Supabase TODA tabla del esquema public queda expuesta por la API.
-- Sin Row Level Security, cualquiera con la llave pública podría leer
-- los datos de todos los clientes. Esta migración:
--   * activa RLS en todas las tablas,
--   * define quién ve y quién edita qué,
--   * crea el perfil automáticamente cuando alguien se registra,
--   * impide que un usuario se convierta solo en "equipo ACT".
--
-- Modelo de acceso:
--   equipo ACT (perfiles.es_equipo_act)  -> ve y edita todo
--   admin_cliente / responsable_sst      -> ve y edita SU empresa
--   lectura                              -> solo ve SU empresa
--   anónimo (sin login)                  -> nada
-- =====================================================================

-- ---------------------------------------------------------------------
-- Funciones de ayuda (security definer: leen perfiles/membresías sin
-- quedar atrapadas en las propias políticas RLS)
-- ---------------------------------------------------------------------
create or replace function public.es_equipo_act()
returns boolean language sql stable security definer
set search_path = ''
as $$
  select coalesce(
    (select p.es_equipo_act from public.perfiles p where p.id = auth.uid()),
    false);
$$;

create or replace function public.tiene_acceso(org uuid)
returns boolean language sql stable security definer
set search_path = ''
as $$
  select public.es_equipo_act()
      or exists (select 1 from public.membresias m
                 where m.perfil_id = auth.uid() and m.organizacion_id = org);
$$;

create or replace function public.puede_editar(org uuid)
returns boolean language sql stable security definer
set search_path = ''
as $$
  select public.es_equipo_act()
      or exists (select 1 from public.membresias m
                 where m.perfil_id = auth.uid() and m.organizacion_id = org
                   and m.rol in ('admin_cliente', 'responsable_sst'));
$$;

-- ---------------------------------------------------------------------
-- Perfil automático al registrarse (auth.users -> public.perfiles)
-- ---------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer
set search_path = ''
as $$
begin
  insert into public.perfiles (id, nombre, email)
  values (new.id,
          coalesce(new.raw_user_meta_data ->> 'nombre', split_part(new.email, '@', 1)),
          new.email);
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------
-- Nadie se da a sí mismo el rango "equipo ACT".
-- Excepción: sin sesión (auth.uid() nulo) = SQL Editor / backend con
-- service_role, que es como se nombra al primer administrador.
-- ---------------------------------------------------------------------
create or replace function public.tg_proteger_equipo_act()
returns trigger language plpgsql
set search_path = ''
as $$
begin
  if auth.uid() is not null and not public.es_equipo_act() then
    if (tg_op = 'INSERT' and new.es_equipo_act)
       or (tg_op = 'UPDATE' and new.es_equipo_act is distinct from old.es_equipo_act) then
      raise exception 'Solo el equipo ACT puede otorgar el rol de equipo ACT';
    end if;
    if tg_op = 'UPDATE' and new.email is distinct from old.email then
      raise exception 'El email se cambia desde la autenticación, no desde el perfil';
    end if;
  end if;
  return new;
end $$;

create trigger proteger_equipo_act
  before insert or update on public.perfiles
  for each row execute function public.tg_proteger_equipo_act();

-- ---------------------------------------------------------------------
-- Activar RLS en todas las tablas
-- ---------------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array[
    'organizaciones', 'perfiles', 'membresias', 'sedes', 'areas', 'puestos',
    'trabajadores', 'fuentes_normativas', 'requisitos', 'diagnosticos',
    'diagnostico_items', 'tipos_riesgo', 'evaluaciones_riesgo', 'acciones',
    'capacitaciones', 'capacitacion_asistentes', 'documentos', 'consultas_ia',
    'consultas_ia_borradores', 'consultas_ia_fuentes']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on public.%I from anon', t);
  end loop;
end $$;

revoke all on public.normativa_para_agente from anon;
revoke all on public.resumen_diagnosticos  from anon;

-- ---------------------------------------------------------------------
-- Tablas de datos de cada empresa (tienen organizacion_id)
--   ver: cualquier miembro | crear/editar/borrar: admin_cliente,
--   responsable_sst o equipo ACT
-- ---------------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array[
    'sedes', 'areas', 'puestos', 'trabajadores', 'diagnosticos',
    'evaluaciones_riesgo', 'acciones', 'capacitaciones', 'documentos']
  loop
    execute format($f$
      create policy %1$s_ver on public.%1$I for select to authenticated
        using (public.tiene_acceso(organizacion_id));
      create policy %1$s_crear on public.%1$I for insert to authenticated
        with check (public.puede_editar(organizacion_id));
      create policy %1$s_editar on public.%1$I for update to authenticated
        using (public.puede_editar(organizacion_id))
        with check (public.puede_editar(organizacion_id));
      create policy %1$s_borrar on public.%1$I for delete to authenticated
        using (public.puede_editar(organizacion_id));
    $f$, t);
  end loop;
end $$;

-- Tablas hijas sin organizacion_id: heredan el permiso del padre
create policy diagnostico_items_ver on public.diagnostico_items for select to authenticated
  using (exists (select 1 from public.diagnosticos d
                 where d.id = diagnostico_id and public.tiene_acceso(d.organizacion_id)));
create policy diagnostico_items_escribir on public.diagnostico_items for all to authenticated
  using (exists (select 1 from public.diagnosticos d
                 where d.id = diagnostico_id and public.puede_editar(d.organizacion_id)))
  with check (exists (select 1 from public.diagnosticos d
                 where d.id = diagnostico_id and public.puede_editar(d.organizacion_id)));

create policy asistentes_ver on public.capacitacion_asistentes for select to authenticated
  using (exists (select 1 from public.capacitaciones c
                 where c.id = capacitacion_id and public.tiene_acceso(c.organizacion_id)));
create policy asistentes_escribir on public.capacitacion_asistentes for all to authenticated
  using (exists (select 1 from public.capacitaciones c
                 where c.id = capacitacion_id and public.puede_editar(c.organizacion_id)))
  with check (exists (select 1 from public.capacitaciones c
                 where c.id = capacitacion_id and public.puede_editar(c.organizacion_id)));

-- ---------------------------------------------------------------------
-- Organizaciones: el cliente ve la suya; solo ACT crea o modifica
-- ---------------------------------------------------------------------
create policy organizaciones_ver on public.organizaciones for select to authenticated
  using (public.tiene_acceso(id));
create policy organizaciones_escribir on public.organizaciones for all to authenticated
  using (public.es_equipo_act()) with check (public.es_equipo_act());

-- ---------------------------------------------------------------------
-- Perfiles: me veo a mí, a mis compañeros de empresa y ACT ve a todos
-- ---------------------------------------------------------------------
create policy perfiles_ver on public.perfiles for select to authenticated
  using (id = auth.uid()
         or public.es_equipo_act()
         or exists (select 1 from public.membresias yo
                    join public.membresias otro on otro.organizacion_id = yo.organizacion_id
                    where yo.perfil_id = auth.uid() and otro.perfil_id = perfiles.id));
create policy perfiles_editar on public.perfiles for update to authenticated
  using (id = auth.uid() or public.es_equipo_act())
  with check (id = auth.uid() or public.es_equipo_act());
-- (los perfiles se crean solos con handle_new_user; no hay política de insert)

-- ---------------------------------------------------------------------
-- Membresías: cada uno ve las suyas, el admin del cliente ve las de su
-- empresa; solo ACT asigna o quita accesos
-- ---------------------------------------------------------------------
create policy membresias_ver on public.membresias for select to authenticated
  using (perfil_id = auth.uid() or public.puede_editar(organizacion_id));
create policy membresias_escribir on public.membresias for all to authenticated
  using (public.es_equipo_act()) with check (public.es_equipo_act());

-- ---------------------------------------------------------------------
-- Catálogos compartidos: cualquier usuario con sesión los lee;
-- solo ACT los mantiene
-- ---------------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array['tipos_riesgo', 'fuentes_normativas', 'requisitos']
  loop
    execute format($f$
      create policy %1$s_ver on public.%1$I for select to authenticated using (true);
      create policy %1$s_escribir on public.%1$I for all to authenticated
        using (public.es_equipo_act()) with check (public.es_equipo_act());
    $f$, t);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- Agente de IA
--   cliente: pregunta y ve el estado + respuesta_final de su empresa
--   ACT: ve borradores, revisa, aprueba y cita fuentes
-- ---------------------------------------------------------------------
create policy consultas_ver on public.consultas_ia for select to authenticated
  using (public.tiene_acceso(organizacion_id) or public.es_equipo_act());
create policy consultas_crear on public.consultas_ia for insert to authenticated
  with check (
    public.es_equipo_act()
    or (public.tiene_acceso(organizacion_id)
        and solicitado_por = auth.uid()
        and estado_revision = 'pendiente'
        and respuesta_final is null));
create policy consultas_revisar on public.consultas_ia for update to authenticated
  using (public.es_equipo_act()) with check (public.es_equipo_act());
create policy consultas_borrar on public.consultas_ia for delete to authenticated
  using (public.es_equipo_act());

create policy borradores_solo_act on public.consultas_ia_borradores for all to authenticated
  using (public.es_equipo_act()) with check (public.es_equipo_act());

create policy fuentes_citadas_ver on public.consultas_ia_fuentes for select to authenticated
  using (exists (select 1 from public.consultas_ia c
                 where c.id = consulta_id
                   and (public.tiene_acceso(c.organizacion_id) or public.es_equipo_act())));
create policy fuentes_citadas_escribir on public.consultas_ia_fuentes for all to authenticated
  using (public.es_equipo_act()) with check (public.es_equipo_act());
