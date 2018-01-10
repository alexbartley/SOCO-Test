CREATE OR REPLACE TRIGGER content_repo."INS_ADDITIONAL_ATTRIBUTES" 
 BEFORE
  INSERT
 ON content_repo.additional_attributes
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

:new.id := pk_ADDITIONAL_ATTRIBUTES.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/