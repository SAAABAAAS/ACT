-- =====================================================================
-- ACT — Datos de PRUEBA (solo para desarrollo local / demo)
--
-- ⚠️  Todo lo de este archivo es FICTICIO. Nunca pongan aquí datos de un
--     cliente real (nombres, cédulas, RUC).
-- ⚠️  Las fuentes normativas se cargan SIN verificar a propósito: el
--     agente no las podrá citar hasta que una persona las coteje con el
--     texto oficial y llene verificado_por + fecha_verificacion.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Catálogo: factores de riesgo
-- Tomado de la clasificación de la Norma Técnica de Seguridad e Higiene
-- del Trabajo (MDT, Anexo 3), que desarrolla el DE 255. VERIFICAR.
-- ---------------------------------------------------------------------
insert into public.tipos_riesgo (codigo, nombre) values
  ('FISICO',       'Riesgos físicos'),
  ('QUIMICO',      'Riesgos químicos'),
  ('BIOLOGICO',    'Riesgos biológicos'),
  ('SEGURIDAD',    'Riesgos de seguridad'),
  ('ERGONOMICO',   'Riesgos ergonómicos'),
  ('PSICOSOCIAL',  'Riesgos psicosociales')
on conflict (codigo) do nothing;

-- ---------------------------------------------------------------------
-- Fuentes normativas (SIN verificar)
-- ---------------------------------------------------------------------
insert into public.fuentes_normativas
  (id, norma, titulo, articulo, resumen, url_oficial, registro_oficial, notas_internas)
values
  ('00000000-0000-4000-8000-000000000001',
   'Decreto Ejecutivo 255',
   'Reglamento de Seguridad y Salud en el Trabajo',
   'Art. 15',
   'Deberes generales de los empleadores en materia de seguridad y salud en el trabajo.',
   'https://www.trabajo.gob.ec/',
   'R.O. 2do Supl. 554, 09-may-2024',
   'PENDIENTE: enlazar el PDF oficial del Registro Oficial y confirmar el texto del artículo.'),
  ('00000000-0000-4000-8000-000000000002',
   'Acuerdo Ministerial MDT-2024-196',
   'Normativa secundaria del Ministerio del Trabajo para aplicar el DE 255',
   null,
   'Desarrolla registros y procedimientos en la plataforma SUT (responsables, delegado, comité, etc.).',
   'https://www.trabajo.gob.ec/',
   null,
   'PENDIENTE: confirmar título oficial, artículos exactos y vigencia.')
on conflict (id) do nothing;

-- ---------------------------------------------------------------------
-- Requisitos de ejemplo para el diagnóstico de cumplimiento
-- Basados en la "Lista de verificación SST" y preguntas frecuentes del
-- MDT. Los artículos exactos deben confirmarse antes de usar con clientes.
-- ---------------------------------------------------------------------
insert into public.requisitos
  (codigo, descripcion, evidencia_esperada, fuente_id, aplica_min_trabajadores, aplica_max_trabajadores)
values
  ('SST-POLITICA',
   '¿La empresa tiene una política de SST aprobada y socializada a todos los trabajadores?',
   'Política firmada + registro de socialización',
   '00000000-0000-4000-8000-000000000001', null, null),
  ('SST-MATRIZ',
   '¿Cuenta con matriz de identificación y evaluación de riesgos por puesto?',
   'Matriz de riesgos vigente',
   '00000000-0000-4000-8000-000000000001', null, null),
  ('SST-REGLAMENTO',
   '¿Tiene reglamento de higiene y seguridad aprobado por el MDT (cuando aplique)?',
   'Reglamento aprobado en la plataforma SUT',
   '00000000-0000-4000-8000-000000000002', null, null),
  ('SST-DELEGADO',
   '¿Tiene delegado de SST registrado en la plataforma SUT?',
   'Registro SUT del delegado',
   '00000000-0000-4000-8000-000000000002', 10, 49),
  ('SST-COMITE',
   '¿Tiene comité de SST conformado y registrado por centro de trabajo?',
   'Acta de conformación + registro SUT',
   '00000000-0000-4000-8000-000000000002', 50, null)
