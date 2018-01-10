CREATE OR REPLACE PACKAGE BODY content_repo.kpmg_import
AS
    -- import != n
    -- m.transaction_type

    PROCEDURE step4_taxdescription
    IS
        vtaxdescid   NUMBER;
    BEGIN
        FOR i IN (SELECT taxdescname
                  FROM kpmg_rates)
        LOOP
            SELECT DISTINCT td1.id tax_desc_id
              INTO vtaxdescid
              FROM tax_descriptions td1
                   JOIN transaction_types tt1
                       ON (td1.transaction_type_id = tt1.id)
                   JOIN taxation_types tt2 ON (tt2.id = td1.taxation_type_id)
                   JOIN specific_applicability_types st1
                       ON (st1.id = td1.spec_applicability_type_id)
             WHERE (   i.taxdescname =
                           tt1.name || ' - ' || tt2.name || ' - ' || st1.name
                    OR i.taxdescname = td1.name);

            UPDATE kpmg_rates
               SET tax_description_id = vtaxdescid,
                   taxdescid = vtaxdescid
            WHERE taxdescname = i.taxdescname;

            COMMIT;
        END LOOP;
    END step4_taxdescription;




    PROCEDURE kpmg_ins_juris_latest (officialname VARCHAR2)
    IS
        vcnt                    NUMBER;
        vjid                    NUMBER;
        vjnkid                  NUMBER;
        vtax_id                 NUMBER;
        vtax_nkid               NUMBER;
        vjuris_start_date       DATE;
        voutline_id             NUMBER;
        voutline_nkid           NUMBER;
        vjuris_appl_id          NUMBER;
        vjuris_appl_nkid        NUMBER;
        vtax_cnt                NUMBER;
        vcal_str                NUMBER;
        vtax_type               NUMBER;
        vamt_type               NUMBER;
        vtax_upper_limit_prev   NUMBER;
        vtax_upper_limit_curr   NUMBER;
        vtax_output_id          NUMBER;
        vtax_output_nkid        NUMBER;
        l_official_name         VARCHAR2 (2000);
        l_authority             VARCHAR2 (2000);
        vcnt_juris              NUMBER;
    BEGIN
        FOR i IN (SELECT DISTINCT official_name
                  FROM kpmg_rates
                  WHERE official_name = officialname
                  ORDER BY official_name)
        LOOP
            l_official_name := i.official_name;

            BEGIN
                -- If the Jurisdiction already exists, Then extract the information

                SELECT MAX (id) id, nkid, start_date
                  INTO vjid, vjnkid, vjuris_start_date
                  FROM jurisdictions
                 WHERE official_name = i.official_name -- and next_rid is null;
                GROUP BY nkid, start_date;

                DBMS_OUTPUT.put_line ('This jurisdiction already exists');
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    DBMS_OUTPUT.put_line ('Entered into exceptional block');

                    FOR a IN (SELECT DISTINCT official_name,
                                              description,
                                              start_date,
                                              -2918 entered_by,
                                              0 status,
                                              (SELECT id
                                               FROM currencies
                                               WHERE currency_code = 'USD')
                                                  currency,
                                              geoareacategory
                              FROM vkpmg_juris_inserts_new
                              WHERE official_name = i.official_name)
                    LOOP
                        l_authority := a.official_name;

                        SELECT COUNT (1)
                          INTO vcnt_juris
                          FROM jurisdictions
                         WHERE official_name = i.official_name;

                        /*
                        if vcnt_juris > 0 then
                            l_authority := l_authority||' ';

                            update tmp_kpmg_rates set official_name = l_authority where official_name = a.official_name;

                        end if;
                        */

                        INSERT INTO jurisdictions (official_name,
                                                   description,
                                                   start_date,
                                                   entered_by,
                                                   status,
                                                   currency_id,
                                                   geo_area_category_id)
                        VALUES (l_authority,
                                a.description || '(KPMG)',
                                a.start_date,
                                -2918,
                                0,
                                a.currency,
                                a.geoareacategory)
                        RETURNING id, nkid, start_date
                          INTO vjid, vjnkid, vjuris_start_date;

                        DBMS_OUTPUT.put_line (
                            'New Jurisdiction inserted ' || vjid);

                        EXIT;
                    END LOOP;
            END;

            -- Loop to process the tax information. UFor each tax, start_date would be the min date of all
            -- the available dates under that tax/reference_code


            FOR j
                IN (SELECT DISTINCT official_name,
                                    reference_code,
                                    tax_description_id,
                                    tax_description,
                                    MIN (start_date) start_date
                    FROM kpmg_rates
                    WHERE official_name = i.official_name
                          AND tax_description_id IS NOT NULL
                          AND import_tax = 'Y'
                    GROUP BY official_name,
                             reference_code,
                             tax_description_id,
                             tax_description
                    ORDER BY official_name, reference_code, start_date)
            LOOP
                vtax_cnt := 0;

                -- Check whether there exists already a tax with the same name and details.

                SELECT COUNT (1)
                  INTO vtax_cnt
                  FROM juris_tax_impositions
                 WHERE     jurisdiction_nkid = vjnkid
                       AND reference_code = j.reference_code;

                --and tax_description_id = j.tax_description_id;
                --and entered_by = -2918;

                DBMS_OUTPUT.put_line ('vtax_cnt value is ' || vtax_cnt);

                IF vtax_cnt = 0
                THEN
                    -- As there is no existing tax with the given information, Add the new tax
                    -- and process all the required information.

                    DBMS_OUTPUT.put_line ('inserting tax impositions');

                    -- Processing new tax details.
                    INSERT INTO juris_tax_impositions (jurisdiction_id,
                                                       jurisdiction_nkid,
                                                       tax_description_id,
                                                       reference_code,
                                                       start_date,
                                                       end_date,
                                                       status,
                                                       description,
                                                       entered_by)
                    VALUES (vjid,
                            vjnkid,
                            j.tax_description_id,
                            j.reference_code,
                            j.start_date,
                            NULL,
                            0,
                            j.tax_description,
                            -2918)
                    RETURNING id, nkid
                      INTO vtax_id, vtax_nkid;

                    DBMS_OUTPUT.put_line ('inserting tax applicabilities');

                    -- Create the Tax Applicability record
                    /*
                    insert into juris_tax_applicabilities
                    (
                        reference_code, jurisdiction_id, jurisdiction_nkid, calculation_method_id,
                        basis_percent, start_date, end_date, entered_by, status
                    )
                    values
                    (
                        'KPMG-TAXABLE'||'-'||j.reference_code, vjid, vjnkid, 2, 100, j.start_date, null, -2918, 0
                    )
                    returning id, nkid into vjuris_appl_id, vjuris_appl_nkid;

                    dbms_output.put_line('Processed Outlines '||vjuris_appl_id||' '||vjuris_appl_nkid);

                    dbms_output.put_line ('inserting taxability_outputs');

                            -- Process taxability output record
                            insert into taxability_outputs
                            (
                                    juris_tax_applicability_id, juris_tax_applicability_nkid, short_text,
                                    full_text, entered_by, status)
                            values
                            (
                                    vjuris_appl_id, vjuris_appl_nkid, 'KPMG Taxable', 'KPMG Taxable', -2918, 0
                            )
                            returning id, nkid into vtax_output_id, vtax_output_nkid;

                    dbms_output.put_line ('After inserting taxability_outputs');

            */
                    -- Insert the tax and the related ratekeyid details into below table
                    -- So that it will be useful for future data processing.

                    INSERT INTO kpmg_comm_taxes
                        SELECT DISTINCT r.ratekeyid,
                                        ji1.id taxid,
                                        j1.official_name,
                                        SYSDATE
                          FROM kpmg_rates r,
                               jurisdictions j1,
                               juris_tax_impositions ji1
                         WHERE     r.official_name = j1.official_name
                               AND (    j1.id = ji1.jurisdiction_id
                                    AND j1.nkid = ji1.jurisdiction_nkid)
                               AND ji1.description = r.tax_description
                               AND r.reference_code = ji1.reference_code
                               AND j1.id = vjid
                               AND ji1.id = vtax_id
                               AND ji1.entered_by = -2918;

                    COMMIT;

                    -- Process data into tax applicability sets information


                    DBMS_OUTPUT.put_line (
                        'inserting tax applicability taxes');
                    /*
                    insert into tax_applicability_taxes
                    (
                        juris_tax_applicability_id, juris_tax_applicability_nkid,
                        juris_tax_imposition_id,  juris_tax_imposition_nkid, start_date,
                        entered_by, status
                    )
                    values
                    (
                        vjuris_appl_id, vjuris_appl_nkid, vtax_id, vtax_nkid,
                        j.start_date, -2918, 0
                    );
                */
                    ----dbms_output.put_line(' About to process the tax outlines ');
                    DBMS_OUTPUT.put_line (
                           ' official_name and tax reference are '
                        || i.official_name
                        || ' - '
                        || j.reference_code);

                    -- We have processed the tax information successfully and now
                    -- we will process tax outlines and tax definition details now.

                    FOR k
                        IN (SELECT DISTINCT reference_code,
                                            start_date,
                                            end_date,
                                            taxratetype,
                                            taxratecalctype
                            FROM kpmg_rates r
                            WHERE     r.official_name = i.official_name
                                  AND r.reference_code = j.reference_code
                                  AND r.tax_description_id IS NOT NULL
                            ORDER BY reference_code, start_date ASC)
                    LOOP
                        DBMS_OUTPUT.put_line (' inside tax outline loop ');

                        SELECT id
                          INTO vtax_type
                          FROM tax_structure_types
                         WHERE description =
                                   DECODE (k.taxratetype,
                                           'Straight', 'Basic',
                                           k.taxratetype);

                        BEGIN
                            SELECT id
                              INTO vamt_type
                              FROM amount_types
                             WHERE description =
                                       (CASE k.taxratecalctype
                                            WHEN 'Per transaction'
                                            THEN
                                                'Default'
                                            WHEN 'Per line'
                                            THEN
                                                'Per telecom line'
                                            WHEN 'Per location'
                                            THEN
                                                'Per location'
                                            WHEN 'Per account'
                                            THEN
                                                'Invoice Amount'
                                            WHEN 'Per client base amount by account'
                                            THEN
                                                'Per Client Base Amt By Account'
                                            ELSE
                                                'Default'
                                        END);
                        EXCEPTION
                            WHEN NO_DATA_FOUND
                            THEN
                                DBMS_OUTPUT.put_line ('Sample testing 1 ');

                                SELECT id
                                  INTO vamt_type
                                  FROM amount_types
                                 WHERE description = 'Default';
                        END;

                        BEGIN
                            DBMS_OUTPUT.put_line ('Sample testing 2 ');

                            SELECT id
                              INTO vcal_str
                              FROM tax_calculation_structures
                             WHERE     tax_structure_type_id = vtax_type
                                   AND amount_type_id = vamt_type;
                        EXCEPTION
                            WHEN NO_DATA_FOUND
                            THEN
                                vcal_str := 4;
                        END;

                        DBMS_OUTPUT.put_line (
                            ' about to insert outline record ');

                        INSERT INTO tax_outlines (juris_tax_imposition_id,
                                                  calculation_structure_id,
                                                  entered_by,
                                                  status,
                                                  juris_tax_imposition_nkid,
                                                  start_date,
                                                  end_date)
                        VALUES (vtax_id,
                                vcal_str,
                                -2918,
                                0,
                                vtax_nkid,
                                k.start_date,
                                k.end_date)
                        RETURNING id, nkid
                          INTO voutline_id, voutline_nkid;

                        DBMS_OUTPUT.put_line (
                            'Sample testing 3 ' || voutline_nkid);

                        vtax_upper_limit_prev := NULL;


                        FOR l
                            IN (SELECT DISTINCT taxratetype,
                                                tieredrateupperlimit,
                                                taxratebasis,
                                                taxratevalue,
                                                tieredratevalue,
                                                k.start_date,
                                                k.end_date
                                FROM kpmg_rates
                                WHERE     official_name = i.official_name
                                      AND reference_code = j.reference_code
                                      AND import_tax != 'N'
                                      AND tax_description_id IS NOT NULL
                                      AND NVL (start_date, SYSDATE) =
                                              NVL (k.start_date, SYSDATE)
                                      AND NVL (end_date, SYSDATE) =
                                              NVL (k.end_date, SYSDATE)
                                ORDER BY taxratetype,
                                         k.start_date,
                                         TO_NUMBER (tieredrateupperlimit))
                        LOOP
                            DBMS_OUTPUT.put_line (
                                ' inside tax definition loop ');

                            vtax_upper_limit_curr := l.tieredrateupperlimit;

                            INSERT INTO tax_definitions (min_threshold,
                                                         max_limit,
                                                         value_type,
                                                         VALUE,
                                                         currency_id,
                                                         entered_by,
                                                         status,
                                                         tax_outline_id,
                                                         tax_outline_nkid)
                                VALUES (
                                           DECODE (
                                               l.taxratetype,
                                               'Tiered', NVL (
                                                             vtax_upper_limit_prev,
                                                             0),
                                               0),
                                           DECODE (
                                               l.taxratetype,
                                               'Tiered', l.tieredrateupperlimit,
                                               0),
                                           DECODE (l.taxratebasis,
                                                   'Revenue', 'Rate',
                                                   'Unit', 'Fee',
                                                   l.taxratetype),
                                           DECODE (
                                               l.taxratetype,
                                               'Straight', l.taxratevalue,
                                               'Tiered', l.tieredratevalue,
                                               l.taxratevalue),
                                           151,
                                           -2918,
                                           0,
                                           voutline_id,
                                           voutline_nkid);

                            vtax_upper_limit_prev := vtax_upper_limit_curr;
                        END LOOP;
                    END LOOP;
                END IF;
            END LOOP;

            DBMS_OUTPUT.put_line (i.official_name);

            SELECT COUNT (1)
              INTO vcnt
              FROM jurisdictions j,
                   juris_tax_impositions ji,
                   tax_outlines tx,
                   tax_definitions td
             WHERE     j.id = ji.jurisdiction_id
                   AND ji.id = tx.juris_tax_imposition_id
                   AND tx.id = td.tax_outline_id
                   AND j.official_name = i.official_name;

            IF vcnt >= 1
            THEN
                UPDATE kpmg_rates
                   SET processed = 'Y'
                 WHERE official_name = i.official_name;

                COMMIT;
            END IF;


            IF vcnt = 0
            THEN
                ROLLBACK;

                UPDATE kpmg_rates
                   SET processed = 'X'
                 WHERE official_name = i.official_name;

                COMMIT;
            --raise_application_error(-20201, 'Taxes were not processed '||i.official_name);
            ELSE
                UPDATE kpmg_rates
                   SET processed = 'Y'
                 WHERE official_name = i.official_name;
            END IF;
        END LOOP;
    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
            DBMS_OUTPUT.put_line ('error occured');
            DBMS_OUTPUT.put_line (DBMS_UTILITY.format_error_backtrace);

            UPDATE kpmg_rates
               SET processed = 'X'
             WHERE official_name = l_official_name;

            COMMIT;
            DBMS_OUTPUT.put_line ('error occured');
            RAISE;
    END;

    FUNCTION getgeoareacategory (categoryname VARCHAR2)
        RETURN NUMBER
    IS
        v_category_code   NUMBER;
    BEGIN
        SELECT id
          INTO v_category_code
          FROM geo_area_categories
         WHERE UPPER (name) = UPPER (categoryname);

        RETURN v_category_code;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN 0;
    END;

    PROCEDURE jurisdiction_tags (tagname VARCHAR2)
    IS
        v_tagid    NUMBER;
        vtag_cnt   NUMBER;
    BEGIN
        SELECT id
          INTO v_tagid
          FROM tags
         WHERE UPPER (name) = UPPER (tagname);


        FOR i IN (SELECT nkid
                  FROM jurisdictions
                  WHERE entered_by = -2918
                    AND entered_date > sysdate-1)
        LOOP
            SELECT COUNT (1)
              INTO vtag_cnt
              FROM jurisdiction_tags
             WHERE ref_nkid = i.nkid AND tag_id = v_tagid;

            IF vtag_cnt = 0
            THEN
                INSERT INTO jurisdiction_tags (ref_nkid,
                                               tag_id,
                                               entered_by,
                                               status)
                VALUES (i.nkid,
                        v_tagid,
                        -2918,
                        0);
            END IF;
        END LOOP;
    END jurisdiction_tags;

    PROCEDURE juris_tax_imposition_tags (tagname VARCHAR2)
    IS
        v_tagid    NUMBER;
        vtag_cnt   NUMBER;
    BEGIN
        SELECT id
          INTO v_tagid
          FROM tags
         WHERE UPPER (name) = UPPER (tagname);

        FOR i IN (SELECT nkid
                  FROM juris_tax_impositions
                  WHERE entered_by = -2918
                    AND entered_date > sysdate-1)
        LOOP
            SELECT COUNT (1)
              INTO vtag_cnt
              FROM juris_tax_imposition_tags
             WHERE ref_nkid = i.nkid AND tag_id = v_tagid;

            IF vtag_cnt = 0
            THEN
                INSERT INTO juris_tax_imposition_tags (ref_nkid,
                                                       tag_id,
                                                       entered_by,
                                                       status)
                VALUES (i.nkid,
                        v_tagid,
                        -2918,
                        0);
            END IF;
        END LOOP;
    END juris_tax_imposition_tags;

    PROCEDURE commodity_tags (tagname VARCHAR2)
    IS
        v_tagid    NUMBER;
        vtag_cnt   NUMBER;
    BEGIN
        SELECT id
          INTO v_tagid
          FROM tags
         WHERE UPPER (name) = UPPER (tagname);

        FOR i IN (SELECT nkid
                  FROM commodities
                  WHERE entered_by = -2918
                    and entered_date > sysdate-1)
        LOOP
            SELECT COUNT (1)
              INTO vtag_cnt
              FROM commodity_tags
             WHERE ref_nkid = i.nkid AND tag_id = v_tagid;

            IF vtag_cnt = 0
            THEN
                INSERT INTO commodity_tags (ref_nkid,
                                            tag_id,
                                            entered_by,
                                            status)
                VALUES (i.nkid,
                        v_tagid,
                        -2918,
                        0);
            END IF;
        END LOOP;
    END commodity_tags;


    PROCEDURE add_tags (tagname_i VARCHAR2)
    IS
    BEGIN
        jurisdiction_tags (tagname_i);
        juris_tax_imposition_tags (tagname_i);
        commodity_tags (tagname_i);
    END;

    PROCEDURE generate_juris_geo_areas (official_name_i VARCHAR2)
    IS
        vpolygon_id     NUMBER;
        varea           VARCHAR2 (100);
        vpolygon_nkid   NUMBER;
        vcnt            NUMBER;
    BEGIN
        FOR j
            IN (SELECT DISTINCT
                       SUBSTR (official_name, 1, 2) state_code, official_name
                FROM kpmg_rates
                WHERE official_name = official_name_i)
        LOOP
            FOR i
                IN (SELECT DISTINCT
                              ''
                           || SUBSTR (k.official_name, 1, 2)
                           || '-'
                           || k.taxboundaryname
                           || ''
                               poly_area,
                           ji.id id,
                           ji.start_date,
                           ji.nkid nkid
                    FROM kpmg_rates k, jurisdictions ji
                    WHERE     k.official_name = j.official_name
                          AND k.official_name = ji.official_name)
            LOOP
                BEGIN
                    DBMS_OUTPUT.put_line (
                           vpolygon_id
                        || '-'
                        || vpolygon_nkid
                        || '-'
                        || i.id
                        || '-'
                        || i.nkid);

                    SELECT id, nkid
                      INTO vpolygon_id, vpolygon_nkid
                      FROM geo_polygons
                     WHERE     UPPER (   SUBSTR (geo_area_key, 1, 2)
                                      || '-'
                                      || SUBSTR (geo_area_key,
                                                   INSTR (geo_area_key,
                                                          '-',
                                                          2,
                                                          2)
                                                 + 1)) = i.poly_area
                           AND ROWNUM = 1;


                    SELECT COUNT (1)
                      INTO vcnt
                      FROM juris_geo_areas
                     WHERE jurisdiction_nkid = i.nkid--and geo_polygon_id = vpolygon_id
                                                     --and geo_polygon_nkid = vpolygon_nkid
                    ;

                    IF vcnt = 0
                    THEN
                        INSERT INTO juris_geo_areas (jurisdiction_id,
                                                     geo_polygon_id,
                                                     jurisdiction_nkid,
                                                     geo_polygon_nkid,
                                                     entered_by,
                                                     status,
                                                     requires_establishment,
                                                     start_date)
                        VALUES (i.id,
                                vpolygon_id,
                                i.nkid,
                                vpolygon_nkid,
                                -2918,
                                0,
                                0,
                                i.start_date);
                    --commit;
                    END IF;
                EXCEPTION
                    WHEN OTHERS
                    THEN
                        vpolygon_id := 10;
                END;
            END LOOP;
        END LOOP;
    END;


    PROCEDURE ins_tax_administrators (administrator_name    VARCHAR2,
                                      tax_id                NUMBER)
    IS
        vtax_admin_id     NUMBER;
        vtax_admin        NUMBER;
        vtax_admin_nkid   NUMBER;
        vtax_id           NUMBER;
        vtax_nkid         NUMBER;
        vstart_date       DATE;
    BEGIN
        SELECT a.id, a.nkid
          INTO vtax_admin_id, vtax_admin_nkid
          FROM administrator_revisions ar, administrators a
         WHERE     a.rid = ar.id
               AND UPPER (a.name) = UPPER (administrator_name)
               AND a.next_rid IS NULL;

        SELECT ji.id, ji.nkid, start_date
          INTO vtax_id, vtax_nkid, vstart_date
          FROM juris_tax_impositions ji
         WHERE id = tax_id;

        SELECT COUNT (1)
          INTO vtax_admin
          FROM tax_administrators
         WHERE juris_tax_imposition_id = vtax_id;

        IF vtax_admin = 0
        THEN
            INSERT INTO tax_administrators (juris_tax_imposition_id,
                                            juris_tax_imposition_nkid,
                                            administrator_id,
                                            administrator_nkid,
                                            entered_by,
                                            status,
                                            start_date)
            VALUES (vtax_id,
                    vtax_nkid,
                    vtax_admin_id,
                    vtax_admin_nkid,
                    -2918,
                    0,
                    vstart_date);
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            NULL;
    END ins_tax_administrators;


