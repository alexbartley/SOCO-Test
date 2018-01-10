CREATE OR REPLACE PROCEDURE sbxtax3.datax_run_check_sbx_qa
   IS
   runId NUMBER;
   errorMessage VARCHAR2(1000);
   errorCode VARCHAR2(10);
BEGIN
    SELECT DATAX_run_seq.NEXTVAL
    INTO runId
    FROM dual;

    INSERT INTO datax_run_executions(run_id,data_check_id,plan_name,execution_Date) (
    SELECT runId, data_check_id, 'QA',sysdate
    FROM datax_checks
    WHERE category = 'QA'
    );
    COMMIT;

    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('Begin DataCheck tests for DATAX_RUN_CHECK_SBX_QA',runId);
    COMMIT;

    DATAX_TB_AUTHORITIES_160(runId);
    DATAX_TB_ZONES_06(runId);
    DATAX_TB_RATES_05(runId);
    DATAX_TB_ALGX_33(runId);
    DATAX_TB_ZONES_74(runId);
    DATAX_TB_ZONE_AUTH_32(runId);
    DATAX_TB_RATE_TIERS_85(runId);
    DATAX_ANY_98(runId);


    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('End DataCheck tests for DATAX_RUN_CHECK_SBX_QA',runId);

EXCEPTION
        WHEN OTHERS THEN
        INSERT INTO datax_records (recorded_message, run_id)
        VALUES ('End DataCheck...Terminated unnaturally! Error occurred while executing DataCheck tests for DATAX_RUN_CHECK_SBX_TAXDATA',runId);
        COMMIT;
        errorCode := SQLCODE;
        errorMessage := SQLERRM;
        INSERT INTO datax_records (recorded_message, run_id)
        VALUES (errorCode||':'||SUBSTR(errorMessage, 1, 993),runId);
        COMMIT;

END;
/