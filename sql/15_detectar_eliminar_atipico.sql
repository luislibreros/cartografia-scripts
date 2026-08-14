-- =============================================================================
-- DETECCIÓN ROBUSTA DE PLACAS ATÍPICAS (VERSIÓN ULTRA-OPTIMIZADA)
-- =============================================================================

DO $$ BEGIN RAISE NOTICE '[%] PASO 0: Preparación...', clock_timestamp(); END $$;

ALTER TABLE "01_tar".placa_ajustado ADD COLUMN IF NOT EXISTS atipico TEXT;
UPDATE "01_tar".placa_ajustado SET atipico = NULL;

ALTER TABLE "01_tar".placa_ajustado ADD COLUMN IF NOT EXISTS _flag_gen         BOOLEAN DEFAULT FALSE;
ALTER TABLE "01_tar".placa_ajustado ADD COLUMN IF NOT EXISTS _flag_cluster     BOOLEAN DEFAULT FALSE;
ALTER TABLE "01_tar".placa_ajustado ADD COLUMN IF NOT EXISTS _flag_iqr         BOOLEAN DEFAULT FALSE;
ALTER TABLE "01_tar".placa_ajustado ADD COLUMN IF NOT EXISTS _flag_knn         BOOLEAN DEFAULT FALSE;
ALTER TABLE "01_tar".placa_ajustado ADD COLUMN IF NOT EXISTS _flag_contexto    BOOLEAN DEFAULT FALSE;
ALTER TABLE "01_tar".placa_ajustado ADD COLUMN IF NOT EXISTS _protegida        BOOLEAN DEFAULT FALSE;
ALTER TABLE "01_tar".placa_ajustado ADD COLUMN IF NOT EXISTS _score_total      INTEGER DEFAULT 0;
ALTER TABLE "01_tar".placa_ajustado ADD COLUMN IF NOT EXISTS _detalle_atipico  TEXT;

UPDATE "01_tar".placa_ajustado SET
    _flag_gen = FALSE, _flag_cluster = FALSE, _flag_iqr = FALSE,
    _flag_knn = FALSE, _flag_contexto = FALSE, _protegida = FALSE,
    _score_total = 0, _detalle_atipico = NULL;

UPDATE "01_tar".placa_ajustado
SET atipico          = 'ATIPICO',
    _detalle_atipico = 'NO_NUMERICO',
    _score_total     = 1
WHERE placa !~ '^\d';;

-- (recalculo de generadora REMOVIDO: ya esta calculada en placa_ajustado)

CREATE INDEX IF NOT EXISTS idx_placa_mavvial ON "01_tar".placa_ajustado (id_mavvial);
CREATE INDEX IF NOT EXISTS idx_placa_nomvia  ON "01_tar".placa_ajustado (nomvia);
CREATE INDEX IF NOT EXISTS idx_placa_id_capa ON "01_tar".placa_ajustado (id_capa);

-- ─────────────────────────────────────────────────────────────────────────────
-- Tabla base temporal
-- ─────────────────────────────────────────────────────────────────────────────
DROP TABLE IF EXISTS _tmp_base;
CREATE TEMP TABLE _tmp_base AS
SELECT id_capa AS id, id_mavvial, nomvia,
       NULLIF(regexp_replace(placa,'[^0-9]','','g'),'')::numeric AS val,
       (floor(NULLIF(regexp_replace(placa,'[^0-9]','','g'),'')::numeric / 100) * 100) AS gen,
       ST_X(geom) AS x, ST_Y(geom) AS y, geom
FROM "01_tar".placa_ajustado
WHERE atipico IS NULL;

CREATE INDEX ON _tmp_base (id_mavvial);
CREATE INDEX ON _tmp_base (id);
CREATE INDEX ON _tmp_base (id_mavvial, val);

