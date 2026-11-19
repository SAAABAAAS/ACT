-- =====================================================================
-- ACT — Inclusive Solutions | Migración 001: NÚCLEO (MVP v0)
-- Base de datos: PostgreSQL 15+ (Supabase)
--
-- Contenido:
--   empresas cliente, usuarios y roles, estructura de la empresa
--   (sedes, áreas, puestos, trabajadores), matriz de riesgos, plan de
--   acción, normativa verificada, diagnóstico de cumplimiento,
--   capacitaciones, documentos y registro de consultas al agente de IA.
--
-- Reglas de oro:
--   1. La normativa solo la usa el agente si una PERSONA la verificó
--      contra la fuente oficial (columna fuentes_normativas.verificada).
--   2. Ninguna respuesta de IA llega al cliente sin revisión humana.
--   3. Datos de salud y discapacidad NO van en este núcleo: irán en una
--      migración aparte con acceso restringido y consentimiento.
-- =====================================================================

create extension if not exists pgcrypto;  -- gen_random_uuid()

-- ---------------------------------------------------------------------
-- Tipos enumerados
-- ---------------------------------------------------------------------
create type public.rol_usuario as enum (
  'admin_cliente',      -- gerente / RR.HH. de la empresa cliente
  'responsable_sst',    -- técnico, monitor o delegado de SST del cliente
  'lectura'             -- solo consulta
);
-- El equipo de ACT no es un rol por empresa: se marca con
-- perfiles.es_equipo_act = true y ve todas las empresas.

create type public.estado_registro    as enum ('activo', 'inactivo');
create type public.estado_accion      as enum ('pendiente', 'en_progreso', 'cumplida', 'vencida', 'cancelada');
create type public.estado_revision_ia as enum ('pendiente', 'aprobada', 'corregida', 'rechazada');
create type public.resultado_requisito as enum ('cumple', 'parcial', 'no_cumple', 'no_aplica', 'sin_evaluar');

-- ---------------------------------------------------------------------
-- Función utilitaria: mantener updated_at
-- ---------------------------------------------------------------------
create or replace function public.tg_set_updated_at()
returns trigger language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end $$;

-- =====================================================================
-- 1. ORGANIZACIONES (empresas cliente de ACT)
-- =====================================================================
create table public.organizaciones (
  id                uuid primary key default gen_random_uuid(),
  ruc               varchar(13) unique check (ruc ~ '^[0-9]{13}$'),
  razon_social      text not null,
  nombre_comercial  text,
  actividad_ciiu    varchar(10),            -- código CIIU como consta en el RUC
  num_trabajadores  integer check (num_trabajadores >= 0),
  provincia         text,
  ciudad            text,
  plan_servicio     text not null default 'piloto'
                    check (plan_servicio in ('piloto', 'basico', 'pro')),  -- ajustar al definir precios
  estado            public.estado_registro not null default 'activo',
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);
comment on table public.organizaciones is 'Empresas cliente a las que ACT presta el servicio de SST.';

