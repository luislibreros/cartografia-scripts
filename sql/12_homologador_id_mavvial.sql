-- ServiFlow · script de placas (parametrizado)
-- El esquema es {{esquema}} (se elige en el panel). Modo 'schema':
-- corre DIRECTO sobre el esquema elegido; úsalo en un esquema de trabajo.

/*
********************************************************************************
* Código: Homologador_v2
* Autor: Jhoinner Manrique
* Fecha de creación: 10-11-2024
* Última modificación:12-02-2026
* Versión: 5.0 -- FIX: congelamiento en "Alimentar placas"
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
select id, geom, nomvia from "{{esquema}}"."placa";-----------------------------------nombre_placas

--renombrar campos para proceso
ALTER TABLE placas RENAME COLUMN nomvia TO nomvia_placas;


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
select id, id_capa, geom, nomvtotal from "{{esquema}}"."mavvial_fin";-----------------------------------nombre_mavvial_fin

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
--Listado de palabras a omitir en el proceso
--------------------------------------------------------------------------------
DROP FUNCTION IF EXISTS listado_palabras();
CREATE OR REPLACE FUNCTION listado_palabras()
RETURNS text AS $$
BEGIN
    RETURN '\m(ESCADARIA|FUNDOS|GOVERNADOR|VEREADOR|SUBOFICIAL|LINHA|NOSSA SENHORA|INTENDENTE|PREFEITO|MINISTRO|CONDOMINIO|MISSIONARIO|VARIANTE|PAL|ANTIGA|ESTR|ACCESO|GENERAL|SANTA|SANTO|PROJETADA|SAO|DOUTOR|PADRE|PROFESSOR|CORONEL|PRESIDENTE|VEREADOR|DOM|ENGENHEIRO|ENGENHEIRA|ALMIRANTE|ACESSO|ALAMEDA|VILA|LARGO|RODOANEL|AVENIDA|QUADRA|PASSAGEM|BOULEVARD|BECO|RUELA|VIELA|CAMINHO|ESTRADA|RUA|RODOVIA|LIGACAO|CONTINUACAO|CONTORNO|TRAVESSIA|TRANSVERSAL|PRACA|RETORNO|ELEVADO|ESCADA|ESCADARIA|SERVIDAO|ESQUINA|EXTENSAO|TRECHO|TRAVESSA|LOTE|MARGINAL|OUTROS|PASSARELA|CORREDOR|LADEIRA|ANEL VIARIO|PERIMETRAL|PONTE|PASSEIO|SAIDA|TRAVESSAO|TREVO|TUNEL|VIA|VIADUTO|SENDERO)\M';
END;
$$ LANGUAGE plpgsql;

-----------------------------------------------------------------------
-- TABLA DE NUMEROS
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
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (00, 'ZERO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (01, 'UM');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (02, 'DOIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (03, 'TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (04, 'QUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (05, 'CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (06, 'SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (07, 'SETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (08, 'OITO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (09, 'NOVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (0, 'ZERO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (1, 'UM');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (2, 'DOIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (3, 'TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (4, 'QUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (5, 'CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (6, 'SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (7, 'SETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (8, 'OITO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (9, 'NOVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (10, 'DEZ');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (11, 'ONZE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (12, 'DOZE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (13, 'TREZE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (14, 'CATORZE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (15, 'QUINZE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (16, 'DEZESSEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (17, 'DEZESSETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (18, 'DEZOITO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (19, 'DEZENOVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (20, 'VINTE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (21, 'VINTE E UM');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (22, 'VINTE E DOIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (23, 'VINTE E TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (24, 'VINTE E QUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (25, 'VINTE E CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (26, 'VINTE E SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (27, 'VINTE E SETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (28, 'VINTE E OITO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (29, 'VINTE E NOVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (30, 'TRINTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (31, 'TRINTA E UM');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (32, 'TRINTA E DOIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (33, 'TRINTA E TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (34, 'TRINTA E QUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (35, 'TRINTA E CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (36, 'TRINTA E SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (37, 'TRINTA E SETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (38, 'TRINTA E OITO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (39, 'TRINTA E NOVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (40, 'QUARENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (41, 'QUARENTA E UM');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (42, 'QUARENTA E DOIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (43, 'QUARENTA E TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (44, 'QUARENTA E QUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (45, 'QUARENTA E CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (46, 'QUARENTA E SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (47, 'QUARENTA E SETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (48, 'QUARENTA E OITO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (49, 'QUARENTA E NOVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (50, 'CINQUENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (51, 'CINQUENTA E UM');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (52, 'CINQUENTA E DOIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (53, 'CINQUENTA E TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (54, 'CINQUENTA E QUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (55, 'CINQUENTA E CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (56, 'CINQUENTA E SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (57, 'CINQUENTA E SETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (58, 'CINQUENTA E OITO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (59, 'CINQUENTA E NOVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (60, 'SESSENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (61, 'SESSENTA E UM');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (62, 'SESSENTA E DOIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (63, 'SESSENTA E TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (64, 'SESSENTA E QUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (65, 'SESSENTA E CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (66, 'SESSENTA E SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (67, 'SESSENTA E SETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (68, 'SESSENTA E OITO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (69, 'SESSENTA E NOVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (70, 'SETENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (71, 'SETENTA E UM');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (72, 'SETENTA E DOIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (73, 'SETENTA E TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (74, 'SETENTA E QUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (75, 'SETENTA E CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (76, 'SETENTA E SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (77, 'SETENTA E SETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (78, 'SETENTA E OITO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (79, 'SETENTA E NOVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (80, 'OITENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (81, 'OITENTA E UM');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (82, 'OITENTA E DOIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (83, 'OITENTA E TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (84, 'OITENTA E QUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (85, 'OITENTA E CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (86, 'OITENTA E SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (87, 'OITENTA E SETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (88, 'OITENTA E OITO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (89, 'OITENTA E NOVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (90, 'NOVENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (91, 'NOVENTA E UM');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (92, 'NOVENTA E DOIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (93, 'NOVENTA E TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (94, 'NOVENTA E QUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (95, 'NOVENTA E CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (96, 'NOVENTA E SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (97, 'NOVENTA E SETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (98, 'NOVENTA E OITO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (99, 'NOVENTA E NOVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (100, 'CEM');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (101, 'CENTO E UM');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (102, 'CENTO E DOIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (103, 'CENTO E TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (104, 'CENTO E QUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (105, 'CENTO E CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (106, 'CENTO E SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (107, 'CENTO E SETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (108, 'CENTO E OITO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (109, 'CENTO E NOVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (110, 'CENTO E DEZ');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (111, 'CENTO E ONZE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (112, 'CENTO E DOZE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (113, 'CENTO E TREZE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (114, 'CENTO E CATORZE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (115, 'CENTO E QUINZE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (116, 'CENTO E DEZESSEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (117, 'CENTO E DEZESSETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (118, 'CENTO E DEZOITO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (119, 'CENTO E DEZENOVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (120, 'CENTO E VINTE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (121, 'CENTO E VINTE E UM');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (122, 'CENTO E VINTE E DOIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (123, 'CENTO E VINTE E TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (124, 'CENTO E VINTE E QUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (125, 'CENTO E VINTE E CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (126, 'CENTO E VINTE E SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (127, 'CENTO E VINTE E SETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (128, 'CENTO E VINTE E OITO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (129, 'CENTO E VINTE E NOVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (130, 'CENTO E TRINTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (131, 'CENTO E TRINTA E UM');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (132, 'CENTO E TRINTA E DOIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (133, 'CENTO E TRINTA E TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (134, 'CENTO E TRINTA E QUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (135, 'CENTO E TRINTA E CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (136, 'CENTO E TRINTA E SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (137, 'CENTO E TRINTA E SETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (138, 'CENTO E TRINTA E OITO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (139, 'CENTO E TRINTA E NOVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (140, 'CENTO E QUARENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (141, 'CENTO E QUARENTA E UM');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (142, 'CENTO E QUARENTA E DOIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (143, 'CENTO E QUARENTA E TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (144, 'CENTO E QUARENTA E QUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (145, 'CENTO E QUARENTA E CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (146, 'CENTO E QUARENTA E SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (147, 'CENTO E QUARENTA E SETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (148, 'CENTO E QUARENTA E OITO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (149, 'CENTO E QUARENTA E NOVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (150, 'CENTO E CINQUENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (151, 'CENTO E CINQUENTA E UM');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (152, 'CENTO E CINQUENTA E DOIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (153, 'CENTO E CINQUENTA E TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (154, 'CENTO E CINQUENTA E QUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (155, 'CENTO E CINQUENTA E CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (156, 'CENTO E CINQUENTA E SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (157, 'CENTO E CINQUENTA E SETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (158, 'CENTO E CINQUENTA E OITO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (159, 'CENTO E CINQUENTA E NOVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (160, 'CENTO E SESSENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (161, 'CENTO E SESSENTA E UM');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (162, 'CENTO E SESSENTA E DOIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (163, 'CENTO E SESSENTA E TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (164, 'CENTO E SESSENTA E QUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (165, 'CENTO E SESSENTA E CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (166, 'CENTO E SESSENTA E SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (167, 'CENTO E SESSENTA E SETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (168, 'CENTO E SESSENTA E OITO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (169, 'CENTO E SESSENTA E NOVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (170, 'CENTO E SETENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (171, 'CENTO E SETENTA E UM');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (172, 'CENTO E SETENTA E DOIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (173, 'CENTO E SETENTA E TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (174, 'CENTO E SETENTA E QUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (175, 'CENTO E SETENTA E CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (176, 'CENTO E SETENTA E SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (177, 'CENTO E SETENTA E SETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (178, 'CENTO E SETENTA E OITO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (179, 'CENTO E SETENTA E NOVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (180, 'CENTO E OITENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (181, 'CENTO E OITENTA E UM');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (182, 'CENTO E OITENTA E DOIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (183, 'CENTO E OITENTA E TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (184, 'CENTO E OITENTA E QUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (185, 'CENTO E OITENTA E CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (186, 'CENTO E OITENTA E SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (187, 'CENTO E OITENTA E SETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (188, 'CENTO E OITENTA E OITO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (189, 'CENTO E OITENTA E NOVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (190, 'CENTO E NOVENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (191, 'CENTO E NOVENTA E UM');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (192, 'CENTO E NOVENTA E DOIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (193, 'CENTO E NOVENTA E TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (194, 'CENTO E NOVENTA E QUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (195, 'CENTO E NOVENTA E CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (196, 'CENTO E NOVENTA E SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (197, 'CENTO E NOVENTA E SETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (198, 'CENTO E NOVENTA E OITO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (199, 'CENTO E NOVENTA E NOVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (200, 'DUZENTOS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (201, 'DUZENTOS E UM');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (202, 'DUZENTOS E DOIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (203, 'DUZENTOS E TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (204, 'DUZENTOS E QUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (205, 'DUZENTOS E CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (206, 'DUZENTOS E SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (207, 'DUZENTOS E SETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (208, 'DUZENTOS E OITO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (209, 'DUZENTOS E NOVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (210, 'DUZENTOS E DEZ');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (211, 'DUZENTOS E ONZE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (212, 'DUZENTOS E DOZE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (213, 'DUZENTOS E TREZE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (214, 'DUZENTOS E CATORZE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (215, 'DUZENTOS E QUINZE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (216, 'DUZENTOS E DEZESSEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (217, 'DUZENTOS E DEZESSETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (218, 'DUZENTOS E DEZOITO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (219, 'DUZENTOS E DEZENOVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (220, 'DUZENTOS E VINTE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (221, 'DUZENTOS E VINTE E UM');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (222, 'DUZENTOS E VINTE E DOIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (223, 'DUZENTOS E VINTE E TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (224, 'DUZENTOS E VINTE E QUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (225, 'DUZENTOS E VINTE E CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (226, 'DUZENTOS E VINTE E SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (227, 'DUZENTOS E VINTE E SETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (228, 'DUZENTOS E VINTE E OITO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (229, 'DUZENTOS E VINTE E NOVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (230, 'DUZENTOS E TRINTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (231, 'DUZENTOS E TRINTA E UM');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (232, 'DUZENTOS E TRINTA E DOIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (233, 'DUZENTOS E TRINTA E TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (234, 'DUZENTOS E TRINTA E QUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (235, 'DUZENTOS E TRINTA E CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (236, 'DUZENTOS E TRINTA E SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (237, 'DUZENTOS E TRINTA E SETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (238, 'DUZENTOS E TRINTA E OITO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (239, 'DUZENTOS E TRINTA E NOVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (240, 'DUZENTOS E QUARENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (241, 'DUZENTOS E QUARENTA E UM');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (242, 'DUZENTOS E QUARENTA E DOIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (243, 'DUZENTOS E QUARENTA E TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (244, 'DUZENTOS E QUARENTA E QUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (245, 'DUZENTOS E QUARENTA E CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (246, 'DUZENTOS E QUARENTA E SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (247, 'DUZENTOS E QUARENTA E SETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (248, 'DUZENTOS E QUARENTA E OITO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (249, 'DUZENTOS E QUARENTA E NOVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (250, 'DUZENTOS E CINQUENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (251, 'DUZENTOS E CINQUENTA E UM');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (252, 'DUZENTOS E CINQUENTA E DOIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (253, 'DUZENTOS E CINQUENTA E TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (254, 'DUZENTOS E CINQUENTA E QUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (255, 'DUZENTOS E CINQUENTA E CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (256, 'DUZENTOS E CINQUENTA E SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (257, 'DUZENTOS E CINQUENTA E SETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (258, 'DUZENTOS E CINQUENTA E OITO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (259, 'DUZENTOS E CINQUENTA E NOVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (260, 'DUZENTOS E SESSENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (261, 'DUZENTOS E SESSENTA E UM');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (262, 'DUZENTOS E SESSENTA E DOIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (263, 'DUZENTOS E SESSENTA E TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (264, 'DUZENTOS E SESSENTA E QUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (265, 'DUZENTOS E SESSENTA E CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (266, 'DUZENTOS E SESSENTA E SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (267, 'DUZENTOS E SESSENTA E SETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (268, 'DUZENTOS E SESSENTA E OITO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (269, 'DUZENTOS E SESSENTA E NOVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (270, 'DUZENTOS E SETENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (271, 'DUZENTOS E SETENTA E UM');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (272, 'DUZENTOS E SETENTA E DOIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (273, 'DUZENTOS E SETENTA E TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (274, 'DUZENTOS E SETENTA E QUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (275, 'DUZENTOS E SETENTA E CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (276, 'DUZENTOS E SETENTA E SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (277, 'DUZENTOS E SETENTA E SETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (278, 'DUZENTOS E SETENTA E OITO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (279, 'DUZENTOS E SETENTA E NOVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (280, 'DUZENTOS E OITENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (281, 'DUZENTOS E OITENTA E UM');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (282, 'DUZENTOS E OITENTA E DOIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (283, 'DUZENTOS E OITENTA E TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (284, 'DUZENTOS E OITENTA E QUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (285, 'DUZENTOS E OITENTA E CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (286, 'DUZENTOS E OITENTA E SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (287, 'DUZENTOS E OITENTA E SETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (288, 'DUZENTOS E OITENTA E OITO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (289, 'DUZENTOS E OITENTA E NOVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (290, 'DUZENTOS E NOVENTA');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (291, 'DUZENTOS E NOVENTA E UM');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (292, 'DUZENTOS E NOVENTA E DOIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (293, 'DUZENTOS E NOVENTA E TRES');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (294, 'DUZENTOS E NOVENTA E QUATRO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (295, 'DUZENTOS E NOVENTA E CINCO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (296, 'DUZENTOS E NOVENTA E SEIS');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (297, 'DUZENTOS E NOVENTA E SETE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (298, 'DUZENTOS E NOVENTA E OITO');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (299, 'DUZENTOS E NOVENTA E NOVE');
INSERT INTO conversion_numeros (numero_natural, numero_texto) VALUES (300, 'TREZENTOS');

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
WHERE nomvia_placas ~* '[ĀÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝ]';

do $$
begin
raise notice 'Depuracion de caracteres especiales, 50%%...';
end $$;

UPDATE placas
SET nomvia_placas = REGEXP_REPLACE(nomvia_placas, '[\./\\*_\-,\(\)]', ' ', 'g')
WHERE nomvia_placas ~ '[\./\\*_\-,\(\)]';

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
WHERE nomvia_mavvial ~* '[ĀÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝ]';

do $$
begin
raise notice 'Depuracion de caracteres especiales, 50%%...';
end $$;

UPDATE mavvial_homologar
SET nomvia_mavvial = REGEXP_REPLACE(nomvia_mavvial, '[\./\\*_\-,\(\)]', ' ', 'g')
WHERE nomvia_mavvial ~ '[\./\\*_\-,\(\)]';

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
create index idx_placas_id on placas (id);
create index idx_mmavvial_homologar_geom on mavvial_homologar using gist (geom);
CREATE INDEX idx_mavvial_id ON mavvial_homologar(id);
commit;

-----------------------------------------------------------------------
-- FIX v5: Se reemplaza el DO $$ con loop + LIMIT/OFFSET por un
-- UPDATE único. Razones del congelamiento original:
--
--   1) DO $$ NO puede hacer COMMIT intermedio en PostgreSQL.
--      Todos los UPDATEs del loop se acumulaban en UNA sola
--      transacción monolítica → WAL sin liberar, row-locks
--      acumulados = congelamiento.
--
--   2) LIMIT X OFFSET Y se degrada: en la iteración N, PostgreSQL
--      escanea N * lote_size filas solo para descartarlas.
--
-- Solución: Con los índices GiST ya creados arriba, un UPDATE único
-- con JOIN LATERAL + ST_DWithin resuelve todo sin batching.
-- El índice GiST hace que cada búsqueda espacial sea O(log n),
-- eliminando la necesidad del loop.
-----------------------------------------------------------------------

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
        p.id,
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
        SELECT id, nomvia_mavvial, nomvia_mavvial_limpio,
               ROW_NUMBER() OVER (ORDER BY p.geom <-> mavvial_homologar.geom) AS rn
        FROM mavvial_homologar
        WHERE ST_DWithin(p.geom, mavvial_homologar.geom, 0.0009)
        ORDER BY p.geom <-> mavvial_homologar.geom
        LIMIT 3
    ) m ON true
    GROUP BY p.id
) sub
WHERE cp.id = sub.id;



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
    SELECT id, nomvia_placas,
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
WHERE placas.id = subquery.id
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
    SELECT id, nomvia_placas,
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
WHERE placas.id = subquery.id
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
    SELECT id, nomvia_placas_limpio,
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
WHERE placas.id = subquery.id
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
    SELECT id, nomvia_placas_limpio,
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
WHERE placas.id = subquery.id
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
    SELECT id, nomvia_placas,
           (SELECT nomvia_mavvial
            FROM (VALUES 
                     (nomvia_mavvial1, LEVENSHTEIN(nomvia_placas, COALESCE(nomvia_mavvial1, ''))),
                     (nomvia_mavvial2, LEVENSHTEIN(nomvia_placas, COALESCE(nomvia_mavvial2, ''))),
                     (nomvia_mavvial3, LEVENSHTEIN(nomvia_placas, COALESCE(nomvia_mavvial3, ''))),
                     (nomvia_mavvial4, LEVENSHTEIN(nomvia_placas, COALESCE(nomvia_mavvial4, '')))
                 ) AS temp(nomvia_mavvial, distancia)
            WHERE distancia <= 5  -- Ajusta el umbral de distancia de edición
            ORDER BY distancia ASC
            LIMIT 1
           ) AS nomvia_mavvial_mas_similar
    FROM placas
	where placas.nom_directo IS NULL
) AS subquery
WHERE placas.id = subquery.id
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
    SELECT id, nomvia_placas,
           (SELECT nomvia_mavvial
            FROM (VALUES 
                     (nomvia_mavvial1_limpio, LEVENSHTEIN(nomvia_placas, COALESCE(nomvia_mavvial1_limpio, ''))),
                     (nomvia_mavvial2_limpio, LEVENSHTEIN(nomvia_placas, COALESCE(nomvia_mavvial2_limpio, ''))),
                     (nomvia_mavvial3_limpio, LEVENSHTEIN(nomvia_placas, COALESCE(nomvia_mavvial3_limpio, ''))),
                     (nomvia_mavvial4_limpio, LEVENSHTEIN(nomvia_placas, COALESCE(nomvia_mavvial4_limpio, '')))
                 ) AS temp(nomvia_mavvial, distancia)
            WHERE distancia <= 5  -- Ajusta el umbral de distancia de edición
            ORDER BY distancia ASC
            LIMIT 1
           ) AS nomvia_mavvial_mas_similar
    FROM placas
	where placas.nom_directo IS NULL
	and placas.nom_levenshtein is null
) AS subquery
WHERE placas.id = subquery.id
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
    SELECT id, nomvia_placas_limpio,
           (SELECT nomvia_mavvial
            FROM (VALUES 
                     (nomvia_mavvial1, LEVENSHTEIN(nomvia_placas_limpio, COALESCE(nomvia_mavvial1, ''))),
                     (nomvia_mavvial2, LEVENSHTEIN(nomvia_placas_limpio, COALESCE(nomvia_mavvial2, ''))),
                     (nomvia_mavvial3, LEVENSHTEIN(nomvia_placas_limpio, COALESCE(nomvia_mavvial3, ''))),
                     (nomvia_mavvial4, LEVENSHTEIN(nomvia_placas_limpio, COALESCE(nomvia_mavvial4, '')))
                 ) AS temp(nomvia_mavvial, distancia)
            WHERE distancia <= 5  -- Ajusta el umbral de distancia de edición
            ORDER BY distancia ASC
            LIMIT 1
           ) AS nomvia_mavvial_mas_similar
    FROM placas
	where placas.nom_directo IS NULL
	and placas.nom_levenshtein is null
) AS subquery
WHERE placas.id = subquery.id
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
    SELECT id, nomvia_placas_limpio,
           (SELECT nomvia_mavvial
            FROM (VALUES 
                     (nomvia_mavvial1_limpio, LEVENSHTEIN(nomvia_placas_limpio, COALESCE(nomvia_mavvial1_limpio, ''))),
                     (nomvia_mavvial2_limpio, LEVENSHTEIN(nomvia_placas_limpio, COALESCE(nomvia_mavvial2_limpio, ''))),
                     (nomvia_mavvial3_limpio, LEVENSHTEIN(nomvia_placas_limpio, COALESCE(nomvia_mavvial3_limpio, ''))),
                     (nomvia_mavvial4_limpio, LEVENSHTEIN(nomvia_placas_limpio, COALESCE(nomvia_mavvial4_limpio, '')))
                 ) AS temp(nomvia_mavvial, distancia)
            WHERE distancia <= 5  -- Ajusta el umbral de distancia de edición
            ORDER BY distancia ASC
            LIMIT 1
           ) AS nomvia_mavvial_mas_similar
    FROM placas
	where placas.nom_directo IS NULL
	and placas.nom_levenshtein is null
) AS subquery
WHERE placas.id = subquery.id
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
    SELECT id, nomvia_placas,
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
WHERE placas.id = subquery.id
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
    SELECT id, nomvia_placas,
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
WHERE placas.id = subquery.id
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
    SELECT id, nomvia_placas_limpio,
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
WHERE placas.id = subquery.id
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
    SELECT id, nomvia_placas_limpio,
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
WHERE placas.id = subquery.id
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
    SELECT id, nomvia_placas,
           (SELECT nomvia_mavvial
            FROM (VALUES 
                     (nomvia_mavvial1, LEVENSHTEIN(nomvia_placas, COALESCE(nomvia_mavvial1, ''))),
                     (nomvia_mavvial2, LEVENSHTEIN(nomvia_placas, COALESCE(nomvia_mavvial2, ''))),
                     (nomvia_mavvial3, LEVENSHTEIN(nomvia_placas, COALESCE(nomvia_mavvial3, ''))),
                     (nomvia_mavvial4, LEVENSHTEIN(nomvia_placas, COALESCE(nomvia_mavvial4, '')))
                 ) AS temp(nomvia_mavvial, distancia)
            WHERE distancia <= 1  -- Ajusta el umbral de distancia de edición
            ORDER BY distancia ASC
            LIMIT 1
           ) AS nomvia_mavvial_mas_similar
    FROM placas
	where placas.nom_directo IS NULL
	AND placas.nom_levenshtein is null
	and placas.nom_xword is null
) AS subquery
WHERE placas.id = subquery.id
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
    SELECT id, nomvia_placas,
           (SELECT nomvia_mavvial
            FROM (VALUES 
                     (nomvia_mavvial1_limpio, LEVENSHTEIN(nomvia_placas, COALESCE(nomvia_mavvial1_limpio, ''))),
                     (nomvia_mavvial2_limpio, LEVENSHTEIN(nomvia_placas, COALESCE(nomvia_mavvial2_limpio, ''))),
                     (nomvia_mavvial3_limpio, LEVENSHTEIN(nomvia_placas, COALESCE(nomvia_mavvial3_limpio, ''))),
                     (nomvia_mavvial4_limpio, LEVENSHTEIN(nomvia_placas, COALESCE(nomvia_mavvial4_limpio, '')))
                 ) AS temp(nomvia_mavvial, distancia)
            WHERE distancia <= 1  -- Ajusta el umbral de distancia de edición
            ORDER BY distancia ASC
            LIMIT 1
           ) AS nomvia_mavvial_mas_similar
    FROM placas
	where placas.nom_directo IS NULL
	and placas.nom_levenshtein is null
	and placas.nom_xword is null
) AS subquery
WHERE placas.id = subquery.id
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
    SELECT id, nomvia_placas_limpio,
           (SELECT nomvia_mavvial
            FROM (VALUES 
                     (nomvia_mavvial1, LEVENSHTEIN(nomvia_placas_limpio, COALESCE(nomvia_mavvial1, ''))),
                     (nomvia_mavvial2, LEVENSHTEIN(nomvia_placas_limpio, COALESCE(nomvia_mavvial2, ''))),
                     (nomvia_mavvial3, LEVENSHTEIN(nomvia_placas_limpio, COALESCE(nomvia_mavvial3, ''))),
                     (nomvia_mavvial4, LEVENSHTEIN(nomvia_placas_limpio, COALESCE(nomvia_mavvial4, '')))
                 ) AS temp(nomvia_mavvial, distancia)
            WHERE distancia <= 1  -- Ajusta el umbral de distancia de edición
            ORDER BY distancia ASC
            LIMIT 1
           ) AS nomvia_mavvial_mas_similar
    FROM placas
	where placas.nom_directo IS NULL
	and placas.nom_levenshtein is null
	and placas.nom_xword is null
) AS subquery
WHERE placas.id = subquery.id
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
    SELECT id, nomvia_placas_limpio,
           (SELECT nomvia_mavvial
            FROM (VALUES 
                     (nomvia_mavvial1_limpio, LEVENSHTEIN(nomvia_placas_limpio, COALESCE(nomvia_mavvial1_limpio, ''))),
                     (nomvia_mavvial2_limpio, LEVENSHTEIN(nomvia_placas_limpio, COALESCE(nomvia_mavvial2_limpio, ''))),
                     (nomvia_mavvial3_limpio, LEVENSHTEIN(nomvia_placas_limpio, COALESCE(nomvia_mavvial3_limpio, ''))),
                     (nomvia_mavvial4_limpio, LEVENSHTEIN(nomvia_placas_limpio, COALESCE(nomvia_mavvial4_limpio, '')))
                 ) AS temp(nomvia_mavvial, distancia)
            WHERE distancia <= 1  -- Ajusta el umbral de distancia de edición
            ORDER BY distancia ASC
            LIMIT 1
           ) AS nomvia_mavvial_mas_similar
    FROM placas
	where placas.nom_directo IS NULL
	and placas.nom_levenshtein is null
	and placas.nom_xword is null
) AS subquery
WHERE placas.id = subquery.id
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
reindex table "{{esquema}}"."placa";
create index idx_id_placa_homologada_directo on placa_homologada_directo (id);
create index idx_id_placa_homologada_double on placa_homologada_double (id);
create index idx_id_placa_homologada_xword on placa_homologada_xword (id);
create index idx_id_placa_homologada_similarity on placa_homologada_similarity (id);
create index idx_id_placa_homologada_levenshtein on placa_homologada_levenshtein (id);

alter table "{{esquema}}"."placa" drop column if exists nom_homologado;
alter table "{{esquema}}"."placa" drop column if exists id_mavvial_homologado;
alter table "{{esquema}}"."placa" drop column if exists metodo_homologado;

alter table "{{esquema}}"."placa" add column nom_homologado varchar;
alter table "{{esquema}}"."placa" add column id_mavvial_homologado integer;
alter table "{{esquema}}"."placa" add column metodo_homologado varchar;

----------------------------------------------------------------
-- tabla temporal de homologados

DROP TABLE IF EXISTS homologados_tmp;

CREATE TEMP TABLE homologados_tmp AS
SELECT id, nom_directo AS nom, id_mavvial, 'DIRECTO' AS metodo FROM placa_homologada_directo
UNION ALL
SELECT id, nom_double, id_mavvial, 'DOUBLE' FROM placa_homologada_double
UNION ALL
SELECT id, nom_xword, id_mavvial, 'XWORD' FROM placa_homologada_xword
UNION ALL
SELECT id, nom_similarity, id_mavvial, 'SIMILARITY' FROM placa_homologada_similarity
UNION ALL
SELECT id, nom_levenshtein, id_mavvial, 'LEVENSHTEIN' FROM placa_homologada_levenshtein;

-- Indexar para acelerar joins
CREATE INDEX ON homologados_tmp(id);

----------------------------------------------------------------
-- Actualizar capa placa original

DO $$
DECLARE
    v_min_id bigint;
    v_max_id bigint;
    v_batch_size int := 100000; -- tamaño del lote
    v_iter int := 1;            -- contador de iteraciones
    v_total bigint;             -- total de registros en placa
    v_procesados bigint := 0;   -- acumulado procesado
    v_filas_lote bigint;        -- filas actualizadas en el lote
BEGIN
    -- calcular rango de ids en homologados (solo a los que se les hace update)
    SELECT min(id), max(id) INTO v_min_id, v_max_id FROM homologados_tmp;

    -- calcular total de registros en la tabla principal
    SELECT count(*) INTO v_total FROM "{{esquema}}"."placa";

    RAISE NOTICE 'Iniciando actualización. Total de registros en placa: %', v_total;

    WHILE v_min_id <= v_max_id LOOP
        UPDATE "{{esquema}}"."placa" p
        SET nom_homologado = h.nom,
            id_mavvial_homologado = h.id_mavvial::integer,
            metodo_homologado = h.metodo
        FROM homologados_tmp h
        WHERE p.id = h.id
          AND h.id BETWEEN v_min_id AND v_min_id + v_batch_size - 1;

        -- obtener cuántas filas se actualizaron en este lote
        GET DIAGNOSTICS v_filas_lote = ROW_COUNT;
        v_procesados := v_procesados + v_filas_lote;

        -- mostrar progreso con respecto al total de placa
        RAISE NOTICE 'Iteración %, procesados: % / % (%%%.2f)', 
                     v_iter, v_procesados, v_total, ROUND((v_procesados::numeric / v_total) * 100, 2);

        v_min_id := v_min_id + v_batch_size;
        v_iter := v_iter + 1;

    END LOOP;

    RAISE NOTICE 'Proceso terminado. Total registros actualizados: % sobre % en placa',
                 v_procesados, v_total;
END$$;

-----------------------------------------------------------------------
----ACTUALIZACION CON DATOS ORIGINALES DE MAVVIAL

do $$
begin
	raise notice '-----------------------------------------------';
	raise notice '--Iniciando Actualizacion placa vs mavvial...--';
	raise notice '-----------------------------------------------';
end $$;


DO $$
DECLARE
    v_total bigint;
    v_batch_size int := 100000; -- tamaño del lote
    v_min_id bigint;
    v_max_id bigint;
    v_current_min bigint;
    v_current_max bigint;
    v_processed bigint := 0;
    v_updated bigint;
BEGIN
    -- contar cuántas placas hay por actualizar
    SELECT count(*) INTO v_total
    FROM "{{esquema}}"."placa" p
    WHERE p.nom_homologado IS DISTINCT FROM (
        SELECT d.nomvia_mavvial_original
        FROM mavvial_homologar d
        WHERE d.id = p.id_mavvial_homologado
        LIMIT 1
    );

    RAISE NOTICE 'Hay % placas por procesar.', v_total;

    -- obtener rango de IDs
    SELECT min(id), max(id) INTO v_min_id, v_max_id
    FROM "{{esquema}}"."placa";

    v_current_min := v_min_id;

    WHILE v_current_min <= v_max_id LOOP
        v_current_max := v_current_min + v_batch_size - 1;

        -- actualizar lote
        UPDATE "{{esquema}}"."placa" p
        SET nom_homologado = d.nomvia_mavvial_original
        FROM mavvial_homologar d
        WHERE p.id_mavvial_homologado = d.id
          AND p.id BETWEEN v_current_min AND v_current_max;

        -- contar cuántas filas se actualizaron
        GET DIAGNOSTICS v_updated = ROW_COUNT;
        v_processed := v_processed + v_updated;

        RAISE NOTICE 'Lote procesado: IDs % - %, filas actualizadas: %, progreso: % / %',
            v_current_min, v_current_max, v_updated, v_processed, v_total;

        v_current_min := v_current_min + v_batch_size;
    END LOOP;

    RAISE NOTICE 'Proceso completado. Total filas actualizadas: %', v_processed;
END $$;


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





