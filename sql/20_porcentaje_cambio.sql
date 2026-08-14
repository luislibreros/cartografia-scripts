-- ============================================================================
-- SCRIPT: Cálculo de longitud vial, distancia de desplazamiento de placas
--         y porcentaje de cambio respecto al tramo vial
-- ============================================================================
-- PARÁMETROS (modificar según esquema/capa):
--   @esquema        : 28_se
--   @capa_vial      : mavvial_fin
--   @capa_placa     : placa
--   @srid_local     : 31984  (UTM zona para Sergipe, Brasil)
--                     Ajustar según la zona UTM del estado/región:
--                       29_ba → 31984 | 35_sp → 31983 | etc.
-- ============================================================================

-- ▸ Usar variables de sesión para parametrizar esquema y SRID
-- ▸ Si se prefiere, reemplazar textualmente los valores antes de ejecutar.

-- ============================================================================
-- PASO 1: Agregar campo longitud_m en mavvial_fin (si no existe)
-- ============================================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = '28_se'
          AND table_name   = 'mavvial_fin'
          AND column_name  = 'longitud_m'
    ) THEN
        ALTER TABLE "28_se".mavvial_fin
            ADD COLUMN longitud_m DOUBLE PRECISION;
        RAISE NOTICE 'Campo longitud_m creado en 28_se.mavvial_fin';
    ELSE
        RAISE NOTICE 'Campo longitud_m ya existe en 28_se.mavvial_fin';
    END IF;
END $$;

-- ============================================================================
-- PASO 2: Calcular longitud en metros por tramo vial
-- ============================================================================
-- Usa ST_Length con geography para precisión geodésica sin depender de SRID local.
-- Si la geometría ya está en un SRID proyectado (UTM), se puede usar
-- ST_Length(geom) directamente, que es más rápido.
-- ============================================================================
UPDATE "28_se".mavvial_fin
SET longitud_m = ST_Length(geom::geography)
WHERE geom IS NOT NULL;

-- Verificación rápida
DO $$
DECLARE
    v_total   BIGINT;
    v_nulos   BIGINT;
    v_min     DOUBLE PRECISION;
    v_max     DOUBLE PRECISION;
    v_avg     DOUBLE PRECISION;
BEGIN
    SELECT COUNT(*),
           COUNT(*) FILTER (WHERE longitud_m IS NULL),
           MIN(longitud_m),
           MAX(longitud_m),
           AVG(longitud_m)
    INTO v_total, v_nulos, v_min, v_max, v_avg
    FROM "28_se".mavvial_fin;

    RAISE NOTICE '── LONGITUD_M ──';
    RAISE NOTICE 'Total registros : %', v_total;
    RAISE NOTICE 'Nulos           : %', v_nulos;
    RAISE NOTICE 'Mín (m)         : %', ROUND(v_min::numeric, 2);
    RAISE NOTICE 'Máx (m)         : %', ROUND(v_max::numeric, 2);
    RAISE NOTICE 'Promedio (m)    : %', ROUND(v_avg::numeric, 2);
END $$;

-- ============================================================================
-- PASO 3: Agregar campos en placa (si no existen)
-- ============================================================================
DO $$
BEGIN
    -- Campo distancia_actual_procesado_m
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = '28_se'
          AND table_name   = 'placa'
          AND column_name  = 'distancia_actual_procesado_m'
    ) THEN
        ALTER TABLE "28_se".placa
            ADD COLUMN distancia_actual_procesado_m DOUBLE PRECISION;
        RAISE NOTICE 'Campo distancia_actual_procesado_m creado en 28_se.placa';
    ELSE
        RAISE NOTICE 'Campo distancia_actual_procesado_m ya existe en 28_se.placa';
    END IF;

    -- Campo porcentaje_cambio
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = '28_se'
          AND table_name   = 'placa'
          AND column_name  = 'porcentaje_cambio'
    ) THEN
        ALTER TABLE "28_se".placa
            ADD COLUMN porcentaje_cambio DOUBLE PRECISION;
        RAISE NOTICE 'Campo porcentaje_cambio creado en 28_se.placa';
    ELSE
        RAISE NOTICE 'Campo porcentaje_cambio ya existe en 28_se.placa';
    END IF;
END $$;

