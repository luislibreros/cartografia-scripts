-- ServiFlow · script de placas (parametrizado)
-- El esquema es {{esquema}} (se elige en el panel). Modo 'schema':
-- corre DIRECTO sobre el esquema elegido; úsalo en un esquema de trabajo.

-- =====================================================================
--  DESAGREGACION DE DIRECCIONES - "{{esquema}}".placa (Chile)
--  Base: rc_direccion (principal) | complemento: dc_direccion (barrio)
--  Lectura izquierda->derecha por estados (nombre -> puerta -> complementos)
--  Salidas con prefijo dir_*  (NO toca columnas existentes como mz)
-- =====================================================================

-- =====================================================================
--  1) DDL - crea columnas dir_* sin sobrescribir nada existente
-- =====================================================================
DO $ddl$
DECLARE
    cols text[] := ARRAY[
        'dir_tipo varchar(5)','dir_via text','dir_numero varchar(25)',
        'dir_mz varchar(25)','dir_sitio varchar(25)','dir_casa varchar(25)',
        'dir_lote varchar(25)','dir_depto varchar(25)','dir_block varchar(25)',
        'dir_barrio text','dir_resto text','dir_revisar boolean'
    ];
    c text; cname text; existe boolean;
BEGIN
    FOREACH c IN ARRAY cols LOOP
        cname := split_part(c,' ',1);
        SELECT EXISTS(SELECT 1 FROM information_schema.columns
                      WHERE table_schema='{{esquema}}' AND table_name='placa'
                        AND column_name=cname) INTO existe;
        IF existe THEN
            RAISE NOTICE 'Columna % ya existe -> se reutiliza.', cname;
        ELSE
            EXECUTE format('ALTER TABLE "{{esquema}}".placa ADD COLUMN %s', c);
            RAISE NOTICE 'Columna % creada.', cname;
        END IF;
    END LOOP;
END $ddl$;

-- =====================================================================
--  2) FUNCION PARSER (rc_direccion -> componentes)
-- =====================================================================
DROP FUNCTION IF EXISTS "{{esquema}}".fn_parse_dir(text);
CREATE OR REPLACE FUNCTION "{{esquema}}".fn_parse_dir(
    p_raw       text,
    OUT tipo    text,
    OUT via     text,
    OUT numero  text,
    OUT mz      text,
    OUT sitio   text,
    OUT casa    text,
    OUT lote    text,
    OUT depto   text,
    OUT blk     text,
    OUT resto   text,
    OUT revisar boolean
)
LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
AS $func$
DECLARE
    mz_set text[] := ARRAY['MANZANA','MZ','MZA','MNZ'];
    st_set text[] := ARRAY['SITIO','SIT','ST'];
    lt_set text[] := ARRAY['LOTE','LOT','LT'];
    dp_set text[] := ARRAY['DEPTO','DPTO','DEPARTAMENTO','DEP','DPT','DP'];
    bl_set text[] := ARRAY['BLOCK','BLOQUE','BLK','BLOC','BL'];
    cs_set text[] := ARRAY['CASA','CS','CSA','CSS'];
    hard   text[];
    t        text;
    tok      text[];
    n        int;
    i        int;
    j        int;
    ini      int := 1;
    nm       text[] := '{}';
    rst      text[] := '{}';
    has_alpha boolean := false;
    has_num   boolean := false;
    suf       text := NULL;
    casa_found boolean := false;
    num_suf   text;
    tk text; nxt text; nx2 text;
