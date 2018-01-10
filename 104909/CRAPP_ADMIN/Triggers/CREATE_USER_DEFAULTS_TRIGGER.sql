CREATE OR REPLACE TRIGGER crapp_admin."CREATE_USER_DEFAULTS_TRIGGER" 
 AFTER 
 INSERT
 ON crapp_admin.USERS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW 
BEGIN

insert into user_defaults(id, entered_by, entered_date, status, status_modified_date, tag_search, user_id, users_search)
values (user_defaults_seq.NEXTVAL, -1803 , SYSTIMESTAMP, 1, SYSTIMESTAMP, '', :new.id, '');

insert into user_roles(id, user_id, role_id)
values (user_roles_seq.NEXTVAL, :new.id, 'user');
end;
/