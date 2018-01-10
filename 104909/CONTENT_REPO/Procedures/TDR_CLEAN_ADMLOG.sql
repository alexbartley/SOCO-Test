CREATE OR REPLACE PROCEDURE content_repo.TDR_CLEAN_ADMLOG IS
/*
|| CLR CRAPP_ADMIN LOGS TABLE 
||
*/
  lProcessIdList   numtabletype;
  ntmpavail        Number;

  E_LOGTABLES exception;  
Begin
  ntmpavail:=0;
  -- Crapp_Admin LOGS
  -- Create small set from current log since this table is not indexed or partitioned.
  -- No index on this log table is for a reason; UI performance for inserts.
  Execute Immediate 'Create Table CRAPP_ADMIN.UI_LOG_TMP NOLOGGING 
                     as 
                     (select * from CRAPP_ADMIN.LOGS where entered_date > sysdate - 60)';
  -- Drop the old log table
  Execute immediate 'Drop Table CRAPP_ADMIN.LOGS ';
  -- Rename current smaller table  
  Execute immediate 'Alter table CRAPP_ADMIN.UI_LOG_TMP rename to LOGS';
  -- Add PK
  Execute immediate 'ALTER TABLE CRAPP_ADMIN.LOGS ADD CONSTRAINT crapp_logs_pk PRIMARY KEY (id)';
  -- Add trigger  
  Execute immediate 'CREATE OR REPLACE TRIGGER CRAPP_ADMIN.LOG_ID_TRIGGER 
                     before insert ON CRAPP_ADMIN.LOGS
                     for each row
                     begin 
                       Select log_id_seq.nextval
                       into :new.id
                       from dual;
                       :new.entered_date := sysdate;
                     end;';
  EXCEPTION
  WHEN TIMEOUT_ON_RESOURCE THEN
    content_repo.errlogger.report_and_stop (SQLCODE,'Deleting data timeout');
  WHEN OTHERS THEN
    ROLLBACK;
    content_repo.errlogger.report_and_stop (SQLCODE,'Log table cleanup failed');
End TDR_CLEAN_ADMLOG;
/