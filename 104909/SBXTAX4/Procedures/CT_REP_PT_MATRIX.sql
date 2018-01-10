CREATE OR REPLACE PROCEDURE sbxtax4."CT_REP_PT_MATRIX"
   ( taxDataProvider IN VARCHAR2, productGroup IN VARCHAR2, authorityGroup IN VARCHAR2, matrixType IN VARCHAR2, authorityKeyword IN VARCHAR2, filename IN VARCHAR2)
   IS
loggingMessage VARCHAR2(4000);
isBeingAnalyzed NUMBER := 1;
executeMergePtSql VARCHAR2(4000);
executeUpdateSql VARCHAR2(4000);
contentVersion VARCHAR2(100);
productGroupId NUMBER;
ftype UTL_FILE.file_type;
fileLine VARCHAR2(4000);
aIndex NUMBER := 0 ;
updateDefaultPt VARCHAR2(4000);
mergePtStatement VARCHAR2(4000);
tdp_not_supplied EXCEPTION;
too_many_authorities EXCEPTION;
outputHeader VARCHAR2(4000) := 'sortkey,Product Category,Commodity Code,';
--SQL statement for updating N/A Taxability
updateNATaxability VARCHAR2(4000) :=
    'UPDATE pt_temp_matrix
    SET ${authorityColumn} = ''T''
    WHERE ${authorityColumn} IS NULL';
--SQL statements for showing Rate Code Taxability
updateDefaultPtRateCode VARCHAR2(4000) :=
    'UPDATE pt_temp_matrix ptm
    SET ${authorityColumn} = (
        SELECT DISTINCT
            CASE WHEN r.rate_Code IS NOT NULL THEN r.rate_code
            WHEN NVL(r.exempt,''N'') = ''Y'' THEN ''E''
            WHEN NVL(r.no_tax,''N'') = ''Y'' THEN ''N'' END taxability
        FROM tb_rules r
        WHERE r.authority_id = ${authorityId}
        AND r.end_Date IS NULL
        AND NVL(r.is_local,''N'') = ''N''
        AND r.tax_type IS NULL
        AND NOT EXISTS (
            SELECT 1
            FROM tb_rule_qualifiers q
            WHERE r.rule_id = q.rule_id
            )
        AND r.product_category_id IS NULL
        AND r.code IS NULL
        AND r.exempt_reason_Code IS NULL
        )
    WHERE ${authorityColumn} IS NULL';

mergePtStatementRateCode VARCHAR2(3900) :=
    'MERGE INTO pt_temp_matrix
        USING  (
            SELECT CASE WHEN NVL(r.exempt,''N'') = ''Y'' THEN ''E''
                WHEN NVL(r.no_tax,''N'') = ''Y'' THEN ''N''
                ELSE r.rate_Code END taxability, pt.primary_key
            FROM pt_product_taxability pt
            JOIN tb_rules r ON (r.rule_order = pt.rule_order
                AND r.authority_id = pt.authority_id
                AND r.end_date IS NULL
                AND r.tax_type IS NULL)
            WHERE pt.product_group_id = ${productGroupId}
            AND pt.authority_id = ${authorityId}
            AND pt.tax_type IS NULL
            ) auth_pt
        ON (pt_temp_matrix.primary_key = auth_pt.primary_key)
        WHEN MATCHED THEN UPDATE SET ${authorityColumn} = auth_pt.taxability';
