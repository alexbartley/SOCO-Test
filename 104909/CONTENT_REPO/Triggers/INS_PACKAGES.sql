CREATE OR REPLACE TRIGGER content_repo."INS_PACKAGES" 
 BEFORE
  INSERT
 ON content_repo.packages
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

:new.id := pk_packages.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/