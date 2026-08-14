-- =====================================================================
-- ServiFlow · Paso 5 · Generar polígono de área urbana Servi
--   esquema={{esquema}}  vial={{tabla}}  oficial={{capa_ibge}}  salida={{capa_salida}}
-- =====================================================================
SET work_mem = '512MB';
SET maintenance_work_mem = '1GB';
SET max_parallel_workers_per_gather = 4;

DROP TABLE IF EXISTS "{{esquema}}".{{capa_salida}} CASCADE;

CREATE TABLE "{{esquema}}".{{capa_salida}} AS
WITH dissolved AS (
    SELECT ST_UnaryUnion(ST_Collect(
             ST_Buffer(ST_SnapToGrid(geom, 0.00001), 0.0009,
                       'quad_segs=12 endcap=flat join=round'))) AS geom
    FROM (
        SELECT geom FROM "{{esquema}}".{{tabla}}     WHERE geom IS NOT NULL
        UNION ALL
        SELECT geom FROM "{{esquema}}".{{capa_ibge}} WHERE geom IS NOT NULL
    ) t
),
dumped AS (SELECT (ST_Dump(geom)).geom AS geom FROM dissolved)
SELECT ROW_NUMBER() OVER()::int AS gid,
       geom::geometry(Polygon, 4326) AS geom
FROM dumped;

CREATE INDEX ON "{{esquema}}".{{capa_salida}} USING GIST (geom);
ALTER TABLE "{{esquema}}".{{capa_salida}} ADD PRIMARY KEY (gid);
RESET ALL;

-- erosión de -2 m para cerrar bordes
DROP TABLE IF EXISTS "{{esquema}}".{{capa_salida}}_m2 CASCADE;
CREATE TABLE "{{esquema}}".{{capa_salida}}_m2 AS
SELECT gid,
       ST_Transform(ST_Buffer(ST_Transform(geom, 3857), -2), 4326)::geometry(MultiPolygon, 4326) AS geom
FROM "{{esquema}}".{{capa_salida}}
WHERE geom IS NOT NULL;

DROP TABLE IF EXISTS "{{esquema}}".{{capa_salida}} CASCADE;
ALTER TABLE "{{esquema}}".{{capa_salida}}_m2 RENAME TO {{capa_salida}};