/*
--SQL statements for showing "T" (instead of Rate Code) Taxability
updateDefaultPtTE VARCHAR2(4000) :=
    'UPDATE pt_temp_matrix ptm
    SET ${authorityColumn} = (
        SELECT DISTINCT
            CASE WHEN r.rate_Code IS NOT NULL THEN ''T'' ELSE ''E'' END taxability
        FROM tb_rules r
        WHERE r.authority_id = ${authorityId}
        AND r.end_Date IS NULL
        AND NVL(r.is_local,''N'') = ''N''
        AND r.tax_type IS NULL
        AND NOT EXISTS (
            SELECT 1
            FROM tb_rule_qualifiers q
            WHERE r.rule_id = q.rule_id
            )
        AND r.product_category_id IS NULL
        AND r.code IS NULL
        AND r.exempt_reason_Code IS NULL
        )
    WHERE ${authorityColumn} IS NULL';

mergePtStatementTE VARCHAR2(3900) :=
    'MERGE INTO pt_temp_matrix
        USING  (
            SELECT CASE WHEN NVL(r.exempt,''N'') = ''Y'' THEN ''E''
                WHEN NVL(r.no_tax,''N'') = ''Y'' THEN ''E''
                ELSE ''T'' END taxability, pt.primary_key
            FROM pt_product_taxability pt
            JOIN tb_rules r ON (r.rule_order = pt.rule_order AND r.authority_id = pt.authority_id AND r.end_date IS NULL AND r.tax_type IS NULL)
            WHERE pt.product_group_id = ${productGroupId}
            AND pt.tax_type IS NULL
            AND pt.authority_id = ${authorityId}
            ) auth_pt
        ON (pt_temp_matrix.primary_key = auth_pt.primary_key)
        WHEN MATCHED THEN UPDATE SET ${authorityColumn} = auth_pt.taxability';
        */
