-- ServiFlow · script de placas (parametrizado)
-- El esquema es {{esquema}} (se elige en el panel). Modo 'schema':
-- corre DIRECTO sobre el esquema elegido; úsalo en un esquema de trabajo.

/*
********************************************************************************
* Código: desplazamientos_placas
* Autor: Jhoinner Manrique
* Fecha de creación: 05-03-2025
* Última modificación:09-09-2025
* Versión: 2.0
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
--------------------------------------------------------------------------------------------------
--Crear mavvial a trabajar
BEGIN;

drop table if exists mavvial_faces;

create table mavvial_faces as 
select geom, id_capa, nomvtotal from "{{esquema}}"."mavvial_fin";

create index idx_geom_mavvial_faces on mavvial_faces using gist (geom);

do $$
begin
	raise notice 'Creacion de insumos 50%%...';
end $$;

COMMIT;
-------------------------------------------------------------------------------------------------
--Crear contorno manzana
BEGIN; 

DROP TABLE IF EXISTS manzana_disuelta;
CREATE TABLE manzana_disuelta AS SELECT ST_Union(geom) AS geom 
FROM "{{esquema}}"."manzana";

do $$
begin
	raise notice 'Creacion de insumos 70%%...';
end $$;

DROP TABLE IF EXISTS manzana_monoparte;
CREATE TABLE manzana_monoparte AS
SELECT (ST_Dump(geom)).geom::geometry(Polygon, 4326) AS geom
FROM manzana_disuelta;

do $$
begin
	raise notice 'Creacion de insumos 80%%...';
end $$;

DROP TABLE IF EXISTS manzana_contorno;
CREATE TABLE manzana_contorno AS
SELECT
    ST_Boundary(ST_Buffer(geom, -0.00002695)) AS geom
FROM manzana_monoparte
WHERE ST_Area(geom) > 0;

do $$
begin
	raise notice 'Creacion de insumos 90%%...';
end $$;

create index idex_geom_manzana_contorno on manzana_contorno using gist (geom);

do $$
begin
	raise notice 'Creacion de insumos, Finalizado!...';
end $$;

COMMIT;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
----------------------CREACION INSUMOS DE ANALISIS------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
do $$
begin
	raise notice '----------------------------------------------';
	raise notice '--Iniciando creacion de capas de analisis...--';
	raise notice '----------------------------------------------';
end $$;

----------------------------------------------------------------
--Crear buffer derecho para la mavvial faces
BEGIN;

drop table if exists mavvial_lado_derecho;
CREATE TABLE mavvial_lado_derecho AS
WITH proyectado AS (
    SELECT 
        id_capa, nomvtotal,
        ST_Transform(geom, 32720) AS geom_utm
    FROM mavvial_faces
)
SELECT 
    id_capa, nomvtotal,
    ST_Transform(ST_OffsetCurve(geom_utm, -2), 4326) AS geom
FROM proyectado;

alter table mavvial_lado_derecho add column costado varchar;

update mavvial_lado_derecho
set costado = 'PAR';

do $$
begin
	raise notice 'creacion de capas de analisis, 20%%!...';
end $$;

COMMIT;

----------------------------------------------------------------
--Crear buffer izquierdo para la mavvial faces
BEGIN;

drop table if exists mavvial_lado_izquierdo;

CREATE TABLE mavvial_lado_izquierdo AS
WITH proyectado AS (
    SELECT 
        id_capa, nomvtotal,
        ST_Transform(geom, 32720) AS geom_utm
    FROM mavvial_faces
)
SELECT 
    id_capa, nomvtotal,
    ST_Transform(ST_OffsetCurve(geom_utm, 2), 4326) AS geom
FROM proyectado;

alter table mavvial_lado_izquierdo add column costado varchar;

update mavvial_lado_izquierdo
set costado = 'IMPAR';

do $$
begin
	raise notice 'creacion de capas de analisis, 40%%!...';
end $$;

COMMIT;

-------------------------------------------------------------------------------------------------
--Crear costados consolidados
BEGIN;

drop table if exists mavvial_costados;

CREATE TABLE mavvial_costados AS
SELECT * FROM mavvial_lado_izquierdo
UNION ALL
SELECT * FROM mavvial_lado_derecho;

create index idx_geom_costados on mavvial_costados using gist (geom);

drop table mavvial_lado_izquierdo;
drop table mavvial_lado_derecho;

do $$
begin
	raise notice 'creacion de capas de analisis, 60%%!...';
end $$;

COMMIT;
-------------------------------------------------------------------------------------------------
--Crear segmentos de manzana
BEGIN;

DROP TABLE IF EXISTS manzana_segmentos;

CREATE TABLE manzana_segmentos AS
SELECT 
  (ST_DumpSegments(geom)).geom AS geom
FROM manzana_contorno;

--Depurar segmentos menores a 2m
DELETE FROM manzana_segmentos
WHERE ST_Length(geom) <0.000008983;

CREATE INDEX idx_geom_segmentos on manzana_segmentos using gist (geom);

alter table manzana_segmentos add column nomvtotal varchar;
alter table manzana_segmentos add column id serial;
alter table manzana_segmentos add column id_capa integer;
alter table manzana_segmentos add column costado varchar;

do $$
begin
	raise notice 'creacion de capas de analisis, 80%%!...';
end $$;

COMMIT;
---------------------------------------------------------------------------------------------
--Crear puntos de cada face
BEGIN;

drop table if exists manzana_segmentos_centroides;
CREATE TABLE manzana_segmentos_centroides AS
SELECT 
    id,
	nomvtotal,
	id_capa,
	costado,
    ST_Centroid(geom) AS geom
FROM 
    manzana_segmentos;
	
create index idx_geom_ptos_manzanas_faces on manzana_segmentos_centroides using gist (geom);

do $$
begin
	raise notice 'creacion de capas de analisis, Finalizado!...';
end $$;

COMMIT;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
----------------------ANALISIS PARA DESPLAZAMIENTO------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
do $$
begin
	raise notice '---------------------------------------------';
	raise notice '--Iniciando analisis para desplazamiento...--';
	raise notice '---------------------------------------------';
end $$;

---------------------------------------------------------------------------------------------------------
--Actualizacion de cada segmento con nomvtotal y id_capa de mavvial
begin;


ALTER TABLE manzana_segmentos_centroides ADD COLUMN revisado boolean DEFAULT false;

CREATE OR REPLACE FUNCTION actualizar_nomvtotal_lotes(
    p_lote_size INTEGER DEFAULT 1000
) RETURNS void AS
$$
DECLARE
    v_total INTEGER;
    v_procesados INTEGER := 0;
    v_lote INTEGER := 0;
BEGIN
    -- Obtener total de registros pendientes
    SELECT COUNT(*) INTO v_total
    FROM manzana_segmentos_centroides
    WHERE NOT revisado;

    RAISE NOTICE 'Total de registros a procesar: %', v_total;

    WHILE v_procesados < v_total LOOP
        -- Paso 1: Tomar lote actual
        CREATE TEMP TABLE tmp_lote_ids ON COMMIT DROP AS
        SELECT id, geom AS centroide
        FROM manzana_segmentos_centroides
        WHERE NOT revisado
        LIMIT p_lote_size;

        -- Paso 2: Encontrar candidatos dentro de 50 metros
        CREATE TEMP TABLE tmp_candidatos ON COMMIT DROP AS
        SELECT
            l.id,
            mv.nomvtotal,
            mv.id_capa,
			mv.costado,
            ST_Distance(l.centroide::geography, mv.geom::geography) AS dist
        FROM tmp_lote_ids l
        JOIN mavvial_costados mv
          ON ST_DWithin(l.centroide, mv.geom, 0.00044915);

        -- Paso 3: Seleccionar el más cercano por ID
        CREATE TEMP TABLE tmp_seleccion ON COMMIT DROP AS
        SELECT DISTINCT ON (id)
            id,
            nomvtotal,
            id_capa,
			costado
        FROM tmp_candidatos
        ORDER BY id, dist;

        -- Paso 4: Actualizar registros encontrados
        UPDATE manzana_segmentos_centroides ms
        SET nomvtotal = s.nomvtotal,
            id_capa = s.id_capa,
			costado = s.costado,
            revisado = true
        FROM tmp_seleccion s
        WHERE ms.id = s.id;

        -- Paso 5: Marcar como revisado los registros sin coincidencias
        UPDATE manzana_segmentos_centroides
        SET revisado = true
        WHERE NOT revisado
          AND id IN (
              SELECT id FROM tmp_lote_ids
              EXCEPT
              SELECT id FROM tmp_candidatos
          );

        -- Contador
        v_lote := v_lote + 1;
        v_procesados := v_procesados + p_lote_size;

        RAISE NOTICE 'Lote % procesado (%/%).', v_lote, LEAST(v_procesados, v_total), v_total;

        DROP TABLE IF EXISTS tmp_lote_ids, tmp_candidatos, tmp_seleccion;
    END LOOP;

    RAISE NOTICE 'Proceso finalizado. Total de registros procesados: %', v_total;
END;
$$ LANGUAGE plpgsql;

SELECT actualizar_nomvtotal_lotes(50000);

do $$
begin
	raise notice 'Analisis para desplazamiento, 50%%!...';
end $$;

commit;

----------------------------------------------------------------------------------------------------------
--Actualizar segmentos con los datos extraidos
BEGIN;

update manzana_segmentos m
set id_capa = p.id_capa, nomvtotal = p.nomvtotal, costado= p.costado
from manzana_segmentos_centroides p
where m.id = p.id;

do $$
begin
	raise notice 'Analisis para desplazamiento, 80%%!...';
end $$;

COMMIT;

------------------------------------------------------------------------------------------
--unir faces por nombre
BEGIN;

DROP TABLE IF EXISTS faces_manzanas;

CREATE TABLE faces_manzanas AS
SELECT
    id_capa,
    nomvtotal,
	costado,
    ST_Union(geom) AS geom
FROM manzana_segmentos
WHERE id_capa IS NOT NULL AND nomvtotal IS NOT NULL
GROUP BY id_capa, nomvtotal, costado;

CREATE INDEX idx_geom_faces ON faces_manzanas USING GIST(geom);

do $$
begin
	raise notice 'Analisis para desplazamiento, Finalizado!...';
end $$;

COMMIT;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
----------------------DESPLAZAMIENTO DE PLACAS----------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
do $$
begin
	raise notice '---------------------------------';
	raise notice '--Iniciando Ajuste de placas...--';
	raise notice '---------------------------------';
end $$;

BEGIN;
--------------------------------------------------------------------------------

alter table "{{esquema}}"."placa" drop column if exists geom_ajustada;
alter table "{{esquema}}"."placa" add column geom_ajustada geometry;

alter table "{{esquema}}"."placa" drop column if exists observ_ajuste;
alter table "{{esquema}}"."placa" add column observ_ajuste varchar;

UPDATE "{{esquema}}"."placa" p
SET geom_ajustada = ST_ClosestPoint(f.geom, p.geom)
FROM faces_manzanas f
WHERE p.id_mavvial = f.id_capa
  AND f.costado = 'PAR'
  AND (CAST(p.placa AS integer) % 2) = 0; -- solo números pares
  
do $$
begin
	raise notice 'Ajuste de placas, 20%%...';
end $$;

commit;

----------------------------------------------------------------
BEGIN;

UPDATE "{{esquema}}"."placa" p
SET geom_ajustada = ST_ClosestPoint(f.geom, p.geom)
FROM faces_manzanas f
WHERE p.id_mavvial = f.id_capa
  AND f.costado = 'IMPAR'
  AND (CAST(p.placa AS integer) % 2) = 1; -- solo números impares

do $$
begin
	raise notice 'Ajuste de placas, 40%%...';
end $$;

commit;

----------------------------------------------------------------
BEGIN;

UPDATE "{{esquema}}"."placa" p
SET geom_ajustada = ST_ClosestPoint(f.geom, p.geom)
FROM faces_manzanas f
WHERE p.id_mavvial = f.id_capa
and p.geom_ajustada is null;


--observacion para los que no se pudieron ajustar
update "{{esquema}}"."placa"
set observ_ajuste = 'no_ajustada'
where geom_ajustada is null;

do $$
begin
	raise notice 'Ajuste de placas, 60%%...';
end $$;

commit;

----------------------------------------------------------------
BEGIN;

UPDATE "{{esquema}}"."placa" p
SET geom_ajustada = geom
where geom_ajustada is null;

do $$
begin
	raise notice 'Ajuste de placas, 80%%...';
end $$;

commit;

----------------------------------------------------------------
BEGIN;

update "{{esquema}}"."placa"
set geom=geom_ajustada
where geom_ajustada is not null;

alter table "{{esquema}}"."placa" drop column geom_ajustada;

do $$
begin
	raise notice 'Ajuste de placas, Finalizado!...';
end $$;

commit;
------------------------------------------------------------------------------------------
--depurar capas creadas

drop table manzana_contorno;
drop table manzana_segmentos;
drop table manzana_segmentos_centroides;
drop table manzana_disuelta;
drop table manzana_monoparte;
drop table faces_manzanas;
drop table mavvial_costados;
drop table mavvial_faces;

do $$
begin
	raise notice '----------------------------------------------------------';
	raise notice '----✔️Algoritmo desplazamiento de placas, FINALIZADO!-----';
	raise notice '----------------------------------------------------------';
end $$;

--------------------------------------------------------------------------------
--CREAR Y CALCULAR CAMPOS LATITUD Y LONGITUD ACTUAL
--------------------------------------------------------------------------------
DO $$
BEGIN
    RAISE NOTICE '---------------------------------------------';
    RAISE NOTICE '--Calculando lat_actual y long_actual...--';
    RAISE NOTICE '---------------------------------------------';
END $$;

BEGIN;

-- Crear campo lat_actual si no existe
ALTER TABLE "{{esquema}}"."placa"
ADD COLUMN IF NOT EXISTS lat_actual double precision;

-- Crear campo long_actual si no existe
ALTER TABLE "{{esquema}}"."placa"
ADD COLUMN IF NOT EXISTS long_actual double precision;

-- Actualizar valores desde la geometría final
UPDATE "{{esquema}}"."placa"
SET 
    lat_actual  = ST_Y(geom),
    long_actual = ST_X(geom)
WHERE geom IS NOT NULL;

DO $$
BEGIN
    RAISE NOTICE 'Campos lat_actual y long_actual calculados correctamente.';
END $$;

COMMIT;
