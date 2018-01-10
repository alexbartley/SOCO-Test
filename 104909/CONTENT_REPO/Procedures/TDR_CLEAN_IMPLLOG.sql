CREATE OR REPLACE procedure content_repo.TDR_CLEAN_IMPLLOG is
/*
|| CLR IMPL LOG TABLE 
||
*/
  lProcessIdList   numtabletype;
  ntmpavail        Number;

  E_LOGTABLES exception;  
Begin
  -- Implicit Explicit log and temporary data
  ntmpavail:=0;
  Select Count(1)
    Into ntmpavail
    From content_repo.impl_process_log
    Where processtime < Sysdate - Interval '8' Hour;
    DBMS_OUTPUT.Put_Line( 'Impl process log records:'||ntmpavail );  

  If ntmpavail > 0 Then
     Delete From content_repo.impl_process_log
       Where processtime < Sysdate - Interval '8' Hour
       returning processid bulk collect into lProcessIdList;

     FORALL ii IN lProcessIdList.FIRST..lProcessIdList.LAST
     DELETE FROM content_repo.impl_process_levels WHERE process_id = lProcessIdList(ii);
  End If;

  EXCEPTION
  WHEN TIMEOUT_ON_RESOURCE THEN
    content_repo.errlogger.report_and_stop (SQLCODE,'Deleting data timeout');
  WHEN OTHERS THEN
    ROLLBACK;
    content_repo.errlogger.report_and_stop (SQLCODE,'Log table cleanup failed');

End TDR_CLEAN_IMPLLOG;
/