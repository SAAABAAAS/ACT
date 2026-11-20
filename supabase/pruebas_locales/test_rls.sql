\set ON_ERROR_STOP 0
-- usuarios: ACT, cliente de la panadería, cliente de otra empresa
insert into auth.users (id, email, raw_user_meta_data) values
 ('a0000000-0000-4000-8000-000000000001','felipe@act.test','{"nombre":"Felipe"}'),
 ('c0000000-0000-4000-8000-000000000001','rrhh@espiga.test','{}'),
 ('c0000000-0000-4000-8000-000000000002','otro@otra.test','{}');
update perfiles set es_equipo_act = true where id='a0000000-0000-4000-8000-000000000001'; -- como SQL editor
insert into organizaciones (id, razon_social) values ('10000000-0000-4000-8000-000000000002','OTRA EMPRESA (FICTICIA)');
insert into membresias values ('c0000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','admin_cliente'),
                              ('c0000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000002','lectura');
insert into consultas_ia (id, organizacion_id, pregunta) values ('e0000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','¿Necesito comité?');
insert into consultas_ia_borradores (consulta_id, respuesta) values ('e0000000-0000-4000-8000-000000000001','BORRADOR SECRETO');

\echo '--- T1 perfil creado solo:' 
select nombre, email from perfiles order by email;

\echo '--- T2 cliente panaderia ve (esperado: 1 org, 2 trabajadores, 0 borradores):'
set role authenticated; set request.jwt.claim.sub = 'c0000000-0000-4000-8000-000000000001';
select (select count(*) from organizaciones) orgs, (select count(*) from trabajadores) trab, (select count(*) from consultas_ia_borradores) borradores, (select count(*) from consultas_ia) consultas;
\echo '--- T3 cliente intenta hacerse equipo ACT (esperado: ERROR):'
update perfiles set es_equipo_act = true where id = auth.uid();
\echo '--- T4 cliente inserta trabajador en OTRA empresa (esperado: ERROR RLS):'
insert into trabajadores (organizacion_id, nombres, apellidos) values ('10000000-0000-4000-8000-000000000002','X','Y');
\echo '--- T5 cliente intenta aprobar su consulta (esperado: UPDATE 0):'
update consultas_ia set estado_revision='aprobada' where id='e0000000-0000-4000-8000-000000000001';

\echo '--- T6 usuario lectura de otra empresa (esperado: 1 org, 0 trabajadores, 0 consultas):'
set request.jwt.claim.sub = 'c0000000-0000-4000-8000-000000000002';
select (select count(*) from organizaciones) orgs, (select count(*) from trabajadores) trab, (select count(*) from consultas_ia) consultas;
\echo '--- T7 lectura intenta crear accion (esperado: ERROR RLS):'
insert into acciones (organizacion_id, origen, descripcion) values ('10000000-0000-4000-8000-000000000002','otro','x');

\echo '--- T8 anonimo (esperado: permission denied):'
reset role; set role anon; select count(*) from organizaciones;

\echo '--- T9 ACT cita fuente NO verificada (esperado: ERROR):'
reset role; set role authenticated; set request.jwt.claim.sub = 'a0000000-0000-4000-8000-000000000001';
select count(*) as act_ve_orgs from organizaciones;
insert into consultas_ia_fuentes values ('e0000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000001');
\echo '--- T10 ACT aprueba sin fuente (esperado: ERROR):'
update consultas_ia set estado_revision='aprobada', revisado_por=auth.uid(), fecha_revision=now(), respuesta_final='x' where id='e0000000-0000-4000-8000-000000000001';
\echo '--- T11 ACT verifica la fuente, la cita y aprueba (esperado: OK):'
update fuentes_normativas set verificado_por=auth.uid(), fecha_verificacion=current_date where id='00000000-0000-4000-8000-000000000001';
insert into consultas_ia_fuentes values ('e0000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000001');
update consultas_ia set estado_revision='aprobada', revisado_por=auth.uid(), fecha_revision=now(), respuesta_final='Respuesta revisada' where id='e0000000-0000-4000-8000-000000000001';
select count(*) as normativa_para_agente from normativa_para_agente;

\echo '--- T12 storage: cliente sube a su carpeta OK y a la ajena ERROR:'
set request.jwt.claim.sub = 'c0000000-0000-4000-8000-000000000001';
insert into storage.objects (bucket_id, name) values ('documentos','10000000-0000-4000-8000-000000000001/diag/a.pdf');
insert into storage.objects (bucket_id, name) values ('documentos','10000000-0000-4000-8000-000000000002/diag/b.pdf');
insert into storage.objects (bucket_id, name) values ('documentos','sin-uuid/c.pdf');