BEGIN
    revisar := false;
    IF p_raw IS NULL OR btrim(p_raw) = '' THEN revisar := true; RETURN; END IF;

    t := upper(btrim(p_raw));
    t := regexp_replace(t, '[^[:alnum:] ]', ' ', 'g');
    t := regexp_replace(t, '\s+', ' ', 'g');
    t := btrim(t);
    IF t = '' THEN revisar := true; RETURN; END IF;

    tok  := string_to_array(t, ' ');
    n    := array_length(tok,1);
    hard := mz_set||st_set||lt_set||dp_set||bl_set||cs_set;

    -- 2.1 tipo de via (SOLO primera palabra) abreviado segun catalogo
    tipo := CASE tok[1]
        WHEN 'AUTOPISTA' THEN 'AU' WHEN 'AUTOP' THEN 'AU' WHEN 'AUT' THEN 'AU' WHEN 'AU' THEN 'AU'
        WHEN 'AVENIDA' THEN 'AV' WHEN 'AVDA' THEN 'AV' WHEN 'AVD' THEN 'AV' WHEN 'AVE' THEN 'AV' WHEN 'AV' THEN 'AV'
        WHEN 'BOULEVARD' THEN 'BLV' WHEN 'BULEVAR' THEN 'BLV' WHEN 'BLVD' THEN 'BLV' WHEN 'BLV' THEN 'BLV'
        WHEN 'CALLE' THEN 'CL' WHEN 'CLL' THEN 'CL' WHEN 'CALL' THEN 'CL' WHEN 'CL' THEN 'CL'
        WHEN 'CALLEJON' THEN 'CJ' WHEN 'CJON' THEN 'CJ' WHEN 'CJ' THEN 'CJ'
        WHEN 'CAMINO' THEN 'CN' WHEN 'CMNO' THEN 'CN' WHEN 'CNO' THEN 'CN' WHEN 'CAM' THEN 'CN' WHEN 'CN' THEN 'CN'
        WHEN 'CARRETERA' THEN 'CT' WHEN 'CTRA' THEN 'CT' WHEN 'CT' THEN 'CT'
        WHEN 'CIRCUNVALACION' THEN 'CVC' WHEN 'CVC' THEN 'CVC'
        WHEN 'CIRCUNVALAR' THEN 'CV' WHEN 'CV' THEN 'CV'
        WHEN 'DIAGONAL' THEN 'DG' WHEN 'DIAG' THEN 'DG' WHEN 'DG' THEN 'DG'
        WHEN 'CARRERA' THEN 'KR' WHEN 'CRA' THEN 'KR' WHEN 'CR' THEN 'KR' WHEN 'KR' THEN 'KR'
        WHEN 'PASAJE' THEN 'PJ' WHEN 'PJE' THEN 'PJ' WHEN 'PSJE' THEN 'PJ' WHEN 'PSJ' THEN 'PJ' WHEN 'PASJ' THEN 'PJ' WHEN 'PJ' THEN 'PJ'
        WHEN 'PERIFERICO' THEN 'PF' WHEN 'PF' THEN 'PF'
        WHEN 'PASEO' THEN 'PS' WHEN 'PSO' THEN 'PS' WHEN 'PS' THEN 'PS'
        WHEN 'PROLONGACION' THEN 'PR' WHEN 'PROL' THEN 'PR' WHEN 'PR' THEN 'PR'
        WHEN 'PEATONAL' THEN 'PT' WHEN 'PEAT' THEN 'PT' WHEN 'PT' THEN 'PT'
        WHEN 'ROTONDA' THEN 'RO' WHEN 'ROT' THEN 'RO' WHEN 'RO' THEN 'RO'
        WHEN 'RETORNO' THEN 'RT' WHEN 'RET' THEN 'RT' WHEN 'RT' THEN 'RT'
        WHEN 'SENDERO' THEN 'SD' WHEN 'SEND' THEN 'SD' WHEN 'SD' THEN 'SD'
        WHEN 'RUTA' THEN 'RU' WHEN 'RU' THEN 'RU'
        WHEN 'TUNEL' THEN 'TUN' WHEN 'TUN' THEN 'TUN'
        WHEN 'TRANSVERSAL' THEN 'TV' WHEN 'TRANSV' THEN 'TV' WHEN 'TRSV' THEN 'TV' WHEN 'TV' THEN 'TV'
        WHEN 'VIA' THEN 'VIA'
        ELSE NULL
    END;
    IF tipo IS NOT NULL THEN ini := 2; END IF;

    -- 2.2 FASE NOMBRE: consume tokens hasta el numero de puerta o un marcador
    i := ini;
    WHILE i <= n LOOP
        tk  := tok[i];
        nxt := CASE WHEN i  < n THEN tok[i+1] ELSE NULL END;
        nx2 := CASE WHEN i+1 < n THEN tok[i+2] ELSE NULL END;

        IF tk = ANY(hard) THEN EXIT; END IF;                       -- marcador duro -> complemento
        IF tk = 'C' AND has_alpha AND nxt ~ '^[0-9]+$' THEN EXIT; END IF;  -- C = casa

        IF tk ~ '^[0-9]+$' THEN
            IF (NOT has_alpha) AND (NOT has_num) THEN
                nm := nm || tk; has_num := true; i := i + 1;        -- numero inicial = nombre
            ELSE
                numero := tk;                                      -- numero de puerta
                IF nxt ~ '^[A-Z]$' AND NOT (nxt = 'C' AND nx2 ~ '^[0-9]+$') THEN
                    suf := nxt; i := i + 2;                         -- sufijo letra
                ELSE
                    i := i + 1;
                END IF;
                EXIT;
            END IF;
        ELSE
            nm := nm || tk; has_alpha := true; i := i + 1;          -- palabra = nombre
        END IF;
    END LOOP;
    via := NULLIF(array_to_string(nm,' '),'');

    -- 2.3 S/N (sin numero)
    IF numero IS NULL AND via IS NOT NULL AND (via ~ '(^| )S N$' OR via ~ '(^| )SN$') THEN
        via := NULLIF(btrim(regexp_replace(via,'(^| )S ?N$','')),'');
        numero := 'S/N';
    END IF;

    -- 2.4 FASE COMPLEMENTO: marcadores + valores; lo no reconocido -> resto
    j := i;
    WHILE j <= n LOOP
        tk  := tok[j];
        nxt := CASE WHEN j < n THEN tok[j+1] ELSE NULL END;
        IF (tk = ANY(cs_set)) OR (tk = 'C' AND nxt ~ '^[0-9]+$') THEN
            casa_found := true;
            IF nxt IS NOT NULL THEN casa := nxt; j := j+2; ELSE rst := rst||tk; j := j+1; END IF;
        ELSIF tk = ANY(mz_set) THEN
            IF nxt IS NOT NULL THEN mz := nxt; j := j+2; ELSE rst := rst||tk; j := j+1; END IF;
        ELSIF tk = ANY(st_set) THEN
            IF nxt IS NOT NULL THEN sitio := nxt; j := j+2; ELSE rst := rst||tk; j := j+1; END IF;
        ELSIF tk = ANY(lt_set) THEN
            IF nxt IS NOT NULL THEN lote := nxt; j := j+2; ELSE rst := rst||tk; j := j+1; END IF;
        ELSIF tk = ANY(dp_set) THEN
            IF nxt IS NOT NULL THEN depto := nxt; j := j+2; ELSE rst := rst||tk; j := j+1; END IF;
        ELSIF tk = ANY(bl_set) THEN
            IF nxt IS NOT NULL THEN blk := nxt; j := j+2; ELSE rst := rst||tk; j := j+1; END IF;
        ELSE
            rst := rst || tk; j := j+1;
        END IF;
    END LOOP;
    resto := NULLIF(array_to_string(rst,' '),'');

    -- 2.5 numero + sufijo  /  patron MANZANA-CASA
    num_suf := numero || COALESCE(' '||suf,'');
    IF casa_found AND mz IS NULL AND numero IS NOT NULL AND numero <> 'S/N' THEN
        mz := num_suf;          
        numero := NULL;         
    ELSE
        numero := num_suf;      
    END IF;

    -- 2.6 banderas de revision
    IF via IS NULL THEN revisar := true; END IF;
    IF resto IS NOT NULL THEN revisar := true; END IF;
    IF numero IS NULL AND casa IS NULL AND mz IS NULL AND sitio IS NULL THEN revisar := true; END IF;

    RETURN;
