CREATE OR REPLACE PROCEDURE sbxtax."DATAX_TB_COMPL_AREAS_175" 
(runId IN OUT NUMBER)
is
   --<data_check id="175" name="Check for invalid date ranges - 1) No older than 1900 2) End date should not lesser than start date" >
   dataCheckId NUMBER := -797;
   vlocal_step varchar2(100);
   err_num number;
   err_msg varchar2(4000);
begin

    vlocal_step := 'DATAX_TB_COMPL_AREAS_175 STEP 0:';
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_COMPL_AREAS_175 started.',runId) RETURNING run_id INTO runId;
    COMMIT;

    vlocal_step := 'DATAX_TB_COMPL_AREAS_175 STEP 1:';
    -- Checking for old dated dates and end date overlapping
    INSERT INTO datax_check_output (step_info, primary_key, data_check_id, run_id, creation_date)
    (
            SELECT vlocal_step || 'TB_COMPLIANCE_AREAS Incorrect Date Range',
                   compliance_area_id,
                   datacheckid,
                   runid,
                   SYSDATE
              FROM (SELECT DISTINCT compliance_area_id
                      FROM tb_compliance_areas tca
                     WHERE (   start_date < '01-Jan-1900'
                            OR NVL (end_date, '31-dec-9999') < start_date
                            OR NVL (end_date, '31-dec-9999') < '01-Jan-1900')
                    MINUS
                    SELECT primary_key
                      FROM datax_check_output
                     WHERE data_check_id = -797)
    );

    vlocal_step := 'DATAX_TB_COMPL_AREAS_175 STEP 2:';
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_COMPL_AREAS_175 finished.',runId);
    COMMIT;

EXCEPTION
WHEN OTHERS THEN
      ROLLBACK;
      err_num := SQLCODE;
      err_msg := SUBSTR(SQLERRM, 1, 4000);

    INSERT INTO data_check_err_log(dataCheckId, runId, errcode, errmsg, step_number, entered_date, entered_by)
    VALUES( dataCheckId, runId, err_num, err_msg, vlocal_step, SYSDATE, -1);
    COMMIT;
END;
 
/