-- Estadísticas por tramo
DROP TABLE IF EXISTS _tmp_stats;
CREATE TEMP TABLE _tmp_stats AS
SELECT id_mavvial, COUNT(*) AS n,
       percentile_cont(0.25) WITHIN GROUP (ORDER BY val) AS q1,
       percentile_cont(0.75) WITHIN GROUP (ORDER BY val) AS q3,
       percentile_cont(0.75) WITHIN GROUP (ORDER BY val) - percentile_cont(0.25) WITHIN GROUP (ORDER BY val) AS iqr,
       stddev_samp(val) AS std_val
FROM _tmp_base GROUP BY id_mavvial;

CREATE UNIQUE INDEX ON _tmp_stats (id_mavvial);
ANALYZE _tmp_base;
ANALYZE _tmp_stats;

DO $$ BEGIN RAISE NOTICE '[%] PASO 0: Completo.', clock_timestamp(); END $$;


-- =============================================================================
-- PASO 1: CADENA POR GRUPO CONTIGUO MÁS GRANDE
-- =============================================================================
DO $$ BEGIN RAISE NOTICE '[%] PASO 1: Grupos contiguos de generadoras...', clock_timestamp(); END $$;

DROP TABLE IF EXISTS _tmp_gens;
CREATE TEMP TABLE _tmp_gens AS SELECT id_mavvial, gen, COUNT(*) AS cnt FROM _tmp_base GROUP BY id_mavvial, gen;

DROP TABLE IF EXISTS _tmp_groups;
CREATE TEMP TABLE _tmp_groups AS
WITH numbered AS (
    SELECT id_mavvial, gen, cnt, gen - LAG(gen) OVER (PARTITION BY id_mavvial ORDER BY gen) AS gap FROM _tmp_gens
),
grouped AS (
    SELECT id_mavvial, gen, cnt, SUM(CASE WHEN gap IS NULL OR gap > 200 THEN 1 ELSE 0 END) OVER (PARTITION BY id_mavvial ORDER BY gen) AS grp_seq FROM numbered
)
SELECT id_mavvial, gen, MIN(gen) OVER (PARTITION BY id_mavvial, grp_seq) AS group_id FROM grouped;

DROP TABLE IF EXISTS _tmp_group_totals;
CREATE TEMP TABLE _tmp_group_totals AS SELECT gr.id_mavvial, gr.group_id, SUM(g.cnt) AS group_total FROM _tmp_groups gr JOIN _tmp_gens g ON gr.id_mavvial = g.id_mavvial AND gr.gen = g.gen GROUP BY gr.id_mavvial, gr.group_id;

DROP TABLE IF EXISTS _tmp_group_rank;
CREATE TEMP TABLE _tmp_group_rank AS SELECT id_mavvial, group_id, group_total, ROW_NUMBER() OVER (PARTITION BY id_mavvial ORDER BY group_total DESC, group_id ASC) AS rn FROM _tmp_group_totals;

DROP TABLE IF EXISTS _tmp_winner;
CREATE TEMP TABLE _tmp_winner AS SELECT r1.id_mavvial, r1.group_id AS winner_group FROM _tmp_group_rank r1 LEFT JOIN _tmp_group_rank r2 ON r1.id_mavvial = r2.id_mavvial AND r2.rn = 2 JOIN _tmp_stats s ON r1.id_mavvial = s.id_mavvial WHERE r1.rn = 1 AND s.n >= 3 AND r1.group_total > COALESCE(r2.group_total, 0);

DROP TABLE IF EXISTS _tmp_chain;
CREATE TEMP TABLE _tmp_chain AS SELECT gr.id_mavvial, gr.gen FROM _tmp_groups gr JOIN _tmp_winner w ON gr.id_mavvial = w.id_mavvial AND gr.group_id = w.winner_group;

