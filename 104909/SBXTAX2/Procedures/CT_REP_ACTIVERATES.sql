CREATE OR REPLACE PROCEDURE sbxtax2.CT_REP_ACTIVERATES
   ( filename IN VARCHAR2)
   IS
    loggingMessage VARCHAR2(4000);
    ftype UTL_FILE.file_type;
    fileLine VARCHAR2(4000);
    outputHeader VARCHAR2(4000) := 
    'Authority_Name,Rate,Rate_Type,Description,Start_Date,Threshold';
    authTypeId NUMBER;
    zoneLevelId NUMBER;
BEGIN
    ct_update_report_queue(filename,'WORKING');
    ftype := UTL_FILE.fopen('CT_REPORTS', filename, 'W');

    UTL_FILE.put_line(ftype, outputHeader);
    FOR r IN (
        SELECT a.name authority_name, COALESCE(r.rate,rt.rate,r.flat_fee,rt.flat_fee) rate,
            CASE WHEN r.rate IS NULL AND rt.rate IS NULL AND rt.rate_code IS NULL THEN 'Fee' ELSE 'Rate' END rate_type, r.description,
            r.start_date, nvl(rt.amount_low,0) threshold
        FROM tb_authorities a
        JOIN tb_merchants m ON (a.merchant_id = m.merchant_id)
        JOIN tb_rates r ON (a.authority_id = r.authority_id AND a.merchant_id = r.merchant_id)
        LEFT OUTER JOIN tb_rate_tiers rt ON (rt.rate_id = r.rate_id)
        WHERE a.effective_zone_level_id = -1
        AND m.name = 'Sabrix INTL Tax Data'
        AND r.end_Date IS NULL
        AND COALESCE(r.rate,rt.rate,r.flat_fee,rt.flat_fee) != 0
        ORDER BY a.name,
            CASE WHEN r.rate_code = 'SR' THEN '0'
                WHEN r.rate_Code = 'RR' THEN '1'
                WHEN r.rate_code = 'LR' THEN '2'
                WHEN UPPER(r.description) LIKE 'STANDARD%' THEN '0'
                WHEN UPPER(r.description) LIKE 'REDUCED%' THEN '1'
                ELSE r.rate_code END, rt.amount_low
        ) LOOP
        fileLine := 
            '"'||r.Authority_Name||'",'||
            '"'||r.rate||'",'||
            '"'||r.rate_type||'",'||
            '"'||r.description||'",'||
            '"'||r.start_date||'",'||
            '"'||r.threshold||'",';
        UTL_FILE.put_line(ftype, fileLine);
    END LOOP;
    UTL_FILE.fflush(ftype);
    UTL_FILE.fclose(ftype);
    ct_update_report_queue(filename,'FINISHED');
EXCEPTION WHEN OTHERS THEN
    loggingMessage := SQLERRM||':'||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
    INSERT INTO ct_proc_log(procedure_name, execution_date, message)
    VALUES ('CT_REP_ACTIVERATES',SYSDATE,loggingMessage);
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