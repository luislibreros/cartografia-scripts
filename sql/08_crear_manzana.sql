-- ServiFlow · Paso 8 · Crear manzanas (dangles + buffer + difference)
-- esquema={{esquema}} vial={{tabla}} area_urbana={{tabla_area}}

/*
********************************************************************************
* Código: identificar dangles
* Autor: Jhoinner Manrique
* Fecha de creación: 29-07-2025
* Última modificación: 29-07-2025
* Versión: 1.1
********************************************************************************
*/

--Cambiar mavvial_antofagasta por el esquema incluyendo las comillas
--cambiar mavvial_antofagasta por el nombre de la capa incluyendo las comillas

/******************************************************************
*******************IDENTIFICAR CALLEJONES**************************
******************************************************************/

--preparar capa
DROP TABLE IF EXISTS mavvial_dangles;

CREATE TABLE mavvial_dangles AS
SELECT DISTINCT ON (ST_AsBinary(geom_part)) 
       row_number() OVER () AS id,
       geom_part AS geom
FROM (
    SELECT (ST_Dump(geom)).geom AS geom_part
    FROM "{{esquema}}".{{tabla}}
) sub
ORDER BY ST_AsBinary(geom_part);



create index idex_geom_mavvial_dangles on mavvial_dangles using gist (geom);
alter table mavvial_dangles drop column if exists id;
alter table mavvial_dangles add column id serial;

----------------------------------------------------------------------------------
--CREAR TABLA CON PUNTOS INICIALES
DROP TABLE IF EXISTS start_point_mavvial;
CREATE TABLE start_point_mavvial AS
SELECT
	id,-- o el ID que tengas en la tabla original
    ST_StartPoint(geom) AS geom
FROM mavvial_dangles;

ALTER TABLE start_point_mavvial
ALTER COLUMN geom TYPE geometry(Point, 4326)
USING geom::geometry(Point, 4326); 

----------------------------------------------------------------------------------
--CREAR TABLA CON PUNTOS FINALES
DROP TABLE IF EXISTS end_point_mavvial;
CREATE TABLE end_point_mavvial AS
SELECT
	id,
    ST_EndPoint(ST_LineMerge(geom)) AS geom
FROM mavvial_dangles;

ALTER TABLE end_point_mavvial
ALTER COLUMN geom TYPE geometry(Point, 4326)
USING geom::geometry(Point, 4326); 

----------------------------------------------------------------------------------
-- CREAR TABLA DANGLES CONSOLIDADA

DROP TABLE IF EXISTS ptos_dangles;

CREATE TABLE ptos_dangles (
    id SERIAL,
    geom GEOMETRY(POINT, 4326)
);

-- 2. Insertar registros desde end_point_mavvial
INSERT INTO ptos_dangles (id, geom)
SELECT id, geom
FROM end_point_mavvial;

-- 3. Insertar registros desde start_point_mavvial
INSERT INTO ptos_dangles (id, geom)
SELECT id, geom
FROM start_point_mavvial;

-- crear indice espacial
create index idx_ptos_dangles on ptos_dangles using gist (geom);

------------------------------------------------------------------
-- crear tabla que conserva todos los extremos
drop table if exists ptos_extremos;
create table ptos_extremos as
select * from ptos_dangles;

create index idx_ptos_extremos on ptos_extremos using gist (geom);

DELETE FROM ptos_extremos
WHERE ctid IN (
  SELECT ctid
  FROM (
    SELECT ctid,
           ROW_NUMBER() OVER (PARTITION BY ST_AsEWKT(geom)) AS fila
    FROM ptos_extremos
  ) sub
  WHERE sub.fila > 1
);

reindex table ptos_extremos;

-- borrar capas de start y end
drop table end_point_mavvial;
drop table start_point_mavvial;

-----------------------------------------------------------------------------
--depurar extremos que conectan

DELETE FROM ptos_dangles
WHERE ST_AsEWKT(geom) IN (
  SELECT geom_text
  FROM (
    SELECT ST_AsEWKT(geom) AS geom_text, COUNT(*) AS cantidad
    FROM ptos_dangles
    GROUP BY geom_text
    HAVING COUNT(*) > 1
  ) repetidos
);

reindex table ptos_dangles;

------------------------------------------------------------------------
-- Alojar dangles en el esquema-----------------------------------------
------------------------------------------------------------------------

drop table if exists "{{esquema}}".dangles_totales;
create table "{{esquema}}".dangles_totales as
select * from ptos_dangles;

create index idx_geom_dangles on "{{esquema}}".dangles_totales using gist (geom);

------------------------------------------------------------------------
---------------Borrar capas temporales----------------------------------
------------------------------------------------------------------------

drop table mavvial_dangles;
drop table ptos_dangles;
drop table ptos_extremos;

/******************************************************************
*************************CREAR BUFFER******************************
******************************************************************/

