CREATE OR REPLACE PROCEDURE content_repo."COMMODITY_TREE_EXEC" as
PRAGMA AUTONOMOUS_TRANSACTION;
/*
|| Log table: content_repo.commodity_tree_build_log
||
||
*/
  v_job Number:=0;
  l_running Number:=0;
Begin
  /*
  Add job if not exist for some reason
  */
  Select count(1) into v_job From all_scheduler_jobs
  where job_name='CTREE_BUILD';
  if v_job = 0 then
    --DBMS_OUTPUT.Put_Line( 'Add job for updating commodity tree' );
    DBMS_SCHEDULER.CREATE_JOB(job_name       =>'CONTENT_REPO.CTREE_BUILD',
                                  job_type        =>'PLSQL_BLOCK',
                                  JOB_ACTION      =>'BEGIN content_repo.commodity_tree_build; END;',
                                  start_date      =>SYSDATE,
                                  repeat_interval =>NULL,
                                  end_date        =>NULL,
                                  enabled         =>TRUE,
                                  AUTO_DROP       =>FALSE
                                  );
  end if; -- end add job

  --DBMS_OUTPUT.Put_Line( 'Checking existing job if it is running -->' );

  SELECT CASE WHEN state = 'RUNNING' THEN 1 ELSE 0 END RJ
  into l_running
  FROM all_scheduler_jobs
  WHERE job_name = 'CTREE_BUILD';

  -- Prereq; Content_Repo must have access to be able to run scheduled jobs
  If l_running = 0 then
    --DBMS_OUTPUT.Put_Line( 'Enable and run' );
    dbms_scheduler.ENABLE(name=> 'CTREE_BUILD');
    -- commit_semantics DEFAULT 'STOP_ON_FIRST_ERROR'
    dbms_scheduler.RUN_JOB(job_name=> 'CTREE_BUILD');
  End if;

  -- Dev purposes
  --DBMS_OUTPUT.Put_Line( 'l_running='||l_running );
  Commit;

  -- CRAPP-3047
  EXCEPTION
  -- Unspecified error (no error codes specified for this error. The system oracle error will be reported)
  WHEN OTHERS THEN
    ROLLBACK;
    errlogger.report_and_stop (SQLCODE,'Creating Commodity Tree build process failed');


End COMMODITY_TREE_EXEC;
/