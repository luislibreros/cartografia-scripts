-- ServiFlow · script de placas (parametrizado)
-- El esquema es {{esquema}} (se elige en el panel). Modo 'schema':
-- corre DIRECTO sobre el esquema elegido; úsalo en un esquema de trabajo.

/*
 * ═══════════════════════════════════════════════════════════════════════════════
 *  REPOSICIONAMIENTO DE PLACAS DENTRO DE MANZANAS v3 - SERGIPE, BRASIL
 * ═══════════════════════════════════════════════════════════════════════════════
 *  Esquema      : 28_se
 *  Tablas       : placa (puntos), manzana (polígonos), mavvial_fin (líneas)
 *  SRID origen  : 4326 (WGS 84)
 *  SRID trabajo : 31984 (SIRGAS 2000 / UTM zona 24S → Sergipe)
 *  Offset       : 3 metros hacia el interior de la manzana
 *  Relación     : placa.id_mavvial = mavvial_fin.id_capa
 *  Filtro       : SOLO registros con porcentaje_cambio > 30
 *
 *  ┌──────────────────────────────────────────────────────────────────────────┐
 *  │  CORRECCIONES v3 respecto a v2:                                         │
 *  │                                                                          │
 *  │  1. BUFFER NEGATIVO: Se usa ST_Buffer(manzana, -3) para crear un        │
 *  │     polígono interior que garantiza ≥ 3m desde TODOS los bordes,        │
 *  │     incluyendo esquinas. Elimina el bug del vector borde→centroide      │
 *  │     que solo garantizaba 3m en UNA dirección.                           │
 *  │                                                                          │
 *  │  2. FALLBACK CORREGIDO: Cuando el punto cae fuera, ahora se            │
 *  │     proyecta sobre el polígono interior (no sobre el borde original     │
 *  │     que lo dejaba a 0m).                                                │
 *  │                                                                          │
 *  │  3. ELIMINADO UMBRAL 5cm: Se compara contra distancia al borde,        │
 *  │     no contra posición anterior. Si no está a ≥ 3m del borde,          │
 *  │     se mueve.                                                           │
 *  │                                                                          │
 *  │  4. MANZANAS PEQUEÑAS: Buffer negativo adaptativo. Si -3m colapsa      │
 *  │     la manzana, se prueba -2m, -1m, y finalmente centroide.            │
 *  └──────────────────────────────────────────────────────────────────────────┘
 *
 *  DIAGRAMA DE LA LÓGICA v3:
 *
 *       VECTOR VIAL (mavvial_fin)
 *  ════════════╤═══════════════════
 *              │  ← _closest_road_pt (punto del vial más cercano al original)
 *              │
 *       ┌──────┼──────────────┐  ← borde ORIGINAL de manzana
 *       │ ┌────┼────────────┐ │  ← borde del BUFFER NEGATIVO (-3m)
 *       │ │    ● NEW PT     │ │     ST_ClosestPoint(inner, _closest_bnd_pt)
 *       │ │                 │ │     → garantiza ≥ 3m de TODOS los bordes
 *       │ │                 │ │
 *       │ │    (esquina)    │ │     En esquina: el buffer redondea,
 *       │ │          ╲      │ │     el punto queda a 3m de AMBOS bordes
 *       │ └──────────────────┘│
 *       └─────────────────────┘
 *
 * ═══════════════════════════════════════════════════════════════════════════════
 */

-- ─────────────────────────────────────────────────────────────────────────────
-- 0. ÍNDICES ESPACIALES
-- ─────────────────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_placa_geom
    ON "{{esquema}}".placa USING GIST (geom);

CREATE INDEX IF NOT EXISTS idx_manzana_geom
    ON "{{esquema}}".manzana USING GIST (geom);

CREATE INDEX IF NOT EXISTS idx_mavvial_fin_geom
    ON "{{esquema}}".mavvial_fin USING GIST (geom);

CREATE INDEX IF NOT EXISTS idx_mavvial_fin_id_capa
    ON "{{esquema}}".mavvial_fin (id_capa);

CREATE INDEX IF NOT EXISTS idx_placa_id_mavvial
    ON "{{esquema}}".placa (id_mavvial);

CREATE INDEX IF NOT EXISTS idx_placa_porcentaje_cambio
    ON "{{esquema}}".placa (porcentaje_cambio)
    WHERE porcentaje_cambio > 30;