UPDATE "01_tar".placa_ajustado p SET _flag_gen = TRUE FROM _tmp_base b WHERE p.id_capa = b.id AND b.id_mavvial IN (SELECT id_mavvial FROM _tmp_winner) AND NOT EXISTS (SELECT 1 FROM _tmp_chain ch WHERE ch.id_mavvial = b.id_mavvial AND ch.gen = b.gen);
UPDATE "01_tar".placa_ajustado p SET _protegida = TRUE FROM _tmp_base b WHERE p.id_capa = b.id AND EXISTS (SELECT 1 FROM _tmp_chain ch WHERE ch.id_mavvial = b.id_mavvial AND ch.gen = b.gen);
UPDATE "01_tar".placa_ajustado SET _protegida = TRUE WHERE id_mavvial IN (SELECT id_mavvial FROM _tmp_stats WHERE n < 3);

DO $$ BEGIN RAISE NOTICE '[%] PASO 1: Completo.', clock_timestamp(); END $$;

-- =============================================================================
-- PASO 2: CLUSTERING
-- =============================================================================
DO $$ BEGIN RAISE NOTICE '[%] PASO 2: Clustering...', clock_timestamp(); END $$;

DROP TABLE IF EXISTS _tmp_ordered;
CREATE TEMP TABLE _tmp_ordered AS SELECT id, id_mavvial, val, ROW_NUMBER() OVER (PARTITION BY id_mavvial ORDER BY val) AS rn, val - LAG(val) OVER (PARTITION BY id_mavvial ORDER BY val) AS gap_prev FROM _tmp_base WHERE id_mavvial IN (SELECT id_mavvial FROM _tmp_stats WHERE n >= 5);

DROP TABLE IF EXISTS _tmp_eps;
CREATE TEMP TABLE _tmp_eps AS SELECT id_mavvial, GREATEST(percentile_cont(0.5) WITHIN GROUP (ORDER BY gap_prev) * 8, 50) AS eps FROM _tmp_ordered WHERE gap_prev IS NOT NULL AND gap_prev > 0 GROUP BY id_mavvial;

DROP TABLE IF EXISTS _tmp_clusters;
CREATE TEMP TABLE _tmp_clusters AS SELECT o.id, o.id_mavvial, o.val, SUM(CASE WHEN o.gap_prev IS NULL OR o.gap_prev <= e.eps THEN 0 ELSE 1 END) OVER (PARTITION BY o.id_mavvial ORDER BY o.rn) AS cluster_id FROM _tmp_ordered o JOIN _tmp_eps e ON o.id_mavvial = e.id_mavvial;

DROP TABLE IF EXISTS _tmp_csizes;
CREATE TEMP TABLE _tmp_csizes AS SELECT id_mavvial, cluster_id, COUNT(*) AS sz FROM _tmp_clusters GROUP BY id_mavvial, cluster_id;

DROP TABLE IF EXISTS _tmp_largest;
CREATE TEMP TABLE _tmp_largest AS SELECT DISTINCT ON (id_mavvial) id_mavvial, cluster_id AS largest_cluster FROM _tmp_csizes ORDER BY id_mavvial, sz DESC, cluster_id;

UPDATE "01_tar".placa_ajustado p SET _flag_cluster = TRUE FROM _tmp_clusters c JOIN _tmp_largest l ON c.id_mavvial = l.id_mavvial WHERE p.id_capa = c.id AND c.cluster_id <> l.largest_cluster AND c.id_mavvial IN (SELECT id_mavvial FROM _tmp_csizes GROUP BY id_mavvial HAVING COUNT(*) > 1);

DO $$ BEGIN RAISE NOTICE '[%] PASO 2: Completo.', clock_timestamp(); END $$;

-- =============================================================================
-- PASO 3: IQR
-- =============================================================================
DO $$ BEGIN RAISE NOTICE '[%] PASO 3: IQR...', clock_timestamp(); END $$;

UPDATE "01_tar".placa_ajustado p SET _flag_iqr = TRUE FROM _tmp_base b JOIN _tmp_stats s ON b.id_mavvial = s.id_mavvial WHERE p.id_capa = b.id AND s.n >= 5 AND s.iqr > 0 AND (b.val < s.q1 - 1.5 * s.iqr OR b.val > s.q3 + 1.5 * s.iqr);