Procedure Fix_Duplicate_Taxes(officialname varchar2, state_name varchar2)
is
        v_cnt number :=0;
        vref_prev varchar2(20);
        vref_curr varchar2(20);
        vstate_code varchar2(2);
        vstate_name varchar2(300);

begin
        -- If there is no Jursidictions exists in the system
        -- Just name the authority with tmp_kpmg andperform blind import.

        vstate_name := state_name;
        --vstate_code := getstatecode(vstate_name);

        -- If there are more than one reference_code for the tax_descriptions, then append the name with number

        for i in( select distinct official_name, reference_code from KPMG_RATES k
                        where official_name = officialname
                        -- official_name like '%KPMG'
                        and taxboundarystate = vstate_name
                        and official_name = officialname
                         order by official_name, reference_code
                )
        loop
                vref_curr := null; vref_prev := null; V_CNT := 0;

                for j in( select official_name,
                                             taxtypegroupdesc, taxtypeclassdesc, tax_description_id, reference_code
                                  from KPMG_RATES
                                 where official_name = i.official_name
                                  and reference_code = i.reference_code
                                  and taxboundarystate = vstate_name
                                group by official_name,    taxtypegroupdesc, taxtypeclassdesc,
                                        tax_description_id, reference_code
                                order by reference_code
                                )
                loop
                     --   --dbms_outPUT.PUT_LINE(j.reference_code);
                       vref_curr := j.reference_code;

                            if vref_prev = vref_curr then
                                v_cnt := v_cnt +1;

                                update KPMG_RATES
                                set reference_code = reference_code||'-'||v_cnt
                                where official_name = j.official_name
                                  and taxtypegroupdesc = j.taxtypegroupdesc
                                  and taxtypeclassdesc = j.taxtypeclassdesc
                                  and tax_description_id = j.tax_description_id
                                  and reference_code = j.reference_code
                                  and taxboundarystate = vstate_name;
                         end if;
                        vref_prev := vref_curr;

                end loop;

        null;

        end loop;

end;

END;
/