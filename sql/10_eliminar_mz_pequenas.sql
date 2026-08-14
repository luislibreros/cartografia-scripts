-- =====================================================================
-- ServiFlow · Paso 10 · Eliminar manzanas menores al umbral
--   esquema={{esquema}}  tabla={{tabla}}  umbral={{umbral_m2}} m²
-- =====================================================================
DO $$
DECLARE
    v_total INT; v_a_eliminar INT; v_eliminadas INT; v_restantes INT;
BEGIN
    SELECT COUNT(*), COUNT(*) FILTER (WHERE ST_Area(geom::geography) < {{umbral_m2}})
    INTO v_total, v_a_eliminar
    FROM "{{esquema}}".{{tabla}};

    RAISE NOTICE '[ServiFlow] Total: %  · a eliminar (<% m2): %', v_total, {{umbral_m2}}, v_a_eliminar;

    DELETE FROM "{{esquema}}".{{tabla}}
    WHERE ST_Area(geom::geography) < {{umbral_m2}};

    GET DIAGNOSTICS v_eliminadas = ROW_COUNT;
    SELECT COUNT(*) INTO v_restantes FROM "{{esquema}}".{{tabla}};
    RAISE NOTICE '[ServiFlow] Eliminadas: %  · restantes: %', v_eliminadas, v_restantes;
END $$;
