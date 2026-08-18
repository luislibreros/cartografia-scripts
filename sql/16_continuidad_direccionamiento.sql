-- ServiFlow · script de placas (parametrizado)
-- El esquema es {{esquema}} (se elige en el panel). Modo 'schema':
-- corre DIRECTO sobre el esquema elegido; úsalo en un esquema de trabajo.

/*
********************************************************************************
* Código: continuidad_direccionamiento
* Fecha de creación: 05-09-2025
* Última modificación: 23-02-2026
* Versión: 2.1
********************************************************************************
*/

----------------------------------------------------------------------
-- Crear columna id_grupo_swap
----------------------------------------------------------------------
ALTER TABLE "{{esquema}}".mavvial_fin 
  DROP COLUMN IF EXISTS id_grupo_swap;

ALTER TABLE "{{esquema}}".mavvial_fin 
  ADD COLUMN id_grupo_swap integer;

----------------------------------------------------------------------
-- Analisis para swap por tramo entero, Crear capa para geometrias continuas
----------------------------------------------------------------------
BEGIN;

-- Agregar id por tramo (solo vectores continuos conectados)
WITH clusters AS (
    SELECT
        id,
        ST_ClusterIntersectingWin(geom) OVER (
            PARTITION BY nomvtotal, cod_mun
        ) AS cluster_id,
        nomvtotal,
        cod_mun
    FROM "{{esquema}}".mavvial_fin
),
grupos AS (
    SELECT
        id,
        DENSE_RANK() OVER (
            ORDER BY nomvtotal, cod_mun, cluster_id
        ) AS nuevo_id_via
    FROM clusters
)
UPDATE "{{esquema}}".mavvial_fin t
SET id_grupo_swap = g.nuevo_id_via
FROM grupos g
WHERE t.id = g.id;

COMMIT;

-----------------------------------------------------------------
-- Paso 1: Calcular y almacenar orientación
-----------------------------------------------------------------

ALTER TABLE "{{esquema}}".mavvial_fin 
  DROP COLUMN IF EXISTS orientacion;

ALTER TABLE "{{esquema}}".mavvial_fin 
  ADD COLUMN orientacion double precision;

-- Usar ST_LineMerge para manejar MULTILINESTRING
UPDATE "{{esquema}}".mavvial_fin
SET orientacion = degrees(
    ST_Azimuth(
        ST_StartPoint(ST_LineMerge(geom)),
        ST_EndPoint(ST_LineMerge(geom))
    )
)
WHERE id_grupo_swap IS NOT NULL
  AND ST_NPoints(geom) >= 2
  AND NOT ST_Equals(
        ST_StartPoint(ST_LineMerge(geom)), 
        ST_EndPoint(ST_LineMerge(geom))
      );

-- Verificación rápida
SELECT COUNT(*) AS total,
       COUNT(orientacion) AS con_orientacion,
       COUNT(*) - COUNT(orientacion) AS sin_orientacion,
       MIN(orientacion)::numeric(6,2) AS min_az,
       MAX(orientacion)::numeric(6,2) AS max_az
FROM "{{esquema}}".mavvial_fin
WHERE id_grupo_swap IS NOT NULL;

-----------------------------------------------------------------
-- Paso 2 (diagnóstico): Ver líneas con orientación opuesta
-----------------------------------------------------------------

WITH dominant AS (
    SELECT 
        id_grupo_swap,
        degrees(
            atan2(
                SUM(sin(radians(orientacion))),
                SUM(cos(radians(orientacion)))
            )
        ) AS azimut_dominante,
        COUNT(*) AS total_lineas
    FROM "{{esquema}}".mavvial_fin
    WHERE orientacion IS NOT NULL
      AND id_grupo_swap IS NOT NULL
    GROUP BY id_grupo_swap
    HAVING COUNT(*) > 1
),
con_diferencia AS (
    SELECT 
        m.id_capa,
        m.id_grupo_swap,
        m.orientacion AS azimut_grados,
        d.azimut_dominante,
        d.total_lineas,
        degrees(
            acos(
                LEAST(1, GREATEST(-1,
                    cos(radians(m.orientacion) - radians(d.azimut_dominante))
                ))
            )
        ) AS diferencia_angular
    FROM "{{esquema}}".mavvial_fin m
    JOIN dominant d ON m.id_grupo_swap = d.id_grupo_swap
    WHERE m.orientacion IS NOT NULL
)
SELECT 
    c.id_capa,
    c.id_grupo_swap,
    c.azimut_grados,
    c.azimut_dominante,
    c.diferencia_angular,
    c.total_lineas
FROM con_diferencia c
WHERE c.diferencia_angular > 120
ORDER BY c.id_grupo_swap, c.diferencia_angular DESC;

-----------------------------------------------------------------
-- Paso 3: Marcar validar_swap (bando minoritario)
-----------------------------------------------------------------

ALTER TABLE "{{esquema}}".mavvial_fin 
  ADD COLUMN IF NOT EXISTS validar_swap integer DEFAULT 0;

UPDATE "{{esquema}}".mavvial_fin SET validar_swap = 0;

WITH dominant AS (
    SELECT 
        id_grupo_swap,
        atan2(
            SUM(sin(radians(orientacion))),
            SUM(cos(radians(orientacion)))
        ) AS dom_az
    FROM "{{esquema}}".mavvial_fin
    WHERE orientacion IS NOT NULL
      AND id_grupo_swap IS NOT NULL
    GROUP BY id_grupo_swap
),
classified AS (
    SELECT 
        m.id_capa,
        m.id_grupo_swap,
        CASE 
            WHEN acos(
                LEAST(1, GREATEST(-1, 
                    cos(radians(m.orientacion) - d.dom_az)
                ))
            ) > 2 * pi() / 3
            THEN 1 
            ELSE 0 
        END AS is_diff
    FROM "{{esquema}}".mavvial_fin m
    JOIN dominant d USING (id_grupo_swap)
    WHERE m.orientacion IS NOT NULL
),
band_counts AS (
    SELECT 
        id_grupo_swap,
        SUM(is_diff)::int AS cnt_diff,
        (COUNT(*) - SUM(is_diff))::int AS cnt_same
    FROM classified
    GROUP BY id_grupo_swap
)
UPDATE "{{esquema}}".mavvial_fin m
SET validar_swap = 1
FROM classified c
JOIN band_counts b USING (id_grupo_swap)
WHERE m.id_capa = c.id_capa
  AND b.cnt_diff > 0
  AND (
      (b.cnt_diff <= b.cnt_same AND c.is_diff = 1)
      OR
      (b.cnt_diff > b.cnt_same AND c.is_diff = 0)
  );

-- Verificación final
SELECT validar_swap, COUNT(*) 
FROM "{{esquema}}".mavvial_fin 
WHERE id_grupo_swap IS NOT NULL 
GROUP BY validar_swap;

-----------------------------------------------------------------
-- Limpieza
-----------------------------------------------------------------
DROP TABLE IF EXISTS mavvial_centroides;
DROP TABLE IF EXISTS mavvial_continuos_buffer;
DROP TABLE IF EXISTS mavvial_continuos;

-- Respaldo antes del swap
DROP TABLE IF EXISTS "{{esquema}}".mavvial_fin_backup;
CREATE TABLE "{{esquema}}".mavvial_fin_backup AS 
SELECT * FROM "{{esquema}}".mavvial_fin;

-- Ahora sí, invertir
UPDATE "{{esquema}}".mavvial_fin
SET geom = ST_Reverse(geom)
WHERE validar_swap = 1;
