CREATE OR REPLACE TRIGGER content_repo."IMPL_PROCESS_LOG_TI"
       before insert on content_repo.impl_process_log
      for each row
  Begin
      select impl_process_pk.nextval
        into :new.processId
        from dual;
  End;
/