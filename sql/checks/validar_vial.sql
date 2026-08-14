-- =====================================================================
-- ServiFlow · Validación de capa vial estructurada  (solo lectura)
-- Devuelve una tabla: chequeo | valor | estado
--   esquema={{esquema}}  tabla={{tabla}}  geom={{geom}}
-- =====================================================================
WITH m AS (SELECT * FROM "{{esquema}}".{{tabla}})
SELECT * FROM (
    SELECT 1 AS ord, 'Total de registros' AS chequeo,
           COUNT(*)::bigint AS valor, 'info' AS estado FROM m
    UNION ALL
    SELECT 2, 'Geometrías nulas',
           COUNT(*) FILTER (WHERE {{geom}} IS NULL),
           CASE WHEN COUNT(*) FILTER (WHERE {{geom}} IS NULL) > 0 THEN 'REVISAR' ELSE 'OK' END FROM m
    UNION ALL
    SELECT 3, 'Geometrías inválidas',
           COUNT(*) FILTER (WHERE {{geom}} IS NOT NULL AND NOT ST_IsValid({{geom}})),
           CASE WHEN COUNT(*) FILTER (WHERE {{geom}} IS NOT NULL AND NOT ST_IsValid({{geom}})) > 0
                THEN 'REVISAR' ELSE 'OK' END FROM m
    UNION ALL
    SELECT 4, 'nomvtotal vacío',
           COUNT(*) FILTER (WHERE nomvtotal IS NULL OR nomvtotal = ''),
           'info' FROM m
    UNION ALL
    SELECT 5, 'Con tipo de vía (tipovia)',
           COUNT(*) FILTER (WHERE tipovia IS NOT NULL AND tipovia <> ''),
           'info' FROM m
    UNION ALL
    SELECT 6, 'tipovia sin nomvia',
           COUNT(*) FILTER (WHERE tipovia IS NOT NULL AND tipovia <> ''
                              AND (nomvia IS NULL OR nomvia = '')),
           CASE WHEN COUNT(*) FILTER (WHERE tipovia IS NOT NULL AND tipovia <> ''
                              AND (nomvia IS NULL OR nomvia = '')) > 0
                THEN 'REVISAR' ELSE 'OK' END FROM m
    UNION ALL
    SELECT 7, 'tipovia mayor a 10 caracteres',
           COUNT(*) FILTER (WHERE LENGTH(tipovia) > 10),
           CASE WHEN COUNT(*) FILTER (WHERE LENGTH(tipovia) > 10) > 0 THEN 'REVISAR' ELSE 'OK' END FROM m
    UNION ALL
    SELECT 8, 'Aún SIN_ESTANDARIZAR',
           COUNT(*) FILTER (WHERE observ_dat = 'SIN_ESTANDARIZAR'),
           'info' FROM m
) q
ORDER BY ord;
