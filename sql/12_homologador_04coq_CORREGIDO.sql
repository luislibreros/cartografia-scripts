/*
********************************************************************************
* CÃƒÂ³digo: Homologador_v2
* Autor: Jhoinner Manrique
* AdaptaciÃƒÂ³n Chile (Antofagasta): Claude Sonnet
* Fecha de creaciÃƒÂ³n: 10-11-2024
* ÃƒÅ¡ltima modificaciÃƒÂ³n: 26-05-2026
* VersiÃƒÂ³n: 5.1 -- AdaptaciÃƒÂ³n Chile / Antofagasta
********************************************************************************
*/
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-----------------------PREPARACION INSUMOS PROCESO------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
do $$
begin
	raise notice '------------------------------------';
	raise notice '--Iniciando creacion de insumos...--';
	raise notice '------------------------------------';
end $$;

--------------------------------------------------------------------------------
--CREAR CAPA PLACAS
--------------------------------------------------------------------------------

do $$
begin
	raise notice 'Creando capa de placas a homologar...';
end $$;

--------------------------------------------------------------------------------
--Crear capa para procesos
drop table if exists placas;
create table placas as
select id_capa, geom, nomvia from "04_coq_prueba"."placa_coq";-----------------------------------nombre_placas

--renombrar campos para proceso
ALTER TABLE placas RENAME COLUMN nomvia TO nomvia_placas;

--ampliar campo para evitar error por longitud al reemplazar numeros por texto
ALTER TABLE placas ALTER COLUMN nomvia_placas TYPE TEXT;


--------------------------------------------------------------------------------
--Crear campos nomvia mavvial

alter table placas add column nomvia_placas_limpio varchar;

alter table placas add column nomvia_placas_original varchar;

alter table placas add column nomvia_mavvial1 varchar;

alter table placas add column nomvia_mavvial1_limpio varchar;

alter table placas add column nomvia_mavvial2 varchar;

alter table placas add column nomvia_mavvial2_limpio varchar;

alter table placas add column nomvia_mavvial3 varchar;

alter table placas add column nomvia_mavvial3_limpio varchar;

alter table placas add column nomvia_mavvial4 varchar;

alter table placas add column nomvia_mavvial4_limpio varchar;

alter table placas add column id_mavvial1 varchar;

alter table placas add column id_mavvial2 varchar;

alter table placas add column id_mavvial3 varchar;

alter table placas add column id_mavvial4 varchar;

---------------------------------------------------------------------------
--Actualizar campo para conservar nombre original en placas
update placas
set nomvia_placas_original = nomvia_placas
where nomvia_placas is not null;

--------------------------------------------------------------------------------
--CREAR CAPA MAVVIAL
--------------------------------------------------------------------------------

do $$
begin
	raise notice 'Creando capa de mavvial a homologar...';
end $$;

--------------------------------------------------------------------------------
--Crear capa para procesos
drop table if exists mavvial_homologar;
create table mavvial_homologar as
select id_capa, geom, nomvtotal from "04_coq_prueba"."mavvial_coq";-----------------------------------nombre_mavvial_antofagasta

--renombrar campos para proceso
ALTER TABLE mavvial_homologar RENAME COLUMN nomvtotal TO nomvia_mavvial;
ALTER TABLE mavvial_homologar RENAME COLUMN id_capa TO id_mavvial;

--------------------------------------------------------------------------------
--Crear campos nomvia mavvial

alter table mavvial_homologar add column nomvia_mavvial_limpio varchar;
alter table mavvial_homologar add column nomvia_mavvial_original varchar;
---------------------------------------------------------------------------
--Actualizar campo para conservar nombre original
update mavvial_homologar
set nomvia_mavvial_original = nomvia_mavvial
where nomvia_mavvial is not null;

--------------------------------------------------------------------------------
--Listado de palabras a omitir en el proceso (tipos de vÃƒÂ­a Chile)
--------------------------------------------------------------------------------
DROP FUNCTION IF EXISTS listado_palabras();
CREATE OR REPLACE FUNCTION listado_palabras()
RETURNS text AS $$
BEGIN
    RETURN '\m(ACERA|ACCESO|ANDADOR|ALAMEDA|ANDEN|AUTOPISTA|AUTOVIA|AVENIDA AUXILIAR|AVENIDA|AVENIDA PROLONGACION|BOULEVARD|CALLE|CALLEJON|CAMINO|CORREDOR|COLECTORA|CERRADA|CARRETERA|CIRCUITO|CIRCUNVALACION|CIRCUNVALAR|CALZADA|DIAGONAL|DISTRIBUIDOR|EJE|ENTRADA|ESCALINATA|HERRADURA|JIRON|CARRERA|PASO|PARALELA|PASAJE|PERIFERICO|PASEO|PLAZA|PASEO PEATONAL|PERIMETRAL|PROLONGACION|PEATONAL|RAMAL|RADIAL|REPARTO|RAMPA|ROTONDA|RESPALDO|REDOMA|RETORNO|SENDERO|RODOVIA|RUA|RUTA|TUNEL|SENDA|TREVO|TRANSVERSAL|TRILLA|VIADUTO|VIELA|TRONCAL|VARIANTE|VIA|VIADUCTO|VILA)\M';
END;
$$ LANGUAGE plpgsql;

-----------------------------------------------------------------------
-- TABLA DE NUMEROS (espaÃƒÂ±ol)
-----------------------------------------------------------------------
do $$
begin
	raise notice 'Creando Tabla de numeros a texto...';
end $$;

