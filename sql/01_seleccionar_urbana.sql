-- =====================================================================
-- ServiFlow · Paso 1 · Selección de malla vial por buffer de área urbana
-- Plantilla parametrizada (los valores los inyecta el panel):
--   esquema={{esquema}}  vial={{tabla}}  urbana={{capa_urbana}}
--   salida={{capa_salida}}  buffer={{buffer_grados}} grados
-- =====================================================================
DO $$
DECLARE
    v_esquema        TEXT    := '{{esquema}}';
    v_capa_urbana    TEXT    := '{{capa_urbana}}';
    v_capa_vial      TEXT    := '{{tabla}}';
    v_capa_salida    TEXT    := '{{capa_salida}}';
    v_buffer_grados  NUMERIC := {{buffer_grados}};
    v_count_input    BIGINT;
    v_count_output   BIGINT;
BEGIN
    RAISE NOTICE '[ServiFlow] Selección urbana %.% -> %.%',
        v_esquema, v_capa_vial, v_esquema, v_capa_salida;

    EXECUTE format('SELECT COUNT(*) FROM %I.%I', v_esquema, v_capa_vial) INTO v_count_input;

    EXECUTE format('DROP TABLE IF EXISTS %I.%I CASCADE', v_esquema, v_capa_salida);

    DROP TABLE IF EXISTS _temp_buffer_urbano;
    EXECUTE format($f$
        CREATE TEMP TABLE _temp_buffer_urbano AS
        SELECT ST_Union(ST_Buffer(geom, %s)) AS geom
        FROM %I.%I WHERE geom IS NOT NULL
    $f$, v_buffer_grados, v_esquema, v_capa_urbana);
    CREATE INDEX idx_temp_buffer_geom ON _temp_buffer_urbano USING GIST (geom);
    ANALYZE _temp_buffer_urbano;

    EXECUTE format($f$
        CREATE TABLE %I.%I AS
        SELECT v.*
        FROM %I.%I v
        INNER JOIN _temp_buffer_urbano b ON ST_Intersects(v.geom, b.geom)
        WHERE v.geom IS NOT NULL
    $f$, v_esquema, v_capa_salida, v_esquema, v_capa_vial);

    EXECUTE format('SELECT COUNT(*) FROM %I.%I', v_esquema, v_capa_salida) INTO v_count_output;
    EXECUTE format('CREATE INDEX idx_%s_geom ON %I.%I USING GIST (geom)',
        v_capa_salida, v_esquema, v_capa_salida);
    EXECUTE format('ANALYZE %I.%I', v_esquema, v_capa_salida);

    DROP TABLE IF EXISTS _temp_buffer_urbano;
    RAISE NOTICE '[ServiFlow] Seleccionadas % de % vías', v_count_output, v_count_input;
EXCEPTION WHEN OTHERS THEN
    DROP TABLE IF EXISTS _temp_buffer_urbano;
    RAISE NOTICE '[ServiFlow] ERROR: %', SQLERRM;
    RAISE;
END $$;
