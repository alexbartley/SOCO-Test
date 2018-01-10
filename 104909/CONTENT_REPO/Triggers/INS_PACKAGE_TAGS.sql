CREATE OR REPLACE TRIGGER content_repo."INS_PACKAGE_TAGS" 
 BEFORE
  INSERT
 ON content_repo.package_tags
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

:new.id := pk_packaging_tags.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/