DO $$ BEGIN RAISE NOTICE '[%] PASO 3: Completo.', clock_timestamp(); END $$;

-- =============================================================================
-- PASO 4: VECINDAD NUMÉRICA (REEMPLAZO ULTRA-RÁPIDO SIN GEOMETRÍA)
-- =============================================================================
DO $$ BEGIN RAISE NOTICE '[%] PASO 4: Vecindad numérica por ventanas (Inmediato)...', clock_timestamp(); END $$;

-- Usamos funciones de ventana de orden numérico (LAG/LEAD) en lugar de cruces espaciales.
-- Promedia las 2 placas anteriores y las 2 posteriores en el mismo tramo.
DROP TABLE IF EXISTS _tmp_knn;
CREATE TEMP TABLE _tmp_knn AS
SELECT id, id_mavvial, val AS val_a,
       ( (COALESCE(LAG(val, 2) OVER (PARTITION BY id_mavvial ORDER BY val), val) +
          COALESCE(LAG(val, 1) OVER (PARTITION BY id_mavvial ORDER BY val), val) +
          COALESCE(LEAD(val, 1) OVER (PARTITION BY id_mavvial ORDER BY val), val) +
          COALESCE(LEAD(val, 2) OVER (PARTITION BY id_mavvial ORDER BY val), val)) / 4.0 ) AS media_vecinos
FROM _tmp_base
WHERE id_mavvial IN (SELECT id_mavvial FROM _tmp_stats WHERE n BETWEEN 5 AND 100 AND std_val > 0);

CREATE INDEX ON _tmp_knn (id);

UPDATE "01_tar".placa_ajustado p
SET _flag_knn = TRUE
FROM _tmp_knn k
JOIN _tmp_stats s ON k.id_mavvial = s.id_mavvial
WHERE p.id_capa = k.id
  AND s.std_val > 0
  AND ABS(k.val_a - k.media_vecinos) / s.std_val > 2.5;

DO $$ BEGIN RAISE NOTICE '[%] PASO 4: Completo.', clock_timestamp(); END $$;

-- =============================================================================
-- PASO 5: CONTEXTO VECINAL (OPTIMIZACIÓN ALFANUMÉRICA)
-- =============================================================================
DO $$ BEGIN RAISE NOTICE '[%] PASO 5: Contexto vecinal...', clock_timestamp(); END $$;

DROP TABLE IF EXISTS _tmp_centroides;
CREATE TEMP TABLE _tmp_centroides AS
SELECT id_mavvial, nomvia, AVG(x) AS cx, AVG(y) AS cy, COUNT(*) AS n_placas 
FROM _tmp_base GROUP BY id_mavvial, nomvia;

CREATE INDEX ON _tmp_centroides (nomvia);

-- Unión puramente por nombre de vía y proximidad de cajas delimitadoras rápidas
DROP TABLE IF EXISTS _tmp_vecinos;
CREATE TEMP TABLE _tmp_vecinos AS
SELECT cp.id_mavvial AS id_pequeno, cv.id_mavvial AS id_vecino 
FROM _tmp_centroides cp 
JOIN _tmp_centroides cv ON cp.nomvia = cv.nomvia 
                       AND cp.id_mavvial <> cv.id_mavvial
                       AND ABS(cp.cx - cv.cx) < 0.005 
                       AND ABS(cp.cy - cv.cy) < 0.005
WHERE cp.n_placas <= 4;

CREATE INDEX ON _tmp_vecinos (id_pequeno);

DROP TABLE IF EXISTS _tmp_ctx;
CREATE TEMP TABLE _tmp_ctx AS
SELECT v.id_pequeno, 
       percentile_cont(0.10) WITHIN GROUP (ORDER BY b.val) AS p10, 
       percentile_cont(0.90) WITHIN GROUP (ORDER BY b.val) AS p90, 
       percentile_cont(0.25) WITHIN GROUP (ORDER BY b.val) AS q1_v, 
       percentile_cont(0.75) WITHIN GROUP (ORDER BY b.val) AS q3_v 
