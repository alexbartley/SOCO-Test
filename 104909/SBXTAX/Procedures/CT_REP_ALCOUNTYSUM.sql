CREATE OR REPLACE PROCEDURE sbxtax."CT_REP_ALCOUNTYSUM"
   ( filename IN VARCHAR2, countyName IN VARCHAR2)
   IS
    loggingMessage VARCHAR2(4000);
    ftype UTL_FILE.file_type;
    fileLine VARCHAR2(4000);
    merchId NUMBER;
    outputHeader VARCHAR2(4000) :=
    'zone_4_name,zone_5_name,zone_6_name,zone_7_name,authority_name';
BEGIN
    SELECT merchant_id
    INTO merchId
    FROM tb_merchants
    WHERE name = 'Sabrix US Tax Data';
    ct_update_report_queue(filename,'WORKING');
    ftype := UTL_FILE.fopen('CT_REPORTS', filename, 'W');

    UTL_FILE.put_line(ftype, outputHeader);
    FOR r IN (
            SELECT t.zone_4_name, t.zone_5_name, t.zone_6_name, t.zone_7_name, authority_name
            FROM ct_zone_Tree t
            LEFT OUTER JOIN ct_zone_authorities a ON (t.primary_key = COALESCE(a.zone_7_id,a.zone_6_id,a.zone_5_id,a.zone_4_id,a.zone_3_id,a.zone_2_id,a.zone_1_id))
            WHERE t.zone_3_name = 'ALABAMA'
            AND UPPER(t.zone_4_name) LIKE UPPER(countyName)
            AND t.merchant_id = merchId
            ORDER BY t.zone_4_name, t.zone_6_name, t.zone_5_name, t.zone_7_name
        ) LOOP
        fileLine :=
            '"'||r.zone_4_name||'",'||
            '"'||r.zone_5_name||'",'||
            '="'||r.zone_6_name||'",'||
            '="'||r.zone_7_name||'",'||
            '"'||r.authority_name||'",';
        UTL_FILE.put_line(ftype, fileLine);
    END LOOP;
    UTL_FILE.fflush(ftype);
    UTL_FILE.fclose(ftype);
    ct_update_report_queue(filename,'FINISHED');
EXCEPTION WHEN OTHERS THEN
    loggingMessage := SQLERRM||':'||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
    INSERT INTO ct_proc_log(procedure_name, execution_date, message)
    VALUES ('CT_REP_ALCOUNTYSUM',SYSDATE,loggingMessage);
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