/**********************/
mergePtRuleExempts VARCHAR2(3900) :=
    'MERGE INTO pt_temp_matrix
        USING  (
            SELECT DISTINCT pt.primary_key
            FROM pt_product_taxability pt
            JOIN tb_rules r ON (
                r.rule_order = pt.rule_order
                AND r.authority_id = pt.authority_id
                AND r.end_date IS NULL
                AND NVL(r.tax_type,''ANY'') = NVL(pt.tax_type,''ANY'')
                AND NVL(r.exempt,''N'') = ''Y''
                )
            WHERE pt.product_group_id = ${productGroupId}
            AND pt.authority_id = ${authorityId}
            ) auth_pt
        ON (pt_temp_matrix.primary_key = auth_pt.primary_key)
        WHEN MATCHED THEN UPDATE SET ${authorityColumn} = ''E''' ;
updatePtCatchallExempts VARCHAR2(3900) :=
    'UPDATE pt_temp_matrix ptm
    SET ${authorityColumn} = ''E''
    WHERE ${authorityColumn} IS NULL
    AND EXISTS (
        SELECT 1
        FROM tb_rules r
        WHERE r.authority_id = ${authorityId}
        AND r.end_Date IS NULL
        AND NVL(r.is_local,''N'') = ''N''
        AND NVL(r.exempt,''N'') = ''Y''
        AND NOT EXISTS (
            SELECT 1
            FROM tb_rule_qualifiers q
            WHERE r.rule_id = q.rule_id
            )
        AND r.product_category_id IS NULL
        AND r.code IS NULL
        )';

BEGIN
    IF (taxDataProvider IS NULL) THEN
        RAISE tdp_not_supplied;
    END IF;



    WHILE (isBeingAnalyzed > 0) LOOP
        SELECT COUNT(*)
        INTO isBeingAnalyzed
        FROM ct_proc_log pl
        WHERE procedure_name = 'CT_ANALYZE_PRODUCT_TAXABILITY'
        AND message like 'Begin analysis%'
        AND NOT EXISTS (
            SELECT 1
            FROM ct_proc_log pl2
            WHERE pl2.procedure_name = pl.procedure_name
            AND (pl2.message LIKE 'End analysis%' OR pl2.message LIKE 'Terminated%')
            AND pl2.execution_Date > pl.execution_date
        );
        --wait 10 seconds
        IF isBeingAnalyzed > 0 THEN
            null; --dbms_lock.sleep(10);
        END IF;
    END LOOP;

    ct_update_report_queue(filename,'WORKING');
    ftype := UTL_FILE.fopen('CT_REPORTS', filename, 'W',32000);
    IF (matrixType = 'RC') THEN
        updateDefaultPt := updateDefaultPtRateCode;
        mergePtStatement := mergePtStatementRateCode;
    ELSE
        updateDefaultPt := updatePtCatchallExempts;
        mergePtStatement := mergePtRuleExempts;
    END IF;
    DELETE FROM pt_temp_authority_Columns;
    DELETE FROM pt_temp_matrix;
    COMMIT;
    SELECT content_version
    INTO contentVersion
    FROM tb_merchants
    WHERE name = taxDataProvider;

    IF productGroup IS NOT NULL AND LENGTH(productGroup) > 1 THEN
        SELECT product_group_id
        INTO productGroupId
        FROM tb_product_Groups
        WHERE name = productGroup;
    END IF;

    IF taxDataProvider LIKE '%US Tax%' AND NVL(authorityGroup,'All States') = 'All States' AND authorityKeyword IS NULL THEN
        productGroupId := NVL(productGroupId,-2); --Set to default US Product Group
        FOR a IN (
            SELECT a.name authority, a.authority_id
            FROM tb_authorities a, tb_merchants m
            WHERE a.merchant_id = m.merchant_id
            AND m.name = taxDataProvider
            AND NVL(a.is_template, 'N') = 'N'
            AND ((
                EXISTS (
                    SELECT 1
                    FROM tb_authority_types
                    WHERE name LIKE 'State Sales/Use'
                    AND authority_type_id = a.authority_type_id
                    )
                AND a.name NOT LIKE 'AK%'
                AND a.name NOT LIKE '%(BRACKET)%'
                AND a.name NOT LIKE '%NAVAJO NATION%'
                AND a.name NOT LIKE '%FEES'
                AND a.name NOT LIKE '%RENTAL%'
                AND a.name NOT LIKE '%EXTENDED%'
                AND a.name NOT LIKE 'SC%CATAWBA%'
                AND a.name NOT LIKE 'AR%ADDITIONAL%'
                AND a.name NOT LIKE 'NM%INC%'
                AND a.name NOT IN ('US - NO TAX STATES','US - UNITED STATES EXPORT')
            ) OR (
                a.name IN (
                    'AK - KENAI, CITY SALES TAX',
                    'AK - KODIAK, CITY SALES TAX',
                    'AK - SITKA, BOROUGH/CITY SALES TAX',
                    'AK - SKAGWAY, CITY SALES TAX',
                    'AK - WASILLA, CITY SALES TAX',
                    'VI - TERRITORY EXCISE TAX',
                    'GU - TERRITORY SALES/USE TAX',
                    'PR - COMMONWEALTH SALES/USE TAX'
                )

            ))
            ORDER BY a.name
        ) LOOP
            aIndex := aIndex+1;
            INSERT INTO pt_temp_authority_Columns (column_name, authority_name)
            VALUES ('AUTHORITY_'||LPAD(aIndex,3,'0'),a.authority);
            COMMIT;
        END LOOP;
    ELSIF taxDataProvider LIKE '%INTL Tax%' AND NVL(authorityGroup,'All Countries') = 'All Countries' THEN
        productGroupId := NVL(productGroupId,-3); --Set to default Harmonized Product Group
        FOR a IN (
            SELECT a.name authority, a.authority_id
            FROM tb_authorities a, tb_merchants m
            WHERE a.merchant_id = m.merchant_id
            AND m.name = taxDataProvider
            AND a.effective_zone_level_id = -1
            AND NVL(a.is_template, 'N') = 'N'
            ORDER BY a.name
        ) LOOP
            aIndex := aIndex+1;
            INSERT INTO pt_temp_authority_Columns (column_name, authority_name)
            VALUES ('AUTHORITY_'||LPAD(aIndex,'0',3),a.authority);
            COMMIT;
        END LOOP;
    ELSIF authorityGroup = 'All Provinces' THEN
        IF contentVersion LIKE '%CANADA%' THEN
            productGroupId := NVL(productGroupId,-1); --Set to default Canada Product Group
        ELSIF contentVersion LIKE '%MTS' THEN
            productGroupId := NVL(productGroupId,-999); --Set to default UNSPSC Product Group
        ELSE
            productGroupId := NVL(productGroupId,-3); --Set to default Harmonized Product Group
        END IF;

        FOR a IN (
            SELECT a.name authority, a.authority_id
            FROM tb_authorities a, tb_merchants m
            WHERE a.merchant_id = m.merchant_id
            AND m.name = taxDataProvider
            AND NVL(a.is_template, 'N') = 'N'
            AND a.effective_zone_level_id = -2
            ORDER BY a.name
        ) LOOP
            aIndex := aIndex+1;
            INSERT INTO pt_temp_authority_Columns (column_name, authority_name)
            VALUES ('AUTHORITY_'||LPAD(aIndex,3,'0'),a.authority);
            COMMIT;
        END LOOP;
    ELSIF authorityGroup = 'EU Countries' THEN
        productGroupId := NVL(productGroupId,-3); --Set to default Harmonized Product Group
        FOR a IN (
			SELECT DISTINCT a.name authority, a.authority_id
			FROM tb_authorities a, ct_zone_authorities za
			WHERE a.merchant_id = (SELECT m.merchant_id FROM tb_merchants m WHERE m.name = taxDataProvider)
			AND a.erp_tax_code NOT LIKE '%HT'
			AND a.name = za.authority_name
			AND za.eu_zone_as_of_date IS NOT NULL
			AND NVL(a.is_template, 'N') = 'N'
			AND a.name != 'No Content'
			AND a.name != 'No VAT'
			ORDER BY a.name
        ) LOOP
            aIndex := aIndex+1;
            INSERT INTO pt_temp_authority_Columns (column_name, authority_name)
            VALUES ('AUTHORITY_'||LPAD(aIndex,3,'0'),a.authority);
            COMMIT;
        END LOOP;


    ELSIF authorityKeyword IS NOT NULL THEN
        IF (taxDataProvider LIKE '% US Tax%') THEN
            productGroupId := NVL(productGroupId,-2); --Set to default US Product Group
        ELSE
            productGroupId := NVL(productGroupId,-3); --Set to default Harmonized Product Group
        END IF;
        FOR a IN (
			SELECT DISTINCT a.name authority, a.authority_id
			FROM tb_authorities a
			WHERE a.merchant_id = (SELECT m.merchant_id FROM tb_merchants m WHERE m.name = taxDataProvider)
			AND a.name LIKE authorityKeyword||'%'
			ORDER BY a.name
        ) LOOP
            aIndex := aIndex+1;
            INSERT INTO pt_temp_authority_Columns (column_name, authority_name)
            VALUES ('AUTHORITY_'||LPAD(aIndex,3,'0'),a.authority);
            COMMIT;
        END LOOP;
    END IF;
    IF aIndex > 200 THEN
        RAISE too_many_authorities;
    END IF;
    INSERT INTO pt_temp_matrix (primary_key) (
        SELECT DISTINCT ts.primary_key
        FROM pt_product_tree_sort ts
        WHERE ts.product_Group_id = productGroupId
        );
    COMMIT;
    FOR ac IN (
        SELECT tac.column_name, tac.authority_name, a.authority_id
        FROM pt_temp_authority_Columns tac, tb_authorities a
        WHERE a.name =tac.authority_name
        ORDER BY column_name
    ) LOOP
        outputHeader := outputHeader||'"'||ac.authority_name||'"'||',';
        executeMergePtSql := replace(replace(replace(mergePtStatement,'${authorityId}',ac.authority_id),'${productGroupId}',productGroupId),'${authorityColumn}',ac.column_name);
        execute immediate executeMergePtSql;
        executeUpdateSql := replace(replace(updateDefaultPt,'${authorityId}',ac.authority_id),'${authorityColumn}',ac.column_name);
        execute immediate executeUpdateSql;
        executeUpdateSql := replace(updateNATaxability,'${authorityColumn}',ac.column_name);
        execute immediate executeUpdateSql;
    END LOOP;
    --

    --UTL_FILE.put_line(ftype, '<table style="white-space:nowrap;text-align:left;">');
    UTL_FILE.put_line(ftype, outputHeader);
    FOR r IN (
        SELECT sort_key, CASE WHEN LENGTH(ps.prodcode) = 2 THEN product_name ELSE LPAD(' ',LENGTH(REPLACE(REPLACE(sort_key,'00000'),'.'))-5,' ')||product_name END product_name, ps.prodcode, tm.*
        FROM pt_temp_matrix tm, pt_product_tree_sort ps
        WHERE tm.primary_key = ps.primary_key
    ) LOOP
        UTL_FILE.put_line(ftype,'"'||r.sort_key||'",'||
        '"'||r.product_name||'",'||
        '="'||r.prodcode||'",'||
        r.AUTHORITY_001||','||
        r.AUTHORITY_002||','||
        r.AUTHORITY_003||','||
        r.AUTHORITY_004||','||
        r.AUTHORITY_005||','||
        r.AUTHORITY_006||','||
        r.AUTHORITY_007||','||
        r.AUTHORITY_008||','||
        r.AUTHORITY_009||','||
        r.AUTHORITY_010||','||
        r.AUTHORITY_011||','||
        r.AUTHORITY_012||','||
        r.AUTHORITY_013||','||
        r.AUTHORITY_014||','||
        r.AUTHORITY_015||','||
        r.AUTHORITY_016||','||
        r.AUTHORITY_017||','||
        r.AUTHORITY_018||','||
        r.AUTHORITY_019||','||
        r.AUTHORITY_020||','||
        r.AUTHORITY_021||','||
        r.AUTHORITY_022||','||
        r.AUTHORITY_023||','||
        r.AUTHORITY_024||','||
        r.AUTHORITY_025||','||
        r.AUTHORITY_026||','||
        r.AUTHORITY_027||','||
        r.AUTHORITY_028||','||
        r.AUTHORITY_029||','||
        r.AUTHORITY_030||','||
        r.AUTHORITY_031||','||
        r.AUTHORITY_032||','||
        r.AUTHORITY_033||','||
        r.AUTHORITY_034||','||
        r.AUTHORITY_035||','||
        r.AUTHORITY_036||','||
        r.AUTHORITY_037||','||
        r.AUTHORITY_038||','||
        r.AUTHORITY_039||','||
        r.AUTHORITY_040||','||
        r.AUTHORITY_041||','||
        r.AUTHORITY_042||','||
        r.AUTHORITY_043||','||
        r.AUTHORITY_044||','||
        r.AUTHORITY_045||','||
        r.AUTHORITY_046||','||
        r.AUTHORITY_047||','||
        r.AUTHORITY_048||','||
        r.AUTHORITY_049||','||
        r.AUTHORITY_050||','||
        r.AUTHORITY_051||','||
        r.AUTHORITY_052||','||
        r.AUTHORITY_053||','||
        r.AUTHORITY_054||','||
        r.AUTHORITY_055||','||
        r.AUTHORITY_056||','||
        r.AUTHORITY_057||','||
        r.AUTHORITY_058||','||
        r.AUTHORITY_059||','||
        r.AUTHORITY_060||','||
        r.AUTHORITY_061||','||
        r.AUTHORITY_062||','||
        r.AUTHORITY_063||','||
        r.AUTHORITY_064||','||
        r.AUTHORITY_065||','||
        r.AUTHORITY_066||','||
        r.AUTHORITY_067||','||
        r.AUTHORITY_068||','||
        r.AUTHORITY_069||','||
        r.AUTHORITY_070||','||
        r.AUTHORITY_071||','||
        r.AUTHORITY_072||','||
        r.AUTHORITY_073||','||
        r.AUTHORITY_074||','||
        r.AUTHORITY_075||','||
        r.AUTHORITY_076||','||
        r.AUTHORITY_077||','||
        r.AUTHORITY_078||','||
        r.AUTHORITY_079||','||
        r.AUTHORITY_080||','||
        r.AUTHORITY_081||','||
        r.AUTHORITY_082||','||
        r.AUTHORITY_083||','||
        r.AUTHORITY_084||','||
        r.AUTHORITY_085||','||
        r.AUTHORITY_086||','||
        r.AUTHORITY_087||','||
        r.AUTHORITY_088||','||
        r.AUTHORITY_089||','||
        r.AUTHORITY_090||','||
        r.AUTHORITY_091||','||
        r.AUTHORITY_092||','||
        r.AUTHORITY_093||','||
        r.AUTHORITY_094||','||
        r.AUTHORITY_095||','||
        r.AUTHORITY_096||','||
        r.AUTHORITY_097||','||
        r.AUTHORITY_098||','||
        r.AUTHORITY_099||','||
        r.AUTHORITY_100||','||
        r.AUTHORITY_101||','||
        r.AUTHORITY_102||','||
        r.AUTHORITY_103||','||
        r.AUTHORITY_104||','||
        r.AUTHORITY_105||','||
        r.AUTHORITY_106||','||
        r.AUTHORITY_107||','||
        r.AUTHORITY_108||','||
        r.AUTHORITY_109||','||
        r.AUTHORITY_110||','||
        r.AUTHORITY_111||','||
        r.AUTHORITY_112||','||
        r.AUTHORITY_113||','||
        r.AUTHORITY_114||','||
        r.AUTHORITY_115||','||
        r.AUTHORITY_116||','||
        r.AUTHORITY_117||','||
        r.AUTHORITY_118||','||
        r.AUTHORITY_119||','||
        r.AUTHORITY_120||','||
        r.AUTHORITY_121||','||
        r.AUTHORITY_122||','||
        r.AUTHORITY_123||','||
        r.AUTHORITY_124||','||
        r.AUTHORITY_125||','||
        r.AUTHORITY_126||','||
        r.AUTHORITY_127||','||
        r.AUTHORITY_128||','||
        r.AUTHORITY_129||','||
        r.AUTHORITY_130||','||
        r.AUTHORITY_131||','||
        r.AUTHORITY_132||','||
        r.AUTHORITY_133||','||
        r.AUTHORITY_134||','||
        r.AUTHORITY_135||','||
        r.AUTHORITY_136||','||
        r.AUTHORITY_137||','||
        r.AUTHORITY_138||','||
        r.AUTHORITY_139||','||
        r.AUTHORITY_140||','||
        r.AUTHORITY_141||','||
        r.AUTHORITY_142||','||
        r.AUTHORITY_143||','||
        r.AUTHORITY_144||','||
        r.AUTHORITY_145||','||
        r.AUTHORITY_146||','||
        r.AUTHORITY_147||','||
        r.AUTHORITY_148||','||
        r.AUTHORITY_149||','||
        r.AUTHORITY_150||','||
        r.AUTHORITY_151||','||
        r.AUTHORITY_152||','||
        r.AUTHORITY_153||','||
        r.AUTHORITY_154||','||
        r.AUTHORITY_155||','||
        r.AUTHORITY_156||','||
        r.AUTHORITY_157||','||
        r.AUTHORITY_158||','||
        r.AUTHORITY_159||','||
        r.AUTHORITY_160||','||
        r.AUTHORITY_161||','||
        r.AUTHORITY_162||','||
        r.AUTHORITY_163||','||
        r.AUTHORITY_164||','||
        r.AUTHORITY_165||','||
        r.AUTHORITY_166||','||
        r.AUTHORITY_167||','||
        r.AUTHORITY_168||','||
        r.AUTHORITY_169||','||
        r.AUTHORITY_170||','||
        r.AUTHORITY_171||','||
        r.AUTHORITY_172||','||
        r.AUTHORITY_173||','||
        r.AUTHORITY_174||','||
        r.AUTHORITY_175||','||
        r.AUTHORITY_176||','||
        r.AUTHORITY_177||','||
        r.AUTHORITY_178||','||
        r.AUTHORITY_179||','||
        r.AUTHORITY_180||','||
        r.AUTHORITY_181||','||
        r.AUTHORITY_182||','||
        r.AUTHORITY_183||','||
        r.AUTHORITY_184||','||
        r.AUTHORITY_185||','||
        r.AUTHORITY_186||','||
        r.AUTHORITY_187||','||
        r.AUTHORITY_188||','||
        r.AUTHORITY_189||','||
        r.AUTHORITY_190||','||
        r.AUTHORITY_191||','||
        r.AUTHORITY_192||','||
        r.AUTHORITY_193||','||
        r.AUTHORITY_194||','||
        r.AUTHORITY_195||','||
        r.AUTHORITY_196||','||
        r.AUTHORITY_197||','||
        r.AUTHORITY_198||','||
        r.AUTHORITY_199||','||
        r.AUTHORITY_200||',');
    END LOOP;

    UTL_FILE.fflush(ftype);
    UTL_FILE.fclose(ftype);

    ct_update_report_queue(filename,'FINISHED');
EXCEPTION
    WHEN tdp_not_supplied THEN
    loggingMessage := 'Tax Data Provider was not supplied';
    INSERT INTO ct_proc_log(procedure_name, execution_date, message)
    VALUES ('CT_REP_PT_MATRIX',SYSDATE,loggingMessage);
    ftype := UTL_FILE.fopen('CT_REPORTS', filename, 'W',32000);
    UTL_FILE.put_line(ftype,'Report did not finish properly because Oracle encountered an error.');
    UTL_FILE.put_line(ftype,loggingMessage);
    UTL_FILE.fflush(ftype);
    UTL_FILE.fclose(ftype);
    ct_update_report_queue(filename,'NEVER HAD A CHANCE');
    WHEN too_many_authorities THEN
    loggingMessage := SQLERRM||':'||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
    INSERT INTO ct_proc_log(procedure_name, execution_date, message)
    VALUES ('CT_REP_PT_MATRIX',SYSDATE,loggingMessage);
    UTL_FILE.fflush(ftype);
    UTL_FILE.fclose(ftype);
    ftype := UTL_FILE.fopen('CT_REPORTS', filename, 'W',32000);
    UTL_FILE.put_line(ftype,'Too many Authorities were returned, the report is limited to 200.');
    UTL_FILE.put_line(ftype,loggingMessage);
    UTL_FILE.fflush(ftype);
    UTL_FILE.fclose(ftype);
    ct_update_report_queue(filename,'NEVER HAD A CHANCE');
    WHEN OTHERS THEN
    loggingMessage := SQLERRM||':'||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
    INSERT INTO ct_proc_log(procedure_name, execution_date, message)
    VALUES ('CT_REP_PT_MATRIX',SYSDATE,loggingMessage);
    UTL_FILE.fflush(ftype);
    UTL_FILE.fclose(ftype);
    ftype := UTL_FILE.fopen('CT_REPORTS', filename, 'W',32000);
    UTL_FILE.put_line(ftype,'Report did not finish properly because Oracle encountered an error.');
    UTL_FILE.put_line(ftype,loggingMessage);
    UTL_FILE.fflush(ftype);
    UTL_FILE.fclose(ftype);
    ct_update_report_queue(filename,'FINISHED BUT FAILED');
END;
 
/