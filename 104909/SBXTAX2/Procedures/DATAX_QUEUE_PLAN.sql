CREATE OR REPLACE PROCEDURE sbxtax2.datax_queue_plan
   ( planName IN VARCHAR2)
   IS
   activeRunning NUMBER;
   execPlanId NUMBER;
   jobId NUMBER;
BEGIN
    SELECT execution_plan_id
    INTO execPlanId
    FROM datax_execution_plans
    WHERE plan_name = planName;

   SELECT count(*)
   INTO activeRunning
   FROM datax_execution_queue eq
   WHERE eq.execution_plan_id = execPlanId
   AND (eq.status like 'WORKING%' or eq.status like 'QUEUED');

   IF activeRunning = 0 THEN
        INSERT INTO datax_execution_queue(execution_plan_id, status, queued_date, status_update_date)
        VALUES (execPlanId, 'QUEUED', sysdate, sysdate);
        COMMIT;
        DBMS_JOB.SUBMIT(jobId, 'DATAX_RUN_CHECK_SBX_TAXDATA('''||planName||''');', SYSDATE, null);
        COMMIT;
   ELSE
        INSERT INTO datax_execution_queue(execution_plan_id, status, queued_date, status_update_date)
        VALUES (execPlanId, 'IGNORED', sysdate, sysdate);
        COMMIT;
   END IF;


END; -- Procedure
 
 
/