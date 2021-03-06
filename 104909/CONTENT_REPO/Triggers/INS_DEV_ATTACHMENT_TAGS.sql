CREATE OR REPLACE TRIGGER content_repo."INS_DEV_ATTACHMENT_TAGS" 
 BEFORE
  INSERT
 ON content_repo.ATTACHMENT_TAGS
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
:new.id := pk_DEV_ATTACHMENT_TAGS.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/