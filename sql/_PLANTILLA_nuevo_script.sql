-- =====================================================================
-- PLANTILLA de un script para ServiFlow
-- Copia este archivo, renómbralo y escribe tu SQL.
-- Reglas:
--   · Usa "{{esquema}}".{{tabla}} donde antes ponías el esquema/tabla fijos.
--   · Usa {{geom}} para la columna de geometría.
--   · Puedes crear parámetros propios (p. ej. {{umbral}}) y declararlos
--     en manifest.json dentro de "params".
--   · No borres ni modifiques nada del servidor de producción: ServiFlow
--     corre esto sobre una COPIA en el esquema de trabajo.
-- =====================================================================

-- Ejemplo: dejar geometrías válidas y quitar duplicados exactos
UPDATE "{{esquema}}".{{tabla}}
SET {{geom}} = ST_MakeValid({{geom}})
WHERE NOT ST_IsValid({{geom}});

-- (agrega aquí el resto de tu lógica…)
