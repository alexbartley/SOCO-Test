CREATE OR REPLACE TRIGGER content_repo."INS_ADMINISTRATOR_CONTACTS" 
 BEFORE
  INSERT
 ON content_repo.administrator_contacts
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

:new.id := pk_administrator_contacts.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/