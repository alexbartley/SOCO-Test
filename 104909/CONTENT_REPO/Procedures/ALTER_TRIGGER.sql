CREATE OR REPLACE PROCEDURE content_repo."ALTER_TRIGGER" ( trigger_name_i varchar2, status varchar2, owner_i varchar2 )
is
    pragma autonomous_transaction;
    vcnt number;
begin
    select count(1) into vcnt from all_triggers where owner = upper(owner_i) and trigger_name = upper(trigger_name_i);
    if vcnt > 0 then
      execute immediate 'alter trigger '||trigger_name_i||' '||status||'';
    end if;

    EXCEPTION
    -- Unspecified error (no error codes specified for this error. The system oracle error will be reported)
    WHEN OTHERS THEN
      ROLLBACK;
      errlogger.report_and_stop (SQLCODE,'Error changing status of trigger '||trigger_name_i);
end;
/