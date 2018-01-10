CREATE OR REPLACE PROCEDURE content_repo."UPDATE_MULTIPLE_REC" (ProcessID in number,
 Status in number,
 Entity in number,
 Action in varchar2,
 editId in number,
 retnId in number,
 ProcSection in number) is
 PRAGMA autonomous_transaction;
begin
  -- // Simple insert for now - No error logging
  Insert Into update_multiple_log(process_id, genDate, status, entity, eid, action, mlt_section, primary_key)
  Values(processid
       , sysdate
       , Status
       , Entity
       , editId
       , Case When (Action = 0) Then 'E'
         When (Action = 1) Then 'I'
         When (Action = 2) Then 'U'
         Else 'D' End -- Entries, Insert, Update or Delete
       , ProcSection
       , retnId
       );
  --
    COMMIT;

  -- CRAPP-1775
  -- Non-specified error. It is either success or fail.
  EXCEPTION
  WHEN TIMEOUT_ON_RESOURCE THEN
    errlogger.report_and_stop (SQLCODE,'Update multiple log table is locked');
  WHEN OTHERS THEN
    ROLLBACK;
    errlogger.report_and_stop (SQLCODE,'Inserting update multiple log information failed');

end;
/