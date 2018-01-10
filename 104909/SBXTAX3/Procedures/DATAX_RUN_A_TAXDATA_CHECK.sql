CREATE OR REPLACE PROCEDURE sbxtax3.datax_run_a_taxdata_check
   ( taxDataProvider IN VARCHAR2, dataCheckName IN VARCHAR2, dataCheckId IN OUT NUMBER)
   IS
   runId NUMBER;
   taxDataProviderId NUMBER;
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

    SELECT merchant_id
    INTO taxDataProviderId
    FROM tb_merchants
    WHERE name = taxDataProvider;

    IF (dataCheckName IS NOT NULL) THEN
        SELECT procedure_name, dataCheckId
        INTO procedureName, dataCheckId
        FROM datax_checks
        WHERE name like dataCheckName||'%';
    ELSE
        SELECT procedure_name
        INTO procedureName
        FROM datax_checks
        WHERE data_check_id = NVL(dataCheckId,0);
    END IF;

    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('Begin DataCheck tests for DATAX_RUN_A_TAXDATA_CHECK(S)',runId);
    callProcedure := procedureName||'('||taxDataProviderId||','||dataCheckId||','||runId||')';
    EXECUTE IMMEDIATE callProcedure;
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('End DataCheck tests for DATAX_RUN_A_TAXDATA_CHECK(S)',runId);
EXCEPTION
        WHEN OTHERS THEN
        INSERT INTO datax_records (recorded_message, run_id)
        VALUES ('End DataCheck...Terminated unnaturally! Error occurred while executing DataCheck tests for DATAX_A_CHECK_SBX_TAXDATA',runId);
        COMMIT;
        errorCode := SQLCODE;
        errorMessage := SQLERRM;
        INSERT INTO datax_records (recorded_message, run_id)
        VALUES (errorCode||':'||SUBSTR(errorMessage, 1, 993),runId);
        COMMIT;
END; -- Procedure
 
 
/