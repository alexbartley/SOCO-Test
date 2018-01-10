CREATE OR REPLACE TRIGGER crapp_admin."LOG_LOGIN_ID_TRIGGER" 
 BEFORE
  INSERT
 ON crapp_admin.LOG_LOGIN
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
begin 
    select log_login_id_seq.nextval
    into :new.id
    from dual;
    :new.entered_date := sysdate;
end;
/