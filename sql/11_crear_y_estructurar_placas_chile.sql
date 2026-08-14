DO $$
BEGIN

-- =============================================================================
-- CREAR CAPA PLACA_SA - SANTIAGO
-- Fuente:  predial.placa_s
-- Filtro:  ST_Intersects con predial.area_urbana
-- Versión: Chile
-- =============================================================================

RAISE NOTICE '=== INICIANDO PROCESO DE CREACIÓN DE CAPA PLACA_SA SANTIAGO ===';

-- =============================================================================
-- PASO 1 · Eliminar y recrear la tabla
-- =============================================================================
RAISE NOTICE 'Eliminando tabla placa_sa si existe...';
DROP TABLE IF EXISTS predial.placa_sa;

RAISE NOTICE 'Creando estructura de tabla placa_sa...';
CREATE TABLE predial.placa_sa (
    id          SERIAL PRIMARY KEY,
    id_capa     INTEGER,
    tipovia     VARCHAR(10),
    nomvia      VARCHAR(100),
    nomvtotal   VARCHAR(100),
    generadora  VARCHAR(50),
    placa       VARCHAR(12),
    cod_bar     VARCHAR(10),
    nom_bar     VARCHAR(100),
    cod_urb     VARCHAR(10),
    nom_urb     VARCHAR(100),
    manzana     VARCHAR(30),
    casa_lote   VARCHAR(50),
    tipo_dir    VARCHAR(20),
    cod_postal  VARCHAR(10),
    direccion   VARCHAR(180),
    id_mavvial  INTEGER,
    cod_reg     VARCHAR(10),
    nom_reg     VARCHAR(100),
    cod_prov    VARCHAR(10),
    nom_prov    VARCHAR(100),
    cod_com     VARCHAR(5),
    nom_com     VARCHAR(100),
    id_fuente   INTEGER,
    fuente      VARCHAR(50),
    observ_dat  VARCHAR(30),
    observ_pos  VARCHAR(30),
    estado      VARCHAR(10),
    fecha_est   VARCHAR(10),
    marca       VARCHAR(5),
    fecha       VARCHAR(10),
    version     VARCHAR(5),
    incidencia  VARCHAR(100),
    atipico     VARCHAR(20),
    geom        geometry(Point, 4326)
);

-- =============================================================================
-- PASO 2 · Insertar registros desde placa_s
--   Filtro espacial: solo puntos dentro de area_urbana
-- =============================================================================
RAISE NOTICE 'Insertando placas que intersectan con área urbana...';

INSERT INTO predial.placa_sa (
    id_capa, tipovia, nomvia, nomvtotal, generadora, placa,
    cod_bar, nom_bar, cod_urb, nom_urb,
    manzana, casa_lote, tipo_dir, cod_postal, direccion,
    id_mavvial, cod_reg, nom_reg, cod_prov, nom_prov,
    cod_com, nom_com, id_fuente, fuente, observ_dat, observ_pos,
    estado, fecha_est, marca, fecha, version, incidencia, atipico,
    geom
)
SELECT
    ps.id_chile_total::INTEGER      AS id_capa,
    ps.tipovia,
    ps.nomvia,
    ps.nomvtotal,
    NULL::VARCHAR(50)               AS generadora,
    ps.placa,
    NULL::VARCHAR(10)               AS cod_bar,
    NULL::VARCHAR(100)              AS nom_bar,
    NULL::VARCHAR(10)               AS cod_urb,
    NULL::VARCHAR(100)              AS nom_urb,
    ps.manzana_servi::VARCHAR(30)   AS manzana,
    ps.casa_lote,
    ps.tipo_direccion_placa         AS tipo_dir,
    ps.cod_postal,
    TRIM(
        COALESCE(ps.tipovia   || ' ', '') ||
        COALESCE(ps.nomvia    || ' ', '') ||
        COALESCE(ps.casa_lote || ' ', '') ||
        COALESCE(ps.placa,           '')
    )                               AS direccion,
    ps.id_mavvial,
    ps.cod_reg,
    ps.nom_reg,
    ps.cod_prov,
    ps.nom_prov,
    ps.cod_com::VARCHAR(5),
    ps.nom_com::VARCHAR(100),
    NULL::INTEGER                   AS id_fuente,
    NULL::VARCHAR(50)               AS fuente,
    NULL::VARCHAR(30)               AS observ_dat,
    NULL::VARCHAR(30)               AS observ_pos,
    NULL::VARCHAR(10)               AS estado,
    NULL::VARCHAR(10)               AS fecha_est,
    NULL::VARCHAR(5)                AS marca,
    NULL::VARCHAR(10)               AS fecha,
    NULL::VARCHAR(5)                AS version,
    NULL::VARCHAR(100)              AS incidencia,
    NULL::VARCHAR(20)               AS atipico,
    ps.geom
FROM predial.placa_s ps
JOIN predial.area_urbana au
  ON ST_Intersects(ps.geom, au.geom);

RAISE NOTICE 'Registros insertados: %', (SELECT COUNT(*) FROM predial.placa_sa);

-- =============================================================================
-- PASO 3 · Crear índice espacial
-- =============================================================================
RAISE NOTICE 'Creando índice espacial...';
CREATE INDEX idx_geom_placa_sa ON predial.placa_sa USING GIST (geom);

-- =============================================================================
-- PASO 4 · Limpiar registros inválidos
--   · Sin nomvia
--   · placa = '0', 'S/N' o 'SN'
-- =============================================================================
RAISE NOTICE 'Eliminando registros inválidos...';
DELETE FROM predial.placa_sa
WHERE nomvia IS NULL
   OR TRIM(nomvia) = ''
   OR placa IN ('0', 'S/N', 'SN');

RAISE NOTICE 'Registros tras limpieza: %', (SELECT COUNT(*) FROM predial.placa_sa);

-- =============================================================================
-- PASO 5 · Limpiar números de 4+ dígitos residuales en nomvtotal
-- =============================================================================
RAISE NOTICE 'Limpiando números residuales en nomvtotal...';
UPDATE predial.placa_sa
SET nomvtotal = TRIM(REGEXP_REPLACE(nomvtotal, '\s*\m\d{4,}.*$', '', 'g'))
WHERE nomvtotal ~ '\m\d{4,}';

-- =============================================================================
-- PASO 6 · Eliminar duplicados por llave
--   Llave: placa + nomvia + manzana + cod_com
-- =============================================================================
RAISE NOTICE 'Calculando y eliminando duplicados...';
ALTER TABLE predial.placa_sa ADD COLUMN llave TEXT;
CREATE INDEX idx_llave_placa_sa ON predial.placa_sa (llave);

UPDATE predial.placa_sa
SET llave = LOWER(REGEXP_REPLACE(
    COALESCE(placa,   '') ||
    COALESCE(nomvia,  '') ||
    COALESCE(manzana, '') ||
    COALESCE(cod_com, ''),
    '\s+', '', 'g'
));

DELETE FROM predial.placa_sa
WHERE id IN (
    SELECT id
    FROM (
        SELECT id,
               ROW_NUMBER() OVER (PARTITION BY llave ORDER BY id) AS rn
        FROM predial.placa_sa
    ) t
    WHERE rn > 1
);

RAISE NOTICE 'Registros finales: %', (SELECT COUNT(*) FROM predial.placa_sa);

-- =============================================================================
-- PASO 7 · Eliminar columna auxiliar llave
-- =============================================================================
ALTER TABLE predial.placa_sa DROP COLUMN llave;

RAISE NOTICE '=== PROCESO COMPLETADO EXITOSAMENTE ===';

END $$;