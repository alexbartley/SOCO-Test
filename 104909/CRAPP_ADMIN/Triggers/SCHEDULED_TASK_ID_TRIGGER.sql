CREATE OR REPLACE TRIGGER crapp_admin."SCHEDULED_TASK_ID_TRIGGER" 
 BEFORE
 INSERT
 ON crapp_admin.SCHEDULED_TASK
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
begin
select scheduled_task_seq.nextval into :new.id from dual;
end;
/