on conflict (codigo) do nothing;

-- ---------------------------------------------------------------------
-- Empresa ficticia de demostración
-- ---------------------------------------------------------------------
insert into public.organizaciones (id, ruc, razon_social, nombre_comercial, actividad_ciiu,
                                   num_trabajadores, provincia, ciudad, plan_servicio)
values ('10000000-0000-4000-8000-000000000001', '9999999999001',
        'PANIFICADORA EJEMPLO S.A.S. (FICTICIA)', 'Panadería La Espiga', 'C1071',
        24, 'Pichincha', 'Quito', 'piloto')
on conflict (id) do nothing;

insert into public.sedes (id, organizacion_id, nombre, ciudad, num_trabajadores) values
  ('20000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001',
   'Planta principal', 'Quito', 24)
on conflict (id) do nothing;

insert into public.areas (id, organizacion_id, sede_id, nombre) values
  ('30000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001',
   '20000000-0000-4000-8000-000000000001', 'Producción'),
  ('30000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001',
   '20000000-0000-4000-8000-000000000001', 'Ventas')
on conflict (id) do nothing;

insert into public.puestos (id, organizacion_id, area_id, nombre, descripcion_tareas, num_expuestos) values
  ('40000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001',
   '30000000-0000-4000-8000-000000000001', 'Panadero', 'Amasado, horneado, manejo de hornos', 8),
  ('40000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000001',
   '30000000-0000-4000-8000-000000000002', 'Cajero/a', 'Atención al cliente y caja', 4)
on conflict (id) do nothing;

insert into public.trabajadores (organizacion_id, puesto_id, sede_id, nombres, apellidos, cedula) values
  ('10000000-0000-4000-8000-000000000001', '40000000-0000-4000-8000-000000000001',
   '20000000-0000-4000-8000-000000000001', 'Persona', 'Ejemplo Uno', '0000000001'),
  ('10000000-0000-4000-8000-000000000001', '40000000-0000-4000-8000-000000000002',
   '20000000-0000-4000-8000-000000000001', 'Persona', 'Ejemplo Dos', '0000000002')
on conflict do nothing;

insert into public.evaluaciones_riesgo (organizacion_id, puesto_id, tipo_riesgo_id, peligro,
                                        consecuencia, probabilidad, severidad, controles_existentes)
select '10000000-0000-4000-8000-000000000001', '40000000-0000-4000-8000-000000000001',
       t.id, 'Contacto con superficies calientes del horno', 'Quemaduras', 3, 4, 'Guantes térmicos'
from public.tipos_riesgo t where t.codigo = 'FISICO';

-- Diagnóstico de ejemplo
insert into public.diagnosticos (id, organizacion_id, sede_id, estado, resumen) values
  ('50000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000001',
   '20000000-0000-4000-8000-000000000001', 'borrador', 'Diagnóstico inicial de demostración')
on conflict (id) do nothing;

insert into public.diagnostico_items (diagnostico_id, requisito_id, resultado, observacion)
select '50000000-0000-4000-8000-000000000001', r.id,
       case r.codigo
         when 'SST-POLITICA'   then 'parcial'::public.resultado_requisito
         when 'SST-MATRIZ'     then 'no_cumple'
         when 'SST-REGLAMENTO' then 'sin_evaluar'
         when 'SST-DELEGADO'   then 'cumple'
         when 'SST-COMITE'     then 'no_aplica'
       end,
       case r.codigo
         when 'SST-POLITICA' then 'Existe política, pero no hay registro de socialización'
         when 'SST-COMITE'   then 'Menos de 50 trabajadores en la sede'
       end
from public.requisitos r
on conflict do nothing;

insert into public.acciones (organizacion_id, origen, diagnostico_item_id, descripcion,
                             jerarquia_control, responsable, fecha_limite)
select '10000000-0000-4000-8000-000000000001', 'diagnostico', i.id,
       'Elaborar matriz de riesgos para todos los puestos', 'administrativo',
       'Responsable SST del cliente', current_date + 30
from public.diagnostico_items i
join public.requisitos r on r.id = i.requisito_id
where r.codigo = 'SST-MATRIZ';
