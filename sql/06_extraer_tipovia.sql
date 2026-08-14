-- =====================================================================
-- ServiFlow · Paso 6 · Extracción tipovia + nomvia desde el campo origen
-- El DICCIONARIO de tipos de vía (con abreviatura) viene del PERFIL del país.
--   esquema={{esquema}} tabla={{tabla}}
--   src={{campo_src}} tipo={{campo_tipo}} nom={{campo_nom}}
-- =====================================================================
DROP FUNCTION IF EXISTS pg_temp.limpiar(TEXT);
CREATE FUNCTION pg_temp.limpiar(val TEXT) RETURNS TEXT
LANGUAGE SQL IMMUTABLE PARALLEL SAFE AS $$
    SELECT NULLIF(UPPER(regexp_replace(
        TRIM(regexp_replace(val, '[^[:alnum:] ]', ' ', 'g')), '\s{2,}', ' ', 'g')), '');
$$;

DO $$
DECLARE
    _esq  CONSTANT TEXT := '{{esquema}}';
    _tbl  CONSTANT TEXT := '{{tabla}}';
    _fsrc CONSTANT TEXT := '{{campo_src}}';
    _ftip CONSTANT TEXT := '{{campo_tipo}}';
    _fnom CONSTANT TEXT := '{{campo_nom}}';
    _candidatos BIGINT;
    _n_updated  BIGINT;
BEGIN
    PERFORM set_config('work_mem', '512MB', true);

    -- Tabla de tipos de vía (DEL PERFIL) --------------------------------
    DROP TABLE IF EXISTS _tmp_tipos;
    CREATE TEMP TABLE _tmp_tipos (
        tipo_upper TEXT NOT NULL, num_palabras INT NOT NULL, abreviatura TEXT NOT NULL);
    INSERT INTO _tmp_tipos (tipo_upper, num_palabras, abreviatura) VALUES
        {{tipos_values}};
    ALTER TABLE _tmp_tipos ADD COLUMN len_tipo INT;
    UPDATE _tmp_tipos SET len_tipo = LENGTH(tipo_upper);
    CREATE INDEX ON _tmp_tipos (tipo_upper) WHERE num_palabras = 1;

    -- Tabla de trabajo --------------------------------------------------
    DROP TABLE IF EXISTS _tmp_work;
    EXECUTE format($q$
        CREATE TEMP TABLE _tmp_work AS
        SELECT row_ctid, fuente,
               split_part(fuente,' ',1) AS p1,
               RTRIM(split_part(fuente,' ',1)||' '||split_part(fuente,' ',2)) AS p12
        FROM (
            SELECT t.ctid AS row_ctid, pg_temp.limpiar(t.%I) AS fuente
            FROM %I.%I t WHERE t.%I IS NOT NULL AND TRIM(t.%I) <> ''
        ) sub WHERE fuente IS NOT NULL AND fuente <> ''
    $q$, _fsrc, _esq, _tbl, _fsrc, _fsrc);
    CREATE INDEX ON _tmp_work (p1);
    SELECT COUNT(*) INTO _candidatos FROM _tmp_work;
    RAISE NOTICE '[ServiFlow] Candidatos: %', _candidatos;

    -- Extracción (una pasada) -------------------------------------------
    DROP TABLE IF EXISTS _tmp_resultado;
    CREATE TEMP TABLE _tmp_resultado AS
    SELECT w.row_ctid, w.fuente AS fuente_limpia,
        CASE WHEN t.abreviatura IS NOT NULL AND TRIM(SUBSTR(w.fuente, t.len_tipo+2)) <> ''
             THEN t.abreviatura ELSE NULL END AS tipo_via,
        CASE WHEN t.abreviatura IS NOT NULL AND TRIM(SUBSTR(w.fuente, t.len_tipo+2)) <> ''
             THEN TRIM(SUBSTR(w.fuente, t.len_tipo+2)) ELSE w.fuente END AS nomvia_out
    FROM _tmp_work w
    LEFT JOIN _tmp_tipos t ON w.p1 = t.tipo_upper AND t.num_palabras = 1;

    -- UPDATE ------------------------------------------------------------
    EXECUTE format($q$
        UPDATE %I.%I c
        SET %I = UPPER(r.fuente_limpia), %I = UPPER(r.tipo_via), %I = UPPER(r.nomvia_out)
        FROM _tmp_resultado r
        WHERE c.ctid = r.row_ctid
          AND (c.%I IS DISTINCT FROM UPPER(r.fuente_limpia)
               OR c.%I IS DISTINCT FROM UPPER(r.tipo_via)
               OR c.%I IS DISTINCT FROM UPPER(r.nomvia_out))
    $q$, _esq, _tbl, _fsrc, _ftip, _fnom, _fsrc, _ftip, _fnom);
    GET DIAGNOSTICS _n_updated = ROW_COUNT;
    RAISE NOTICE '[ServiFlow] Filas actualizadas: %', _n_updated;

    -- tipovia -> VARCHAR(10)
    EXECUTE format('ALTER TABLE %I.%I ALTER COLUMN %I TYPE VARCHAR(10) USING LEFT(%I,10)',
                   _esq, _tbl, _ftip, _ftip);

    DROP TABLE IF EXISTS _tmp_work;
    DROP TABLE IF EXISTS _tmp_resultado;
    DROP TABLE IF EXISTS _tmp_tipos;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '[ServiFlow] ERROR %: %', SQLSTATE, SQLERRM;
    DROP TABLE IF EXISTS _tmp_work;
    DROP TABLE IF EXISTS _tmp_resultado;
    DROP TABLE IF EXISTS _tmp_tipos;
    RAISE;
END $$;
