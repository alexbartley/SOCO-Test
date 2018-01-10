CREATE OR REPLACE PROCEDURE sbxtax2.datax_purge_output
   ( dataCheckId IN NUMBER, planName IN VARCHAR2, userId IN NUMBER)
   IS
    affected NUMBER := 0;
    message VARCHAR2(250);
    execPlanId NUMBER;
    activeRunningPlan NUMBER;
    activeRunningDC NUMBER;
    vlocal_step varchar2(100);
    err_num number;
    err_msg varchar2(4000);

BEGIN

    vlocal_step := 'DATAX_PURGE_OUTPUT STEP 0';
    SELECT execution_plan_id
    INTO execPlanId
    FROM datax_execution_plans
    WHERE plan_name = planName;

    vlocal_step := 'DATAX_PURGE_OUTPUT STEP 1';
   SELECT count(*)
   INTO activeRunningPlan
   FROM datax_execution_queue eq
   WHERE eq.execution_plan_id = execPlanId
   AND (eq.status like 'WORKING%' or eq.status like 'QUEUED');

    vlocal_step := 'DATAX_PURGE_OUTPUT STEP 2';
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

    vlocal_step := 'DATAX_PURGE_OUTPUT STEP 3';
   IF activeRunningPlan > 0 OR (activeRunningDC > 0 AND dataCheckId IS NOT NULL) THEN
        INSERT INTO datax_records (recorded_message, run_id)
        VALUES ('Cannot purge DataChecks while DataChecks are running.',-1);
        GOTO log_result;
   END IF;

    vlocal_step := 'DATAX_PURGE_OUTPUT STEP 4';
    IF planName IS NULL THEN
        message := 'No planName supplied.';
        GOTO log_result;
    END IF;

    vlocal_step := 'DATAX_PURGE_OUTPUT STEP 5';
    INSERT INTO datax_records (recorded_message, run_id)
    VALUES ('Purging unapproved results for '||planName||'.',-1);

    vlocal_step := 'DATAX_PURGE_OUTPUT STEP 6';
    IF (dataCheckId IS NULL) THEN
    message := '.';

       vlocal_step := 'DATAX_PURGE_OUTPUT STEP 6';
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

       /*
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
       */

   ELSE
    message := ', DataCheck '||dataCheckId||'.';

       vlocal_step := 'DATAX_PURGE_OUTPUT STEP 7';
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

       /*
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
       */

    END IF;

    vlocal_step := 'DATAX_PURGE_OUTPUT STEP 8';
    message := 'User: '||userId||' deleted '||affected||' output results for '||planName||message;

    <<log_result>>
    BEGIN
        vlocal_step := 'DATAX_PURGE_OUTPUT STEP 9';
        INSERT INTO datax_records (recorded_message, run_id)
        VALUES (message,-1);
    END;

EXCEPTION
WHEN OTHERS THEN
      ROLLBACK;
      err_num := SQLCODE;
      err_msg := SUBSTR(SQLERRM, 1, 4000);

    INSERT INTO data_check_err_log(dataCheckId, errcode, errmsg, step_number, entered_date, entered_by)
    VALUES( nvl(datacheckid,-1), err_num, err_msg, vlocal_step, SYSDATE, -1);
    COMMIT;

END; -- Procedure
 
 
/