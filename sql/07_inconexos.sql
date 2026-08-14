-- ServiFlow · Paso 7 · Detección de tramos inconexos (parametrizado)
-- esquema={{esquema}} vial={{tabla}} urbana={{tabla_urbana}} epsg={{epsg_metrico}}

/*******************************************************************************
 * SCRIPT: Detección de Tramos Inconexos en Malla Vial
 * ============================================================================
 * Miguel Ángel Bernal Segura  |  ESQUEMA: predial
 * ----------------------------------------------------------------------------
 * NOTA (correccion de tipos): id_capa en la tabla vial es VARCHAR. Todas las
 * tablas temporales castean seg_id / comp_id a BIGINT para que los JOINs y el
 * Union-Find operen numericamente y la escritura a componente_red (INT) no falle.
 ******************************************************************************/

SET work_mem                        = '512MB';
SET maintenance_work_mem            = '1GB';
SET max_parallel_workers_per_gather = 4;
SET enable_hashjoin                 = ON;
SET enable_mergejoin                = OFF;
SET jit                             = OFF;

DO $$
DECLARE
    -- =========================================================================
    --   PARÁMETROS  ← AJUSTAR AQUÍ
    -- =========================================================================
    p_esquema           CONSTANT TEXT    := '{{esquema}}';
    p_tabla_vial        CONSTANT TEXT    := '{{tabla}}';
    p_tabla_urbana      CONSTANT TEXT    := '{{tabla_urbana}}';
    p_id_vial           CONSTANT TEXT    := '{{id_vial}}';
    p_geom_vial         CONSTANT TEXT    := '{{geom}}';
    p_es_4326           CONSTANT BOOLEAN := TRUE;
    p_snap_tolerancia_m CONSTANT FLOAT   := 0.5;
    -- Buffer de proximidad directa a la red (metros)
    p_buffer_proximidad CONSTANT FLOAT   := {{buffer_prox}};
    -- Buffer del tejido envolvente — forma las "manzanas" de la red.
    -- 150m cierra la mayoría de bloques urbanos típicos.
    p_buffer_envolvente CONSTANT FLOAT   := {{buffer_env}};
    -- ── SISTEMA DE DOS NIVELES (TIER) ──
    -- Tier 1: componentes con < p_umbral_tier1 segs → 1 criterio basta
    p_umbral_tier1      CONSTANT INT     := {{umbral_t1}};
    -- Tier 2: componentes con >= tier1 y < p_umbral_tier2 segs → 2+ criterios
    p_umbral_tier2      CONSTANT INT     := {{umbral_t2}};
    -- Latitud de referencia y EPSG métrico para la zona
    p_latitud_ref  CONSTANT FLOAT := {{latitud_ref}};  -- latitud central aproximada de Chile
    p_epsg_metrico CONSTANT INT   := {{epsg_metrico}};  -- WGS 84 / UTM zona 19S

    -- Variables internas
    v_snap_tol           FLOAT;
    v_buffer_grados      FLOAT;
    v_total_segmentos    INT;
    v_total_componentes  INT;
    v_comp_principal     BIGINT;
    v_size_principal     INT;
    v_no_principal       INT;
    v_candidatos         INT;
    v_candidatos_t1      INT;
    v_candidatos_t2      INT;
    v_legitimas          INT;
    v_cnt_b              INT := 0;
    v_cnt_u              INT := 0;
    v_cnt_e              INT := 0;
    v_inconexos          INT;
    v_revertidos_t2      INT := 0;
    v_perifericos        INT;
    v_updated            INT;
    v_updated2           INT;
    v_iteracion          INT;
    v_t0                 TIMESTAMPTZ;
    v_t_step             TIMESTAMPTZ;
    v_count              INT;

