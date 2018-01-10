CREATE OR REPLACE PROCEDURE sbxtax3.ct_rep_rateby
   ( filename IN VARCHAR2, taxDataProvider IN VARCHAR2, ratecode IN VARCHAR2, keyword IN VARCHAR2, authType IN VARCHAR2, adminLevel IN VARCHAR2, authCategory IN VARCHAR2, rateDate IN DATE)
   IS
    loggingMessage VARCHAR2(4000);
    ftype UTL_FILE.file_type;
    fileLine VARCHAR2(4000);
    outputHeader VARCHAR2(4000) := 
    'Authority_Name,Authority_Type,Admin_Level,Authority_Category,Rate_Code, Start_Date, End_Date, Rate_type, Rate, Threshold, Tier_Rate_Code';
    authTypeId NUMBER;
    zoneLevelId NUMBER;
BEGIN
    ct_update_report_queue(filename,'WORKING');
    ftype := UTL_FILE.fopen('CT_REPORTS', filename, 'W');
    IF (authType IS NOT NULL )THEN
        SELECT authority_type_id
        INTO authTypeId
        FROM tb_Authority_types aty, tb_merchants m
        WHERE m.merchant_id = aty.merchant_id
        AND m.name = taxDataProvider
        AND aty.name = authType;
    END IF;
    IF (adminLevel IS NOT NULL)THEN
        SELECT zone_level_id
        INTO zoneLevelId
        FROM tb_zone_levels
        WHERE name = adminLevel;
    END IF;
    UTL_FILE.put_line(ftype, outputHeader);
    FOR r IN (
        SELECT a.name Authority_Name, aty.name authority_Type, az.name admin_level, a.authority_category, r.rate_code, r.start_date, r.end_date,
            CASE WHEN NVL(r.flat_fee,0) > 0 THEN 'FEE' WHEN rt.rate_id IS NOT NULL THEN 'TIER/GRAD' ELSE 'RATE' END rate_type, NVL(r.rate,rt.rate) rate, NVL(rt.amount_low,0) threshold, 
            CASE WHEN NVL(r.rate,rt.rate) IS NULL THEN rt.rate_Code END tier_rate_Code
        FROM tb_merchants m
        JOIN tb_authorities a ON (a.merchant_id = m.merchant_id)
        JOIN tb_Zone_levels az ON (a.admin_zone_level_id = az.zone_level_id)
        JOIN tb_Authority_types aty ON (a.authority_type_id = aty.authority_type_id)
        JOIN tb_Rates r ON (r.authority_id = a.authority_id AND r.merchant_id = a.merchant_id)
        LEFT OUTER JOIN tb_rate_tiers rt ON(r.rate_id = rt.rate_id)
        WHERE a.name LIKE keyword||'%'
        AND NVL(a.authority_Category,'NULL') LIKE NVL(authCategory,NVL(a.authority_Category,'NULL'))||'%'
        AND m.name = taxDataProvider
        AND NVL(authTypeId,a.authority_type_id) = a.authority_type_id
        AND NVL(zoneLevelId,a.admin_zone_level_id) = a.admin_zone_level_id
        AND r.rate_code LIKE NVL(rateCode,r.rate_code)||'%'
        AND COALESCE(r.end_Date,TO_DATE(rateDate),SYSDATE+1) >= NVL(rateDate,SYSDATE)
        ) LOOP
        --'Authority_Name,Authority_Type,Admin_Level,Authority_Category,Rate_Code, Start_Date, Rate_type, Rate, Threshold, Tier_Rate_Code';
        fileLine := 
            '"'||r.Authority_Name||'",'||
            '"'||r.authority_Type||'",'||
            '"'||r.admin_level||'",'||
            '"'||r.authority_Category||'",'||
            '"'||r.rate_code||'",'||
            '"'||r.start_date||'",'||
            '"'||r.end_date||'",'||
            '"'||r.rate_type||'",'||
            '"'||r.rate||'",'||
            '"'||r.threshold||'",'||
            '"'||r.tier_rate_code||'",';
        UTL_FILE.put_line(ftype, fileLine);
    END LOOP;
    UTL_FILE.fflush(ftype);
    UTL_FILE.fclose(ftype);
    ct_update_report_queue(filename,'FINISHED');
EXCEPTION WHEN OTHERS THEN
    loggingMessage := SQLERRM||':'||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
    INSERT INTO ct_proc_log(procedure_name, execution_date, message)
    VALUES ('CT_REP_RATEBY',SYSDATE,loggingMessage);
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