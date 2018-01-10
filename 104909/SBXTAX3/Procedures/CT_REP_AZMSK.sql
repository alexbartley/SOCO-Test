CREATE OR REPLACE PROCEDURE sbxtax3.ct_rep_azmsk
   ( filename IN VARCHAR2, stateCode IN VARCHAR2, keyword IN VARCHAR2)
   IS
    loggingMessage VARCHAR2(4000);
    ftype UTL_FILE.file_type;
    fileLine VARCHAR2(4000);
    outputHeader VARCHAR2(4000) := 
    'Authority_Name,zone_1_name,zone_2_name,zone_3_name,zone_4_name,zone_5_name,zone_6_name,zone_7_name,';

BEGIN
    ct_update_report_queue(filename,'WORKING');
    ftype := UTL_FILE.fopen('CT_REPORTS', filename, 'W');
    --UTL_FILE.put_line(ftype, '<table style="white-space:nowrap;text-align:left;">');
    UTL_FILE.put_line(ftype, outputHeader);
    FOR r IN (
        SELECT authority_name, zone_1_name, zone_2_name, zone_3_name, zone_4_name, zone_5_name, zone_6_name, zone_7_name
        FROM ct_zone_authorities za, tb_merchants m
        WHERE authority_name LIKE stateCode||'%'||keyword||'%'
        AND za.merchant_id = m.merchant_id
        AND m.name = 'Sabrix US Tax Data'
        ) LOOP
        fileLine := 
            '"'||r.Authority_Name||'",'||
            r.zone_1_name||','||
            r.zone_2_name||','||
            r.zone_3_name||','||
            r.zone_4_name||','||
            r.zone_5_name||','||
            '="'||r.zone_6_name||'",'||
            '="'||r.zone_7_name||'",';
        UTL_FILE.put_line(ftype, fileLine);
    END LOOP;
    UTL_FILE.fflush(ftype);
    UTL_FILE.fclose(ftype);
    ct_update_report_queue(filename,'FINISHED');
EXCEPTION WHEN OTHERS THEN
    loggingMessage := SQLERRM||':'||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
    INSERT INTO ct_proc_log(procedure_name, execution_date, message)
    VALUES ('CT_REP_AZMSK',SYSDATE,loggingMessage);
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