BEGIN
    v_t0 := clock_timestamp();

    IF p_es_4326 THEN
        v_snap_tol      := p_snap_tolerancia_m / 111320.0;
        v_buffer_grados := (p_buffer_proximidad / (111320.0 * cos(radians(p_latitud_ref)))) * 1.3;
    ELSE
        v_snap_tol      := p_snap_tolerancia_m;
        v_buffer_grados := p_buffer_proximidad;
    END IF;

    RAISE NOTICE '';
    RAISE NOTICE '=================================================================';
    RAISE NOTICE '    DETECCION DE TRAMOS INCONEXOS - MODELO TRIPLE v4.1 (bigint)';
    RAISE NOTICE '=================================================================';
    RAISE NOTICE '  Tabla vial:           %.%', p_esquema, p_tabla_vial;
    RAISE NOTICE '  Área urbana:          %.%', p_esquema, p_tabla_urbana;
    RAISE NOTICE '  EPSG métrico:         %', p_epsg_metrico;
    RAISE NOTICE '  Buffer proximidad:    % m', p_buffer_proximidad;
    RAISE NOTICE '  Buffer tejido env.:   % m', p_buffer_envolvente;
    RAISE NOTICE '  Tier 1 (1 criterio):  < % segs', p_umbral_tier1;
    RAISE NOTICE '  Tier 2 (2+ crit.):    % – % segs', p_umbral_tier1, p_umbral_tier2 - 1;
    RAISE NOTICE '  Legítima (intocable): >= % segs', p_umbral_tier2;
    RAISE NOTICE '  Inicio: %', to_char(clock_timestamp(), 'YYYY-MM-DD HH24:MI:SS');
    RAISE NOTICE '-----------------------------------------------------------------';

    -- =========================================================================
    -- PASO 0: PREPARACIÓN DE CAMPOS
    -- =========================================================================
    v_t_step := clock_timestamp();
    RAISE NOTICE '';
    RAISE NOTICE '[PASO 0/7] Preparando campos...';

    EXECUTE format('ALTER TABLE %I.%I ADD COLUMN IF NOT EXISTS inconexo        VARCHAR(1) DEFAULT NULL', p_esquema, p_tabla_vial);
    EXECUTE format('ALTER TABLE %I.%I ADD COLUMN IF NOT EXISTS componente_red  INT        DEFAULT NULL', p_esquema, p_tabla_vial);
    EXECUTE format('ALTER TABLE %I.%I ADD COLUMN IF NOT EXISTS tam_componente  INT        DEFAULT NULL', p_esquema, p_tabla_vial);
    EXECUTE format('ALTER TABLE %I.%I ADD COLUMN IF NOT EXISTS razon_inconexo  VARCHAR(3) DEFAULT NULL', p_esquema, p_tabla_vial);
    -- Garantizar VARCHAR(3) si la columna ya existía con un tipo más corto
    EXECUTE format('ALTER TABLE %I.%I ALTER COLUMN razon_inconexo TYPE VARCHAR(3)', p_esquema, p_tabla_vial);

    EXECUTE format($q$
        UPDATE %I.%I SET
            inconexo = NULL, componente_red = NULL,
            tam_componente = NULL, razon_inconexo = NULL
    $q$, p_esquema, p_tabla_vial);

    EXECUTE format('SELECT count(*) FROM %I.%I', p_esquema, p_tabla_vial) INTO v_total_segmentos;
    RAISE NOTICE '  OK Segmentos: %  (% ms)', v_total_segmentos,
        EXTRACT(MILLISECONDS FROM clock_timestamp() - v_t_step)::int;

    -- =========================================================================
    -- PASO 1: EXTRACCIÓN DE NODOS CON SNAP   (seg_id -> BIGINT)
    -- =========================================================================
    v_t_step := clock_timestamp();
    RAISE NOTICE '';
    RAISE NOTICE '[PASO 1/7] Extrayendo endpoints + snap...';

    DROP TABLE IF EXISTS _tmp_nodos;
    EXECUTE format($q$
        CREATE TEMP TABLE _tmp_nodos AS
        WITH raw AS (
            SELECT %I::bigint AS seg_id,
                ST_StartPoint(
                    CASE WHEN ST_GeometryType(%I) = 'ST_MultiLineString'
                         THEN ST_GeometryN(%I, 1) ELSE %I END
                ) AS pt
            FROM %I.%I WHERE %I IS NOT NULL AND NOT ST_IsEmpty(%I)
            UNION ALL
            SELECT %I::bigint AS seg_id,
                ST_EndPoint(
                    CASE WHEN ST_GeometryType(%I) = 'ST_MultiLineString'
                         THEN ST_GeometryN(%I, ST_NumGeometries(%I)) ELSE %I END
                ) AS pt
            FROM %I.%I WHERE %I IS NOT NULL AND NOT ST_IsEmpty(%I)
        ),
        snapped AS (
            SELECT seg_id, ST_SnapToGrid(pt, %s) AS nodo
            FROM raw WHERE pt IS NOT NULL
        )
        SELECT seg_id, nodo,
            round(ST_X(nodo)::numeric, 8)::text || '|' ||
            round(ST_Y(nodo)::numeric, 8)::text AS nodo_key
        FROM snapped WHERE nodo IS NOT NULL
    $q$,
        p_id_vial, p_geom_vial, p_geom_vial, p_geom_vial,
        p_esquema, p_tabla_vial, p_geom_vial, p_geom_vial,
        p_id_vial, p_geom_vial, p_geom_vial, p_geom_vial, p_geom_vial,
        p_esquema, p_tabla_vial, p_geom_vial, p_geom_vial,
        v_snap_tol
    );

    CREATE INDEX _idx_nodos_key ON _tmp_nodos USING HASH (nodo_key);
    CREATE INDEX _idx_nodos_seg ON _tmp_nodos USING HASH (seg_id);
    ANALYZE _tmp_nodos;
    SELECT count(*) INTO v_count FROM _tmp_nodos;
    RAISE NOTICE '  OK Nodos: %  (% ms)', v_count,
        EXTRACT(MILLISECONDS FROM clock_timestamp() - v_t_step)::int;

    -- =========================================================================
    -- PASO 2: GRAFO DE ADYACENCIA   (id_a / id_b heredan BIGINT de _tmp_nodos)
    -- =========================================================================
    v_t_step := clock_timestamp();
    RAISE NOTICE '';
    RAISE NOTICE '[PASO 2/7] Construyendo grafo de adyacencia...';

    DROP TABLE IF EXISTS _tmp_adyacencia;
    CREATE TEMP TABLE _tmp_adyacencia AS
    SELECT DISTINCT
        LEAST(a.seg_id, b.seg_id)    AS id_a,
        GREATEST(a.seg_id, b.seg_id) AS id_b
    FROM _tmp_nodos a
    JOIN _tmp_nodos b ON a.nodo_key = b.nodo_key AND a.seg_id < b.seg_id;

    CREATE INDEX _idx_adj_a ON _tmp_adyacencia USING HASH (id_a);
    CREATE INDEX _idx_adj_b ON _tmp_adyacencia USING HASH (id_b);
    ANALYZE _tmp_adyacencia;
    SELECT count(*) INTO v_count FROM _tmp_adyacencia;
    RAISE NOTICE '  OK Aristas: %  (% ms)', v_count,
        EXTRACT(MILLISECONDS FROM clock_timestamp() - v_t_step)::int;

    -- =========================================================================
    -- PASO 3: COMPONENTES CONEXOS — UNION-FIND   (seg_id / comp_id -> BIGINT)
    -- =========================================================================
    v_t_step := clock_timestamp();
    RAISE NOTICE '';
    RAISE NOTICE '[PASO 3/7] Resolviendo componentes conexos (Union-Find)...';

    DROP TABLE IF EXISTS _tmp_componentes;
    EXECUTE format($q$
        CREATE TEMP TABLE _tmp_componentes AS
        SELECT %I::bigint AS seg_id, %I::bigint AS comp_id FROM %I.%I
    $q$, p_id_vial, p_id_vial, p_esquema, p_tabla_vial);

    CREATE INDEX _idx_comp_seg  ON _tmp_componentes USING HASH (seg_id);
    CREATE INDEX _idx_comp_comp ON _tmp_componentes (comp_id);
    ANALYZE _tmp_componentes;

    v_iteracion := 0;
    LOOP
        v_iteracion := v_iteracion + 1;
        v_updated   := 0;

        UPDATE _tmp_componentes c SET comp_id = sub.nuevo_comp
        FROM (
            SELECT c1.seg_id, LEAST(c1.comp_id, MIN(c2.comp_id)) AS nuevo_comp
            FROM _tmp_componentes c1
            JOIN _tmp_adyacencia  a  ON c1.seg_id = a.id_a
            JOIN _tmp_componentes c2 ON c2.seg_id = a.id_b
            GROUP BY c1.seg_id, c1.comp_id
            HAVING LEAST(c1.comp_id, MIN(c2.comp_id)) < c1.comp_id
        ) sub WHERE c.seg_id = sub.seg_id;
        GET DIAGNOSTICS v_updated2 = ROW_COUNT; v_updated := v_updated + v_updated2;

        UPDATE _tmp_componentes c SET comp_id = sub.nuevo_comp
        FROM (
            SELECT c1.seg_id, LEAST(c1.comp_id, MIN(c2.comp_id)) AS nuevo_comp
            FROM _tmp_componentes c1
            JOIN _tmp_adyacencia  a  ON c1.seg_id = a.id_b
            JOIN _tmp_componentes c2 ON c2.seg_id = a.id_a
            GROUP BY c1.seg_id, c1.comp_id
            HAVING LEAST(c1.comp_id, MIN(c2.comp_id)) < c1.comp_id
        ) sub WHERE c.seg_id = sub.seg_id;
        GET DIAGNOSTICS v_updated2 = ROW_COUNT; v_updated := v_updated + v_updated2;

        UPDATE _tmp_componentes c SET comp_id = c2.comp_id
        FROM _tmp_componentes c2
        WHERE c.comp_id = c2.seg_id AND c2.comp_id < c.comp_id;
        GET DIAGNOSTICS v_updated2 = ROW_COUNT; v_updated := v_updated + v_updated2;

        EXIT WHEN v_updated = 0;
        IF v_iteracion % 5 = 0 THEN
            RAISE NOTICE '    Iteración %: % cambios', v_iteracion, v_updated;
        END IF;
        IF v_iteracion > 500 THEN RAISE WARNING 'Límite iteraciones.'; EXIT; END IF;
    END LOOP;

    RAISE NOTICE '  OK Convergencia en % iter  (% ms)', v_iteracion,
        EXTRACT(MILLISECONDS FROM clock_timestamp() - v_t_step)::int;

    SELECT comp_id, count(*) INTO v_comp_principal, v_size_principal
    FROM _tmp_componentes GROUP BY comp_id ORDER BY count(*) DESC LIMIT 1;

    SELECT count(DISTINCT comp_id) INTO v_total_componentes FROM _tmp_componentes;
    RAISE NOTICE '  OK Componentes: %  |  Red principal: % segs (% %%)',
        v_total_componentes, v_size_principal,
        round((v_size_principal::numeric / NULLIF(v_total_segmentos, 0) * 100), 1);

    -- Tamaños de componente + escribir a tabla principal
    DROP TABLE IF EXISTS _tmp_comp_size;
    CREATE TEMP TABLE _tmp_comp_size AS
    SELECT comp_id, count(*)::int AS tam FROM _tmp_componentes GROUP BY comp_id;
    CREATE INDEX _idx_cs ON _tmp_comp_size USING HASH (comp_id);

    -- Escritura: comp_id (bigint) -> componente_red (int). El cast bigint->int
    -- es implicito y seguro para los rangos de id_capa manejados.
    EXECUTE format($q$
        UPDATE %I.%I v
        SET componente_red = c.comp_id, tam_componente = s.tam
        FROM _tmp_componentes c
        JOIN _tmp_comp_size  s ON c.comp_id = s.comp_id
        WHERE v.%I::bigint = c.seg_id
    $q$, p_esquema, p_tabla_vial, p_id_vial);

    -- =========================================================================
    -- PASO 4: PREPARAR CAPAS ESPACIALES AUXILIARES
    -- =========================================================================
    v_t_step := clock_timestamp();
    RAISE NOTICE '';
    RAISE NOTICE '[PASO 4/7] Preparando capas espaciales auxiliares...';

    -- 4a. Red principal
    DROP TABLE IF EXISTS _tmp_principal;
    EXECUTE format($q$
        CREATE TEMP TABLE _tmp_principal AS
        SELECT v.%I::bigint AS seg_id, v.%I AS geom
        FROM %I.%I v WHERE v.componente_red = %s
    $q$, p_id_vial, p_geom_vial, p_esquema, p_tabla_vial, v_comp_principal);
    CREATE INDEX _idx_principal_geom ON _tmp_principal USING GIST (geom);
    ANALYZE _tmp_principal;
    SELECT count(*) INTO v_count FROM _tmp_principal;
    RAISE NOTICE '  OK Red principal:            % segs', v_count;

    -- 4b. Candidatos — ahora incluye AMBOS tiers (< p_umbral_tier2)
    DROP TABLE IF EXISTS _tmp_candidatos;
    EXECUTE format($q$
        CREATE TEMP TABLE _tmp_candidatos AS
        SELECT v.%I::bigint AS seg_id, v.%I AS geom, v.tam_componente
        FROM %I.%I v
        WHERE v.componente_red != %s AND v.tam_componente < %s
    $q$, p_id_vial, p_geom_vial, p_esquema, p_tabla_vial,
        v_comp_principal, p_umbral_tier2);
    CREATE INDEX _idx_cand_geom ON _tmp_candidatos USING GIST (geom);
    ANALYZE _tmp_candidatos;
    SELECT count(*) INTO v_candidatos FROM _tmp_candidatos;

    -- Conteos por tier
    SELECT count(*) INTO v_candidatos_t1 FROM _tmp_candidatos
    WHERE tam_componente < p_umbral_tier1;

    v_candidatos_t2 := v_candidatos - v_candidatos_t1;

    EXECUTE format('SELECT count(*) FROM %I.%I WHERE componente_red != %s AND tam_componente >= %s',
        p_esquema, p_tabla_vial, v_comp_principal, p_umbral_tier2) INTO v_legitimas;
    EXECUTE format('SELECT count(*) FROM %I.%I WHERE componente_red != %s',
        p_esquema, p_tabla_vial, v_comp_principal) INTO v_no_principal;

    RAISE NOTICE '  OK No-principales total:     %', v_no_principal;
    RAISE NOTICE '  OK Redes legítimas (>=%):  %  (intocables)',
        p_umbral_tier2, v_legitimas;
    RAISE NOTICE '  OK Candidatos Tier 1 (<%): %  (1 criterio basta)',
        p_umbral_tier1, v_candidatos_t1;
    RAISE NOTICE '  OK Candidatos Tier 2 (%–%): %  (necesitan 2+ criterios)',
        p_umbral_tier1, p_umbral_tier2 - 1, v_candidatos_t2;

    -- 4c. Área urbana subdividida
    DROP TABLE IF EXISTS _tmp_urbana_sub;
    EXECUTE format($q$
        CREATE TEMP TABLE _tmp_urbana_sub AS
        SELECT (ST_Subdivide(geom, 256))::geometry(Polygon, 4326) AS geom
        FROM %I.%I WHERE geom IS NOT NULL AND ST_IsValid(geom)
    $q$, p_esquema, p_tabla_urbana);
    CREATE INDEX _idx_urb_geom ON _tmp_urbana_sub USING GIST (geom);
    ANALYZE _tmp_urbana_sub;
    SELECT count(*) INTO v_count FROM _tmp_urbana_sub;
    RAISE NOTICE '  OK Área urbana subdiv.:      % polígonos', v_count;

    -- 4d. TEJIDO ENVOLVENTE DE LA RED PRINCIPAL (CRITERIO E)
    RAISE NOTICE '  -> Construyendo tejido envolvente (% m, EPSG:%)...', p_buffer_envolvente, p_epsg_metrico;

    DROP TABLE IF EXISTS _tmp_tejido;
    EXECUTE format($q$
        CREATE TEMP TABLE _tmp_tejido AS
        WITH red_m AS (
            SELECT ST_Transform(geom, %s) AS geom_m
            FROM _tmp_principal
            WHERE geom IS NOT NULL
        ),
        buffered AS (
            SELECT ST_Buffer(geom_m, %s) AS geom_buf
            FROM red_m
        ),
        disuelto AS (
            SELECT ST_UnaryUnion(ST_Collect(geom_buf)) AS geom_union
            FROM buffered
        )
        SELECT (
            ST_Subdivide(
                ST_Transform(geom_union, 4326),
                256
            )
        )::geometry(Polygon, 4326) AS geom
        FROM disuelto
        WHERE geom_union IS NOT NULL
    $q$, p_epsg_metrico, p_buffer_envolvente);

    CREATE INDEX _idx_tejido_geom ON _tmp_tejido USING GIST (geom);
    ANALYZE _tmp_tejido;
    SELECT count(*) INTO v_count FROM _tmp_tejido;
    RAISE NOTICE '  OK Tejido envolvente:        % sub-polígonos  (% ms)',
        v_count, EXTRACT(MILLISECONDS FROM clock_timestamp() - v_t_step)::int;

    -- =========================================================================
    -- PASO 5: CLASIFICACIÓN — TRIPLE CRITERIO ESPACIAL
    -- =========================================================================
    v_t_step := clock_timestamp();
    RAISE NOTICE '';
    RAISE NOTICE '[PASO 5/7] Clasificando con triple criterio espacial...';

    -- [B] Proximidad directa a la red principal
    RAISE NOTICE '  -> [B] ST_DWithin % m de la red principal...', p_buffer_proximidad;
    EXECUTE format($q$
        UPDATE %I.%I v
        SET inconexo = 'x', razon_inconexo = 'B'
        FROM _tmp_candidatos c
        WHERE v.%I::bigint = c.seg_id
          AND EXISTS (
              SELECT 1 FROM _tmp_principal p
              WHERE ST_DWithin(c.geom, p.geom, %s) LIMIT 1
          )
    $q$, p_esquema, p_tabla_vial, p_id_vial, v_buffer_grados);
    GET DIAGNOSTICS v_cnt_b = ROW_COUNT;
    RAISE NOTICE '  OK [B] Por proximidad:              %', v_cnt_b;

    -- [U] Dentro del área urbana consolidada
    RAISE NOTICE '  -> [U] ST_Intersects con area_urbana...';
    EXECUTE format($q$
        UPDATE %I.%I v
        SET inconexo = 'x',
            razon_inconexo = CASE
                WHEN razon_inconexo = 'B' THEN 'BU' ELSE 'U' END
        FROM _tmp_candidatos c
        WHERE v.%I::bigint = c.seg_id
          AND EXISTS (
              SELECT 1 FROM _tmp_urbana_sub u
              WHERE ST_Intersects(c.geom, u.geom) LIMIT 1
          )
    $q$, p_esquema, p_tabla_vial, p_id_vial);
    GET DIAGNOSTICS v_cnt_u = ROW_COUNT;
    RAISE NOTICE '  OK [U] Por área urbana (tot.):      %', v_cnt_u;

    -- [E] Encerrado dentro del tejido envolvente de la red
    RAISE NOTICE '  -> [E] ST_Intersects con tejido envolvente (% m)...', p_buffer_envolvente;
    EXECUTE format($q$
        UPDATE %I.%I v
        SET inconexo = 'x',
            razon_inconexo = CASE
                WHEN razon_inconexo = 'BU' THEN 'BUE'
                WHEN razon_inconexo = 'B'  THEN 'BE'
                WHEN razon_inconexo = 'U'  THEN 'UE'
                ELSE 'E'
            END
        FROM _tmp_candidatos c
        WHERE v.%I::bigint = c.seg_id
          AND EXISTS (
              SELECT 1 FROM _tmp_tejido t
              WHERE ST_Intersects(c.geom, t.geom) LIMIT 1
          )
    $q$, p_esquema, p_tabla_vial, p_id_vial);
    GET DIAGNOSTICS v_cnt_e = ROW_COUNT;
    RAISE NOTICE '  OK [E] Por tejido envolvente (tot.):%', v_cnt_e;

    RAISE NOTICE '  OK Paso 5 completado  (% ms)',
        EXTRACT(MILLISECONDS FROM clock_timestamp() - v_t_step)::int;

    -- =========================================================================
    -- PASO 6: FILTRO TIER 2 — exigir ≥ 2 criterios para componentes medianos
    -- =========================================================================
    v_t_step := clock_timestamp();
    RAISE NOTICE '';
    RAISE NOTICE '[PASO 6/7] Filtro Tier 2: revirtiendo marcas con < 2 criterios...';

    EXECUTE format($q$
        UPDATE %I.%I
        SET inconexo = NULL, razon_inconexo = NULL
        WHERE inconexo = 'x'
          AND tam_componente >= %s
          AND tam_componente <  %s
          AND length(razon_inconexo) < 2
    $q$, p_esquema, p_tabla_vial, p_umbral_tier1, p_umbral_tier2);
    GET DIAGNOSTICS v_revertidos_t2 = ROW_COUNT;
    RAISE NOTICE '  OK Tier 2 revertidos (1 solo criterio): %', v_revertidos_t2;
    RAISE NOTICE '  OK Paso 6 completado  (% ms)',
        EXTRACT(MILLISECONDS FROM clock_timestamp() - v_t_step)::int;

    -- =========================================================================
    -- PASO 7: RESUMEN FINAL
    -- =========================================================================
    EXECUTE format('SELECT count(*) FROM %I.%I WHERE inconexo = ''x''',
        p_esquema, p_tabla_vial) INTO v_inconexos;
    v_perifericos := v_candidatos - v_inconexos;

    RAISE NOTICE '';
    RAISE NOTICE '=================================================================';
    RAISE NOTICE '                    RESUMEN DE RESULTADOS';
    RAISE NOTICE '=================================================================';
    RAISE NOTICE '  Total segmentos viales:            %', lpad(v_total_segmentos::text, 12);
    RAISE NOTICE '  Componentes de red:                %', lpad(v_total_componentes::text, 12);
    RAISE NOTICE '  Red principal:                     %', lpad(v_size_principal::text, 12);
    RAISE NOTICE '  No-principales total:              %', lpad(v_no_principal::text, 12);
    RAISE NOTICE '    -> Legítimas (>=% segs):          %', p_umbral_tier2, lpad(v_legitimas::text, 12);
    RAISE NOTICE '    -> Candidatos Tier 1 (<% s):      %', p_umbral_tier1, lpad(v_candidatos_t1::text, 12);
    RAISE NOTICE '    -> Candidatos Tier 2 (%-% s):     %', p_umbral_tier1, p_umbral_tier2-1, lpad(v_candidatos_t2::text, 12);
    RAISE NOTICE '  -------------------------------------------------------------';
    RAISE NOTICE '  Detectados por [B] proximidad:     %', lpad(v_cnt_b::text, 12);
    RAISE NOTICE '  Detectados por [U] área urbana:    %', lpad(v_cnt_u::text, 12);
    RAISE NOTICE '  Detectados por [E] tejido env.:    %', lpad(v_cnt_e::text, 12);
    RAISE NOTICE '  Tier 2 revertidos (< 2 crit.):     %', lpad(v_revertidos_t2::text, 12);
    RAISE NOTICE '  -------------------------------------------------------------';
    RAISE NOTICE '  INCONEXOS TOTAL:                   %', lpad(v_inconexos::text, 12);
    RAISE NOTICE '  Periféricos válidos (fuera):       %', lpad(v_perifericos::text, 12);
    RAISE NOTICE '=================================================================';

    DROP TABLE IF EXISTS _tmp_nodos;
    DROP TABLE IF EXISTS _tmp_adyacencia;
    DROP TABLE IF EXISTS _tmp_componentes;
    DROP TABLE IF EXISTS _tmp_comp_size;
    DROP TABLE IF EXISTS _tmp_principal;
    DROP TABLE IF EXISTS _tmp_candidatos;
    DROP TABLE IF EXISTS _tmp_urbana_sub;
    DROP TABLE IF EXISTS _tmp_tejido;

    RAISE NOTICE '';
    RAISE NOTICE '  Tiempo total: % segundos', round(EXTRACT(EPOCH FROM clock_timestamp() - v_t0)::numeric, 1);
    RAISE NOTICE '=================================================================';
    RAISE NOTICE '  OK COMPLETADO - %.%', p_esquema, p_tabla_vial;

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '=================================================================';
    RAISE NOTICE '  ERROR - ROLLBACK AUTOMATICO';
    RAISE NOTICE '=================================================================';
    RAISE NOTICE '  SQLSTATE: %  |  %', SQLSTATE, SQLERRM;
    DROP TABLE IF EXISTS _tmp_nodos;
    DROP TABLE IF EXISTS _tmp_adyacencia;
    DROP TABLE IF EXISTS _tmp_componentes;
    DROP TABLE IF EXISTS _tmp_comp_size;
    DROP TABLE IF EXISTS _tmp_principal;
    DROP TABLE IF EXISTS _tmp_candidatos;
    DROP TABLE IF EXISTS _tmp_urbana_sub;
    DROP TABLE IF EXISTS _tmp_tejido;
    RAISE NOTICE '  Tabla original intacta.';
    RAISE;
END $$;

RESET ALL;

-- =============================================================================
-- PASO 8: ELIMINAR INCONEXOS  (ejecutar SOLO tras validar visualmente en QGIS)
-- =============================================================================
--  DELETE FROM "{{esquema}}".{{tabla}}
--  WHERE inconexo = 'x';

/*******************************************************************************
 * CONSULTAS DE VERIFICACIÓN Y CALIBRACIÓN  (ajustadas a {{esquema}}.mavvial_fin_urbana)
 ******************************************************************************/

-- 1. Distribución por criterio de detección
/*
SELECT razon_inconexo AS criterio, count(*) AS n_segmentos,
       min(tam_componente) AS min_comp, max(tam_componente) AS max_comp,
       round(avg(tam_componente), 1) AS avg_comp
FROM "{{esquema}}".{{tabla}}
WHERE inconexo = 'x'
GROUP BY razon_inconexo ORDER BY razon_inconexo;
*/

-- 4. Todos los inconexos
/*
SELECT id_capa, componente_red, tam_componente, inconexo, razon_inconexo
FROM "{{esquema}}".{{tabla}}
WHERE inconexo = 'x'
ORDER BY tam_componente DESC, razon_inconexo, id_capa;
*/