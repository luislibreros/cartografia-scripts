-- ServiFlow · script de placas (parametrizado)
-- El esquema es {{esquema}} (se elige en el panel). Modo 'schema':
-- corre DIRECTO sobre el esquema elegido; úsalo en un esquema de trabajo.

DELETE FROM "{{esquema}}"."placa"
WHERE id_mavvial_homologado IS NULL;