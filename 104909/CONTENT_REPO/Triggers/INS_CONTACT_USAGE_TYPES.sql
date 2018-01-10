CREATE OR REPLACE TRIGGER content_repo."INS_CONTACT_USAGE_TYPES" 
 BEFORE
  INSERT
 ON content_repo.contact_usage_types
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

:new.id := pk_contact_usage_types.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/