ANALYZE "{{esquema}}".placa;
ANALYZE "{{esquema}}".manzana;
ANALYZE "{{esquema}}".mavvial_fin;

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. PROCESO PRINCIPAL
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
    _srid_proj   CONSTANT INT   := 31984;  -- SIRGAS 2000 / UTM 24S
    _offset_m    CONSTANT FLOAT := 3.0;    -- metros hacia adentro
    _ts          TEXT := to_char(now(), 'YYYYMMDD_HH24MISS');
    _total       BIGINT;
    _procesados  BIGINT := 0;
    _actualizados BIGINT := 0;
    _sin_via     BIGINT := 0;
    _sin_manzana BIGINT := 0;
    _mz_pequena  BIGINT := 0;
    _ya_ok       BIGINT := 0;
    _errores     BIGINT := 0;
    _t0          TIMESTAMPTZ := clock_timestamp();
    _batch_t     TIMESTAMPTZ;
    rec          RECORD;

    -- geometrías de trabajo (todas en _srid_proj = metros)
    _pt_orig         GEOMETRY;   -- punto original proyectado
    _road_proj       GEOMETRY;   -- vector vial proyectado
    _mz_proj         GEOMETRY;   -- manzana seleccionada proyectada
    _mz_inner        GEOMETRY;   -- ★ NUEVO: polígono interior (buffer -3m)
    _mz_boundary     GEOMETRY;   -- borde de la manzana original
    _closest_road_pt GEOMETRY;   -- punto del vial más cercano al punto original
    _closest_bnd_pt  GEOMETRY;   -- punto del borde más cercano al vial
    _ref_pt          GEOMETRY;   -- punto de referencia para proyección al inner
    _centroid        GEOMETRY;   -- centroide de la manzana
    _new_pt_proj     GEOMETRY;   -- punto nuevo en metros
    _new_pt_4326     GEOMETRY;   -- punto nuevo en 4326

    _dx FLOAT; _dy FLOAT; _norm FLOAT;
    _dist_al_borde   FLOAT;     -- distancia del punto actual al borde
    _try_offset      FLOAT;     -- offset adaptativo para manzanas pequeñas

