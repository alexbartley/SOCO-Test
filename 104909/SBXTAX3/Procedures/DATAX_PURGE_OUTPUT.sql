CREATE OR REPLACE PROCEDURE sbxtax3.datax_purge_output
   ( dataCheckId IN NUMBER, planName IN VARCHAR2, userId IN NUMBER)
   IS
    affected NUMBER := 0;
    message VARCHAR2(250);
    execPlanId NUMBER;
    activeRunningPlan NUMBER;
    activeRunningDC NUMBER;
BEGIN
    SELECT execution_plan_id
    INTO execPlanId
    FROM datax_execution_plans
    WHERE plan_name = planName;
    
   SELECT count(*)
   INTO activeRunningPlan
   FROM datax_execution_queue eq
   WHERE eq.execution_plan_id = execPlanId
   AND (eq.status like 'WORKING%' or eq.status like 'QUEUED');
   
    SELECT COUNT(*)
    INTO activeRunningDC
    FROM datax_records r, datax_run_executions re
    WHERE r.run_id = re.run_id
    AND recorded_message LIKE '% started%'
    AND re.execution_date > sysdate-2                            
    AND re.data_check_id = dataCheckId                                   
    AND NOT EXISTS (
        SELECT 1
        FROM datax_records r2, datax_run_executions re2
        WHERE r2.run_id = r.run_id
        AND r2.recorded_message LIKE '% finished%'
        AND re2.data_check_id = re.data_Check_id
        );
   
   IF activeRunningPlan > 0 OR (activeRunningDC > 0 AND dataCheckId IS NOT NULL) THEN
        INSERT INTO datax_records (recorded_message, run_id)
        VALUES ('Cannot purge DataChecks while DataChecks are running.',-1);
        GOTO log_result;   
   END IF;
   
    IF planName IS NULL THEN
        message := 'No planName supplied.';
        GOTO log_result;
    END IF;

    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('Purging unapproved results for '||planName||'.',-1);
    
    IF (dataCheckId IS NULL) THEN
    message := '.';
       DELETE FROM datax_check_output dco
       WHERE verified IS NULL
       AND EXISTS (
        SELECT 1
        FROM datax_run_Executions re
        WHERE run_id = dco.run_id
        AND (re.plan_name = planName OR re.plan_name like '%CUSTOM%')
        );
        affected := SQL%ROWCOUNT;
       COMMIT;

       DELETE FROM datax_check_misc_output dco
       WHERE data_check_id = dataCheckId
       AND EXISTS (
        SELECT 1
        FROM datax_run_Executions re
        WHERE run_id = dco.run_id
        AND (re.plan_name = planName OR re.plan_name like '%CUSTOM%')
        );
        affected := SQL%ROWCOUNT;
       COMMIT;

   ELSE
    message := ', DataCheck '||dataCheckId||'.';
       DELETE FROM datax_check_output dco
       WHERE data_check_id = dataCheckId
       AND EXISTS (
        SELECT 1
        FROM datax_run_Executions re
        WHERE run_id = dco.run_id
        AND (re.plan_name = planName OR re.plan_name like '%CUSTOM%')
        );
        affected := SQL%ROWCOUNT;
       COMMIT;

       DELETE FROM datax_check_misc_output dco
       WHERE data_check_id = dataCheckId
       AND EXISTS (
        SELECT 1
        FROM datax_run_Executions re
        WHERE run_id = dco.run_id
        AND (re.plan_name = planName OR re.plan_name like '%CUSTOM%')
        );
        affected := SQL%ROWCOUNT;
       COMMIT;

    END IF;
    message := 'User: '||userId||' deleted '||affected||' output results for '||planName||message;

    <<log_result>>
    BEGIN
        INSERT INTO datax_records (recorded_message, run_id)
        VALUES (message,-1);
    END;
END; -- Procedure
 
 
/