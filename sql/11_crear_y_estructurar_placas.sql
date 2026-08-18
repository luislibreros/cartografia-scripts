-- ServiFlow · script de placas (parametrizado)
-- El esquema es {{esquema}} (se elige en el panel). Modo 'schema':
-- corre DIRECTO sobre el esquema elegido; úsalo en un esquema de trabajo.

DO $$
BEGIN

--CREAR CAPA PLACA
RAISE NOTICE '=== INICIANDO PROCESO DE CREACIÓN DE CAPA PLACA ===';
RAISE NOTICE 'Eliminando tabla placa si existe...';

DROP TABLE IF EXISTS "{{esquema}}".placa;

RAISE NOTICE 'Creando estructura de tabla placa...';
CREATE TABLE "{{esquema}}".placa (
	id 			SERIAL PRIMARY KEY,
    id_capa     serial,
    tipovia     VARCHAR(10),
    nomvia      VARCHAR(100),
    nomvtotal   VARCHAR(100),
    generadora  VARCHAR(50),
    placa       VARCHAR(10),
    cod_urb     VARCHAR(15),
    tipo_urb    VARCHAR(10),
    nom_urb     VARCHAR(100),
    manzana     VARCHAR(30),
    casa_lote   VARCHAR(50),
    tipo_dir    VARCHAR(20),
    direccion   VARCHAR(100),
    cep         VARCHAR(10),
    atipico     VARCHAR(10),
    id_manzana  INTEGER,
    id_mavvial  INTEGER,
    cod_estado  VARCHAR(10),
    nom_estado  VARCHAR(100),
    cod_mun     VARCHAR(10),
    nom_mun     VARCHAR(100),
    cod_distri  VARCHAR(10),
    nom_distri  VARCHAR(100),
    cod_bar     VARCHAR(10),
    nom_bar     VARCHAR(100),
	id_fuente   INTEGER,
	fuente      VARCHAR(15),
    observ_dat  VARCHAR(30),
    observ_pos  VARCHAR(30),
    marca       VARCHAR(5),
    fecha       VARCHAR(10),
    version     VARCHAR(5),
    geom        geometry (point, 4326)
);

RAISE NOTICE 'Insertando placas desde IBGE que intersectan con área urbana de servicio...';
INSERT INTO "{{esquema}}".placa 
(placa, nomvia, id_fuente, fuente, cep, geom)
SELECT 
	num_endereco as placa,
	UPPER(replace(COALESCE(nom_tipo_seglogr, '') || ' ' || COALESCE(nom_titulo_seglogr, '') || ' ' || COALESCE(nom_seglogr, ''), '  ', ' ')) as nomvia,
	cod_unico_endereco::integer as id_fuente,
	'IBGE' as fuente,
	p.cep,
	p.geom
FROM "{{esquema}}".placa_ibge p
JOIN "{{esquema}}".area_urbana_servi a
  ON ST_intersects(p.geom, a.geom);

RAISE NOTICE 'Registros insertados: %', (SELECT COUNT(*) FROM "{{esquema}}".placa);

RAISE NOTICE 'Creando índice espacial en geometría...';
CREATE INDEX idx_geom_placa ON "{{esquema}}".placa USING gist (geom);

--DESTACAR PLACAS QUE NO SIRVEN POR VALOR 0 O SIN NOMBRE
RAISE NOTICE 'Eliminando placas inválidas (valor 0, sin nominación, S/N, SN)...';
DELETE FROM "{{esquema}}".placa
WHERE placa = '0' OR
	  nomvia ILIKE '%NOMINACAO%'
	  OR nomvia ILIKE '%DENOM%'
	  OR placa LIKE 'S/N'
	  OR placa LIKE 'SN';

RAISE NOTICE 'Registros después de limpieza: %', (SELECT COUNT(*) FROM "{{esquema}}".placa);

--CAMPOS GEOGRÁFICOS
RAISE NOTICE 'Actualizando campos geográficos desde distrito (estado, municipio, distrito)...';
UPDATE "{{esquema}}".placa m
SET cod_distri = p.cod_distri,
	nom_distri = UPPER(p.nom_distri),
	cod_mun = p.cod_mun,
	nom_mun = UPPER(p.nom_mun),
	cod_estado = p.cod_estado,
	nom_estado = UPPER(p.nom_estado)
FROM "{{esquema}}".distrito p
WHERE ST_intersects (m.geom, p.geom);

RAISE NOTICE 'Actualizando campos de barrio desde bairro_ibge...';
UPDATE "{{esquema}}".placa m
SET cod_bar = p.cd_bairro,
	nom_bar = UPPER(p.nm_bairro)
FROM "{{esquema}}".bairro_ibge p
WHERE ST_intersects (m.geom, p.geom);

--ELIMINAR PLACAS DUPLICADAS POR LLAVE
RAISE NOTICE 'Agregando columna llave para identificar duplicados...';
ALTER TABLE "{{esquema}}".placa ADD COLUMN llave TEXT;

RAISE NOTICE 'Creando índice en columna llave...';
CREATE INDEX idx_llave_placa ON "{{esquema}}".placa (llave);

RAISE NOTICE 'Calculando llave única por registro...';
UPDATE "{{esquema}}".placa
SET llave = unaccent(
    replace(
        COALESCE(placa, '') ||
        COALESCE(nomvia, '') ||
        COALESCE(cod_distri, '') ||
        COALESCE(cod_bar, '') ||
        COALESCE(cep, ''),
    ' ', '')
);

RAISE NOTICE 'Eliminando registros duplicados por llave...';
DELETE FROM "{{esquema}}".placa
WHERE id IN (
    SELECT id
    FROM (
        SELECT id,
               ROW_NUMBER() OVER (PARTITION BY llave ORDER BY id) AS rn
        FROM "{{esquema}}".placa
    ) t
    WHERE rn > 1
);

RAISE NOTICE 'Registros finales en tabla placa: %', (SELECT COUNT(*) FROM "{{esquema}}".placa);
RAISE NOTICE '=== PROCESO COMPLETADO EXITOSAMENTE ===';

END $$;