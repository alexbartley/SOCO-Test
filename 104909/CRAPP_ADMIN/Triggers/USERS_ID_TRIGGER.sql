CREATE OR REPLACE TRIGGER crapp_admin."USERS_ID_TRIGGER" 
before insert on crapp_admin.users
for each row
begin
select users_seq.nextval into :new.id from dual;
end;
/