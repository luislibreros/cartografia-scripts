-- =====================================================================
-- ServiFlow · Paso 3 · Estructurar malla vial (tabla final)
-- La ESTRUCTURA de columnas y la lista de ESTADOS vienen del PERFIL del país.
--   esquema={{esquema}}   origen(OSM)={{tabla}}   final={{tabla_final}}
--   nombres={{tabla_nomvia}}   distritos={{tabla_distrito}}
-- =====================================================================
DO $$
DECLARE
    v_count INTEGER;
BEGIN
    RAISE NOTICE '=== ServiFlow · Estructurar % .% ===', '{{esquema}}', '{{tabla_final}}';

    -- 1) marca_vial (puente / túnel) en la capa origen
    ALTER TABLE "{{esquema}}".{{tabla}} DROP COLUMN IF EXISTS marca_vial;
    ALTER TABLE "{{esquema}}".{{tabla}} ADD COLUMN marca_vial TEXT;

    UPDATE "{{esquema}}".{{tabla}}
    SET marca_vial = CASE WHEN bridge = 'T' THEN 'PUENTE' ELSE marca_vial END;

    UPDATE "{{esquema}}".{{tabla}}
    SET marca_vial = CASE WHEN tunnel = 'T' THEN 'TUNEL' ELSE marca_vial END
    WHERE marca_vial IS NULL;

    -- 2) crear tabla final con la ESTRUCTURA DEL PERFIL
    DROP TABLE IF EXISTS "{{esquema}}".{{tabla_final}};
    CREATE TABLE "{{esquema}}".{{tabla_final}} (
{{ddl_columnas}}
    );
    RAISE NOTICE '  -> Tabla % creada', '{{tabla_final}}';

    -- 3) insertar desde la capa origen (mapeo OSM)
    INSERT INTO "{{esquema}}".{{tabla_final}} (
        geom, categ_vial, oneway, id_fuente, velocidad, marca_vial, nomvtotal, nom_original
    )
    SELECT geom, fclass, oneway, osm_id, maxspeed, marca_vial, name, name
    FROM "{{esquema}}".{{tabla}};
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE '  -> Registros insertados: %', v_count;

    -- 4) estandarizar nombres con la tabla de vectores de nombres
    UPDATE "{{esquema}}".{{tabla_final}} m
    SET nomvtotal = n.nom_final, tipovia = n.tipovia, nomvia = n.nomvia
    FROM {{tabla_nomvia}} n
    WHERE n.nom_original_limpio = unaccent(UPPER(m.nomvtotal));
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE '  -> Nombres estandarizados: %', v_count;

    UPDATE "{{esquema}}".{{tabla_final}} m
    SET observ_dat = 'SIN_ESTANDARIZAR'
    WHERE observ_dat IS NULL
      AND NOT EXISTS (SELECT 1 FROM {{tabla_nomvia}} n WHERE n.nom_final = m.nomvtotal)
      AND nomvtotal IS NOT NULL;

    -- 5) índice espacial
    EXECUTE format('CREATE INDEX %I ON "{{esquema}}".{{tabla_final}} USING GIST (geom)',
                   '{{tabla_final}}_geom_idx');

    -- 6) campos geográficos por centroide corregido
    WITH centroides AS (
        SELECT id_capa, geom, ST_Centroid(geom) AS c FROM "{{esquema}}".{{tabla_final}}
    ),
    corregido AS (
        SELECT id_capa, ST_ClosestPoint(geom, c) AS pt FROM centroides
    )
    UPDATE "{{esquema}}".{{tabla_final}} m
    SET cod_distri = p.cod_distri, nom_distri = UPPER(p.nom_distri),
        cod_mun = p.cod_mun,       nom_mun = UPPER(p.nom_mun),
        cod_estado = p.cod_estado, nom_estado = UPPER(p.nom_estado)
    FROM {{tabla_distrito}} p
    JOIN corregido nc ON ST_Intersects(nc.pt, p.geom)
    WHERE m.id_capa = nc.id_capa;
    GET DIAGNOSTICS v_count = ROW_COUNT;
    RAISE NOTICE '  -> Asignación geográfica: %', v_count;

    -- 7) abreviar estado (lista del PERFIL)
    WITH estados_abrev (sigla_estado, nombre_estado) AS (
        VALUES
        {{estados_values}}
    )
    UPDATE "{{esquema}}".{{tabla_final}}
    SET nom_estado = sigla_estado
    FROM estados_abrev
    WHERE nom_estado = nombre_estado;

    RAISE NOTICE '=== ServiFlow · Estructuración finalizada ===';
END $$;
