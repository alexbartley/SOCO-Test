CREATE OR REPLACE TRIGGER content_repo."INS_SPECIFIC_APP_TYPES" 
 BEFORE
  INSERT
 ON content_repo.specific_applicability_types
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
:new.id := pk_SPECIFIC_APP_TYPES.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/