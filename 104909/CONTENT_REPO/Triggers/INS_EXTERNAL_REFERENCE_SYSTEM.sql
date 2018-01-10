CREATE OR REPLACE TRIGGER content_repo."INS_EXTERNAL_REFERENCE_SYSTEM" 
 BEFORE
  INSERT
 ON content_repo.external_reference_system
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
  :new.id := pk_external_reference_system.nextval;
  :new.entered_date := SYSTIMESTAMP;
  :new.status_modified_date := SYSTIMESTAMP;
END;
/