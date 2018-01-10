CREATE OR REPLACE TRIGGER crapp_admin.ACTION_LOG_ID_TRIGGER
 BEFORE 
 INSERT
 ON crapp_admin.ACTION_LOG
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW 
begin 
    select action_log_id_seq.nextval
    into :new.id
    from dual;
    :new.action_start := sysdate;
    :new.action_end := sysdate;
    if :new.status is null
    then
		:new.status := 0;
    end if;
    
    if :new.process_id is null
    then
		:new.process_id := pk_action_log_process_id.nextval;
    end if;
end;
/