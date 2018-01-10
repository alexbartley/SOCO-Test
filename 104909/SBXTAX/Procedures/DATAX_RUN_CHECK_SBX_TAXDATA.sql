CREATE OR REPLACE PROCEDURE sbxtax."DATAX_RUN_CHECK_SBX_TAXDATA"
   ( planName IN VARCHAR2)
   IS
   runId NUMBER;
   taxDataProviderId NUMBER;
   contentVersion VARCHAR2(100);
   errorMessage VARCHAR2(1000);
   errorCode VARCHAR2(10);
   execSql VARCHAR2(100);
   executionPlanId NUMBER;

    CURSOR datax_queue IS
    SELECT procedure_name, c.DATA_check_id
      FROM datax_checks c, datax_planned_checks rp
     WHERE c.data_Check_id = rp.data_Check_id
       AND rp.execution_plan_id = executionPlanId
       AND nvl(c.tax_research_only,'N') !=
         case
           when (select 1 from tb_config where parm_name = 'INSTANCE_NAME' and parm_value = 'Tax Research Production System') = 1 then '1'
           else 'Y'
         end;
BEGIN
    SELECT DATAX_run_seq.NEXTVAL
    INTO runId
    FROM dual;

    SELECT DISTINCT merchant_id, content_version, ep.execution_plan_id
    INTO taxDataProviderId, contentVersion, executionPlanId
    FROM tb_merchants m, datax_execution_plans ep
    WHERE name = ep.param_1_value
    AND ep.param_1_name = 'TaxDataProvider'
    AND ep.plan_name = planName;


    UPDATE datax_execution_queue q
    SET status = 'WORKING'
    WHERE execution_plan_id = executionPlanId
    AND status = 'QUEUED';
    COMMIT;

    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('Begin DataCheck tests for DATAX_RUN_CHECK_SBX_TAXDATA on Plan: '||planName||'('||executionPlanId||')',runId);
    COMMIT;


    dbms_output.put_line('About to execute the process');
    FOR dc IN datax_queue LOOP

        INSERT INTO datax_run_executions(run_id,data_check_id,plan_name,execution_Date,execution_plan_id)
        VALUES ( runId, dc.data_check_id, planName, sysdate,executionPlanId);
        COMMIT;
            --These DataChecks are not restricted by TDP
        IF dc.data_check_id NOT IN (-711,-716,-749,-755,-758,-759,-623,-639,-746,-785,-790, -797, -798, -799, -800) THEN
            execSql  := dc.procedure_name||'('||taxDataProviderId||',runId);';
        ELSE
            execSql  := dc.procedure_name||'(runId);';
        END IF;

        dbms_output.put_line('the executing state is '||execSql);

        EXECUTE IMMEDIATE 'declare runId number :='||runId||'; begin '||execSql||' end;' ;
    END LOOP;

    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('End DataCheck tests for DATAX_RUN_CHECK_SBX_TAXDATA on Plan: '||planName||'('||executionPlanId||')',runId);
    COMMIT;
    UPDATE datax_execution_queue q
    SET status = 'ENDED'
    WHERE execution_plan_id = executionPlanId
    AND status = 'WORKING';
    COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
        INSERT INTO datax_records (recorded_message, run_id)
        VALUES ('End DataCheck...Terminated unnaturally! Error occurred while executing DataCheck tests for DATAX_RUN_CHECK_SBX_TAXDATA on Plan: '||planName||'('||executionPlanId||')',runId);
        COMMIT;
        errorCode := SQLCODE;
        errorMessage := SQLERRM;
        INSERT INTO datax_records (recorded_message, run_id)
        VALUES (errorCode||':'||SUBSTR(errorMessage, 1, 993),runId);
        COMMIT;
        UPDATE datax_execution_queue q
        SET status = 'ENDED'
        WHERE execution_plan_id = executionPlanId
        AND status = 'WORKING';
        COMMIT;

END;
/