BEGIN
    -- ═══ RESPALDO ══════════════════════════════════════════════════════════
    RAISE NOTICE '════════════════════════════════════════════════════════════';
    RAISE NOTICE '  INICIO v3: Reposicionamiento de placas 28_se - %', now();
    RAISE NOTICE '  FILTRO: porcentaje_cambio > 30';
    RAISE NOTICE '  MÉTODO: ST_Buffer negativo (garantiza 3m en TODAS';
    RAISE NOTICE '          las direcciones, incluyendo esquinas)';
    RAISE NOTICE '════════════════════════════════════════════════════════════';

    EXECUTE format(
        'DROP TABLE IF EXISTS "{{esquema}}".placa_bkp_%s; '
        'CREATE TABLE "{{esquema}}".placa_bkp_%s AS '
        'SELECT * FROM "{{esquema}}".placa WHERE porcentaje_cambio > 30;',
        _ts, _ts
    );
    RAISE NOTICE '✔ Respaldo (solo filtrados): "{{esquema}}".placa_bkp_%', _ts;

    SELECT count(*) INTO _total
      FROM "{{esquema}}".placa
     WHERE porcentaje_cambio > 30;

    RAISE NOTICE '✔ Registros a procesar (porcentaje_cambio > 30): %', _total;
    RAISE NOTICE '────────────────────────────────────────────────────────────';

    _batch_t := clock_timestamp();

    -- ═══ LOOP PRINCIPAL (SOLO porcentaje_cambio > 30) ════════════════════
    FOR rec IN
        SELECT p.id, p.id_mavvial, p.geom
          FROM "{{esquema}}".placa p
         WHERE p.porcentaje_cambio > 30
         ORDER BY p.id
    LOOP
        _procesados := _procesados + 1;

        BEGIN  -- bloque protegido por registro

            -- ──────────────────────────────────────────────────────────────
            -- A. PUNTO ORIGINAL → proyectar a metros
            -- ──────────────────────────────────────────────────────────────
            _pt_orig := ST_Transform(rec.geom, _srid_proj);

            -- ──────────────────────────────────────────────────────────────
            -- B. VECTOR VIAL ASOCIADO (por id_mavvial = id_capa)
            -- ──────────────────────────────────────────────────────────────
            SELECT ST_Transform(mv.geom, _srid_proj)
              INTO _road_proj
              FROM "{{esquema}}".mavvial_fin mv
             WHERE mv.id_capa = rec.id_mavvial
             LIMIT 1;

            IF _road_proj IS NULL THEN
                _sin_via := _sin_via + 1;
                CONTINUE;
            END IF;

            -- ──────────────────────────────────────────────────────────────
            -- C. MANZANA MÁS CERCANA (distancia real, no bounding box)
            --    KNN toma 10 candidatos rápido, luego distancia real
            -- ──────────────────────────────────────────────────────────────
            SELECT sub.geom_proj
              INTO _mz_proj
              FROM (
                  SELECT ST_Transform(cand.geom, _srid_proj) AS geom_proj
                    FROM (
                        SELECT mz.geom
                          FROM "{{esquema}}".manzana mz
                         ORDER BY mz.geom <-> rec.geom
                         LIMIT 10
                    ) cand
              ) sub
             ORDER BY ST_Distance(sub.geom_proj, _pt_orig)
             LIMIT 1;

            IF _mz_proj IS NULL THEN
                _sin_manzana := _sin_manzana + 1;
                CONTINUE;
            END IF;

            -- ──────────────────────────────────────────────────────────────
            -- D. VERIFICAR SI YA ESTÁ A ≥ 3m DE TODOS LOS BORDES
            --    (v3: comparamos contra borde, no contra posición anterior)
            -- ──────────────────────────────────────────────────────────────
            _mz_boundary := ST_Boundary(_mz_proj);

            -- Distancia mínima del punto actual a CUALQUIER borde
            _dist_al_borde := ST_Distance(_pt_orig, _mz_boundary);

            -- Si el punto está DENTRO y a ≥ 3m de todos los bordes → no tocar
            IF ST_Contains(_mz_proj, _pt_orig) AND _dist_al_borde >= _offset_m THEN
                _ya_ok := _ya_ok + 1;
                CONTINUE;
            END IF;

            -- ──────────────────────────────────────────────────────────────
            -- E. ★ CREAR POLÍGONO INTERIOR CON BUFFER NEGATIVO
            --
            --    ST_Buffer(manzana, -3) produce un polígono encogido 3m
            --    desde TODOS los bordes. En esquinas, el buffer redondea
            --    automáticamente, garantizando ≥ 3m en todas direcciones.
            --
            --    Si la manzana es muy pequeña y -3m la colapsa, se intenta
            --    con offsets menores: -2m, -1m, y finalmente centroide.
            -- ──────────────────────────────────────────────────────────────
            _mz_inner := NULL;
            _try_offset := _offset_m;  -- empezar con 3m

            -- Intentar con 3m, luego 2m, luego 1m
            WHILE _try_offset >= 1.0 LOOP
                _mz_inner := ST_Buffer(_mz_proj, -_try_offset);

                -- Validar que el resultado es un polígono usable
                IF _mz_inner IS NOT NULL
                   AND NOT ST_IsEmpty(_mz_inner)
                   AND ST_GeometryType(_mz_inner) IN ('ST_Polygon', 'ST_MultiPolygon')
                   AND ST_Area(_mz_inner) > 0.5  -- > 0.5 m² mínimo
                THEN
                    EXIT;  -- buffer válido, salir del while
                END IF;

                _mz_inner := NULL;
                _try_offset := _try_offset - 1.0;
            END LOOP;

            -- Si ningún buffer funcionó → centroide como último recurso
            IF _mz_inner IS NULL THEN
                _centroid := ST_Centroid(_mz_proj);
                -- Solo usar centroide si está dentro de la manzana
                IF ST_Contains(_mz_proj, _centroid) THEN
                    _new_pt_proj := _centroid;
                ELSE
                    _new_pt_proj := ST_PointOnSurface(_mz_proj);
                END IF;
                _mz_pequena := _mz_pequena + 1;

                -- Saltar al UPDATE (no hay inner polygon para proyectar)
                _new_pt_4326 := ST_Transform(_new_pt_proj, 4326);
                UPDATE "{{esquema}}".placa
                   SET geom = _new_pt_4326
                 WHERE id = rec.id;
                _actualizados := _actualizados + 1;

                IF _try_offset < _offset_m THEN
                    RAISE NOTICE '  ⚠ id=% manzana muy pequeña, offset=% (fallback)', rec.id, _try_offset;
                END IF;
                CONTINUE;
            END IF;

            IF _try_offset < _offset_m THEN
                _mz_pequena := _mz_pequena + 1;
            END IF;

            -- ──────────────────────────────────────────────────────────────
            -- F. CALCULAR PUNTO DE REFERENCIA SOBRE EL BORDE
            --    (determina en QUÉ LADO de la manzana va la placa)
            --
            --    1. Punto del vial más cercano al punto original
            --       → ancla la posición al segmento de vía correcto
            --    2. Punto del borde original más cercano a ese punto del vial
            --       → este es el "frente" de la manzana hacia la vía
            -- ──────────────────────────────────────────────────────────────
            _closest_road_pt := ST_ClosestPoint(_road_proj, _pt_orig);
            _closest_bnd_pt  := ST_ClosestPoint(_mz_boundary, _closest_road_pt);

            -- ──────────────────────────────────────────────────────────────
            -- G. ★ PROYECTAR SOBRE EL POLÍGONO INTERIOR
            --
            --    ST_ClosestPoint(inner_polygon, punto_borde) nos da el
            --    punto sobre el borde del polígono interior que está más
            --    cerca del punto de referencia en el borde original.
            --
            --    Esto GARANTIZA:
            --    • ≥ 3m de distancia a TODOS los bordes (no solo uno)
            --    • En esquinas: 3m de AMBOS bordes adyacentes
            --    • El punto queda del lado correcto (frente al vial)
            -- ──────────────────────────────────────────────────────────────
            _new_pt_proj := ST_ClosestPoint(_mz_inner, _closest_bnd_pt);

            -- ──────────────────────────────────────────────────────────────
            -- H. VALIDACIÓN DE SEGURIDAD
            --    Doble check: el punto DEBE estar dentro de la manzana
            --    original. Si por algún edge case de geometría no lo está,
            --    usar ST_PointOnSurface del inner como fallback seguro.
            -- ──────────────────────────────────────────────────────────────
            IF NOT ST_Contains(_mz_proj, _new_pt_proj) THEN
                -- Esto no debería pasar, pero por seguridad:
                _new_pt_proj := ST_PointOnSurface(_mz_inner);
                RAISE NOTICE '  ⚠ id=% punto fuera tras proyección, usando PointOnSurface', rec.id;
            END IF;

            -- Verificación extra: confirmar que quedó a ≥ offset del borde
            IF ST_Distance(_new_pt_proj, _mz_boundary) < (_try_offset - 0.1) THEN
                -- Si no cumple, forzar al interior del polígono inner
                _new_pt_proj := ST_PointOnSurface(_mz_inner);
            END IF;

            -- ──────────────────────────────────────────────────────────────
            -- I. REPROYECTAR A 4326 Y ACTUALIZAR
            -- ──────────────────────────────────────────────────────────────
            _new_pt_4326 := ST_Transform(_new_pt_proj, 4326);

            UPDATE "{{esquema}}".placa
               SET geom = _new_pt_4326
             WHERE id = rec.id;

            _actualizados := _actualizados + 1;

        EXCEPTION WHEN OTHERS THEN
            _errores := _errores + 1;
            IF _errores <= 20 THEN
                RAISE WARNING '⚠ Error id=%: %', rec.id, SQLERRM;
            END IF;
        END;

        -- ── REPORTE CADA 500 ──────────────────────────────────────────────
        IF _procesados % 500 = 0 THEN
            RAISE NOTICE '  [%/%] act:% | ok:% | sin_via:% | sin_mz:% | peq:% | err:% | %.2fs',
                _procesados, _total, _actualizados, _ya_ok, _sin_via,
                _sin_manzana, _mz_pequena, _errores,
                round(EXTRACT(EPOCH FROM clock_timestamp() - _batch_t)::numeric, 2);
            _batch_t := clock_timestamp();
        END IF;

    END LOOP;

    -- ═══ RESUMEN FINAL ════════════════════════════════════════════════════
    RAISE NOTICE '════════════════════════════════════════════════════════════';
    RAISE NOTICE '  RESUMEN FINAL v3 - 28_se.placa (porcentaje_cambio > 30)';
    RAISE NOTICE '────────────────────────────────────────────────────────────';
    RAISE NOTICE '  Total registros       : %', _total;
    RAISE NOTICE '  Actualizados          : %', _actualizados;
    RAISE NOTICE '  Ya estaban bien (≥3m) : %', _ya_ok;
    RAISE NOTICE '  Sin vía asociada      : %', _sin_via;
    RAISE NOTICE '  Sin manzana cercana   : %', _sin_manzana;
    RAISE NOTICE '  Manzana muy pequeña   : % (offset reducido o centroide)', _mz_pequena;
    RAISE NOTICE '  Errores               : %', _errores;
    RAISE NOTICE '  Tiempo total          : %s',
        round(EXTRACT(EPOCH FROM clock_timestamp() - _t0)::numeric, 2);
    RAISE NOTICE '  Respaldo              : "{{esquema}}".placa_bkp_%', _ts;
    RAISE NOTICE '════════════════════════════════════════════════════════════';