begin;
drop table if exists conversion_numeros;
CREATE TABLE conversion_numeros (
    numero_natural varchar,
    numero_texto VARCHAR(50) NOT NULL
);
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (00, 'CERO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (01, 'UNO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (02, 'DOS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (03, 'TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (04, 'CUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (05, 'CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (06, 'SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (07, 'SIETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (08, 'OCHO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (09, 'NUEVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (0, 'CERO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (1, 'UNO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (2, 'DOS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (3, 'TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (4, 'CUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (5, 'CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (6, 'SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (7, 'SIETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (8, 'OCHO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (9, 'NUEVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (10, 'DIEZ');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (11, 'ONCE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (12, 'DOCE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (13, 'TRECE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (14, 'CATORCE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (15, 'QUINCE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (16, 'DIECISEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (17, 'DIECISIETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (18, 'DIECIOCHO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (19, 'DIECINUEVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (20, 'VEINTE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (21, 'VEINTIUNO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (22, 'VEINTIDOS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (23, 'VEINTITRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (24, 'VEINTICUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (25, 'VEINTICINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (26, 'VEINTISEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (27, 'VEINTISIETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (28, 'VEINTIOCHO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (29, 'VEINTINUEVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (30, 'TREINTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (31, 'TREINTA Y UNO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (32, 'TREINTA Y DOS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (33, 'TREINTA Y TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (34, 'TREINTA Y CUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (35, 'TREINTA Y CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (36, 'TREINTA Y SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (37, 'TREINTA Y SIETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (38, 'TREINTA Y OCHO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (39, 'TREINTA Y NUEVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (40, 'CUARENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (41, 'CUARENTA Y UNO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (42, 'CUARENTA Y DOS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (43, 'CUARENTA Y TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (44, 'CUARENTA Y CUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (45, 'CUARENTA Y CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (46, 'CUARENTA Y SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (47, 'CUARENTA Y SIETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (48, 'CUARENTA Y OCHO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (49, 'CUARENTA Y NUEVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (50, 'CINCUENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (51, 'CINCUENTA Y UNO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (52, 'CINCUENTA Y DOS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (53, 'CINCUENTA Y TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (54, 'CINCUENTA Y CUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (55, 'CINCUENTA Y CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (56, 'CINCUENTA Y SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (57, 'CINCUENTA Y SIETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (58, 'CINCUENTA Y OCHO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (59, 'CINCUENTA Y NUEVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (60, 'SESENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (61, 'SESENTA Y UNO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (62, 'SESENTA Y DOS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (63, 'SESENTA Y TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (64, 'SESENTA Y CUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (65, 'SESENTA Y CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (66, 'SESENTA Y SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (67, 'SESENTA Y SIETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (68, 'SESENTA Y OCHO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (69, 'SESENTA Y NUEVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (70, 'SETENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (71, 'SETENTA Y UNO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (72, 'SETENTA Y DOS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (73, 'SETENTA Y TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (74, 'SETENTA Y CUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (75, 'SETENTA Y CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (76, 'SETENTA Y SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (77, 'SETENTA Y SIETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (78, 'SETENTA Y OCHO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (79, 'SETENTA Y NUEVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (80, 'OCHENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (81, 'OCHENTA Y UNO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (82, 'OCHENTA Y DOS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (83, 'OCHENTA Y TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (84, 'OCHENTA Y CUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (85, 'OCHENTA Y CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (86, 'OCHENTA Y SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (87, 'OCHENTA Y SIETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (88, 'OCHENTA Y OCHO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (89, 'OCHENTA Y NUEVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (90, 'NOVENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (91, 'NOVENTA Y UNO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (92, 'NOVENTA Y DOS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (93, 'NOVENTA Y TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (94, 'NOVENTA Y CUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (95, 'NOVENTA Y CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (96, 'NOVENTA Y SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (97, 'NOVENTA Y SIETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (98, 'NOVENTA Y OCHO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (99, 'NOVENTA Y NUEVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (100, 'CIEN');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (101, 'CIENTO UNO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (102, 'CIENTO DOS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (103, 'CIENTO TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (104, 'CIENTO CUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (105, 'CIENTO CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (106, 'CIENTO SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (107, 'CIENTO SIETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (108, 'CIENTO OCHO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (109, 'CIENTO NUEVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (110, 'CIENTO DIEZ');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (111, 'CIENTO ONCE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (112, 'CIENTO DOCE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (113, 'CIENTO TRECE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (114, 'CIENTO CATORCE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (115, 'CIENTO QUINCE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (116, 'CIENTO DIECISEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (117, 'CIENTO DIECISIETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (118, 'CIENTO DIECIOCHO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (119, 'CIENTO DIECINUEVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (120, 'CIENTO VEINTE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (121, 'CIENTO VEINTIUNO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (122, 'CIENTO VEINTIDOS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (123, 'CIENTO VEINTITRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (124, 'CIENTO VEINTICUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (125, 'CIENTO VEINTICINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (126, 'CIENTO VEINTISEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (127, 'CIENTO VEINTISIETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (128, 'CIENTO VEINTIOCHO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (129, 'CIENTO VEINTINUEVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (130, 'CIENTO TREINTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (131, 'CIENTO TREINTA Y UNO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (132, 'CIENTO TREINTA Y DOS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (133, 'CIENTO TREINTA Y TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (134, 'CIENTO TREINTA Y CUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (135, 'CIENTO TREINTA Y CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (136, 'CIENTO TREINTA Y SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (137, 'CIENTO TREINTA Y SIETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (138, 'CIENTO TREINTA Y OCHO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (139, 'CIENTO TREINTA Y NUEVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (140, 'CIENTO CUARENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (141, 'CIENTO CUARENTA Y UNO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (142, 'CIENTO CUARENTA Y DOS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (143, 'CIENTO CUARENTA Y TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (144, 'CIENTO CUARENTA Y CUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (145, 'CIENTO CUARENTA Y CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (146, 'CIENTO CUARENTA Y SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (147, 'CIENTO CUARENTA Y SIETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (148, 'CIENTO CUARENTA Y OCHO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (149, 'CIENTO CUARENTA Y NUEVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (150, 'CIENTO CINCUENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (151, 'CIENTO CINCUENTA Y UNO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (152, 'CIENTO CINCUENTA Y DOS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (153, 'CIENTO CINCUENTA Y TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (154, 'CIENTO CINCUENTA Y CUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (155, 'CIENTO CINCUENTA Y CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (156, 'CIENTO CINCUENTA Y SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (157, 'CIENTO CINCUENTA Y SIETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (158, 'CIENTO CINCUENTA Y OCHO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (159, 'CIENTO CINCUENTA Y NUEVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (160, 'CIENTO SESENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (161, 'CIENTO SESENTA Y UNO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (162, 'CIENTO SESENTA Y DOS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (163, 'CIENTO SESENTA Y TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (164, 'CIENTO SESENTA Y CUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (165, 'CIENTO SESENTA Y CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (166, 'CIENTO SESENTA Y SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (167, 'CIENTO SESENTA Y SIETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (168, 'CIENTO SESENTA Y OCHO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (169, 'CIENTO SESENTA Y NUEVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (170, 'CIENTO SETENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (171, 'CIENTO SETENTA Y UNO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (172, 'CIENTO SETENTA Y DOS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (173, 'CIENTO SETENTA Y TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (174, 'CIENTO SETENTA Y CUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (175, 'CIENTO SETENTA Y CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (176, 'CIENTO SETENTA Y SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (177, 'CIENTO SETENTA Y SIETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (178, 'CIENTO SETENTA Y OCHO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (179, 'CIENTO SETENTA Y NUEVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (180, 'CIENTO OCHENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (181, 'CIENTO OCHENTA Y UNO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (182, 'CIENTO OCHENTA Y DOS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (183, 'CIENTO OCHENTA Y TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (184, 'CIENTO OCHENTA Y CUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (185, 'CIENTO OCHENTA Y CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (186, 'CIENTO OCHENTA Y SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (187, 'CIENTO OCHENTA Y SIETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (188, 'CIENTO OCHENTA Y OCHO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (189, 'CIENTO OCHENTA Y NUEVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (190, 'CIENTO NOVENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (191, 'CIENTO NOVENTA Y UNO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (192, 'CIENTO NOVENTA Y DOS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (193, 'CIENTO NOVENTA Y TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (194, 'CIENTO NOVENTA Y CUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (195, 'CIENTO NOVENTA Y CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (196, 'CIENTO NOVENTA Y SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (197, 'CIENTO NOVENTA Y SIETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (198, 'CIENTO NOVENTA Y OCHO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (199, 'CIENTO NOVENTA Y NUEVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (200, 'DOSCIENTOS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (201, 'DOSCIENTOS UNO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (202, 'DOSCIENTOS DOS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (203, 'DOSCIENTOS TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (204, 'DOSCIENTOS CUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (205, 'DOSCIENTOS CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (206, 'DOSCIENTOS SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (207, 'DOSCIENTOS SIETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (208, 'DOSCIENTOS OCHO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (209, 'DOSCIENTOS NUEVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (210, 'DOSCIENTOS DIEZ');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (211, 'DOSCIENTOS ONCE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (212, 'DOSCIENTOS DOCE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (213, 'DOSCIENTOS TRECE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (214, 'DOSCIENTOS CATORCE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (215, 'DOSCIENTOS QUINCE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (216, 'DOSCIENTOS DIECISEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (217, 'DOSCIENTOS DIECISIETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (218, 'DOSCIENTOS DIECIOCHO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (219, 'DOSCIENTOS DIECINUEVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (220, 'DOSCIENTOS VEINTE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (221, 'DOSCIENTOS VEINTIUNO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (222, 'DOSCIENTOS VEINTIDOS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (223, 'DOSCIENTOS VEINTITRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (224, 'DOSCIENTOS VEINTICUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (225, 'DOSCIENTOS VEINTICINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (226, 'DOSCIENTOS VEINTISEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (227, 'DOSCIENTOS VEINTISIETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (228, 'DOSCIENTOS VEINTIOCHO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (229, 'DOSCIENTOS VEINTINUEVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (230, 'DOSCIENTOS TREINTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (231, 'DOSCIENTOS TREINTA Y UNO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (232, 'DOSCIENTOS TREINTA Y DOS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (233, 'DOSCIENTOS TREINTA Y TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (234, 'DOSCIENTOS TREINTA Y CUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (235, 'DOSCIENTOS TREINTA Y CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (236, 'DOSCIENTOS TREINTA Y SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (237, 'DOSCIENTOS TREINTA Y SIETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (238, 'DOSCIENTOS TREINTA Y OCHO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (239, 'DOSCIENTOS TREINTA Y NUEVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (240, 'DOSCIENTOS CUARENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (241, 'DOSCIENTOS CUARENTA Y UNO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (242, 'DOSCIENTOS CUARENTA Y DOS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (243, 'DOSCIENTOS CUARENTA Y TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (244, 'DOSCIENTOS CUARENTA Y CUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (245, 'DOSCIENTOS CUARENTA Y CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (246, 'DOSCIENTOS CUARENTA Y SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (247, 'DOSCIENTOS CUARENTA Y SIETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (248, 'DOSCIENTOS CUARENTA Y OCHO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (249, 'DOSCIENTOS CUARENTA Y NUEVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (250, 'DOSCIENTOS CINCUENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (251, 'DOSCIENTOS CINCUENTA Y UNO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (252, 'DOSCIENTOS CINCUENTA Y DOS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (253, 'DOSCIENTOS CINCUENTA Y TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (254, 'DOSCIENTOS CINCUENTA Y CUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (255, 'DOSCIENTOS CINCUENTA Y CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (256, 'DOSCIENTOS CINCUENTA Y SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (257, 'DOSCIENTOS CINCUENTA Y SIETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (258, 'DOSCIENTOS CINCUENTA Y OCHO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (259, 'DOSCIENTOS CINCUENTA Y NUEVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (260, 'DOSCIENTOS SESENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (261, 'DOSCIENTOS SESENTA Y UNO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (262, 'DOSCIENTOS SESENTA Y DOS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (263, 'DOSCIENTOS SESENTA Y TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (264, 'DOSCIENTOS SESENTA Y CUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (265, 'DOSCIENTOS SESENTA Y CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (266, 'DOSCIENTOS SESENTA Y SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (267, 'DOSCIENTOS SESENTA Y SIETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (268, 'DOSCIENTOS SESENTA Y OCHO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (269, 'DOSCIENTOS SESENTA Y NUEVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (270, 'DOSCIENTOS SETENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (271, 'DOSCIENTOS SETENTA Y UNO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (272, 'DOSCIENTOS SETENTA Y DOS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (273, 'DOSCIENTOS SETENTA Y TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (274, 'DOSCIENTOS SETENTA Y CUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (275, 'DOSCIENTOS SETENTA Y CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (276, 'DOSCIENTOS SETENTA Y SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (277, 'DOSCIENTOS SETENTA Y SIETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (278, 'DOSCIENTOS SETENTA Y OCHO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (279, 'DOSCIENTOS SETENTA Y NUEVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (280, 'DOSCIENTOS OCHENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (281, 'DOSCIENTOS OCHENTA Y UNO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (282, 'DOSCIENTOS OCHENTA Y DOS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (283, 'DOSCIENTOS OCHENTA Y TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (284, 'DOSCIENTOS OCHENTA Y CUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (285, 'DOSCIENTOS OCHENTA Y CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (286, 'DOSCIENTOS OCHENTA Y SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (287, 'DOSCIENTOS OCHENTA Y SIETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (288, 'DOSCIENTOS OCHENTA Y OCHO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (289, 'DOSCIENTOS OCHENTA Y NUEVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (290, 'DOSCIENTOS NOVENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (291, 'DOSCIENTOS NOVENTA Y UNO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (292, 'DOSCIENTOS NOVENTA Y DOS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (293, 'DOSCIENTOS NOVENTA Y TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (294, 'DOSCIENTOS NOVENTA Y CUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (295, 'DOSCIENTOS NOVENTA Y CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (296, 'DOSCIENTOS NOVENTA Y SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (297, 'DOSCIENTOS NOVENTA Y SIETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (298, 'DOSCIENTOS NOVENTA Y OCHO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (299, 'DOSCIENTOS NOVENTA Y NUEVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (300, 'TRESCIENTOS');

alter table conversion_numeros add column numero_homologado varchar;

update conversion_numeros
set numero_homologado = replace(numero_texto,' ','');

create index idx_numeronatural on conversion_numeros(numero_natural);
create index idx_numerotexto on conversion_numeros(numero_texto);
commit;

do $$
begin
	raise notice 'Tabla de numeros a texto, Terminada...';
end $$;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-------------------------PREPARACION CAPA PLACAS--------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

------------------------------------------------------------------------
--NORMALIZAR NOMBRES
------------------------------------------------------------------------
do $$
begin
	raise notice '--------------------------------------------------------------';
	raise notice '--Iniciando depuracion de caracteres especiales en placas...--';
	raise notice '--------------------------------------------------------------';
end $$;

begin;

UPDATE placas
SET nomvia_placas = UPPER(nomvia_placas)
WHERE nomvia_placas ~ '[a-z]';

do $$
begin
raise notice 'Depuracion de caracteres especiales, 25%%...';
end $$;


UPDATE placas
SET nomvia_placas = unaccent(nomvia_placas)
WHERE nomvia_placas ~* '[Ã„â‚¬Ãƒâ‚¬ÃƒÂÃƒâ€šÃƒÆ’Ãƒâ€žÃƒâ€¦Ãƒâ€ Ãƒâ€¡ÃƒË†Ãƒâ€°ÃƒÅ Ãƒâ€¹ÃƒÅ’ÃƒÂÃƒÅ½ÃƒÂÃƒÂÃƒâ€˜Ãƒâ€™Ãƒâ€œÃƒâ€Ãƒâ€¢Ãƒâ€“ÃƒËœÃƒâ„¢ÃƒÅ¡Ãƒâ€ºÃƒÅ“ÃƒÂ]';

do $$
begin
raise notice 'Depuracion de caracteres especiales, 50%%...';
end $$;

-- EliminaciÃƒÂ³n de caracteres especiales: , . - _ : ; { } + Ã‚Â´ Ã‚Â¿ ' Ã‚Â¿ ' ( ) / \ *
UPDATE placas
SET nomvia_placas = REGEXP_REPLACE(nomvia_placas, '[,\.\-\_\:\;\{\}\+Ã‚Â´Ã‚Â¿''\(\)\/\\\*]', ' ', 'g')
WHERE nomvia_placas ~ '[,\.\-\_\:\;\{\}\+Ã‚Â´Ã‚Â¿''\(\)\/\\\*]';

do $$
begin
raise notice 'Depuracion de caracteres especiales, 75%%...';
end $$;


UPDATE placas
SET nomvia_placas = REGEXP_REPLACE(nomvia_placas, '\s+', ' ', 'g')
WHERE nomvia_placas ~ '\s{2,}';

commit;

do $$
begin
raise notice 'Depuracion de caracteres especiales, Finalizada!...';
end $$;

------------------------------------------------------------------------
--CONVERTIR A NUMERO ALFABETICO
------------------------------------------------------------------------

do $$
begin
	raise notice '--------------------------------------------------------';
	raise notice '--Conversion de Numero a Texto en placas, Iniciando...--';
	raise notice '--------------------------------------------------------';
End $$;

-----------------------------------------------------------------------
--natural a texto en nomvia_placas
begin;

DO $$
DECLARE
  r RECORD;
  total INT := 0;
BEGIN
  FOR r IN SELECT * FROM conversion_numeros LOOP
    UPDATE placas c
    SET nomvia_placas = regexp_replace(
      c.nomvia_placas,
      '\m' || r.numero_natural || '\M',
      r.numero_homologado,
      'gi'
    )
    WHERE c.nomvia_placas ~ ('\m' || r.numero_natural || '\M');

    GET DIAGNOSTICS total = ROW_COUNT;

    IF total > 0 THEN
      RAISE NOTICE 'Reemplazado % por % en % registros', r.numero_natural, r.numero_homologado, total;
    END IF;
  END LOOP;
END $$;

commit;

------------------------------------------------------------------------
--CREAR NOMVIA DEPURADO, SIN TIPOVIAS
------------------------------------------------------------------------
BEGIN;

UPDATE placas
SET nomvia_placas_limpio = REGEXP_REPLACE(nomvia_placas, listado_palabras(), '', 'g')
WHERE nomvia_placas ~ listado_palabras();
	
--dobles espacios	
UPDATE placas
SET nomvia_placas_limpio = trim(regexp_replace(nomvia_placas_limpio, '\s+', ' ', 'g'))
WHERE nomvia_placas_limpio ~ '\s{2,}' OR
      nomvia_placas_limpio LIKE ' %' OR
      nomvia_placas_limpio LIKE '% ';
	  
COMMIT;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-------------------------PREPARACION CAPA MAVVIAL--------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

------------------------------------------------------------------------
--NORMALIZAR NOMBRES
------------------------------------------------------------------------
do $$
begin
	raise notice 'Iniciando depuracion de caracteres especiales...';
end $$;

begin;

UPDATE mavvial_homologar
SET nomvia_mavvial = UPPER(nomvia_mavvial)
WHERE nomvia_mavvial ~ '[a-z]';

do $$
begin
raise notice 'Depuracion de caracteres especiales, 25%%...';
end $$;


UPDATE mavvial_homologar
SET nomvia_mavvial = unaccent(nomvia_mavvial)
WHERE nomvia_mavvial ~* '[Ã„â‚¬Ãƒâ‚¬ÃƒÂÃƒâ€šÃƒÆ’Ãƒâ€žÃƒâ€¦Ãƒâ€ Ãƒâ€¡ÃƒË†Ãƒâ€°ÃƒÅ Ãƒâ€¹ÃƒÅ’ÃƒÂÃƒÅ½ÃƒÂÃƒÂÃƒâ€˜Ãƒâ€™Ãƒâ€œÃƒâ€Ãƒâ€¢Ãƒâ€“ÃƒËœÃƒâ„¢ÃƒÅ¡Ãƒâ€ºÃƒÅ“ÃƒÂ]';

do $$
begin
raise notice 'Depuracion de caracteres especiales, 50%%...';
end $$;

-- EliminaciÃƒÂ³n de caracteres especiales: , . - _ : ; { } + Ã‚Â´ Ã‚Â¿ ' Ã‚Â¿ ' ( ) / \ *
UPDATE mavvial_homologar
SET nomvia_mavvial = REGEXP_REPLACE(nomvia_mavvial, '[,\.\-\_\:\;\{\}\+Ã‚Â´Ã‚Â¿''\(\)\/\\\*]', ' ', 'g')
WHERE nomvia_mavvial ~ '[,\.\-\_\:\;\{\}\+Ã‚Â´Ã‚Â¿''\(\)\/\\\*]';

do $$
begin
raise notice 'Depuracion de caracteres especiales, 75%%...';
end $$;


UPDATE mavvial_homologar
SET nomvia_mavvial = REGEXP_REPLACE(nomvia_mavvial, '\s+', ' ', 'g')
WHERE nomvia_mavvial ~ '\s{2,}';

commit;

do $$
begin
raise notice 'Depuracion de caracteres especiales, Finalizada!...';
end $$;

------------------------------------------------------------------------
--CONVERTIR A NUMERO ALFABETICO
------------------------------------------------------------------------

do $$
begin
	raise notice '--------------------------------------------------------';
	raise notice '--Conversion de Numero a Texto en mavvial, Iniciando...--';
	raise notice '--------------------------------------------------------';
End $$;

-----------------------------------------------------------------------
--natural a texto en nomvia_mavvial
begin;

DO $$
DECLARE
  r RECORD;
  total INT := 0;
BEGIN
  FOR r IN SELECT * FROM conversion_numeros LOOP
    UPDATE mavvial_homologar c
    SET nomvia_mavvial = regexp_replace(
      c.nomvia_mavvial,
      '\m' || r.numero_natural || '\M',
      r.numero_homologado,
      'gi'
    )
    WHERE c.nomvia_mavvial ~ ('\m' || r.numero_natural || '\M');

    GET DIAGNOSTICS total = ROW_COUNT;

    IF total > 0 THEN
      RAISE NOTICE 'Reemplazado % por % en % registros', r.numero_natural, r.numero_homologado, total;
    END IF;
  END LOOP;
END $$;

commit;

------------------------------------------------------------------------
--CREAR NOMVIA DEPURADO, SIN TIPOVIAS
------------------------------------------------------------------------
BEGIN;

UPDATE mavvial_homologar
SET nomvia_mavvial_limpio = REGEXP_REPLACE(nomvia_mavvial, listado_palabras(), '', 'g')
WHERE nomvia_mavvial ~ listado_palabras();
	
--dobles espacios	
UPDATE mavvial_homologar
SET nomvia_mavvial_limpio = trim(regexp_replace(nomvia_mavvial_limpio, '\s+', ' ', 'g'))
WHERE nomvia_mavvial_limpio ~ '\s{2,}' OR
      nomvia_mavvial_limpio LIKE ' %' OR
      nomvia_mavvial_limpio LIKE '% ';

--rellenar nombres no modificados
update mavvial_homologar
set nomvia_mavvial_limpio = nomvia_mavvial
where nomvia_mavvial_limpio is null and nomvia_mavvial is not null;
	  
COMMIT;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------ALIMENTAR placaS---------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
analyze placas;
analyze mavvial_homologar;


do $$
begin
	raise notice '----------------------------------------------------------';
	raise notice '--Actualizacion de nomvia mavvial a placas, Iniciando...--';
	raise notice '----------------------------------------------------------';
End $$;

begin;
--CREAR INDICES ESPACIALES PARA LAS CAPAS
create index idx_placas_geom on placas using gist (geom);
create index idx_placas_id on placas (id_capa);
create index idx_mmavvial_homologar_geom on mavvial_homologar using gist (geom);
CREATE INDEX idx_mavvial_id ON mavvial_homologar(id_mavvial);
commit;

-----------------------------------------------------------------------
-- FIX v5: Se reemplaza el DO $$ con loop + LIMIT/OFFSET por un
-- UPDATE ÃƒÂºnico. Razones del congelamiento original:
--
--   1) DO $$ NO puede hacer COMMIT intermedio en PostgreSQL.
--      Todos los UPDATEs del loop se acumulaban en UNA sola
--      transacciÃƒÂ³n monolÃƒÂ­tica Ã¢â€ â€™ WAL sin liberar, row-locks
--      acumulados = congelamiento.
--
--   2) LIMIT X OFFSET Y se degrada: en la iteraciÃƒÂ³n N, PostgreSQL
--      escanea N * lote_size filas solo para descartarlas.
--
-- SoluciÃƒÂ³n: Con los ÃƒÂ­ndices GiST ya creados arriba, un UPDATE ÃƒÂºnico
-- con JOIN LATERAL + ST_DWithin resuelve todo sin batching.
-- El ÃƒÂ­ndice GiST hace que cada bÃƒÂºsqueda espacial sea O(log n),
-- eliminando la necesidad del loop.
--
-- NOTA SISTEMA DE COORDENADAS (Antofagasta, Chile):
-- Las capas deben estar en WGS84 geogrÃƒÂ¡fico (EPSG:4326) para que
-- el umbral de ST_DWithin (0.0009 grados Ã¢â€°Ë† 100 m) sea correcto,
-- o en UTM Huso 19S (EPSG:32719) ajustando el umbral a metros (100).
-- Verificar con: SELECT ST_SRID(geom) FROM "04_coq_prueba"."placa_coq" LIMIT 1;
-----------------------------------------------------------------------

-- OPTIMIZADO: el LATERAL ya trae las 3 vias mas cercanas por placa usando el
-- indice GiST (<->). El WHERE ST_DWithin solo acota el universo; con LIMIT 3 y
-- ORDER BY <-> el KNN es O(log n) por placa. Se baja el radio a ~40m para que en
-- zonas urbanas densas no evalue decenas de vias por placa (causa del cuelgue).
-- Si tus geom estan en UTM 32719 (metros), cambia 0.00036 por 40.
UPDATE placas cp
SET
    id_mavvial1 = sub.id_m1,
    nomvia_mavvial1 = sub.nom_m1,
    nomvia_mavvial1_limpio = sub.lim_m1,
    id_mavvial2 = sub.id_m2,
    nomvia_mavvial2 = sub.nom_m2,
    nomvia_mavvial2_limpio = sub.lim_m2,
    id_mavvial3 = sub.id_m3,
    nomvia_mavvial3 = sub.nom_m3,
    nomvia_mavvial3_limpio = sub.lim_m3
FROM (
    SELECT
        p.id_capa,
        MAX(CASE WHEN rn = 1 THEN m.id END)::varchar   AS id_m1,
        MAX(CASE WHEN rn = 1 THEN m.nomvia_mavvial END) AS nom_m1,
        MAX(CASE WHEN rn = 1 THEN m.nomvia_mavvial_limpio END) AS lim_m1,
        MAX(CASE WHEN rn = 2 THEN m.id END)::varchar   AS id_m2,
        MAX(CASE WHEN rn = 2 THEN m.nomvia_mavvial END) AS nom_m2,
        MAX(CASE WHEN rn = 2 THEN m.nomvia_mavvial_limpio END) AS lim_m2,
        MAX(CASE WHEN rn = 3 THEN m.id END)::varchar   AS id_m3,
        MAX(CASE WHEN rn = 3 THEN m.nomvia_mavvial END) AS nom_m3,
        MAX(CASE WHEN rn = 3 THEN m.nomvia_mavvial_limpio END) AS lim_m3
    FROM placas p
    JOIN LATERAL (
        SELECT id_mavvial AS id, nomvia_mavvial, nomvia_mavvial_limpio,
               ROW_NUMBER() OVER (ORDER BY p.geom <-> mavvial_homologar.geom) AS rn
        FROM mavvial_homologar
        WHERE ST_DWithin(p.geom, mavvial_homologar.geom, 0.00036)  -- ~40m (antes 0.0009 ~100m)
        ORDER BY p.geom <-> mavvial_homologar.geom
        LIMIT 3
    ) m ON true
    GROUP BY p.id_capa
) sub
WHERE cp.id_capa = sub.id_capa;



-----------------------------------------------------------------------
----------------------- COMPARACIONES ---------------------------------
-----------------------------------------------------------------------
do $$
begin
	raise notice '-------------------------------------------------';
	raise notice '------Iniciando Analisis, Metodo directo...------';
	raise notice '-------------------------------------------------';
End $$;

BEGIN;

-----------------------------------------------------------------------
-- Metodo directo
-----------------------------------------------------------------------

-- columna nom_directo existe
ALTER TABLE placas ADD COLUMN nom_directo TEXT;
ALTER TABLE placas ADD COLUMN id_mavvial TEXT;

-- Paso 1: comparar con nomvia_mavvial1
UPDATE placas
SET nom_directo = nomvia_mavvial1, id_mavvial = id_mavvial1
WHERE nom_directo IS NULL
  AND nomvia_placas = nomvia_mavvial1;

-- Paso 2: comparar con nomvia_mavvial2
UPDATE placas
SET nom_directo = nomvia_mavvial2, id_mavvial = id_mavvial2
WHERE nom_directo IS NULL
  AND nomvia_placas = nomvia_mavvial2;

-- Paso 3: comparar con nomvia_mavvial3
UPDATE placas
SET nom_directo = nomvia_mavvial3, id_mavvial = id_mavvial3
WHERE nom_directo IS NULL
  AND nomvia_placas = nomvia_mavvial3;

-- Paso 4: comparar con nomvia_mavvial4
UPDATE placas
SET nom_directo = nomvia_mavvial4, id_mavvial = id_mavvial4
WHERE nom_directo IS NULL
  AND nomvia_placas = nomvia_mavvial4;
  
do $$
begin
	raise notice 'Metodo Directo, 50%%...';
end $$;
  
  
-----------------------------------------------------------------------
-- Con nombres limpios

-- Paso 1: comparar con nomvia_mavvial1
UPDATE placas
SET nom_directo = nomvia_mavvial1, id_mavvial = id_mavvial1
WHERE nom_directo IS NULL
  AND nomvia_placas = nomvia_mavvial1_limpio;

-- Paso 2: comparar con nomvia_mavvial2
UPDATE placas
SET nom_directo = nomvia_mavvial2, id_mavvial = id_mavvial2
WHERE nom_directo IS NULL
  AND nomvia_placas = nomvia_mavvial2_limpio;

-- Paso 3: comparar con nomvia_mavvial3
UPDATE placas
SET nom_directo = nomvia_mavvial3, id_mavvial = id_mavvial3
WHERE nom_directo IS NULL
  AND nomvia_placas = nomvia_mavvial3_limpio;

-- Paso 4: comparar con nomvia_mavvial4
UPDATE placas
SET nom_directo = nomvia_mavvial4, id_mavvial = id_mavvial4
WHERE nom_directo IS NULL
  AND nomvia_placas = nomvia_mavvial4_limpio;
  
-----------------------------------------------------------------------
--Entre nombres limpios

-- Paso 1: comparar con nomvia_mavvial1
UPDATE placas
SET nom_directo = nomvia_mavvial1, id_mavvial = id_mavvial1
WHERE nom_directo IS NULL
  AND nomvia_placas_limpio = nomvia_mavvial1_limpio;

-- Paso 2: comparar con nomvia_mavvial2
UPDATE placas
SET nom_directo = nomvia_mavvial2, id_mavvial = id_mavvial2
WHERE nom_directo IS NULL
  AND nomvia_placas_limpio = nomvia_mavvial2_limpio;

-- Paso 3: comparar con nomvia_mavvial3
UPDATE placas
SET nom_directo = nomvia_mavvial3, id_mavvial = id_mavvial3
WHERE nom_directo IS NULL
  AND nomvia_placas_limpio = nomvia_mavvial3_limpio;

-- Paso 4: comparar con nomvia_mavvial4
UPDATE placas
SET nom_directo = nomvia_mavvial4, id_mavvial = id_mavvial4
WHERE nom_directo IS NULL
  AND nomvia_placas_limpio = nomvia_mavvial4_limpio;
  
commit;

ANALYZE placas;

do $$
begin 
	raise notice 'Metodo directo, 90%%';
end $$;



--------------------------------------------------------------
-- Extraer los registros que pasaron el metodo directo. 
drop table if exists placa_homologada_directo;
create table placa_homologada_directo as
select * from placas 
where id_mavvial is not null;

delete from placas
where id_mavvial is not null;

do $$
begin 
	raise notice 'Metodo directo, Finalizado';
end $$;

-----------------------------------------------------------------------
-- lIMPIEZA PREVIA ANALISIS DE SIMILITUDES
-----------------------------------------------------------------------
--Limpieza previa para evitar falsos positivos
--Primero se limpian aquellos registros que al quitar las palabras irrelevantes
--deja como remanente una letra independiente o dos letras, con el fin de evitar falsos positivos
BEGIN;

update placas
set nomvia_mavvial1_limpio = null, nomvia_mavvial1 = null
WHERE (length(REGEXP_REPLACE(nomvia_mavvial1_limpio, '\s', '', 'g')) <= 2
  AND REGEXP_REPLACE(nomvia_mavvial1_limpio, '\s', '', 'g') ~ '^[A-Za-z]+$') or nomvia_mavvial1_limpio is null;
  
update placas
set nomvia_mavvial2_limpio = null, nomvia_mavvial2 = null
WHERE (length(REGEXP_REPLACE(nomvia_mavvial2_limpio, '\s', '', 'g')) <= 2
  AND REGEXP_REPLACE(nomvia_mavvial2_limpio, '\s', '', 'g') ~ '^[A-Za-z]+$') or nomvia_mavvial2_limpio is null;
  
update placas
set nomvia_mavvial3_limpio = null, nomvia_mavvial3 = null
WHERE (length(REGEXP_REPLACE(nomvia_mavvial3_limpio, '\s', '', 'g')) <= 2
  AND REGEXP_REPLACE(nomvia_mavvial3_limpio, '\s', '', 'g') ~ '^[A-Za-z]+$') or nomvia_mavvial3_limpio is null;
  
COMMIT;

-----------------------------------------------------------------------
-- Metodo Double
-----------------------------------------------------------------------



do $$
begin
	raise notice '------------------------------';
	raise notice '--Iniciando metodo Double...--';
	raise notice '------------------------------';
end $$;

begin;

----------------------------------------------------------------------
--SIMILARITY DOUBLE
----------------------------------------------------------------------

ALTER TABLE placas drop COLUMN if exists nom_similarity;
ALTER TABLE placas ADD COLUMN nom_similarity TEXT;

UPDATE placas 
SET nom_similarity = subquery.nomvia_mavvial_mas_similar
FROM (
    SELECT id_capa, nomvia_placas,
           (SELECT nomvia_mavvial
            FROM (VALUES 
                     (nomvia_mavvial1, SIMILARITY(nomvia_placas, COALESCE(nomvia_mavvial1, ''))),
                     (nomvia_mavvial2, SIMILARITY(nomvia_placas, COALESCE(nomvia_mavvial2, ''))),
                     (nomvia_mavvial3, SIMILARITY(nomvia_placas, COALESCE(nomvia_mavvial3, ''))),
                     (nomvia_mavvial4, SIMILARITY(nomvia_placas, COALESCE(nomvia_mavvial4, '')))
                 ) AS temp(nomvia_mavvial, similitud)
            WHERE similitud >= 0.6  -- Ajusta el umbral de similitud
            ORDER BY similitud DESC
            LIMIT 1
           ) AS nomvia_mavvial_mas_similar
    FROM placas
	where nom_directo is null
) AS subquery
WHERE placas.id_capa = subquery.id_capa
AND placas.nom_directo IS NULL;
commit;

do $$
begin
	raise notice 'Metodo Double, 10%%...';
end $$;

-----------------------------------------------------------------------
--Similarity placas en mavvial_limpio

begin;
UPDATE placas 
SET nom_similarity = subquery.nomvia_mavvial_mas_similar
FROM (
    SELECT id_capa, nomvia_placas,
           (SELECT nomvia_mavvial
            FROM (VALUES 
                     (nomvia_mavvial1_limpio, SIMILARITY(nomvia_placas, COALESCE(nomvia_mavvial1_limpio, ''))),
                     (nomvia_mavvial2_limpio, SIMILARITY(nomvia_placas, COALESCE(nomvia_mavvial2_limpio, ''))),
                     (nomvia_mavvial3_limpio, SIMILARITY(nomvia_placas, COALESCE(nomvia_mavvial3_limpio, ''))),
                     (nomvia_mavvial4_limpio, SIMILARITY(nomvia_placas, COALESCE(nomvia_mavvial4_limpio, '')))
                 ) AS temp(nomvia_mavvial, similitud)
            WHERE similitud >= 0.6  -- Ajusta el umbral de similitud
            ORDER BY similitud DESC
            LIMIT 1
           ) AS nomvia_mavvial_mas_similar
    FROM placas
	where nom_directo is null
) AS subquery
WHERE placas.id_capa = subquery.id_capa
AND placas.nom_directo IS NULL
AND placas.nom_similarity is null;

commit;

do $$
begin
	raise notice 'Metodo Double, 20%%...';
end $$;

-----------------------------------------------------------------------
--Similarity placas_limpio en mavvial

begin;

UPDATE placas 
SET nom_similarity = subquery.nomvia_mavvial_mas_similar
FROM (
    SELECT id_capa, nomvia_placas_limpio,
           (SELECT nomvia_mavvial
            FROM (VALUES 
                     (nomvia_mavvial1, SIMILARITY(nomvia_placas_limpio, COALESCE(nomvia_mavvial1, ''))),
                     (nomvia_mavvial2, SIMILARITY(nomvia_placas_limpio, COALESCE(nomvia_mavvial2, ''))),
                     (nomvia_mavvial3, SIMILARITY(nomvia_placas_limpio, COALESCE(nomvia_mavvial3, ''))),
                     (nomvia_mavvial4, SIMILARITY(nomvia_placas_limpio, COALESCE(nomvia_mavvial4, '')))
                 ) AS temp(nomvia_mavvial, similitud)
            WHERE similitud >= 0.6  -- Ajusta el umbral de similitud
            ORDER BY similitud DESC
            LIMIT 1
           ) AS nomvia_mavvial_mas_similar
    FROM placas
	where nom_directo is null
) AS subquery
WHERE placas.id_capa = subquery.id_capa
AND placas.nom_directo IS NULL
and placas.nom_similarity is null;

commit;

do $$
begin
	raise notice 'Metodo Double, 30%%...';
end $$;

-----------------------------------------------------------------------
--Similarity placas_limpio en mavvial_limpio

begin;


UPDATE placas 
SET nom_similarity = subquery.nomvia_mavvial_mas_similar
FROM (
    SELECT id_capa, nomvia_placas_limpio,
           (SELECT nomvia_mavvial
            FROM (VALUES 
                     (nomvia_mavvial1_limpio, SIMILARITY(nomvia_placas_limpio, COALESCE(nomvia_mavvial1_limpio, ''))),
                     (nomvia_mavvial2_limpio, SIMILARITY(nomvia_placas_limpio, COALESCE(nomvia_mavvial2_limpio, ''))),
                     (nomvia_mavvial3_limpio, SIMILARITY(nomvia_placas_limpio, COALESCE(nomvia_mavvial3_limpio, ''))),
                     (nomvia_mavvial4_limpio, SIMILARITY(nomvia_placas_limpio, COALESCE(nomvia_mavvial4_limpio, '')))
                 ) AS temp(nomvia_mavvial, similitud)
            WHERE similitud >= 0.6  -- Ajusta el umbral de similitud
            ORDER BY similitud DESC
            LIMIT 1
           ) AS nomvia_mavvial_mas_similar
    FROM placas
	where nom_directo is null
) AS subquery
WHERE placas.id_capa = subquery.id_capa
AND placas.nom_directo IS NULL
AND placas.nom_similarity is null;

commit;

do $$
begin
	raise notice 'Metodo Double, 40%%...';
end $$;

-----------------------------------------------------------------------
--Asignar nombres sin limpiar
-----------------------------------------------------------------------
begin;

update placas
set nom_similarity = nomvia_mavvial1
where nom_similarity = nomvia_mavvial1_limpio
and nom_similarity is not null;

update placas
set nom_similarity = nomvia_mavvial2
where nom_similarity = nomvia_mavvial2_limpio
and nom_similarity is not null;

update placas
set nom_similarity = nomvia_mavvial3
where nom_similarity = nomvia_mavvial3_limpio
and nom_similarity is not null;
commit; 

do $$
begin
	raise notice 'Metodo Double, 50%%...';
end $$;

ANALYZE placas;

----------------------------------------------------------------------
--LEVENSHTEIN DOUBLE
----------------------------------------------------------------------

ALTER TABLE placas ADD COLUMN nom_levenshtein TEXT;

UPDATE placas 
SET nom_levenshtein = subquery.nomvia_mavvial_mas_similar
FROM (
    SELECT id_capa, nomvia_placas,
           (SELECT nomvia_mavvial
            FROM (VALUES 
                     (nomvia_mavvial1, LEVENSHTEIN(nomvia_placas, COALESCE(nomvia_mavvial1, ''))),
                     (nomvia_mavvial2, LEVENSHTEIN(nomvia_placas, COALESCE(nomvia_mavvial2, ''))),
                     (nomvia_mavvial3, LEVENSHTEIN(nomvia_placas, COALESCE(nomvia_mavvial3, ''))),
                     (nomvia_mavvial4, LEVENSHTEIN(nomvia_placas, COALESCE(nomvia_mavvial4, '')))
                 ) AS temp(nomvia_mavvial, distancia)
            WHERE distancia <= 5  -- Ajusta el umbral de distancia de ediciÃƒÂ³n
            ORDER BY distancia ASC
            LIMIT 1
           ) AS nomvia_mavvial_mas_similar
    FROM placas
	where placas.nom_directo IS NULL
) AS subquery
WHERE placas.id_capa = subquery.id_capa
AND placas.nom_directo IS NULL;



do $$
begin
	raise notice 'Metodo Double, 60%%...';
end $$;

-----------------------------------------------------------------------
--LEVENSHTEIN placas en mavvial_limpio

begin;

UPDATE placas 
SET nom_levenshtein = subquery.nomvia_mavvial_mas_similar
FROM (
    SELECT id_capa, nomvia_placas,
           (SELECT nomvia_mavvial
            FROM (VALUES 
                     (nomvia_mavvial1_limpio, LEVENSHTEIN(nomvia_placas, COALESCE(nomvia_mavvial1_limpio, ''))),
                     (nomvia_mavvial2_limpio, LEVENSHTEIN(nomvia_placas, COALESCE(nomvia_mavvial2_limpio, ''))),
                     (nomvia_mavvial3_limpio, LEVENSHTEIN(nomvia_placas, COALESCE(nomvia_mavvial3_limpio, ''))),
                     (nomvia_mavvial4_limpio, LEVENSHTEIN(nomvia_placas, COALESCE(nomvia_mavvial4_limpio, '')))
                 ) AS temp(nomvia_mavvial, distancia)
            WHERE distancia <= 5  -- Ajusta el umbral de distancia de ediciÃƒÂ³n
            ORDER BY distancia ASC
            LIMIT 1
           ) AS nomvia_mavvial_mas_similar
    FROM placas
	where placas.nom_directo IS NULL
	and placas.nom_levenshtein is null
) AS subquery
WHERE placas.id_capa = subquery.id_capa
AND placas.nom_directo IS NULL
AND placas.nom_levenshtein is null;

commit;

do $$
begin
	raise notice 'Metodo Double, 70%%...';
end $$;


-----------------------------------------------------------------------
--levenshtein placas_limpio en mavvial

begin;

UPDATE placas 
SET nom_levenshtein = subquery.nomvia_mavvial_mas_similar
FROM (
    SELECT id_capa, nomvia_placas_limpio,
           (SELECT nomvia_mavvial
            FROM (VALUES 
                     (nomvia_mavvial1, LEVENSHTEIN(nomvia_placas_limpio, COALESCE(nomvia_mavvial1, ''))),
                     (nomvia_mavvial2, LEVENSHTEIN(nomvia_placas_limpio, COALESCE(nomvia_mavvial2, ''))),
                     (nomvia_mavvial3, LEVENSHTEIN(nomvia_placas_limpio, COALESCE(nomvia_mavvial3, ''))),
                     (nomvia_mavvial4, LEVENSHTEIN(nomvia_placas_limpio, COALESCE(nomvia_mavvial4, '')))
                 ) AS temp(nomvia_mavvial, distancia)
            WHERE distancia <= 5  -- Ajusta el umbral de distancia de ediciÃƒÂ³n
            ORDER BY distancia ASC
            LIMIT 1
           ) AS nomvia_mavvial_mas_similar
    FROM placas
	where placas.nom_directo IS NULL
	and placas.nom_levenshtein is null
) AS subquery
WHERE placas.id_capa = subquery.id_capa
AND placas.nom_directo IS NULL
and placas.nom_levenshtein is null;

commit;

do $$
begin
	raise notice 'Metodo Double, 80%%...';
end $$;


-----------------------------------------------------------------------
--levenshtein placas_limpio en mavvial_limpio

begin;

UPDATE placas 
SET nom_levenshtein = subquery.nomvia_mavvial_mas_similar
FROM (
    SELECT id_capa, nomvia_placas_limpio,
           (SELECT nomvia_mavvial
            FROM (VALUES 
                     (nomvia_mavvial1_limpio, LEVENSHTEIN(nomvia_placas_limpio, COALESCE(nomvia_mavvial1_limpio, ''))),
                     (nomvia_mavvial2_limpio, LEVENSHTEIN(nomvia_placas_limpio, COALESCE(nomvia_mavvial2_limpio, ''))),
                     (nomvia_mavvial3_limpio, LEVENSHTEIN(nomvia_placas_limpio, COALESCE(nomvia_mavvial3_limpio, ''))),
                     (nomvia_mavvial4_limpio, LEVENSHTEIN(nomvia_placas_limpio, COALESCE(nomvia_mavvial4_limpio, '')))
                 ) AS temp(nomvia_mavvial, distancia)
            WHERE distancia <= 5  -- Ajusta el umbral de distancia de ediciÃƒÂ³n
            ORDER BY distancia ASC
            LIMIT 1
           ) AS nomvia_mavvial_mas_similar
    FROM placas
	where placas.nom_directo IS NULL
	and placas.nom_levenshtein is null
) AS subquery
WHERE placas.id_capa = subquery.id_capa
AND placas.nom_directo IS NULL
and placas.nom_levenshtein is null;

commit;

do $$
begin
	raise notice 'Metodo Double, 90%%...';
end $$;


-----------------------------------------------------------------------
--Asignar nombres sin limpiar
-----------------------------------------------------------------------

update placas
set nom_levenshtein = nomvia_mavvial1
where nom_levenshtein = nomvia_mavvial1_limpio
and nom_levenshtein is not null;

update placas
set nom_levenshtein = nomvia_mavvial2
where nom_levenshtein = nomvia_mavvial2_limpio
and nom_levenshtein is not null;

update placas
set nom_levenshtein = nomvia_mavvial3
where nom_levenshtein = nomvia_mavvial3_limpio
and nom_levenshtein is not null;

do $$
begin
	raise notice 'Metodo Double, 95%%...';
end $$;

ANALYZE placas;

-----------------------------------------------------------------------
--ASIGNAR RESULTADO DOUBLE
-----------------------------------------------------------------------

UPDATE placas
set nom_similarity = null, nom_levenshtein = null
where nom_similarity IS DISTINCT FROM nom_levenshtein;

alter table placas add column nom_double varchar;

UPDATE placas
set nom_double = nom_similarity
where nom_similarity = nom_levenshtein and nom_similarity is not null;

alter table placas drop column nom_levenshtein;
alter table placas drop column nom_similarity;

-----------------------------------------------------------------------
--Asignar id_mavvial
-----------------------------------------------------------------------
update placas
set id_mavvial = id_mavvial1
where nom_double = nomvia_mavvial1
and id_mavvial is null;

update placas
set id_mavvial = id_mavvial2
where nom_double = nomvia_mavvial2
and id_mavvial is null;

update placas
set id_mavvial = id_mavvial3
where nom_double = nomvia_mavvial3
and id_mavvial is null;

update placas
set id_mavvial = id_mavvial4
where nom_double = nomvia_mavvial4
and id_mavvial is null;

----------------------------------------------------------------------
--CREAR CAPA DOUBLES

drop table if exists placa_homologada_double;
create table placa_homologada_double as select * from placas where nom_double is not null;

delete from placas where nom_double is not null;

do $$
begin
	raise notice 'Metodo Double, Finalizado...';
end $$;

-----------------------------------------------------------------------
--METODO XWORD
-----------------------------------------------------------------------
begin;
do $$
begin
	raise notice '-----------------------------';
	raise notice '--Iniciando metodo Xword...--';
	raise notice '-----------------------------';
end $$;
--------------------------------------------------
ALTER TABLE placas DROP COLUMN IF EXISTS nom_xword;
ALTER TABLE placas ADD COLUMN nom_xword VARCHAR;

-----------------------------------------------------------------------
--placas en mavvial
UPDATE placas
SET nom_xword = nomvia_mavvial1
where nomvia_mavvial1 ~ ('\m' || nomvia_placas || '\M') and nom_xword is null;

UPDATE placas
SET nom_xword = nomvia_mavvial2
where nomvia_mavvial2 ~ ('\m' || nomvia_placas || '\M') and nom_xword is null;

UPDATE placas
SET nom_xword = nomvia_mavvial3
where nomvia_mavvial3 ~ ('\m' || nomvia_placas || '\M') and nom_xword is null;

commit;

do $$
begin
	raise notice 'Metodo Xword, 10%%...';
end $$;


-----------------------------------------------------------------------
--mavvial en placas

begin;

UPDATE placas
SET nom_xword = nomvia_mavvial1
where nomvia_placas ~ ('\m' || nomvia_mavvial1 || '\M') and nom_xword is null ;

UPDATE placas
SET nom_xword = nomvia_mavvial2
where nomvia_placas ~ ('\m' || nomvia_mavvial2 || '\M') and nom_xword is null ;

UPDATE placas
SET nom_xword = nomvia_mavvial3
where nomvia_placas ~ ('\m' || nomvia_mavvial3 || '\M') and nom_xword is null ;

commit;

do $$
begin
	raise notice 'Metodo Xword, 20%%...';
end $$;


-----------------------------------------------------------------------
--placas_limpio en mavvial

begin;

UPDATE placas
SET nom_xword = nomvia_mavvial1
where nomvia_mavvial1 ~ ('\m' || nomvia_placas_limpio || '\M') and nom_xword is null ;

UPDATE placas
SET nom_xword = nomvia_mavvial2
where nomvia_mavvial2 ~ ('\m' || nomvia_placas_limpio || '\M') and nom_xword is null ;

UPDATE placas
SET nom_xword = nomvia_mavvial3
where nomvia_mavvial3 ~ ('\m' || nomvia_placas_limpio || '\M') and nom_xword is null ;

commit;

do $$
begin
	raise notice 'Metodo Xword, 30%%...';
end $$;


-----------------------------------------------------------------------
--placas_limpio en mavvial_limpio

begin;


UPDATE placas
SET nom_xword = nomvia_mavvial1
where nomvia_mavvial1_limpio ~ ('\m' || nomvia_placas_limpio || '\M') and nom_xword is null ;

UPDATE placas
SET nom_xword = nomvia_mavvial2
where nomvia_mavvial2_limpio ~ ('\m' || nomvia_placas_limpio || '\M') and nom_xword is null ;

UPDATE placas
SET nom_xword = nomvia_mavvial3
where nomvia_mavvial3_limpio ~ ('\m' || nomvia_placas_limpio || '\M') and nom_xword is null ;

commit;

do $$
begin
	raise notice 'Metodo Xword, 60%%...';
end $$;


-----------------------------------------------------------------------
--mavvial_limpio en placas

begin;


UPDATE placas
SET nom_xword = nomvia_mavvial1
where nomvia_placas ~ ('\m' || nomvia_mavvial1_limpio || '\M') and nom_xword is null ;

UPDATE placas
SET nom_xword = nomvia_mavvial2
where nomvia_placas ~ ('\m' || nomvia_mavvial2_limpio || '\M') and nom_xword is null ;

UPDATE placas
SET nom_xword = nomvia_mavvial3
where nomvia_placas ~ ('\m' || nomvia_mavvial3_limpio || '\M') and nom_xword is null ;

commit;

do $$
begin
	raise notice 'Metodo Xword, 80%%...';
end $$;

-----------------------------------------------------------------------
-- mavvial_limpio en placas_limpio

begin;


UPDATE placas
SET nom_xword = nomvia_mavvial1
where  nomvia_placas_limpio ~ ('\m' || nomvia_mavvial1_limpio || '\M') and nom_xword is null ;

UPDATE placas
SET nom_xword = nomvia_mavvial2
where  nomvia_placas_limpio ~ ('\m' || nomvia_mavvial2_limpio || '\M') and nom_xword is null ;

UPDATE placas
SET nom_xword = nomvia_mavvial3
where  nomvia_placas_limpio ~ ('\m' || nomvia_mavvial3_limpio || '\M') and nom_xword is null ;

commit;
-----------------------------------------------------------------------
--Asignar nombres sin limpiar
-----------------------------------------------------------------------

update placas
set nom_xword = nomvia_mavvial1
where nom_xword = nomvia_mavvial1_limpio
and nom_xword is not null;

update placas
set nom_xword = nomvia_mavvial2
where nom_xword = nomvia_mavvial2_limpio
and nom_xword is not null;

update placas
set nom_xword = nomvia_mavvial3
where nom_xword = nomvia_mavvial3_limpio
and nom_xword is not null;

ANALYZE placas;

-----------------------------------------------------------------------
--Asignar id_mavvial
-----------------------------------------------------------------------
update placas
set id_mavvial = id_mavvial1
where nom_xword = nomvia_mavvial1
and id_mavvial is null;

update placas
set id_mavvial = id_mavvial2
where nom_xword = nomvia_mavvial2
and id_mavvial is null;

update placas
set id_mavvial = id_mavvial3
where nom_xword = nomvia_mavvial3
and id_mavvial is null;

update placas
set id_mavvial = id_mavvial4
where nom_xword = nomvia_mavvial4
and id_mavvial is null;

----------------------------------------------------------------------
--CREAR CAPA xword

drop table if exists placa_homologada_xword;
create table placa_homologada_xword as select * from placas where nom_xword is not null;

delete from placas where nom_xword is not null;

do $$
begin
	raise notice 'Metodo Xword, Finalizado...';
end $$;

-----------------------------------------------------------------------
-----------------------------------------------------------------------
---------------METODO SIMILARITY MAS ESTRICTO--------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------
Begin;

do $$
begin
	raise notice '-------------------------------------';
	raise notice '--Iniciando Similarity Estricto...--';
	raise notice '-------------------------------------';
end $$;
-----------------------------------------------------------------------
--Similarity placas en mavvial

alter table placas add column nom_similarity varchar;

UPDATE placas 
SET nom_similarity = subquery.nomvia_mavvial_mas_similar
FROM (
    SELECT id_capa, nomvia_placas,
           (SELECT nomvia_mavvial
            FROM (VALUES 
                     (nomvia_mavvial1, SIMILARITY(nomvia_placas, COALESCE(nomvia_mavvial1, ''))),
                     (nomvia_mavvial2, SIMILARITY(nomvia_placas, COALESCE(nomvia_mavvial2, ''))),
                     (nomvia_mavvial3, SIMILARITY(nomvia_placas, COALESCE(nomvia_mavvial3, ''))),
                     (nomvia_mavvial4, SIMILARITY(nomvia_placas, COALESCE(nomvia_mavvial4, '')))
                 ) AS temp(nomvia_mavvial, similitud)
            WHERE similitud >= 0.90  -- Ajusta el umbral de similitud
            ORDER BY similitud DESC
            LIMIT 1
           ) AS nomvia_mavvial_mas_similar
    FROM placas
	where nom_directo is null 
	and nom_similarity is null
	and nom_xword is null
) AS subquery
WHERE placas.id_capa = subquery.id_capa
AND placas.nom_directo IS NULL
AND placas.nom_similarity is null
and placas.nom_xword is null;

commit;

do $$
begin
	raise notice 'Metodo Similarity Estricto, 20%%...';
end $$;


-----------------------------------------------------------------------
--Similarity placas en mavvial_limpio

begin;


UPDATE placas 
SET nom_similarity = subquery.nomvia_mavvial_mas_similar
FROM (
    SELECT id_capa, nomvia_placas,
           (SELECT nomvia_mavvial
            FROM (VALUES 
                     (nomvia_mavvial1_limpio, SIMILARITY(nomvia_placas, COALESCE(nomvia_mavvial1_limpio, ''))),
                     (nomvia_mavvial2_limpio, SIMILARITY(nomvia_placas, COALESCE(nomvia_mavvial2_limpio, ''))),
                     (nomvia_mavvial3_limpio, SIMILARITY(nomvia_placas, COALESCE(nomvia_mavvial3_limpio, ''))),
                     (nomvia_mavvial4_limpio, SIMILARITY(nomvia_placas, COALESCE(nomvia_mavvial4_limpio, '')))
                 ) AS temp(nomvia_mavvial, similitud)
            WHERE similitud >= 0.90  -- Ajusta el umbral de similitud
            ORDER BY similitud DESC
            LIMIT 1
           ) AS nomvia_mavvial_mas_similar
    FROM placas
	where nom_directo is null 
	and nom_similarity is null
	and nom_xword is null
) AS subquery
WHERE placas.id_capa = subquery.id_capa
AND placas.nom_directo IS NULL
AND placas.nom_similarity is null
and placas.nom_xword is null;

commit;

do $$
begin
	raise notice 'Metodo Similarity Estricto, 40%%...';
end $$;


-----------------------------------------------------------------------
--Similarity placas_limpio en mavvial

begin;

UPDATE placas 
SET nom_similarity = subquery.nomvia_mavvial_mas_similar
FROM (
    SELECT id_capa, nomvia_placas_limpio,
           (SELECT nomvia_mavvial
            FROM (VALUES 
                     (nomvia_mavvial1, SIMILARITY(nomvia_placas_limpio, COALESCE(nomvia_mavvial1, ''))),
                     (nomvia_mavvial2, SIMILARITY(nomvia_placas_limpio, COALESCE(nomvia_mavvial2, ''))),
                     (nomvia_mavvial3, SIMILARITY(nomvia_placas_limpio, COALESCE(nomvia_mavvial3, ''))),
                     (nomvia_mavvial4, SIMILARITY(nomvia_placas_limpio, COALESCE(nomvia_mavvial4, '')))
                 ) AS temp(nomvia_mavvial, similitud)
            WHERE similitud >= 0.90  -- Ajusta el umbral de similitud
            ORDER BY similitud DESC
            LIMIT 1
           ) AS nomvia_mavvial_mas_similar
    FROM placas
	where nom_directo is null 
	and nom_similarity is null
	and nom_xword is null
) AS subquery
WHERE placas.id_capa = subquery.id_capa
AND placas.nom_directo IS NULL
and placas.nom_similarity is null
and placas.nom_xword is null;

commit;

do $$
begin
	raise notice 'Metodo Similarity Estricto, 60%%...';
end $$;


-----------------------------------------------------------------------
--Similarity placas_limpio en mavvial_limpio

begin;

UPDATE placas 
SET nom_similarity = subquery.nomvia_mavvial_mas_similar
FROM (
    SELECT id_capa, nomvia_placas_limpio,
           (SELECT nomvia_mavvial
            FROM (VALUES 
                     (nomvia_mavvial1_limpio, SIMILARITY(nomvia_placas_limpio, COALESCE(nomvia_mavvial1_limpio, ''))),
                     (nomvia_mavvial2_limpio, SIMILARITY(nomvia_placas_limpio, COALESCE(nomvia_mavvial2_limpio, ''))),
                     (nomvia_mavvial3_limpio, SIMILARITY(nomvia_placas_limpio, COALESCE(nomvia_mavvial3_limpio, ''))),
                     (nomvia_mavvial4_limpio, SIMILARITY(nomvia_placas_limpio, COALESCE(nomvia_mavvial4_limpio, '')))
                 ) AS temp(nomvia_mavvial, similitud)
            WHERE similitud >= 0.90  -- Ajusta el umbral de similitud
            ORDER BY similitud DESC
            LIMIT 1
           ) AS nomvia_mavvial_mas_similar
    FROM placas
	where nom_directo is null 
	and nom_similarity is null
	and nom_xword is null
) AS subquery
WHERE placas.id_capa = subquery.id_capa
AND placas.nom_directo IS NULL
AND placas.nom_similarity is null
and placas.nom_xword is null;

commit;

do $$
begin
	raise notice 'Metodo Similarity Estricto, 80%%...';
end $$;


-----------------------------------------------------------------------
--Asignar nombres sin limpiar
-----------------------------------------------------------------------
begin;

update placas
set nom_similarity = nomvia_mavvial1
where nom_similarity = nomvia_mavvial1_limpio
and nom_similarity is not null;

update placas
set nom_similarity = nomvia_mavvial2
where nom_similarity = nomvia_mavvial2_limpio
and nom_similarity is not null;

update placas
set nom_similarity = nomvia_mavvial3
where nom_similarity = nomvia_mavvial3_limpio
and nom_similarity is not null;

----------------------------------------------------------------------
--asignar id_mavvial
update placas
set id_mavvial = id_mavvial1
where nom_similarity = nomvia_mavvial1
and id_mavvial is null;

update placas
set id_mavvial = id_mavvial2
where nom_similarity = nomvia_mavvial2
and id_mavvial is null;

update placas
set id_mavvial = id_mavvial3
where nom_similarity = nomvia_mavvial3
and id_mavvial is null;

update placas
set id_mavvial = id_mavvial4
where nom_similarity = nomvia_mavvial4
and id_mavvial is null;

commit;



----------------------------------------------------------------------
--CREAR CAPA SIMILARITY ESTRICTO

drop table if exists placa_homologada_similarity;
create table placa_homologada_similarity as select * from placas where nom_similarity is not null;

delete from placas where nom_similarity is not null;

do $$
begin
	raise notice 'Metodo Similarity restrigido, Finalizado...';
end $$;

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--------------METODO LEVENSHTEIN MAS ESTRICTO--------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------

Begin;

do $$
begin
	raise notice '-------------------------------------';
	raise notice '--Iniciando Levenshtein Estricto...--';
	raise notice '-------------------------------------';
end $$;
-----------------------------------------------------------------------
--LEVENSHTEIN placas en mavvial

alter table placas add column nom_levenshtein varchar;

UPDATE placas 
SET nom_levenshtein = subquery.nomvia_mavvial_mas_similar
FROM (
    SELECT id_capa, nomvia_placas,
           (SELECT nomvia_mavvial
            FROM (VALUES 
                     (nomvia_mavvial1, LEVENSHTEIN(nomvia_placas, COALESCE(nomvia_mavvial1, ''))),
                     (nomvia_mavvial2, LEVENSHTEIN(nomvia_placas, COALESCE(nomvia_mavvial2, ''))),
                     (nomvia_mavvial3, LEVENSHTEIN(nomvia_placas, COALESCE(nomvia_mavvial3, ''))),
                     (nomvia_mavvial4, LEVENSHTEIN(nomvia_placas, COALESCE(nomvia_mavvial4, '')))
                 ) AS temp(nomvia_mavvial, distancia)
            WHERE distancia <= 1  -- Ajusta el umbral de distancia de ediciÃƒÂ³n
            ORDER BY distancia ASC
            LIMIT 1
           ) AS nomvia_mavvial_mas_similar
    FROM placas
	where placas.nom_directo IS NULL
	AND placas.nom_levenshtein is null
	and placas.nom_xword is null
) AS subquery
WHERE placas.id_capa = subquery.id_capa
AND placas.nom_directo IS NULL
AND placas.nom_levenshtein is null
and placas.nom_xword is null;

commit;

do $$
begin
	raise notice 'Metodo Levenshtein Estricto, 20%%...';
end $$;

-----------------------------------------------------------------------
--LEVENSHTEIN placas en mavvial_limpio

begin;

UPDATE placas 
SET nom_levenshtein = subquery.nomvia_mavvial_mas_similar
FROM (
    SELECT id_capa, nomvia_placas,
           (SELECT nomvia_mavvial
            FROM (VALUES 
                     (nomvia_mavvial1_limpio, LEVENSHTEIN(nomvia_placas, COALESCE(nomvia_mavvial1_limpio, ''))),
                     (nomvia_mavvial2_limpio, LEVENSHTEIN(nomvia_placas, COALESCE(nomvia_mavvial2_limpio, ''))),
                     (nomvia_mavvial3_limpio, LEVENSHTEIN(nomvia_placas, COALESCE(nomvia_mavvial3_limpio, ''))),
                     (nomvia_mavvial4_limpio, LEVENSHTEIN(nomvia_placas, COALESCE(nomvia_mavvial4_limpio, '')))
                 ) AS temp(nomvia_mavvial, distancia)
            WHERE distancia <= 1  -- Ajusta el umbral de distancia de ediciÃƒÂ³n
            ORDER BY distancia ASC
            LIMIT 1
           ) AS nomvia_mavvial_mas_similar
    FROM placas
	where placas.nom_directo IS NULL
	and placas.nom_levenshtein is null
	and placas.nom_xword is null
) AS subquery
WHERE placas.id_capa = subquery.id_capa
AND placas.nom_directo IS NULL
AND placas.nom_levenshtein is null
and placas.nom_xword is null;

commit;

do $$
begin
	raise notice 'Metodo Levenshtein Estricto, 40%%...';
end $$;

-----------------------------------------------------------------------
--levenshtein placas_limpio en mavvial

begin;

UPDATE placas 
SET nom_levenshtein = subquery.nomvia_mavvial_mas_similar
FROM (
    SELECT id_capa, nomvia_placas_limpio,
           (SELECT nomvia_mavvial
            FROM (VALUES 
                     (nomvia_mavvial1, LEVENSHTEIN(nomvia_placas_limpio, COALESCE(nomvia_mavvial1, ''))),
                     (nomvia_mavvial2, LEVENSHTEIN(nomvia_placas_limpio, COALESCE(nomvia_mavvial2, ''))),
                     (nomvia_mavvial3, LEVENSHTEIN(nomvia_placas_limpio, COALESCE(nomvia_mavvial3, ''))),
                     (nomvia_mavvial4, LEVENSHTEIN(nomvia_placas_limpio, COALESCE(nomvia_mavvial4, '')))
                 ) AS temp(nomvia_mavvial, distancia)
            WHERE distancia <= 1  -- Ajusta el umbral de distancia de ediciÃƒÂ³n
            ORDER BY distancia ASC
            LIMIT 1
           ) AS nomvia_mavvial_mas_similar
    FROM placas
	where placas.nom_directo IS NULL
	and placas.nom_levenshtein is null
	and placas.nom_xword is null
) AS subquery
WHERE placas.id_capa = subquery.id_capa
AND placas.nom_directo IS NULL
and placas.nom_levenshtein is null
and placas.nom_xword is null;

commit;

do $$
begin
	raise notice 'Metodo Levenshtein Estricto, 60%%...';
end $$;

-----------------------------------------------------------------------
--levenshtein placas_limpio en mavvial_limpio

begin;

UPDATE placas 
SET nom_levenshtein = subquery.nomvia_mavvial_mas_similar
FROM (
    SELECT id_capa, nomvia_placas_limpio,
           (SELECT nomvia_mavvial
            FROM (VALUES 
                     (nomvia_mavvial1_limpio, LEVENSHTEIN(nomvia_placas_limpio, COALESCE(nomvia_mavvial1_limpio, ''))),
                     (nomvia_mavvial2_limpio, LEVENSHTEIN(nomvia_placas_limpio, COALESCE(nomvia_mavvial2_limpio, ''))),
                     (nomvia_mavvial3_limpio, LEVENSHTEIN(nomvia_placas_limpio, COALESCE(nomvia_mavvial3_limpio, ''))),
                     (nomvia_mavvial4_limpio, LEVENSHTEIN(nomvia_placas_limpio, COALESCE(nomvia_mavvial4_limpio, '')))
                 ) AS temp(nomvia_mavvial, distancia)
            WHERE distancia <= 1  -- Ajusta el umbral de distancia de ediciÃƒÂ³n
            ORDER BY distancia ASC
            LIMIT 1
           ) AS nomvia_mavvial_mas_similar
    FROM placas
	where placas.nom_directo IS NULL
	and placas.nom_levenshtein is null
	and placas.nom_xword is null
) AS subquery
WHERE placas.id_capa = subquery.id_capa
AND placas.nom_directo IS NULL
and placas.nom_levenshtein is null
and placas.nom_xword is null;

commit;

do $$
begin
	raise notice 'Metodo Levenshtein Estricto, 80%%...';
end $$;

-----------------------------------------------------------------------
--Asignar nombres sin limpiar
-----------------------------------------------------------------------

begin;

update placas
set nom_levenshtein = nomvia_mavvial1
where nom_levenshtein = nomvia_mavvial1_limpio
and nom_levenshtein is not null;

update placas
set nom_levenshtein = nomvia_mavvial2
where nom_levenshtein = nomvia_mavvial2_limpio
and nom_levenshtein is not null;

update placas
set nom_levenshtein = nomvia_mavvial3
where nom_levenshtein = nomvia_mavvial3_limpio
and nom_levenshtein is not null;

----------------------------------------------------------------------
--asignar id_mavvial
update placas
set id_mavvial = id_mavvial1
where nom_levenshtein = nomvia_mavvial1
and id_mavvial is null;

update placas
set id_mavvial = id_mavvial2
where nom_levenshtein = nomvia_mavvial2
and id_mavvial is null;

update placas
set id_mavvial = id_mavvial3
where nom_levenshtein = nomvia_mavvial3
and id_mavvial is null;

update placas
set id_mavvial = id_mavvial4
where nom_levenshtein = nomvia_mavvial4
and id_mavvial is null;

commit;

----------------------------------------------------------------------
--CREAR CAPA levenshtein ESTRICTO
BEGIN;

drop table if exists placa_homologada_levenshtein;
create table placa_homologada_levenshtein as select * from placas where nom_levenshtein is not null;

delete from placas where nom_levenshtein is not null;

do $$
begin
	raise notice 'Metodo Similarity restrigido, Finalizado...';
end $$;

do $$
begin
	raise notice 'Metodo Levenshtein restringido, Finalizado...';
End $$;

COMMIT;

-----------------------------------------------------------------------
-----------------------------------------------------------------------
-----------ACTUALIZACION DE DATOS EN CAPA ORIGINAL---------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------
BEGIN;

do $$
begin
	raise notice '-----------------------------------------------';
	raise notice '--Iniciando Actualizacion en capa original...--';
	raise notice '-----------------------------------------------';
end $$;

------------------------------------------------------------------
REINDEX TABLE "04_coq_prueba"."placa_coq";
create index idx_id_placa_homologada_directo on placa_homologada_directo (id_capa);
create index idx_id_placa_homologada_double on placa_homologada_double (id_capa);
create index idx_id_placa_homologada_xword on placa_homologada_xword (id_capa);
create index idx_id_placa_homologada_similarity on placa_homologada_similarity (id_capa);
create index idx_id_placa_homologada_levenshtein on placa_homologada_levenshtein (id_capa);

alter table "04_coq_prueba"."placa_coq" drop column if exists nom_homologado;
alter table "04_coq_prueba"."placa_coq" drop column if exists id_mavvial_homologado;
alter table "04_coq_prueba"."placa_coq" drop column if exists metodo_homologado;

alter table "04_coq_prueba"."placa_coq" add column nom_homologado varchar;
alter table "04_coq_prueba"."placa_coq" add column id_mavvial_homologado integer;
alter table "04_coq_prueba"."placa_coq" add column metodo_homologado varchar;

----------------------------------------------------------------
-- tabla temporal de homologados

DROP TABLE IF EXISTS homologados_tmp;

CREATE TEMP TABLE homologados_tmp AS
SELECT id_capa, nom_directo AS nom, id_mavvial, 'DIRECTO' AS metodo FROM placa_homologada_directo
UNION ALL
SELECT id_capa, nom_double, id_mavvial, 'DOUBLE' FROM placa_homologada_double
UNION ALL
SELECT id_capa, nom_xword, id_mavvial, 'XWORD' FROM placa_homologada_xword
UNION ALL
SELECT id_capa, nom_similarity, id_mavvial, 'SIMILARITY' FROM placa_homologada_similarity
UNION ALL
SELECT id_capa, nom_levenshtein, id_mavvial, 'LEVENSHTEIN' FROM placa_homologada_levenshtein;

-- Indexar para acelerar joins
CREATE INDEX ON homologados_tmp(id_capa);

----------------------------------------------------------------
-- Actualizar capa placa original
----------------------------------------------------------------
-- CORREGIDO: sin bucles WHILE (se colgaban con id_capa no denso)
--            sin count correlacionado O(N*M) que tardaba horas.
--            Dos UPDATE unicos que el planner resuelve como HASH JOIN.

-- 1) Volcar resultado de homologacion (UPDATE unico)
UPDATE "04_coq_prueba"."placa_coq" p
SET nom_homologado        = h.nom,
    id_mavvial_homologado = h.id_mavvial::integer,
    metodo_homologado     = h.metodo
FROM homologados_tmp h
WHERE p.id_capa = h.id_capa;

do $$ begin raise notice '--Paso 1/2 (resultado homologacion) terminado.--'; end $$;

-----------------------------------------------------------------------
----ACTUALIZACION CON DATOS ORIGINALES DE MAVVIAL

do $$
begin
	raise notice '-----------------------------------------------';
	raise notice '--Iniciando Actualizacion placa vs mavvial...--';
	raise notice '-----------------------------------------------';
end $$;

-- 2) Backfill con nombre ORIGINAL de mavvial (UPDATE unico; SIN count, SIN WHILE)
--    Aqui estaba el cuelgue de horas. Ahora es una sola pasada (hash join).
UPDATE "04_coq_prueba"."placa_coq" p
SET nom_homologado = d.nomvia_mavvial_original
FROM mavvial_homologar d
WHERE p.id_mavvial_homologado = d.id_mavvial::integer;

do $$ begin raise notice '--Paso 2/2 (nombre original mavvial) terminado.--'; end $$;

COMMIT;

-----------------------------------------------------------------------
-----------------------------------------------------------------------
---------------------ELIMINAR CAPAS DE PROCESOS------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------
DROP TABLE placas;
DROP TABLE mavvial_homologar;
DROP TABLE placa_homologada_levenshtein;
DROP TABLE placa_homologada_similarity;
DROP TABLE placa_homologada_xword;
DROP TABLE placa_homologada_directo;
DROP TABLE placa_homologada_double;
