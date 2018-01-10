CREATE OR REPLACE PROCEDURE sbxtax."DATAX_TB_COMPL_AREAS_177" 
(runId IN OUT NUMBER)
is
   --<data_check id="177" name="Check for compliance areas which are not associated with any Compliance Authorities " >

   dataCheckId NUMBER := -799;
   vlocal_step varchar2(100);
   err_num number;
   err_msg varchar2(4000);
begin

    vlocal_step := 'DATAX_TB_COMPL_AREAS_177 STEP 0:';
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_COMPL_AREAS_177 started.',runId) RETURNING run_id INTO runId;
    COMMIT;

    vlocal_step := 'DATAX_TB_COMPL_AREAS_177 STEP 1:';
    -- Checking for orphan compliance area authorities
     INSERT INTO datax_check_output (step_info, primary_key, data_check_id, run_id, creation_date)
    (
        SELECT 'TABLE_NAME: TB_COMP_AREA_AUTHORITIES - No Associated Authorities',
               compliance_area_id,
               datacheckid,
               runid,
               SYSDATE
          FROM (SELECT DISTINCT compliance_area_id
                  FROM tb_compliance_areas tc1
                 WHERE NOT EXISTS
                           (SELECT 1
                              FROM tb_comp_area_authorities tc2
                             WHERE tc1.compliance_area_id = tc2.compliance_area_id)
                MINUS
                SELECT primary_key
                  FROM datax_check_output
                 WHERE data_check_id = -799)
    );

    vlocal_step := 'DATAX_TB_COMPL_AREAS_177 STEP 2:';
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('DATAX_TB_COMPL_AREAS_177 finished.',runId);
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