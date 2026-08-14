--actualizar generadora en placa
UPDATE "13_am".placa
SET generadora = (floor(placa::numeric / 100) * 100)::text;

--reset campo atipico
UPDATE "13_am".placa p
SET atipico = null;

--marcar atipicos
UPDATE "13_am".placa p
SET atipico = 'ATIPICO'
FROM (
    SELECT id_mavvial,
           generadora,
           COUNT(*) AS conteo,
           FIRST_VALUE(generadora) OVER (PARTITION BY id_mavvial ORDER BY COUNT(*) DESC, generadora) AS generadora_moda
    FROM "13_am".placa
    GROUP BY id_mavvial, generadora
) sub
WHERE p.id_mavvial = sub.id_mavvial
  AND p.generadora = sub.generadora
  AND p.generadora <> sub.generadora_moda
  AND ABS(CAST(p.generadora AS integer) - CAST(sub.generadora_moda AS integer)) > 150;

--borrar atipicos
delete from "13_am".placa
where atipico is not null;

