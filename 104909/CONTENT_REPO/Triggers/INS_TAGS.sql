CREATE OR REPLACE TRIGGER content_repo."INS_TAGS" 
 BEFORE
  INSERT
 ON content_repo.tags
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

:new.id := pk_tags.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/