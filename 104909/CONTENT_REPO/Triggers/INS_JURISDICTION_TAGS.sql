CREATE OR REPLACE TRIGGER content_repo."INS_JURISDICTION_TAGS" 
 BEFORE
  INSERT
 ON content_repo.jurisdiction_tags
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

:new.id := pk_jurisdiction_tags.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/