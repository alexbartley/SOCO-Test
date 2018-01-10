CREATE OR REPLACE TRIGGER content_repo."INS_CONTACT_USAGES" 
 BEFORE
  INSERT
 ON content_repo.contact_usages
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

:new.id := pk_contact_usages.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/