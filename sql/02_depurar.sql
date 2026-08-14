-- =====================================================================
-- ServiFlow · Paso 2 · Depurar malla vial
-- esquema={{esquema}}  tabla={{tabla}}  campo de categoría={{campo_categoria}}
-- Quita categorías no vehiculares y puentes peatonales.
-- (Ejecutar contra la columna correcta: en crudo OSM suele ser 'fclass').
-- =====================================================================
DO $$
DECLARE
    v_a INT := 0;
    v_b INT := 0;
BEGIN
    DELETE FROM "{{esquema}}".{{tabla}}
    WHERE {{campo_categoria}} IN (
        'footway','cycleway','track','track_grade1','track_grade2',
        'track_grade3','track_grade4','track_grade5','busway','unknown'
    );
    GET DIAGNOSTICS v_a = ROW_COUNT;

    BEGIN
        DELETE FROM "{{esquema}}".{{tabla}} a
        WHERE a.{{campo_categoria}} IN ('path','pedestrian','bridleway','service','steps','living street')
          AND a.bridge = 'T';
        GET DIAGNOSTICS v_b = ROW_COUNT;
    EXCEPTION WHEN undefined_column THEN
        RAISE NOTICE '[ServiFlow] (sin columna "bridge": se omite el filtro de puentes peatonales)';
    END;

    RAISE NOTICE '[ServiFlow] Depurar: % por categoría + % puentes peatonales = % eliminadas.',
        v_a, v_b, v_a + v_b;
    IF v_a + v_b = 0 THEN
        RAISE NOTICE '[ServiFlow] Nada eliminado: revisa que "{{campo_categoria}}" sea la columna correcta (¿fclass?) y sus valores con "Explorar capa".';
    END IF;
END $$;
