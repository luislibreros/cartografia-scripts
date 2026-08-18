-- ServiFlow · script de placas (parametrizado)
-- El esquema es {{esquema}} (se elige en el panel). Modo 'schema':
-- corre DIRECTO sobre el esquema elegido; úsalo en un esquema de trabajo.

BEGIN;

UPDATE "{{esquema}}".placa_estructurada
SET direccion =
CASE
    -- Con barrio
    WHEN NULLIF(TRIM(nom_bar), '') IS NOT NULL THEN
        CONCAT_WS(', ',
            CONCAT_WS(' ', nomvtotal, placa),
            nom_bar,
            nom_com,
            cod_postal
        )

    -- Sin barrio
    ELSE
        CONCAT_WS(', ',
            CONCAT_WS(' ', nomvtotal, placa),
            nom_com,
            nom_prov,
            cod_postal
        )
END;
COMMIT;
-- ROLLBACK;