CREATE OR REPLACE PROCEDURE sbxtax4."CT_REP_NEWPRODS"
   ( filename IN VARCHAR2, taxDataProvider IN VARCHAR2, creationDate IN VARCHAR2)
   IS
    loggingMessage VARCHAR2(4000);
    ftype UTL_FILE.file_type;
    fileLine VARCHAR2(4000);
    outputHeader VARCHAR2(4000) :=
    'commodity_code,product_1_name,product_2_name,product_3_name,product_4_name,product_5_name,product_6_name,product_7_name,product_8_name,product_9_name,';

BEGIN
    ct_update_report_queue(filename,'WORKING');
    ftype := UTL_FILE.fopen('CT_REPORTS', filename, 'W');
    --UTL_FILE.put_line(ftype, '<table style="white-space:nowrap;text-align:left;">');
    UTL_FILE.put_line(ftype, outputHeader);
    FOR r IN (
        SELECT pc.prodcode Commodity_Code, product_1_name, product_2_name, product_3_name, product_4_name, product_5_name, product_6_name, product_7_name, product_8_name, product_9_name
        FROM ct_product_tree pt, tb_merchants m, tb_product_categories pc
        WHERE m.name = taxDataProvider
        AND pc.creation_Date >= creationDate
        AND m.merchant_id = pt.merchant_id
        AND pc.merchant_id = m.merchant_id
        AND pc.product_category_id = pt.primary_key
        ) LOOP
        fileLine :=
            '="'||r.Commodity_Code||'",'||
            '"'||r.product_1_name||'",'||
            '"'||r.product_2_name||'",'||
            '"'||r.product_3_name||'",'||
            '"'||r.product_4_name||'",'||
            '"'||r.product_5_name||'",'||
            '"'||r.product_6_name||'",'||
            '"'||r.product_7_name||'",'||
            '"'||r.product_8_name||'",'||
            '"'||r.product_9_name||'",';
        UTL_FILE.put_line(ftype, fileLine);
    END LOOP;
    UTL_FILE.fflush(ftype);
    UTL_FILE.fclose(ftype);
    ct_update_report_queue(filename,'FINISHED');
EXCEPTION WHEN OTHERS THEN
    loggingMessage := SQLERRM||':'||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
    INSERT INTO ct_proc_log(procedure_name, execution_date, message)
    VALUES ('CT_REP_NEWPRODS',SYSDATE,loggingMessage);
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