CREATE OR REPLACE TRIGGER crapp_admin.LOG_ID_TRIGGER 
                     before insert ON crapp_admin.LOGS
                     for each row
                     begin 
                       Select log_id_seq.nextval
                       into :new.id
                       from dual;
                       :new.entered_date := sysdate;
                     end;
/