END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 2. VERIFICACIÓN POST-PROCESO
-- ─────────────────────────────────────────────────────────────────────────────

-- a) Puntos filtrados que quedaron fuera de toda manzana (esperado: 0)
SELECT count(*) AS puntos_fuera_manzana
  FROM "{{esquema}}".placa p
 WHERE p.porcentaje_cambio > 30
   AND NOT EXISTS (
    SELECT 1 FROM "{{esquema}}".manzana mz
     WHERE ST_Contains(mz.geom, p.geom)
 );

-- b) Distribución de distancia al borde (esperado: ≈ 3.00m para la mayoría)
SELECT
    round(avg(d)::numeric, 2)    AS prom_m,
    round(min(d)::numeric, 2)    AS min_m,
    round(max(d)::numeric, 2)    AS max_m,
    round(stddev(d)::numeric, 2) AS std_m,
    count(*)                     AS n,
    count(*) FILTER (WHERE d < 2.5) AS menos_de_2_5m,
    count(*) FILTER (WHERE d >= 2.9 AND d <= 3.1) AS entre_2_9_y_3_1m,
    count(*) FILTER (WHERE d > 3.1) AS mas_de_3_1m
FROM (
    SELECT ST_Distance(
        ST_Transform(p.geom, 31984),
        ST_Boundary(ST_Transform(mz.geom, 31984))
    ) AS d
    FROM "{{esquema}}".placa p
    CROSS JOIN LATERAL (
        SELECT mz.geom
          FROM "{{esquema}}".manzana mz
         WHERE ST_Contains(mz.geom, p.geom)
         ORDER BY mz.geom <-> p.geom
         LIMIT 1
    ) mz
    WHERE p.porcentaje_cambio > 30
) sub;

