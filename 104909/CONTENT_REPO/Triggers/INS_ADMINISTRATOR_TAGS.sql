CREATE OR REPLACE TRIGGER content_repo."INS_ADMINISTRATOR_TAGS" 
 BEFORE
  INSERT
 ON content_repo.administrator_tags
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

:new.id := pk_administrator_tags.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/