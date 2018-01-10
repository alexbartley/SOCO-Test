CREATE OR REPLACE PROCEDURE sbxtax."CT_REP_COMBINED_RATES"
   ( filename IN VARCHAR2, taxDataProvider IN VARCHAR2, state IN VARCHAR2, effectiveDate IN VARCHAR2, rate_min IN VARCHAR2, rate_max IN VARCHAR2)
   IS
    loggingMessage VARCHAR2(4000);
    ftype UTL_FILE.file_type;
    fileLine VARCHAR2(4000);
    stateCode VARCHAR2(2) := state;
    outputHeader VARCHAR2(4000) :=
    'State,County,City,Zip,Plus4,Rate,';
BEGIN
    ct_update_report_queue(filename,'WORKING');
    ftype := UTL_FILE.fopen('CT_REPORTS', filename, 'W');
    ct_analyze_combined_rates(taxDataProvider, effectiveDate);

    UTL_FILE.put_line(ftype, outputHeader);
    FOR r IN (
        SELECT state, county, city, zip, plus4, rate
        FROM ct_combined_rates cr, tb_states s
        WHERE cr.state = s.name
        AND s.code = NVL(stateCode,s.code)
        AND cr.rate >= rate_min
        AND cr.rate <= rate_max
        ) LOOP
        fileLine :=
            '"'||r.state||'",'||
            '"'||r.county||'",'||
            '"'||r.city||'",'||
            '"'||r.zip||'",'||
            '"'||r.plus4||'",'||
            '"'||r.rate||'",';
        UTL_FILE.put_line(ftype, fileLine);
    END LOOP;
    UTL_FILE.fflush(ftype);
    UTL_FILE.fclose(ftype);
    ct_update_report_queue(filename,'FINISHED');
EXCEPTION WHEN OTHERS THEN
    loggingMessage := SQLERRM||':'||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
    INSERT INTO ct_proc_log(procedure_name, execution_date, message)
    VALUES ('CT_REP_COMBINED_RATES',SYSDATE,loggingMessage);
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