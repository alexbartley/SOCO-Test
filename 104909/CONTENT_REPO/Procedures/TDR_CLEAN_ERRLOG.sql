CREATE OR REPLACE Procedure content_repo.tdr_clean_errlog IS
/*
|| CLR ERR LOG TABLE 
||
*/
  lProcessIdList   numtabletype;
  ntmpavail        Number;

  E_LOGTABLES exception;  
Begin

  -- ERRLOG +60 days
  ntmpavail:=0;
  Select Count(1)
    Into ntmpavail
    From content_repo.errlog
    Where entered_date < Sysdate - 60 ;
    DBMS_OUTPUT.Put_Line( 'Errlog records:'||ntmpavail );  

  If ntmpavail > 0 Then
     Delete From content_repo.errlog
       Where entered_date < Sysdate - 60 ;
  End If;

  EXCEPTION
  WHEN TIMEOUT_ON_RESOURCE THEN
    content_repo.errlogger.report_and_stop (SQLCODE,'Deleting data timeout');
  WHEN OTHERS THEN
    ROLLBACK;
    content_repo.errlogger.report_and_stop (SQLCODE,'Log table cleanup failed');

END tdr_clean_errlog;
/