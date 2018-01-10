CREATE OR REPLACE TRIGGER content_repo."INS_ADMINISTRATOR_TYPES" 
 BEFORE
  INSERT
 ON content_repo.administrator_types
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
:new.id := pk_ADMINISTRATOR_TYPES.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/