END;
$func$;

-- =====================================================================
--  3) FUNCION BARRIO (dc_direccion menos rc_direccion -> urbanizacion)
-- =====================================================================
CREATE OR REPLACE FUNCTION "{{esquema}}".fn_barrio(p_rc text, p_dc text)
RETURNS text LANGUAGE plpgsql IMMUTABLE PARALLEL SAFE
AS $f$
DECLARE rcn text; dcn text; rem text; p int;
BEGIN
    IF p_dc IS NULL OR btrim(p_dc) = '' THEN RETURN NULL; END IF;
    dcn := btrim(regexp_replace(regexp_replace(upper(btrim(p_dc)),'[^[:alnum:] ]',' ','g'),'\s+',' ','g'));
    IF p_rc IS NULL OR btrim(p_rc) = '' THEN RETURN NULLIF(dcn,''); END IF;
    rcn := btrim(regexp_replace(regexp_replace(upper(btrim(p_rc)),'[^[:alnum:] ]',' ','g'),'\s+',' ','g'));
    IF dcn = rcn THEN RETURN NULL; END IF;
    p := position(rcn in dcn);
    IF p = 1 THEN
        RETURN NULLIF(btrim(substr(dcn, length(rcn)+1)), '');
    ELSIF p > 1 THEN
        rem := btrim(regexp_replace(replace(dcn, rcn, ' '),'\s+',' ','g'));
        RETURN NULLIF(rem, '');
    END IF;
    RETURN NULLIF(dcn, '');
END;
$f$;

-- =====================================================================
--  4) EJECUCION (1 sola pasada sobre "{{esquema}}".placa)
-- =====================================================================
DO $run$
DECLARE nfil bigint; t0 timestamptz := clock_timestamp();
BEGIN
    RAISE NOTICE 'Parseando direcciones de placa...';
    WITH parsed AS (
        SELECT t.ctid, r.tipo,r.via,r.numero,r.mz,r.sitio,r.casa,r.lote,
               r.depto,r.blk,r.resto,r.revisar,
               "{{esquema}}".fn_barrio(t.rc_direccion, t.dc_direccion) AS barrio
        FROM "{{esquema}}".placa t
        CROSS JOIN LATERAL "{{esquema}}".fn_parse_dir(t.rc_direccion) r
    )
    UPDATE "{{esquema}}".placa p
    SET dir_tipo=x.tipo, dir_via=x.via, dir_numero=x.numero, dir_mz=x.mz,
        dir_sitio=x.sitio, dir_casa=x.casa, dir_lote=x.lote, dir_depto=x.depto,
        dir_block=x.blk, dir_barrio=x.barrio, dir_resto=x.resto, dir_revisar=x.revisar
    FROM parsed x WHERE p.ctid = x.ctid;
    GET DIAGNOSTICS nfil = ROW_COUNT;
    RAISE NOTICE 'Filas procesadas en Santiago: %  (% s)', nfil,
                 round(EXTRACT(epoch FROM clock_timestamp()-t0)::numeric, 3);
END $run$;