-- =====================================================================
-- 2. PERFILES DE USUARIO y membresías
--    En Supabase el login vive en auth.users; aquí guardamos el perfil.
-- =====================================================================
create table public.perfiles (
  id             uuid primary key references auth.users(id) on delete cascade,
  nombre         text not null,
  email          text not null unique,
  es_equipo_act  boolean not null default false,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
comment on column public.perfiles.es_equipo_act is
  'true = integrante de ACT (acceso a todas las empresas). Solo otro integrante de ACT puede cambiarlo.';

create table public.membresias (
  perfil_id        uuid not null references public.perfiles(id) on delete cascade,
  organizacion_id  uuid not null references public.organizaciones(id) on delete cascade,
  rol              public.rol_usuario not null,
  created_at       timestamptz not null default now(),
  primary key (perfil_id, organizacion_id)
);
comment on table public.membresias is 'Qué usuario del cliente puede ver qué empresa y con qué rol (base de la seguridad por filas).';

-- =====================================================================
-- 3. ESTRUCTURA DE LA EMPRESA
-- =====================================================================
create table public.sedes (
  id               uuid primary key default gen_random_uuid(),
  organizacion_id  uuid not null references public.organizaciones(id) on delete cascade,
  nombre           text not null,
  direccion        text,
  ciudad           text,
  num_trabajadores integer check (num_trabajadores >= 0),  -- algunas obligaciones se miden por centro de trabajo
  estado           public.estado_registro not null default 'activo',
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create table public.areas (
  id               uuid primary key default gen_random_uuid(),
  organizacion_id  uuid not null references public.organizaciones(id) on delete cascade,
  sede_id          uuid references public.sedes(id) on delete set null,
  nombre           text not null,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create table public.puestos (
  id                   uuid primary key default gen_random_uuid(),
  organizacion_id      uuid not null references public.organizaciones(id) on delete cascade,
  area_id              uuid references public.areas(id) on delete set null,
  nombre               text not null,
  descripcion_tareas   text,
  num_expuestos        integer check (num_expuestos >= 0),
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);

-- Datos MÍNIMOS del trabajador. Nada de salud ni discapacidad aquí.
create table public.trabajadores (
  id                uuid primary key default gen_random_uuid(),
  organizacion_id   uuid not null references public.organizaciones(id) on delete cascade,
  puesto_id         uuid references public.puestos(id) on delete set null,
  sede_id           uuid references public.sedes(id) on delete set null,
  nombres           text not null,
  apellidos         text not null,
  cedula            varchar(10) check (cedula ~ '^[0-9]{10}$'),
  email             text,
  fecha_ingreso     date,
  estado            public.estado_registro not null default 'activo',
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  unique (organizacion_id, cedula)
);

-- =====================================================================
-- 4. NORMATIVA VERIFICADA (la "fuente de verdad" del agente de IA)
-- =====================================================================
create table public.fuentes_normativas (
  id                 uuid primary key default gen_random_uuid(),
  norma              text not null,        -- ej. 'Decreto Ejecutivo 255'
  titulo             text not null,        -- ej. 'Reglamento de Seguridad y Salud en el Trabajo'
  articulo           text,                 -- ej. 'Art. 15'
  resumen            text not null,        -- resumen propio, NO copia literal extensa
  url_oficial        text not null,        -- Registro Oficial, trabajo.gob.ec, iess.gob.ec...
  registro_oficial   text,                 -- ej. 'R.O. 2do Supl. 554, 09-may-2024'
  vigente            boolean not null default true,   -- ¿la norma sigue en vigor?
  verificado_por     uuid references public.perfiles(id),
  fecha_verificacion date,
  verificada         boolean generated always as
                       (verificado_por is not null and fecha_verificacion is not null) stored,
  notas_internas     text,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);
comment on table public.fuentes_normativas is
  'Normativa con su fuente oficial. El agente de IA SOLO puede citar filas con verificada = true y vigente = true.';

-- Vista que usa el agente: nunca leer la tabla directamente.
create view public.normativa_para_agente
with (security_invoker = true) as
  select id, norma, titulo, articulo, resumen, url_oficial, registro_oficial, fecha_verificacion
  from public.fuentes_normativas
  where verificada and vigente;

-- =====================================================================
-- 5. DIAGNÓSTICO DE CUMPLIMIENTO (servicio estrella del MVP)
--    Catálogo de requisitos -> diagnóstico por empresa -> ítems evaluados
-- =====================================================================
create table public.requisitos (
  id                     uuid primary key default gen_random_uuid(),
  codigo                 varchar(30) not null unique,   -- ej. 'SST-DELEGADO'
  descripcion            text not null,                 -- ej. '¿Cuenta con delegado de SST registrado?'
  evidencia_esperada     text,                          -- qué documento o registro lo demuestra
  fuente_id              uuid not null references public.fuentes_normativas(id),
  aplica_min_trabajadores integer check (aplica_min_trabajadores >= 0),  -- null = sin mínimo
  aplica_max_trabajadores integer check (aplica_max_trabajadores >= 0),  -- null = sin máximo
  activo                 boolean not null default true,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),
  check (aplica_max_trabajadores is null or aplica_min_trabajadores is null
         or aplica_max_trabajadores >= aplica_min_trabajadores)
);
comment on table public.requisitos is
  'Obligaciones verificables. Cada una debe apuntar a una fuente normativa; no se usa con clientes hasta que esa fuente esté verificada.';

create table public.diagnosticos (
  id                uuid primary key default gen_random_uuid(),
  organizacion_id   uuid not null references public.organizaciones(id) on delete cascade,
  sede_id           uuid references public.sedes(id) on delete set null,
  fecha             date not null default current_date,
  realizado_por     uuid references public.perfiles(id),
  estado            text not null default 'borrador'
                    check (estado in ('borrador', 'finalizado', 'entregado')),
  resumen           text,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create table public.diagnostico_items (
  id               uuid primary key default gen_random_uuid(),
  diagnostico_id   uuid not null references public.diagnosticos(id) on delete cascade,
  requisito_id     uuid not null references public.requisitos(id),
  resultado        public.resultado_requisito not null default 'sin_evaluar',
  observacion      text,
  evidencia_path   text,                    -- ruta en Storage (bucket privado 'documentos')
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  unique (diagnostico_id, requisito_id)
);

-- % de cumplimiento por diagnóstico (no cuenta 'no_aplica' ni 'sin_evaluar';
-- 'parcial' cuenta como medio punto).
create view public.resumen_diagnosticos
with (security_invoker = true) as
  select d.id               as diagnostico_id,
         d.organizacion_id,
         d.fecha,
         d.estado,
         count(*) filter (where i.resultado = 'cumple')     as cumple,
         count(*) filter (where i.resultado = 'parcial')    as parcial,
         count(*) filter (where i.resultado = 'no_cumple')  as no_cumple,
         count(*) filter (where i.resultado = 'sin_evaluar') as sin_evaluar,
         round(100.0 *
           (count(*) filter (where i.resultado = 'cumple')
            + 0.5 * count(*) filter (where i.resultado = 'parcial'))
           / nullif(count(*) filter (where i.resultado in ('cumple', 'parcial', 'no_cumple')), 0)
         , 1) as porcentaje_cumplimiento
  from public.diagnosticos d
  left join public.diagnostico_items i on i.diagnostico_id = d.id
  group by d.id;

-- =====================================================================
-- 6. MATRIZ DE RIESGOS (identificación de peligros y evaluación)
-- =====================================================================
-- Catálogo de factores de riesgo. Valores iniciales en seed.sql, tomados
-- de la clasificación del DE 255 / Norma Técnica del MDT: verificar antes
-- de usar con clientes.
create table public.tipos_riesgo (
  id           smallserial primary key,
  codigo       varchar(20) not null unique,
  nombre       text not null,
  descripcion  text
);

create table public.evaluaciones_riesgo (
  id                uuid primary key default gen_random_uuid(),
  organizacion_id   uuid not null references public.organizaciones(id) on delete cascade,
  puesto_id         uuid not null references public.puestos(id) on delete cascade,
  tipo_riesgo_id    smallint not null references public.tipos_riesgo(id),
  peligro           text not null,         -- ej. 'Piso resbaloso en bodega'
  consecuencia      text,                  -- ej. 'Caídas al mismo nivel'
  metodologia       text not null default 'matriz_5x5',
  probabilidad      smallint not null check (probabilidad between 1 and 5),
  severidad         smallint not null check (severidad between 1 and 5),
  nivel_riesgo      smallint generated always as (probabilidad * severidad) stored,
  clasificacion     text generated always as (
                      case
                        when probabilidad * severidad >= 15 then 'critico'
                        when probabilidad * severidad >= 9  then 'alto'
                        when probabilidad * severidad >= 4  then 'moderado'
                        else 'bajo'
                      end) stored,
  controles_existentes text,
  fecha_evaluacion  date not null default current_date,
  evaluado_por      uuid references public.perfiles(id),
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);
comment on column public.evaluaciones_riesgo.clasificacion is
  'Umbrales de ejemplo para matriz 5x5. Ajustar a la metodología que valide el mentor / técnico SST.';

-- =====================================================================
-- 7. PLAN DE ACCIÓN (medidas correctivas / preventivas)
-- =====================================================================
create table public.acciones (
  id                  uuid primary key default gen_random_uuid(),
  organizacion_id     uuid not null references public.organizaciones(id) on delete cascade,
  origen              text not null check (origen in
                        ('diagnostico', 'riesgo', 'incidente', 'inspeccion', 'auditoria', 'otro')),
  diagnostico_item_id uuid references public.diagnostico_items(id) on delete set null,
  evaluacion_id       uuid references public.evaluaciones_riesgo(id) on delete set null,
  descripcion         text not null,
  jerarquia_control   text check (jerarquia_control in
                        ('eliminacion', 'sustitucion', 'ingenieria', 'administrativo', 'epp')),
  responsable         text,
  fecha_limite        date,
  fecha_cierre        date,
  estado              public.estado_accion not null default 'pendiente',
  evidencia_path      text,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  check (fecha_cierre is null or estado = 'cumplida'),
  check (estado <> 'cumplida' or fecha_cierre is not null)
);

-- =====================================================================
-- 8. CAPACITACIONES (primeros auxilios, SST, inclusión...)
-- =====================================================================
create table public.capacitaciones (
  id                uuid primary key default gen_random_uuid(),
  organizacion_id   uuid not null references public.organizaciones(id) on delete cascade,
  tema              text not null,
  categoria         text not null default 'sst'
                    check (categoria in ('sst', 'primeros_auxilios', 'emergencias',
                                         'salud_mental', 'inclusion', 'otro')),
  modalidad         text check (modalidad in ('presencial', 'virtual', 'mixta')),
  fecha             date not null,
  duracion_horas    numeric(4,1) check (duracion_horas > 0),
  facilitador       text,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create table public.capacitacion_asistentes (
  capacitacion_id  uuid not null references public.capacitaciones(id) on delete cascade,
  trabajador_id    uuid not null references public.trabajadores(id) on delete cascade,
  asistio          boolean not null default true,
  calificacion     numeric(4,1) check (calificacion between 0 and 100),
  primary key (capacitacion_id, trabajador_id)
);

-- =====================================================================
-- 9. DOCUMENTOS DEL SISTEMA DE GESTIÓN DEL CLIENTE
-- =====================================================================
create table public.documentos (
  id                uuid primary key default gen_random_uuid(),
  organizacion_id   uuid not null references public.organizaciones(id) on delete cascade,
  tipo              text not null check (tipo in (
                      'politica_sst', 'reglamento_higiene_seguridad', 'plan_prevencion',
                      'matriz_riesgos', 'plan_emergencia', 'registro_capacitacion',
                      'informe_diagnostico', 'procedimiento', 'otro')),
  titulo            text not null,
  version           text not null default '1.0',
  archivo_path      text,                  -- ruta en Supabase Storage (bucket privado 'documentos')
  estado            text not null default 'borrador'
                    check (estado in ('borrador', 'en_revision', 'aprobado', 'registrado_mdt', 'vencido')),
  fecha_aprobacion  date,
  vigente_hasta     date,
  elaborado_por     uuid references public.perfiles(id),
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

-- =====================================================================
-- 10. AGENTE DE IA con supervisión humana
-- =====================================================================
create table public.consultas_ia (
  id                  uuid primary key default gen_random_uuid(),
  organizacion_id     uuid references public.organizaciones(id) on delete cascade,
  solicitado_por      uuid references public.perfiles(id),
  pregunta            text not null,
  respuesta_final     text,                -- lo que se entrega al cliente tras revisión humana
  sin_norma_aplicable boolean not null default false, -- el agente declaró que no encontró norma
  estado_revision     public.estado_revision_ia not null default 'pendiente',
  revisado_por        uuid references public.perfiles(id),
  fecha_revision      timestamptz,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  check (estado_revision = 'pendiente' or (revisado_por is not null and fecha_revision is not null)),
  check (estado_revision not in ('aprobada', 'corregida') or respuesta_final is not null)
);

comment on table public.consultas_ia is
  'Preguntas de clientes al agente. El cliente solo ve respuesta_final, que existe únicamente tras revisión humana.';

-- Lo que generó el modelo. Tabla aparte para que el cliente NUNCA vea
-- un borrador sin revisar (solo el equipo ACT tiene acceso).
create table public.consultas_ia_borradores (
  id              uuid primary key default gen_random_uuid(),
  consulta_id     uuid not null references public.consultas_ia(id) on delete cascade,
  respuesta       text not null,
  modelo          text,                -- ej. 'claude-sonnet-...'
  version_prompt  text,                -- ej. 'sso-intelligence v0.1'
  created_at      timestamptz not null default now()
);

create table public.consultas_ia_fuentes (
  consulta_id  uuid not null references public.consultas_ia(id) on delete cascade,
  fuente_id    uuid not null references public.fuentes_normativas(id),
  primary key (consulta_id, fuente_id)
);

-- Regla: solo se puede citar normativa verificada y vigente.
create or replace function public.tg_validar_fuente_citada()
returns trigger language plpgsql
set search_path = ''
as $$
begin
  if not exists (select 1 from public.fuentes_normativas f
                 where f.id = new.fuente_id and f.verificada and f.vigente) then
    raise exception 'La fuente % no está verificada o no está vigente; el agente no puede citarla', new.fuente_id;
  end if;
  return new;
end $$;

create trigger validar_fuente_citada
  before insert or update on public.consultas_ia_fuentes
  for each row execute function public.tg_validar_fuente_citada();

-- Regla: una respuesta no se aprueba si no cita al menos una fuente
-- verificada, salvo que declare explícitamente que no hay norma aplicable.
create or replace function public.tg_validar_aprobacion_ia()
returns trigger language plpgsql
set search_path = ''
as $$
begin
  if new.estado_revision in ('aprobada', 'corregida') and not new.sin_norma_aplicable then
    if not exists (select 1 from public.consultas_ia_fuentes f where f.consulta_id = new.id) then
      raise exception 'La consulta % no puede aprobarse sin al menos una fuente normativa verificada', new.id;
    end if;
  end if;
  return new;
end $$;

create trigger validar_aprobacion_ia
  before insert or update of estado_revision, sin_norma_aplicable on public.consultas_ia
  for each row execute function public.tg_validar_aprobacion_ia();

-- =====================================================================
-- Índices para las consultas más comunes
-- =====================================================================
create index on public.membresias (organizacion_id);
create index on public.sedes (organizacion_id);
create index on public.areas (organizacion_id);
create index on public.puestos (organizacion_id);
create index on public.trabajadores (organizacion_id);
create index on public.diagnosticos (organizacion_id, fecha);
create index on public.diagnostico_items (requisito_id);
create index on public.evaluaciones_riesgo (organizacion_id, puesto_id);
create index on public.acciones (organizacion_id, estado, fecha_limite);
create index on public.capacitaciones (organizacion_id, fecha);
create index on public.capacitacion_asistentes (trabajador_id);
create index on public.documentos (organizacion_id, tipo);
create index on public.consultas_ia (organizacion_id, estado_revision);
create index on public.consultas_ia_borradores (consulta_id);

-- =====================================================================
-- Triggers updated_at
-- =====================================================================
do $$
declare t text;
begin
  foreach t in array array[
    'organizaciones', 'perfiles', 'sedes', 'areas', 'puestos', 'trabajadores',
    'fuentes_normativas', 'requisitos', 'diagnosticos', 'diagnostico_items',
    'evaluaciones_riesgo', 'acciones', 'capacitaciones', 'documentos', 'consultas_ia']
  loop
    execute format(
      'create trigger set_updated_at before update on public.%I
         for each row execute function public.tg_set_updated_at()', t);
  end loop;
end $$;