FROM _tmp_vecinos v 
JOIN _tmp_base b ON b.id_mavvial = v.id_vecino 
GROUP BY v.id_pequeno HAVING COUNT(*) >= 10;

UPDATE "01_tar".placa_ajustado p
SET _flag_contexto = TRUE
FROM _tmp_base b
JOIN _tmp_ctx cs ON b.id_mavvial = cs.id_pequeno
WHERE p.id_capa = b.id
  AND (b.val < cs.p10 - 1.5 * (cs.q3_v - cs.q1_v) OR b.val > cs.p90 + 1.5 * (cs.q3_v - cs.q1_v));

DO $$ BEGIN RAISE NOTICE '[%] PASO 5: Completo.', clock_timestamp(); END $$;

-- =============================================================================
-- PASO 6: VOTACIÓN Y MARCADO FINAL
-- =============================================================================
DO $$ BEGIN RAISE NOTICE '[%] PASO 6: Votación...', clock_timestamp(); END $$;

UPDATE "01_tar".placa_ajustado SET _score_total = (_flag_gen::int + _flag_cluster::int + _flag_iqr::int + _flag_knn::int + _flag_contexto::int) WHERE atipico IS NULL;
UPDATE "01_tar".placa_ajustado SET _detalle_atipico = CONCAT_WS(', ', CASE WHEN _flag_gen THEN 'GEN' END, CASE WHEN _flag_cluster THEN 'CLUSTER' END, CASE WHEN _flag_iqr THEN 'IQR' END, CASE WHEN _flag_knn THEN 'KNN' END, CASE WHEN _flag_contexto THEN 'CONTEXTO' END, CASE WHEN _protegida THEN '(PROTEGIDA)' END) WHERE atipico IS NULL AND _score_total > 0;
UPDATE "01_tar".placa_ajustado SET atipico = 'ATIPICO' WHERE _flag_gen = TRUE;
UPDATE "01_tar".placa_ajustado SET atipico = 'ATIPICO' WHERE atipico IS NULL AND _protegida = FALSE AND (_flag_cluster::int + _flag_iqr::int + _flag_knn::int + _flag_contexto::int) >= 2;
UPDATE "01_tar".placa_ajustado SET atipico = 'ATIPICO' WHERE atipico IS NULL AND _protegida = FALSE AND _flag_contexto = TRUE AND id_mavvial IN (SELECT id_mavvial FROM _tmp_stats WHERE n <= 4);

DO $$ BEGIN RAISE NOTICE '[%] PASO 6: Completo.', clock_timestamp(); END $$;

-- =============================================================================
-- REPORTE Y LIMPIEZA
-- =============================================================================
DROP TABLE IF EXISTS _tmp_base; DROP TABLE IF EXISTS _tmp_stats; DROP TABLE IF EXISTS _tmp_gens; DROP TABLE IF EXISTS _tmp_groups; DROP TABLE IF EXISTS _tmp_group_totals; DROP TABLE IF EXISTS _tmp_group_rank; DROP TABLE IF EXISTS _tmp_winner; DROP TABLE IF EXISTS _tmp_chain; DROP TABLE IF EXISTS _tmp_ordered; DROP TABLE IF EXISTS _tmp_eps; DROP TABLE IF EXISTS _tmp_clusters; DROP TABLE IF EXISTS _tmp_csizes; DROP TABLE IF EXISTS _tmp_largest; DROP TABLE IF EXISTS _tmp_knn; DROP TABLE IF EXISTS _tmp_centroides; DROP TABLE IF EXISTS _tmp_vecinos; DROP TABLE IF EXISTS _tmp_ctx;

DO $$ BEGIN RAISE NOTICE '[%] PROCESO COMPLETO EXITOSAMENTE.', clock_timestamp(); END $$;