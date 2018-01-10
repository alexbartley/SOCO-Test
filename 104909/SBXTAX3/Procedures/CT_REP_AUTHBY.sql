CREATE OR REPLACE PROCEDURE sbxtax3.ct_rep_authby
   ( filename IN VARCHAR2, taxDataProvider IN VARCHAR2, ratecode IN VARCHAR2, keyword IN VARCHAR2, authType IN VARCHAR2, adminLevel IN VARCHAR2, authCategory IN VARCHAR2)
   IS
    loggingMessage VARCHAR2(4000);
    ftype UTL_FILE.file_type;
    fileLine VARCHAR2(4000);
    outputHeader VARCHAR2(4000) := 
    'Authority_Name,Official_Name,Location_Code,Authority_Type,Product_Group,Admin_Level,Authority_Category,Erp_Tax_Code,Registration_Mask';
    authTypeId NUMBER;
    zoneLevelId NUMBER;
BEGIN
    ct_update_report_queue(filename,'WORKING');
    ftype := UTL_FILE.fopen('CT_REPORTS', filename, 'W');
    IF (authType IS NOT NULL )THEN
        SELECT authority_type_id
        INTO authTypeId
        FROM tb_Authority_types aty
        JOIn tb_merchants m on (m.merchant_id = aty.merchant_id and m.name = taxDataProvider)
        WHERE aty.name = authType;
    END IF;
    IF (adminLevel IS NOT NULL )THEN
        SELECT zone_level_id
        INTO zoneLevelId
        FROM tb_zone_levels
        WHERE name = adminLevel;
    END IF;
    UTL_FILE.put_line(ftype, outputHeader);
    FOR r IN (
        SELECT a.name Authority_Name, a.official_name, a.location_Code, aty.name authority_Type, pg.name product_group, az.name admin_level, a.authority_category, a.erp_tax_code, a.registration_mask
        FROM tb_authorities a, tb_merchants m, tb_Zone_levels az, tb_Authority_types aty, tb_product_groups pg
        WHERE a.name LIKE keyword||'%'
        and pg.product_group_id = a.product_group_id
        AND NVL(a.authority_Category,'NULL') LIKE NVL(authCategory,NVL(a.authority_Category,'NULL'))||'%'
        AND a.merchant_id = m.merchant_id
        AND m.name = taxDataProvider
        AND a.authority_type_id = aty.authority_type_id
        AND a.admin_zone_level_id = az.zone_level_id
        AND NVL(authTypeId,a.authority_type_id) = a.authority_type_id
        AND NVL(zoneLevelId,a.admin_zone_level_id) = a.admin_zone_level_id
        AND EXISTS (
            SELECT 1
            FROM tb_rates r
            WHERE r.rate_code LIKE NVL(rateCode,r.rate_code)||'%'
            AND r.authority_id = a.authority_id
            and r.merchant_id = a.merchant_id
            )
        ) LOOP
        fileLine := 
            '"'||r.Authority_Name||'",'||
            '"'||r.official_name||'",'||
            '="'||r.location_code||'",'||
            '"'||r.authority_Type||'",'||
            '"'||r.product_group||'",'||
            '"'||r.admin_level||'",'||
            '"'||r.authority_Category||'",'||
            '"'||r.erp_tax_Code||'",'||
            '"'||r.registration_mask||'",';
        UTL_FILE.put_line(ftype, fileLine);
    END LOOP;
    UTL_FILE.fflush(ftype);
    UTL_FILE.fclose(ftype);
    ct_update_report_queue(filename,'FINISHED');
EXCEPTION WHEN OTHERS THEN
    loggingMessage := SQLERRM||':'||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
    INSERT INTO ct_proc_log(procedure_name, execution_date, message)
    VALUES ('CT_REP_AUTHBY',SYSDATE,loggingMessage);
    UTL_FILE.fflush(ftype);
    UTL_FILE.fclose(ftype);
    ftype := UTL_FILE.fopen('CT_REPORTS', filename, 'W',32000);
    UTL_FILE.put_line(ftype,'Report did not finish properly because Oracle encountered an error.');
    UTL_FILE.put_line(ftype,loggingMessage);
    UTL_FILE.fflush(ftype);
    UTL_FILE.fclose(ftype);
    ct_update_report_queue(filename,'FINISHED BUT FAILED');
END; -- Procedure
 
 
/