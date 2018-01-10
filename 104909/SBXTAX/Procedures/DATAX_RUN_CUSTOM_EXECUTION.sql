CREATE OR REPLACE PROCEDURE sbxtax."DATAX_RUN_CUSTOM_EXECUTION" (inputString IN VARCHAR2, taxDataProvider IN VARCHAR2)
   IS
   runId NUMBER;
   errorMessage VARCHAR2(1000);
   errorCode VARCHAR2(10);
   procedureName VARCHAR2(50);
   callProcedure VARCHAR2(100);
   taxDataProviderId NUMBER;

    CURSOR custom_queue IS
    SELECT DISTINCT procedure_name, dc.DATA_check_id, re.run_execution_id
    FROM datax_run_executions re, datax_checks dc
    WHERE run_id = runId
    AND re.data_check_id = dc.data_check_id;
BEGIN

    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('Begin validating DataChecks list for custom execution.',runId) RETURNING run_id INTO runId;

    datax_parse_list(inputString,runId);

    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('End validating DataChecks list for custom execution.',runId);

    IF (taxDataProvider IS NOT NULL) THEN
        INSERT INTO datax_records (recorded_message, run_id)
        VALUES ('Validate taxDataProvider for custom execution.',runId);

        SELECT DISTINCT merchant_id
        INTO taxDataProviderId
        FROM tb_merchants m
        WHERE name = taxDataProvider;
    END IF;

    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('Begin DataCheck tests for custom execution.',runId);
    FOR dc IN custom_queue LOOP
        IF dc.data_check_id NOT IN (-711,-716,-749,-755,-758,-759,-623,-639,-746,-787, -790,  -797, -798, -799, -800) THEN
            callProcedure := dc.procedure_name||'('||taxDataProviderId||',runId);';
        ELSE

            callProcedure := dc.procedure_name||'(runId);';
        END IF;
        EXECUTE IMMEDIATE 'declare runId number :='||runId||'; begin '||callProcedure||' end;' ;
        UPDATE datax_run_executions SET execution_date = SYSDATE WHERE run_execution_id = dc.run_execution_id;
        COMMIT;
    END LOOP;

    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('End DataCheck tests for custom execution.',runId);
EXCEPTION
        WHEN OTHERS THEN
        INSERT INTO datax_records (recorded_message, run_id)
        VALUES ('End DataCheck...Terminated unnaturally! Error occurred while executing DataCheck tests for DATAX_RUN_CUSTOM_EXECUTION',runId);
        COMMIT;
        errorCode := SQLCODE;
        errorMessage := SQLERRM;
        INSERT INTO datax_records (recorded_message, run_id)
        VALUES (errorCode||':'||SUBSTR(errorMessage, 1, 993),runId);
        COMMIT;
END; -- Procedure
 
/