-- ============================================================================
-- PASO 4: Calcular distancia entre posición actual y procesada (metros)
--         y porcentaje de cambio respecto a la longitud del tramo vial
-- ============================================================================
-- ST_DistanceSphere: calcula distancia geodésica en metros entre dos puntos
-- dados en lon/lat (SRID 4326). Es rápido y no requiere cast a geography.
--
-- Condiciones de seguridad:
--   • La placa debe tener coordenadas válidas (no nulas)
--   • El tramo vial asociado debe existir (JOIN)
--   • longitud_m del tramo debe ser > 0 para evitar división por cero
-- ============================================================================
UPDATE "28_se".placa AS p
SET
    distancia_actual_procesado_m = sub.dist_m,
    porcentaje_cambio            = sub.pct_cambio
FROM (
    SELECT
        p2.ctid AS rid,  -- usar ctid para update directo sin ambigüedad de PK
        ST_DistanceSphere(
            ST_MakePoint(p2.long_actual,  p2.lat_actual),
            ST_MakePoint(p2.lon_procesada, p2.lat_procesada)
        ) AS dist_m,
        (
            ST_DistanceSphere(
                ST_MakePoint(p2.long_actual,  p2.lat_actual),
                ST_MakePoint(p2.lon_procesada, p2.lat_procesada)
            )
            / m.longitud_m
        ) * 100.0 AS pct_cambio
    FROM "28_se".placa p2
    INNER JOIN "28_se".mavvial_fin m
        ON p2.id_mavvial = m.id_capa
    WHERE p2.long_actual    IS NOT NULL
      AND p2.lat_actual     IS NOT NULL
      AND p2.lon_procesada  IS NOT NULL
      AND p2.lat_procesada  IS NOT NULL
      AND m.longitud_m      IS NOT NULL
      AND m.longitud_m      > 0
) AS sub
WHERE p.ctid = sub.rid;

-- ============================================================================
-- PASO 5: Verificación final
-- ============================================================================
DO $$
DECLARE
    v_total      BIGINT;
    v_calculados BIGINT;
    v_sin_tramo  BIGINT;
    v_min_dist   DOUBLE PRECISION;
    v_max_dist   DOUBLE PRECISION;
    v_avg_pct    DOUBLE PRECISION;
BEGIN
    SELECT COUNT(*) INTO v_total FROM "28_se".placa;

    SELECT COUNT(*) INTO v_calculados
    FROM "28_se".placa
    WHERE distancia_actual_procesado_m IS NOT NULL;

    SELECT COUNT(*) INTO v_sin_tramo
    FROM "28_se".placa p
    LEFT JOIN "28_se".mavvial_fin m ON p.id_mavvial = m.id_capa
    WHERE m.id_capa IS NULL;

    SELECT MIN(distancia_actual_procesado_m),
           MAX(distancia_actual_procesado_m),
           AVG(porcentaje_cambio)
    INTO v_min_dist, v_max_dist, v_avg_pct
    FROM "28_se".placa
    WHERE distancia_actual_procesado_m IS NOT NULL;

    RAISE NOTICE '── RESULTADO FINAL ──';
    RAISE NOTICE 'Total placas           : %', v_total;
    RAISE NOTICE 'Placas calculadas      : %', v_calculados;
    RAISE NOTICE 'Placas sin tramo vial  : %', v_sin_tramo;
    RAISE NOTICE 'Dist mín (m)           : %', ROUND(v_min_dist::numeric, 4);
    RAISE NOTICE 'Dist máx (m)           : %', ROUND(v_max_dist::numeric, 4);
    RAISE NOTICE 'Porcentaje cambio prom : %', ROUND(v_avg_pct::numeric, 4);
END $$;

-- ============================================================================
-- CONSULTA DE REVISIÓN (no modifica datos)
-- ============================================================================
SELECT
    p.id_mavvial,
    p.long_actual,
    p.lat_actual,
    p.lon_procesada,
    p.lat_procesada,
    p.distancia_actual_procesado_m,
    m.longitud_m,
    p.porcentaje_cambio
FROM "28_se".placa p
INNER JOIN "28_se".mavvial_fin m
    ON p.id_mavvial = m.id_capa
WHERE p.distancia_actual_procesado_m IS NOT NULL
ORDER BY p.porcentaje_cambio DESC
LIMIT 50;
