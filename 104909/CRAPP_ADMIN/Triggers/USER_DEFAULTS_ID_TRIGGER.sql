CREATE OR REPLACE TRIGGER crapp_admin."USER_DEFAULTS_ID_TRIGGER" 
 BEFORE 
 INSERT
 ON crapp_admin.USER_DEFAULTS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW 
begin
select user_defaults_seq.nextval into :new.id from dual;
end;
/