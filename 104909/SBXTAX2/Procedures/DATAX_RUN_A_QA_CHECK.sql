CREATE OR REPLACE PROCEDURE sbxtax2.datax_run_a_qa_check
   (dataCheckName IN VARCHAR2, dataCheckId IN OUT NUMBER)
   IS
   runId NUMBER;
   errorMessage VARCHAR2(1000);
   errorCode VARCHAR2(10);
   procedureName VARCHAR2(50);
   callProcedure VARCHAR2(100);
BEGIN
    SELECT DATAX_run_seq.NEXTVAL
    INTO runId
    FROM dual;

    INSERT INTO datax_run_executions(run_id,data_check_id,plan_name,execution_Date)
    VALUES (runId, dataCheckId, 'CUSTOM',sysdate);
    COMMIT;

    SELECT procedure_name
    INTO procedureName
    FROM datax_checks
    WHERE data_check_id = NVL(dataCheckId,0);


    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('Begin DataCheck tests for DATAX_RUN_A_QA_CHECK(S)',runId);
    callProcedure := procedureName||'('||runId||')';
    EXECUTE IMMEDIATE callProcedure;
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('End DataCheck tests for DATAX_RUN_A_QA_CHECK(S)',runId);
EXCEPTION
        WHEN OTHERS THEN
        INSERT INTO datax_records (recorded_message, run_id)
        VALUES ('End DataCheck...Terminated unnaturally! Error occurred while executing DataCheck tests for DATAX_RUN_A_QA_CHECK',runId);
        COMMIT;
        errorCode := SQLCODE;
        errorMessage := SQLERRM;
        INSERT INTO datax_records (recorded_message, run_id)
        VALUES (errorCode||':'||SUBSTR(errorMessage, 1, 993),runId);
        COMMIT;
END; -- Procedure
 
 
/