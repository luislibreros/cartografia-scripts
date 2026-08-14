/*
********************************************************************************
* Código: swap_vector_v2
* Autor: Jhoinner Manrique
* Fecha de creación: 05-09-2025
* Última modificación:05-09-2025
* Versión: 2.0
* Correcciones: ST_LineMerge en StartPoint, buffer geography en metros
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

----------------------------------------------------------------------------------
--crear tabla de mavvial a procesar

BEGIN;

ALTER TABLE "28_se"."mavvial_fin" ADD COLUMN IF NOT EXISTS id serial;

DROP TABLE IF EXISTS mavvial_procesar;

CREATE TABLE mavvial_procesar AS
SELECT m.id, m.geom,m.id_capa
FROM "28_se"."mavvial_fin" m
JOIN (
    SELECT id_mavvial
    FROM "28_se"."placa"
    WHERE id_mavvial IS NOT NULL
    GROUP BY id_mavvial
    HAVING COUNT(*) >= 4
) p ON m.id_capa::INTEGER = p.id_mavvial::INTEGER;


create index idx_geom_mavvial_procesar on mavvial_procesar using gist (geom);

alter table mavvial_procesar rename column id_capa to id_unico_mavvial;

do $$
begin
	raise notice 'Creacion de insumos 20%%...';
end $$;

----------------------------------------------------------------------------------
--crear tabla de placas a procesar

drop table if exists placas_procesar;

create table placas_procesar as
select id, geom, placa,id_mavvial from "28_se"."placa"
where atipico is null;

update placas_procesar p
set geom = ST_ClosestPoint(ST_LineMerge(m.geom), p.geom)
from mavvial_procesar m
where m.id_unico_mavvial = p.id_mavvial;

create index idx_geom_placas_procesar on placas_procesar using gist (geom);

alter table placas_procesar rename column id_mavvial to id_mavvial_placa;

do $$
begin
	raise notice 'Creacion de insumos 40%%...';
end $$;

COMMIT;


----------------------------------------------------------------------------------
--CREAR TABLA CON PUNTOS INICIALES
BEGIN;

DROP TABLE IF EXISTS start_point_mavvial;
CREATE TABLE start_point_mavvial AS
SELECT
    id,
	id_unico_mavvial,
    ST_StartPoint(ST_LineMerge(geom)) AS geom
FROM mavvial_procesar;

ALTER TABLE start_point_mavvial
ALTER COLUMN geom TYPE geometry(Point, 4326); 

--CREAR INDICE
CREATE INDEX idx_geom_start_point on start_point_mavvial using gist (geom);


do $$
begin
	raise notice 'Creacion de insumos 60%%...';
end $$;

COMMIT;
----------------------------------------------------------------------------------
--CREAR TABLA CON PUNTOS FINALES
BEGIN;

DROP TABLE IF EXISTS end_point_mavvial;
CREATE TABLE end_point_mavvial AS
SELECT
    id,
	id_unico_mavvial,
    ST_EndPoint(ST_LineMerge(geom)) AS geom
FROM mavvial_procesar;

ALTER TABLE end_point_mavvial
ALTER COLUMN geom TYPE geometry(Point, 4326)
USING geom::geometry(Point, 4326); 

--Eliminar puntos finales que son el mismo inicial
DELETE FROM end_point_mavvial ep
USING start_point_mavvial sp
WHERE ep.id = sp.id
  AND ST_Equals(ep.geom, sp.geom);
  
do $$
begin
	raise notice 'Creacion de insumos 80%%...';
end $$;

---------------------------------------------------------------------------
--Crear penultimo nodo para glorietas 
CREATE TABLE penultimo_nodo AS
WITH sin_endpoint AS (
    SELECT mp.*
    FROM mavvial_procesar mp
    WHERE NOT EXISTS (
        SELECT 1
        FROM end_point_mavvial ep
        WHERE mp.id = ep.id
    )
), puntos_con_index AS (
    SELECT
        id,
        id_unico_mavvial,
        (punto_geom)::geometry(Point, 4326) AS geom,
        ROW_NUMBER() OVER (PARTITION BY id ORDER BY ord) AS punto_orden,
        ST_NumPoints(ST_LineMerge(geom_linea)) AS total_puntos
    FROM (
        SELECT
            mp.id,
            mp.id_unico_mavvial,
            mp.geom AS geom_linea,
            (ST_DumpPoints(ST_LineMerge(mp.geom))).geom AS punto_geom,
            generate_series(1, ST_NumPoints(ST_LineMerge(mp.geom))) AS ord
        FROM sin_endpoint mp
    ) dp
), penultimos AS (
    SELECT *
    FROM puntos_con_index
    WHERE punto_orden = total_puntos - 1
)
SELECT id, id_unico_mavvial, geom
FROM penultimos;

ALTER TABLE penultimo_nodo
ALTER COLUMN geom TYPE geometry(Point, 4326)
USING geom::geometry(Point, 4326);

--insertar en tabla de endpoints los penultimos
INSERT INTO end_point_mavvial (id, id_unico_mavvial, geom)
SELECT p.id, p.id_unico_mavvial, p.geom
FROM penultimo_nodo p
WHERE NOT EXISTS (
    SELECT 1
    FROM end_point_mavvial ep
    WHERE ep.id = p.id
);

--CREAR INDICE
CREATE INDEX idx_geom_end_point on end_point_mavvial using gist (geom);

drop table penultimo_nodo;

do $$
begin
	raise notice 'Creacion de insumos, FINALIZADA!...';
end $$;

COMMIT;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
------------------------ACTULIZACION PARA ANALISIS------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
do $$
begin
	raise notice '--------------------------------------------';
	raise notice '--Iniciando Actualizacion para analisis...--';
	raise notice '--------------------------------------------';
end $$;
----------------------------------------------------------------------------------
--Actualizar con las tres placas mas cercanas cada capa

--Puntos iniciales

alter table start_point_mavvial add column placa_1 varchar;
alter table start_point_mavvial add column placa_2 varchar;
alter table start_point_mavvial add column placa_3 varchar;

do $$
begin
	raise notice 'Actualizando Start Point...';
end $$;

--Indices necesarios

CREATE INDEX IF NOT EXISTS idx_start_point_id_unico_mavvial ON start_point_mavvial(id_unico_mavvial);
CREATE INDEX IF NOT EXISTS idx_start_point_id ON start_point_mavvial(id);

DO $$
DECLARE
    lote_size       INTEGER := 10000;
    v_min_id        BIGINT;
    v_max_id        BIGINT;
    total_registros INTEGER;
    procesados      INTEGER := 0;
    filas_afectadas INTEGER;
BEGIN
    SELECT MIN(id), MAX(id), COUNT(*)
    INTO v_min_id, v_max_id, total_registros
    FROM start_point_mavvial;

    RAISE NOTICE '  Actualizando Start Points: % registros...', total_registros;

    WHILE v_min_id <= v_max_id LOOP
        WITH puntos_lote AS (
            SELECT id, geom, id_unico_mavvial
            FROM start_point_mavvial
            WHERE id BETWEEN v_min_id AND v_min_id + lote_size - 1
        ),
        cercanas AS (
            SELECT
                p.id AS id_punto,
                pl.placa,
                ROW_NUMBER() OVER (
                    PARTITION BY p.id ORDER BY p.geom <-> pl.geom
                ) AS rn
            FROM puntos_lote p
            JOIN placas_procesar pl
              ON p.id_unico_mavvial = pl.id_mavvial_placa
            WHERE ST_DWithin(p.geom, pl.geom, 0.00225)
        )
        UPDATE start_point_mavvial s
        SET
            placa_1 = c1.placa,
            placa_2 = c2.placa,
            placa_3 = c3.placa
        FROM
            (SELECT id_punto, placa FROM cercanas WHERE rn = 1) c1
            LEFT JOIN (SELECT id_punto, placa FROM cercanas WHERE rn = 2) c2
                ON c1.id_punto = c2.id_punto
            LEFT JOIN (SELECT id_punto, placa FROM cercanas WHERE rn = 3) c3
                ON c1.id_punto = c3.id_punto
        WHERE s.id = c1.id_punto;

        GET DIAGNOSTICS filas_afectadas = ROW_COUNT;
        procesados := procesados + filas_afectadas;

        IF filas_afectadas > 0 THEN
            RAISE NOTICE '    Start Points: % de % (%.%%)',
                procesados, total_registros,
                ROUND(procesados * 100.0 / total_registros, 2);
        END IF;

        v_min_id := v_min_id + lote_size;
    END LOOP;

    RAISE NOTICE '  Start Points finalizados: % actualizados.', procesados;
END $$;

do $$
begin
	raise notice 'Actualizando insumos para analisis 50%%...';
end $$;


------------------------------------------------------------------------------------------------------
--puntos finales
do $$
begin
	raise notice 'Actualizando End Point...';
end $$;

BEGIN;

alter table end_point_mavvial add column placa_1 varchar;
alter table end_point_mavvial add column placa_2 varchar;
alter table end_point_mavvial add column placa_3 varchar;

--Indices necesarios

CREATE INDEX IF NOT EXISTS idx_end_point_id_unico_mavvial ON end_point_mavvial(id_unico_mavvial);
CREATE INDEX IF NOT EXISTS idx_end_point_id ON end_point_mavvial(id);

DO $$
DECLARE
    lote_size       INTEGER := 10000;
    v_min_id        BIGINT;
    v_max_id        BIGINT;
    total_registros INTEGER;
    procesados      INTEGER := 0;
    filas_afectadas INTEGER;
BEGIN
    SELECT MIN(id), MAX(id), COUNT(*)
    INTO v_min_id, v_max_id, total_registros
    FROM end_point_mavvial;

    RAISE NOTICE '  Actualizando End Points: % registros...', total_registros;

    WHILE v_min_id <= v_max_id LOOP
        WITH puntos_lote AS (
            SELECT id, geom, id_unico_mavvial
            FROM end_point_mavvial
            WHERE id BETWEEN v_min_id AND v_min_id + lote_size - 1
        ),
        cercanas AS (
            SELECT
                p.id AS id_punto,
                pl.placa,
                ROW_NUMBER() OVER (
                    PARTITION BY p.id ORDER BY p.geom <-> pl.geom
                ) AS rn
            FROM puntos_lote p
            JOIN placas_procesar pl
              ON p.id_unico_mavvial = pl.id_mavvial_placa
            WHERE ST_DWithin(p.geom, pl.geom, 0.00225)
        )
        UPDATE end_point_mavvial s
        SET
            placa_1 = c1.placa,
            placa_2 = c2.placa,
            placa_3 = c3.placa
        FROM
            (SELECT id_punto, placa FROM cercanas WHERE rn = 1) c1
            LEFT JOIN (SELECT id_punto, placa FROM cercanas WHERE rn = 2) c2
                ON c1.id_punto = c2.id_punto
            LEFT JOIN (SELECT id_punto, placa FROM cercanas WHERE rn = 3) c3
                ON c1.id_punto = c3.id_punto
        WHERE s.id = c1.id_punto;

        GET DIAGNOSTICS filas_afectadas = ROW_COUNT;
        procesados := procesados + filas_afectadas;

        IF filas_afectadas > 0 THEN
            RAISE NOTICE '    End Points: % de % (%.%%)',
                procesados, total_registros,
                ROUND(procesados * 100.0 / total_registros, 2);
        END IF;

        v_min_id := v_min_id + lote_size;
    END LOOP;

    RAISE NOTICE '  End Points finalizados: % actualizados.', procesados;
END $$;

COMMIT;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-------------------------ANALISIS PARA SWAP VECTOR------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
do $$
begin
	raise notice '-------------------------------------';
	raise notice '--Iniciando Analisis Swap Vector...--';
	raise notice '-------------------------------------';
end $$;

BEGIN;
----------------------------------------------------------------------------------
--Calcular cual punto tiene una sumatoria mas alta
alter table start_point_mavvial add column sumatoria integer;
alter table end_point_mavvial add column sumatoria integer;

UPDATE start_point_mavvial
SET sumatoria =
    COALESCE(NULLIF(regexp_replace(placa_1, '[^0-9].*$', ''), '')::integer, 0) +
    COALESCE(NULLIF(regexp_replace(placa_2, '[^0-9].*$', ''), '')::integer, 0) +
	COALESCE(NULLIF(regexp_replace(placa_3, '[^0-9].*$', ''), '')::integer, 0);

UPDATE end_point_mavvial
SET sumatoria =
    COALESCE(NULLIF(regexp_replace(placa_1, '[^0-9].*$', ''), '')::integer, 0) +
    COALESCE(NULLIF(regexp_replace(placa_2, '[^0-9].*$', ''), '')::integer, 0) +
	COALESCE(NULLIF(regexp_replace(placa_3, '[^0-9].*$', ''), '')::integer, 0);
	
do $$
begin
	raise notice 'Analisis para swap vector 30%%...';
end $$;
----------------------------------------------------------------------------------------
--Actualizar mavvial_procesar con los datos obtenidos
alter table mavvial_procesar add column placa_1_s varchar;
alter table mavvial_procesar add column placa_2_s varchar;
alter table mavvial_procesar add column placa_3_s varchar;
alter table mavvial_procesar add column sum_start integer;
alter table mavvial_procesar add column placa_1_e varchar;
alter table mavvial_procesar add column placa_2_e varchar;
alter table mavvial_procesar add column placa_3_e varchar;
alter table mavvial_procesar add column sum_end integer;

update mavvial_procesar m
set placa_1_s = s.placa_1, placa_2_s=s.placa_2,placa_3_s=s.placa_3, sum_start = s.sumatoria
from start_point_mavvial s
where m.id = s.id;

update mavvial_procesar m
set placa_1_e = e.placa_1, placa_2_e=e.placa_2, placa_3_e=e.placa_3, sum_end = e.sumatoria
from end_point_mavvial e
where m.id = e.id;

do $$
begin
	raise notice 'Analisis para swap vector 60%%...';
end $$;
----------------------------------------------------------------------
--Definir swap
alter table mavvial_procesar add column swap varchar;

update mavvial_procesar
set swap = 'si'
where sum_start>sum_end;

update mavvial_procesar
set swap = 'no'
where sum_end>sum_start;

UPDATE mavvial_procesar
SET swap = 'si'
WHERE
    swap IS NULL
    AND regexp_replace(placa_1_s, '[^0-9].*$', '') ~ '^[0-9]+$'
    AND regexp_replace(placa_1_e, '[^0-9].*$', '') ~ '^[0-9]+$'
    AND regexp_replace(placa_1_s, '[^0-9].*$', '')::integer >
        regexp_replace(placa_1_e, '[^0-9].*$', '')::integer;

    
UPDATE mavvial_procesar
SET swap = 'no'
WHERE
    swap IS NULL
    AND NULLIF(regexp_replace(placa_1_s, '[^0-9].*$', ''), '')::integer <
        NULLIF(regexp_replace(placa_1_e, '[^0-9].*$', ''), '')::integer;
	
update mavvial_procesar
set swap = 'revisar'
where swap is null;

do $$
begin
	raise notice 'Analisis para swap vector, Finalizado!...';
end $$;

COMMIT;
----------------------------------------------------------------------
--actualizar mavvial

do $$
begin
	raise notice '---------------------------------------------';
	raise notice '--Actualizando Datos en mavvial original...--';
	raise notice '---------------------------------------------';
end $$;

BEGIN;
----------------------------------------------------------------------
--Actualizar swap individual
alter table "28_se"."mavvial_fin" drop column if exists swap;
alter table "28_se"."mavvial_fin" add column swap varchar;

update "28_se"."mavvial_fin" v
set swap = 'si'
from mavvial_procesar p
where v.id = p.id and p.swap = 'si';

do $$
begin
	raise notice '--Actualizando Datos en mavvial original, 20%%...--';
end $$;

commit;

----------------------------------------------------------------------
--Analisis para swap por tramo entero, Crear capa para geometrias continuas
----------------------------------------------------------------------
begin;

DROP TABLE IF EXISTS mavvial_continuos;

CREATE TABLE mavvial_continuos AS
WITH disolved AS (
    SELECT nomvtotal,
           (ST_Dump(ST_LineMerge(ST_Union(geom)))).geom AS geom
    FROM "28_se"."mavvial_fin"
    WHERE nomvtotal IS NOT NULL
    GROUP BY nomvtotal
)
SELECT row_number() OVER () AS id,
       nomvtotal,
       geom
FROM disolved;

do $$
begin
	raise notice '--Actualizando Datos en mavvial original, 40%%...--';
end $$;

commit;

-----------------------------------------------------------------
--crear buffer para analisis
begin;

DROP TABLE IF EXISTS mavvial_continuos_buffer;

CREATE TABLE mavvial_continuos_buffer AS
SELECT 
    id,
    nomvtotal,
    ST_Buffer(geom::geography, 10)::geometry AS geom
FROM mavvial_continuos;

create index idx_geom_mavvial_continuos_buffer on mavvial_continuos_buffer using gist (geom);

do $$
begin
	raise notice '--Actualizando Datos en mavvial original, 50%%...--';
end $$;

commit;
-----------------------------------------------------------------
--centroides para mavvial
begin;

alter table "28_se"."mavvial_fin" drop column if exists id_grupo_swap;
alter table "28_se"."mavvial_fin" add column id_grupo_swap integer;

drop table if exists mavvial_centroides;
CREATE TABLE mavvial_centroides AS
SELECT 
    id,
    ST_ClosestPoint(ST_LineMerge(m.geom), ST_Centroid(m.geom)) AS geom,
	id_grupo_swap
FROM "28_se"."mavvial_fin" m
where nomvtotal is not null;

create index idx_geom_mavvial_centroides on mavvial_centroides using gist (geom);

do $$
begin
	raise notice '--Actualizando Datos en mavvial original, 70%%...--';
end $$;

commit;

-----------------------------------------------------------------
--actualizacion de grupo continuidad
begin;

update mavvial_centroides m
set id_grupo_swap = b.id
from mavvial_continuos_buffer b
where st_intersects(m.geom,b.geom);

update "28_se"."mavvial_fin" m
set id_grupo_swap = c.id_grupo_swap
from mavvial_centroides c
where m.id = c.id;

do $$
begin
	raise notice '--Actualizando Datos en mavvial original, 90%%...--';
end $$;

commit;
-----------------------------------------------------------------
--definir swap final
begin;

ALTER TABLE "28_se"."mavvial_fin" drop COLUMN if exists swap_grupal;
ALTER TABLE "28_se"."mavvial_fin" ADD COLUMN swap_grupal text;

WITH porcentajes AS (
    SELECT 
        id_grupo_swap,
        COUNT(*)::numeric AS total,
        SUM(CASE WHEN swap = 'si' THEN 1 ELSE 0 END)::numeric AS conteo_si
    FROM "28_se"."mavvial_fin"
    GROUP BY id_grupo_swap
)
UPDATE "28_se"."mavvial_fin" m
SET swap_grupal = 'swap'
FROM porcentajes p
WHERE m.id_grupo_swap = p.id_grupo_swap
  AND (
      (p.total = 1 AND p.conteo_si = 1)                -- caso único
      OR ((p.conteo_si / p.total) >= 0.3 AND p.conteo_si >= 2)  -- resto de casos
  );

do $$
begin
	raise notice '--Actualizando Datos en mavvial original, 100%%...--';
end $$;
----------------------------------------------------------------------
--ELIMINAR CAMPOS Y CAPAS DE PROCESOS
----------------------------------------------------------------------
drop table mavvial_procesar;
drop table placas_procesar;
drop table mavvial_continuos;
drop table mavvial_continuos_buffer;
drop table mavvial_centroides;
drop table start_point_mavvial;
drop table end_point_mavvial;
ALTER TABLE "28_se"."mavvial_fin" drop COLUMN if exists swap;
ALTER TABLE "28_se"."mavvial_fin" drop COLUMN if exists id_grupo_swap;
ALTER TABLE "28_se"."mavvial_fin" rename column swap_grupal to swap;


commit;

do $$
begin
	raise notice '---------------------------------------------';
	raise notice '----✔️Algoritmo Swap Vector, FINALIZADO!-----';
	raise notice '---------------------------------------------';
end $$;
