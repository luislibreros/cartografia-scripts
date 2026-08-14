/*
********************************************************************************
* Código: Ordenar Placas
* Autor: Jhoinner Manrique
* Fecha de creación: 23-09-2025
* Última modificación:23-09-2025
* Versión: 1.0
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

ALTER TABLE produccion.mavvial ADD COLUMN IF NOT EXISTS id serial;

DROP TABLE IF EXISTS mavvial_procesar;

CREATE TABLE mavvial_procesar AS
SELECT m.id, m.geom,m.id_capa
FROM produccion.mavvial m
JOIN (
    SELECT id_mavvial
    FROM produccion.prueba
    WHERE id_mavvial IS NOT NULL
    GROUP BY id_mavvial
    HAVING COUNT(*) >= 2
) p ON m.id_capa::INTEGER = p.id_mavvial::INTEGER;


create index idx_geom_mavvial_procesar on mavvial_procesar using gist (geom);

alter table mavvial_procesar rename column id_capa to id_unico_mavvial;

do $$
begin
	raise notice 'Creacion de insumos 40%%...';
end $$;

----------------------------------------------------------------------------------
--crear tabla de placas a procesar
ALTER TABLE produccion.prueba ADD COLUMN IF NOT EXISTS id serial;

drop table if exists placas_procesar;

create table placas_procesar as
select p.id, p.geom, p.placa, p.id_mavvial
from produccion.prueba p
inner join mavvial_procesar m
    on p.id_mavvial = m.id_unico_mavvial
where p.atipico is null;

create index idx_geom_placas_procesar on placas_procesar using gist (geom);

alter table placas_procesar rename column id_mavvial to id_mavvial_placa;

alter table placas_procesar add column costado varchar;
alter table placas_procesar add column distancia numeric;
alter table placas_procesar add column posicion_por_placa numeric;
alter table placas_procesar add column posicion_por_distancia numeric;
alter table placas_procesar add column orden_placa varchar;
alter table placas_procesar add column nueva_geom geometry;

UPDATE placas_procesar
SET costado = CASE
    WHEN (regexp_replace(placa, '[^0-9]', '', 'g') <> '') 
         AND (CAST(regexp_replace(placa, '[^0-9]', '', 'g') AS INTEGER) % 2 = 0) 
    THEN 'par'
    WHEN (regexp_replace(placa, '[^0-9]', '', 'g') <> '') 
         AND (CAST(regexp_replace(placa, '[^0-9]', '', 'g') AS INTEGER) % 2 = 1) 
    THEN 'impar'
    ELSE NULL
END;


do $$
begin
	raise notice 'Creacion de insumos 80%%...';
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
    ST_StartPoint(geom) AS geom
FROM mavvial_procesar;

ALTER TABLE start_point_mavvial
ALTER COLUMN geom TYPE geometry(Point, 4326); 

--CREAR INDICE
CREATE INDEX idx_geom_start_point on start_point_mavvial using gist (geom);


do $$
begin
	raise notice 'Creacion de insumos, FINALIZADA!...';
end $$;

COMMIT;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
------------------------ANALISIS PARA ORDENAR PLACAS----------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
do $$
begin
	raise notice '----------------------------------------';
	raise notice '--Iniciando Analisis ORDENAR PLACAS...--';
	raise notice '----------------------------------------';
end $$;
--------------------------------------------------------------------------------
BEGIN;

DO $$
DECLARE
    batch_size INTEGER := 50000;
    total INTEGER;
    updated INTEGER := 0;
    processed INTEGER;
BEGIN
    -- contar total de placas a actualizar
    SELECT COUNT(*) INTO total 
    FROM placas_procesar p
    JOIN start_point_mavvial s 
      ON p.id_mavvial_placa = s.id_unico_mavvial;

    RAISE NOTICE 'Total de registros a actualizar: %', total;

    -- mientras queden registros por actualizar
    WHILE updated < total LOOP
        WITH cte AS (
            SELECT p.ctid
            FROM placas_procesar p
            JOIN start_point_mavvial s
              ON p.id_mavvial_placa = s.id_unico_mavvial
            WHERE p.distancia IS NULL -- solo los que falten
            LIMIT batch_size
        )
        UPDATE placas_procesar p
        SET distancia = ST_DistanceSphere(p.geom, s.geom)
        FROM start_point_mavvial s, cte
        WHERE p.ctid = cte.ctid
          AND p.id_mavvial_placa = s.id_unico_mavvial;

        -- filas actualizadas en este batch
        GET DIAGNOSTICS processed = ROW_COUNT;
        updated := updated + processed;

        RAISE NOTICE 'Avance: % de % registros actualizados', updated, total;
    END LOOP;

    RAISE NOTICE 'Proceso finalizado. Total actualizado: %', total;
END $$;

COMMIT;

do $$
begin
	raise notice '-----------------------------------';
	raise notice '--Analizando para ordenamiento...--';
	raise notice '-----------------------------------';
end $$;

--------------------------------------------------------------------------------
--Actualizar posicion por distancia
BEGIN;

WITH ordenadas AS (
    SELECT
        p.ctid,
        ROW_NUMBER() OVER (
            PARTITION BY p.id_mavvial_placa, p.costado
            ORDER BY p.distancia ASC
        ) AS pos
    FROM placas_procesar p
    WHERE p.distancia IS NOT NULL
)
UPDATE placas_procesar p
SET posicion_por_distancia = o.pos
FROM ordenadas o
WHERE p.ctid = o.ctid;

do $$
begin
	raise notice 'Analizando para ordenamiento,30%%...';
end $$;

COMMIT;
--------------------------------------------------------------------------------
--Actualizar posicion por placa
BEGIN;

WITH ordenadas AS (
    SELECT
        p.ctid,
        ROW_NUMBER() OVER (
            PARTITION BY p.id_mavvial_placa, p.costado
            ORDER BY CAST(NULLIF(regexp_replace(p.placa, '[^0-9]', '', 'g'), '') AS INTEGER) ASC
        ) AS pos
    FROM placas_procesar p
    WHERE p.placa IS NOT NULL
)
UPDATE placas_procesar p
SET posicion_por_placa = o.pos
FROM ordenadas o
WHERE p.ctid = o.ctid;

do $$
begin
	raise notice 'Analizando para ordenamiento,70%%...';
end $$;

COMMIT;
--------------------------------------------------------------------------------
--Actualizar nueva posicion
begin;

delete from placas_procesar
where posicion_por_distancia = posicion_por_placa;

do $$
begin
	raise notice 'Analizando para ordenamiento,Finalizado!...';
end $$;

commit;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-------------------------ACTUALIZACION NUEVO ORDEN------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
BEGIN;

do $$
begin
	raise notice '-----------------------------------';
	raise notice '--Actualizando nuevo orden...--';
	raise notice '-----------------------------------';
end $$;

--------------------------------------------------------------------------------
DO $$
DECLARE
    total_registros BIGINT;
    lote INTEGER := 10000;
    procesados BIGINT := 0;
    porcentaje NUMERIC;
    actualizados INTEGER;
BEGIN
    -- 1. Contar cuántos registros hay por actualizar
    SELECT count(*)
    INTO total_registros
    FROM placas_procesar p
    JOIN placas_procesar p2
      ON p.id_mavvial_placa = p2.id_mavvial_placa
     AND p.costado = p2.costado
     AND p.posicion_por_placa = p2.posicion_por_distancia
    WHERE p.nueva_geom IS NULL;

    RAISE NOTICE 'Total por actualizar: %', total_registros;

    -- 2. Ejecutar en lotes de 10k
    WHILE procesados < total_registros LOOP
        WITH cte AS (
            SELECT p.ctid
            FROM placas_procesar p
            JOIN placas_procesar p2
              ON p.id_mavvial_placa = p2.id_mavvial_placa
             AND p.costado = p2.costado
             AND p.posicion_por_placa = p2.posicion_por_distancia
            WHERE p.nueva_geom IS NULL
            LIMIT lote
        )
        UPDATE placas_procesar p
        SET nueva_geom = p2.geom,
            orden_placa = 'cambio_orden'
        FROM placas_procesar p2, cte
        WHERE p.ctid = cte.ctid
          AND p.id_mavvial_placa = p2.id_mavvial_placa
          AND p.costado = p2.costado
          AND p.posicion_por_placa = p2.posicion_por_distancia;

        -- Capturar cuántos se actualizaron en este lote
        GET DIAGNOSTICS actualizados = ROW_COUNT;

        -- Acumular en el total procesado
        procesados := procesados + actualizados;

        -- Calcular avance
        porcentaje := ROUND((procesados::NUMERIC / total_registros) * 100, 1);
        RAISE NOTICE 'Avance: % de % ( % % )', procesados, total_registros, porcentaje, '%';

        -- Seguridad: salir si ya no se actualiza nada
        IF actualizados = 0 THEN
            EXIT;
        END IF;
    END LOOP;

    RAISE NOTICE 'Proceso finalizado. Total actualizado: %', procesados;
END $$;

COMMIT;
  
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------ACTUALIZACION EN CAPA DE ENTRADA----------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

do $$
begin
	raise notice '--------------------------------------------------------';
	raise notice '--Actualizando nuevo orden, en la capa suministrada...--';
	raise notice '--------------------------------------------------------';
end $$;

--------------------------------------------------------------------------------
--actualizar nueva geometria
BEGIN;

alter table produccion.prueba add column ordenamiento_placa varchar;

update produccion.prueba o
set geom = p.nueva_geom, ordenamiento_placa = 'cambio_orden'
from placas_procesar p
where o.id = p.id;

do $$
begin
	raise notice 'Actualizacion en capa suministrada, 50%%...';
end $$;

reindex table produccion.prueba;

COMMIT;

do $$
begin
	raise notice 'Actualizacion en capa suministrada, 80%%...';
end $$;

--------------------------------------------------------------------------------
--Eliminar capas de procesos
BEGIN;

DROP TABLE placas_procesar;
drop table mavvial_procesar;
drop table start_point_mavvial;

COMMIT;

do $$
begin
	raise notice '-------------------------------------------------';
	raise notice '-------------------------------------------------';
	raise notice '--Algoritmo Ordenamiento de placas, FINALIZADO!--';
	raise notice '-------------------------------------------------';
	raise notice '-------------------------------------------------';
end $$;