-- c) Casos problemáticos: puntos a < 2m del borde (para revisar manualmente)
SELECT
    p.id,
    round(ST_Distance(
        ST_Transform(p.geom, 31984),
        ST_Boundary(ST_Transform(mz.geom, 31984))
    )::numeric, 2) AS dist_borde_m
FROM "{{esquema}}".placa p
CROSS JOIN LATERAL (
    SELECT mz.geom
      FROM "{{esquema}}".manzana mz
     WHERE ST_Contains(mz.geom, p.geom)
     ORDER BY mz.geom <-> p.geom
     LIMIT 1
) mz
WHERE p.porcentaje_cambio > 30
  AND ST_Distance(
        ST_Transform(p.geom, 31984),
        ST_Boundary(ST_Transform(mz.geom, 31984))
      ) < 2.0
ORDER BY dist_borde_m;

-- d) Comparar desplazamiento vs respaldo
/*
SELECT
    round(avg(d)::numeric, 2) AS prom_desplaz_m,
    round(max(d)::numeric, 2) AS max_desplaz_m,
    count(*) FILTER (WHERE d > 50) AS movidos_mas_50m
FROM (
    SELECT ST_Distance(
        ST_Transform(p.geom, 31984),
        ST_Transform(bk.geom, 31984)
    ) AS d
    FROM "{{esquema}}".placa p
    JOIN "{{esquema}}".placa_bkp_YYYYMMDD_HHMMSS bk USING (id)
    WHERE p.porcentaje_cambio > 30
) sub;
*/


-- ─────────────────────────────────────────────────────────────────────────────
-- 3. ROLLBACK (ejecutar solo si necesita revertir)
-- ─────────────────────────────────────────────────────────────────────────────
/*
   Reemplazar YYYYMMDD_HHMMSS con el timestamp del respaldo.

   BEGIN;
     UPDATE "{{esquema}}".placa p
        SET geom = bk.geom
       FROM "{{esquema}}".placa_bkp_YYYYMMDD_HHMMSS bk
      WHERE p.id = bk.id;
   COMMIT;

   -- DROP TABLE "{{esquema}}".placa_bkp_YYYYMMDD_HHMMSS;
*/