--crear tabla de callejones
create table "{{esquema}}".callejones as
SELECT m.*
FROM "{{esquema}}".{{tabla}} m
WHERE EXISTS (
    SELECT 1
    FROM "{{esquema}}".dangles_totales d
    WHERE ST_Intersects(m.geom, d.geom)
);

--crear buffer callejones
drop table if exists "{{esquema}}".callejones_buffer;
CREATE TABLE "{{esquema}}".callejones_buffer AS
SELECT 
    ST_Buffer(geom, 0.00002695, 'endcap=square') AS geom
FROM "{{esquema}}".callejones;

--crear tabla de vias
create table "{{esquema}}".vias as
SELECT m.*
FROM "{{esquema}}".{{tabla}} m
WHERE not EXISTS (
    SELECT 1
    FROM "{{esquema}}".dangles_totales d
    WHERE ST_Intersects(m.geom, d.geom)
);

--crear buffer vias
drop table if exists "{{esquema}}".vias_buffer;
CREATE TABLE "{{esquema}}".vias_buffer AS
SELECT 
    ST_Buffer(geom, 0.00007186) AS geom
FROM "{{esquema}}".vias;

--crear capa total 
CREATE TABLE "{{esquema}}".buffer_vias AS
SELECT geom
FROM "{{esquema}}".vias_buffer
UNION ALL
SELECT geom
FROM "{{esquema}}".callejones_buffer;

drop index if exists "{{esquema}}".idx_geom_buffer_vias;
create index idx_geom_buffer_vias on "{{esquema}}".buffer_vias using gist (geom);

--limpiar capas 
drop table "{{esquema}}".callejones_buffer;
drop table "{{esquema}}".callejones;
drop table "{{esquema}}".vias;
drop table "{{esquema}}".vias_buffer;
drop table "{{esquema}}".dangles_totales;

/******************************************************************
*************************CREAR MANZANAS****************************
******************************************************************/

drop index if exists "{{esquema}}".idx_geom_area_urbana;
create index idx_geom_area_urbana on "{{esquema}}".{{tabla_area}} using gist(geom);

-- Primero crea la tabla vacía
DROP TABLE IF EXISTS "{{esquema}}".manzana_cruda;
CREATE TABLE "{{esquema}}".manzana_cruda (
    id SERIAL PRIMARY KEY,
    geom GEOMETRY
);

-- Procesa por lotes con mensajes de avance
DO $$
DECLARE
    area_record RECORD;
    buffer_geom GEOMETRY;
    total_areas INTEGER;
    contador INTEGER := 0;
    resultado_geom GEOMETRY;
BEGIN
    -- Calcula el total de áreas urbanas
    SELECT COUNT(*) INTO total_areas 
    FROM "{{esquema}}".{{tabla_area}};
    
    RAISE NOTICE 'Iniciando procesamiento de % áreas urbanas', total_areas;
    
    -- Pre-calcula la unión de buffers (se hace solo una vez)
    RAISE NOTICE 'Calculando unión de buffers...';
    SELECT ST_Union(geom) INTO buffer_geom 
    FROM "{{esquema}}".buffer_vias;
    
    RAISE NOTICE 'Unión de buffers completada. Procesando áreas...';
    
    -- Loop por cada área urbana
    FOR area_record IN 
        SELECT * FROM "{{esquema}}".{{tabla_area}}
    LOOP
        contador := contador + 1;
        
        -- Verifica si intersecta antes de procesar
        IF ST_Intersects(area_record.geom, buffer_geom) THEN
            resultado_geom := ST_Difference(area_record.geom, buffer_geom);
            
            -- Inserta solo si el resultado no está vacío
            IF NOT ST_IsEmpty(resultado_geom) THEN
                INSERT INTO "{{esquema}}".manzana_cruda (geom) 
                VALUES (resultado_geom);
            END IF;
        ELSE
            -- Si no intersecta, inserta la geometría original
            INSERT INTO "{{esquema}}".manzana_cruda (geom) 
            VALUES (area_record.geom);
        END IF;
        
        -- Muestra progreso cada 10 registros o en el último
        IF contador % 10 = 0 OR contador = total_areas THEN
            RAISE NOTICE 'Procesadas % de % áreas (%.2f%%)', 
                contador, total_areas, (contador::FLOAT / total_areas * 100);
        END IF;
    END LOOP;
    
    RAISE NOTICE 'Procesamiento completado. Total procesado: % áreas', contador;
END $$;

--crear multiparte
create table "{{esquema}}".monoparte AS (
    SELECT
        (ST_Dump(ST_MakeValid(geom))).geom::geometry(Polygon, 4326) AS geom
    FROM "{{esquema}}".manzana_cruda
);

--renombrar tabla 
drop table if exists "{{esquema}}".manzana_cruda;
ALTER TABLE "{{esquema}}".monoparte RENAME TO manzana_cruda;

--limpiar tablas 
drop table if exists "{{esquema}}".buffer_vias;
drop table if exists "{{esquema}}".buffer_total;

