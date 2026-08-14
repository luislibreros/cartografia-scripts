-- =====================================================================
-- ServiFlow · Paso 4 · Normalizar nombres de vía
-- La LIMPIEZA es genérica; el DICCIONARIO de normalización viene del PERFIL.
--   esquema={{esquema}}  tabla={{tabla}}  campo={{campo}}
-- =====================================================================

-- ---- limpieza genérica -------------------------------------------------
UPDATE "{{esquema}}".{{tabla}}
SET {{campo}} = upper({{campo}})
WHERE observ_dat = 'SIN_ESTANDARIZAR';

UPDATE "{{esquema}}".{{tabla}}
SET {{campo}} = REGEXP_REPLACE({{campo}}, '[]ª°:\./\\*_\-,\(\)?¿[]', ' ', 'g')
WHERE {{campo}} ~ '[]ª°:\./\\*_\-,\(\)?¿[]'
  AND observ_dat = 'SIN_ESTANDARIZAR';

UPDATE "{{esquema}}".{{tabla}}
SET {{campo}} = REGEXP_REPLACE({{campo}}, '\s+', ' ', 'g')
WHERE {{campo}} ~ '\s{2,}'
  AND observ_dat = 'SIN_ESTANDARIZAR';

UPDATE "{{esquema}}".{{tabla}}
SET {{campo}} = trim({{campo}})
WHERE observ_dat = 'SIN_ESTANDARIZAR';

-- ---- normalización dirigida por el PERFIL del país ---------------------
{{normalizacion_updates}}

-- ---- marcar como NORMALIZADO lo que cambió -----------------------------
UPDATE "{{esquema}}".{{tabla}}
SET observ_dat = 'NORMALIZADO'
WHERE {{campo}} <> nom_original
  AND observ_dat = 'SIN_ESTANDARIZAR';
