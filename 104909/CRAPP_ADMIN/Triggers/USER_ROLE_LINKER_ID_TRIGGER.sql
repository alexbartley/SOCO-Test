CREATE OR REPLACE TRIGGER crapp_admin."USER_ROLE_LINKER_ID_TRIGGER" 
 BEFORE 
 INSERT
 ON crapp_admin.USER_ROLES
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW 
begin
select user_roles_seq.nextval into :new.id from dual;
end;
/