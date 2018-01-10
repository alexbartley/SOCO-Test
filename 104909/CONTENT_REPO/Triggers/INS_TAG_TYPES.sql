CREATE OR REPLACE TRIGGER content_repo."INS_TAG_TYPES" 
 BEFORE
  INSERT
 ON content_repo.tag_types
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
:new.id := pk_TAG_TYPES.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/