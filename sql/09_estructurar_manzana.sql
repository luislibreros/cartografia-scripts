-- =====================================================================
-- ServiFlow · Paso 9 · Estructurar manzana (tabla final)
-- La ESTRUCTURA y la lista de ESTADOS vienen del PERFIL del país.
--   esquema={{esquema}}  cruda={{tabla_cruda}}  final=manzana
--   distritos={{tabla_distrito}}  barrios={{tabla_bairro}}
-- =====================================================================
DROP TABLE IF EXISTS "{{esquema}}".manzana;

CREATE TABLE "{{esquema}}".manzana (
{{ddl_columnas_manzana}}
);
CREATE INDEX idx_manzana_geom ON "{{esquema}}".manzana USING gist(geom);

INSERT INTO "{{esquema}}".manzana (geom)
SELECT geom FROM "{{esquema}}".{{tabla_cruda}};

-- campos geográficos (punto interior; luego intersección directa para los nulos)
UPDATE "{{esquema}}".manzana m
SET cod_distri=p.cod_distri, nom_distri=UPPER(p.nom_distri),
    cod_mun=p.cod_mun, nom_mun=UPPER(p.nom_mun),
    cod_estado=p.cod_estado, nom_estado=UPPER(p.nom_estado)
FROM "{{esquema}}".{{tabla_distrito}} p
WHERE ST_Intersects(ST_PointOnSurface(m.geom), p.geom);

UPDATE "{{esquema}}".manzana m
SET cod_distri=p.cod_distri, nom_distri=UPPER(p.nom_distri),
    cod_mun=p.cod_mun, nom_mun=UPPER(p.nom_mun),
    cod_estado=p.cod_estado, nom_estado=UPPER(p.nom_estado)
FROM "{{esquema}}".{{tabla_distrito}} p
WHERE ST_Intersects(m.geom, p.geom) AND m.cod_estado IS NULL;

-- barrios
UPDATE "{{esquema}}".manzana m
SET cod_bar=p.cd_bairro, nom_bar=UPPER(p.nm_bairro)
FROM "{{esquema}}".{{tabla_bairro}} p
WHERE ST_Intersects(ST_PointOnSurface(m.geom), p.geom);

UPDATE "{{esquema}}".manzana m
SET cod_bar=p.cd_bairro, nom_bar=UPPER(p.nm_bairro)
FROM "{{esquema}}".{{tabla_bairro}} p
WHERE ST_Intersects(m.geom, p.geom) AND m.cod_bar IS NULL;

-- abreviar estado (lista del PERFIL)
WITH estados_abrev (sigla_estado, nombre_estado) AS (
    VALUES
    {{estados_values}}
)
UPDATE "{{esquema}}".manzana
SET nom_estado = sigla_estado
FROM estados_abrev
WHERE nom_estado = nombre_estado;

REINDEX TABLE "{{esquema}}".manzana;
