CREATE OR REPLACE PROCEDURE content_repo."IMPL_EXPL_CLEANUP" Is
/*
|| Clean up implicit/explicit build raw data after 6 hours
|| based on execution time
||
*/
    lProcessIdList   numtabletype;
    ntmpavail        Number;
Begin
    Select Count (1)
      Into ntmpavail
      From impl_process_log
     Where processtime < Sysdate - Interval '6' Hour;

    If ntmpavail > 0 Then
        Delete From impl_process_log
         Where processtime < Sysdate - Interval '6' Hour
         returning processid bulk collect into lProcessIdList;

         FORALL ii IN lProcessIdList.FIRST..lProcessIdList.LAST
         DELETE FROM impl_process_levels WHERE process_id = lProcessIdList(ii);

         -- Hack for Commodity data
         -- * the thought was to have this data in the same table
         --   it might be to much data after a while for that table to be fast
         FORALL ii IN lProcessIdList.FIRST..lProcessIdList.LAST
         DELETE FROM impl_comm_data_t WHERE process_id = lProcessIdList(ii);

         -- Extract data for UI changed 7/25/2016
         -- Can be used as reporting table/history but for now the data will be
         -- removed
         FORALL ii IN lProcessIdList.FIRST..lProcessIdList.LAST
         DELETE FROM impl_expl_raw_ds WHERE processid = lProcessIdList(ii);
        commit;--njv
    End If;

  -- CRAPP-3047
  EXCEPTION
  -- Implicit raw data cleanup failed
  WHEN OTHERS THEN
    ROLLBACK;
    errlogger.report_and_stop (SQLCODE,'Implicit raw data cleanup failed');

End;
/