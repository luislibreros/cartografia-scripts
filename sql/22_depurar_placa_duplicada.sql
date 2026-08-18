-- ServiFlow · script de placas (parametrizado)
-- El esquema es {{esquema}} (se elige en el panel). Modo 'schema':
-- corre DIRECTO sobre el esquema elegido; úsalo en un esquema de trabajo.

DO $$
BEGIN

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
ALTER TABLE "{{esquema}}".placa 
ADD COLUMN IF NOT EXISTS llave TEXT;

RAISE NOTICE 'Creando índice en columna llave...';
CREATE INDEX IF NOT EXISTS idx_llave_placa 
ON "{{esquema}}".placa (llave);

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