CREATE OR REPLACE TRIGGER content_repo."INS_LOCATION_CATEGORIES" 
 BEFORE
  INSERT
 ON content_repo.location_categories
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

:new.id := pk_LOCATION_CATEGORIES.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;

END;
/