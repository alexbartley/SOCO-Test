CREATE OR REPLACE TRIGGER content_repo."INS_LOCATION_HIERARCHIES" 
 BEFORE
  INSERT
 ON content_repo.location_hierarchies
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

:new.id := pk_LOCATION_HIERARCHIES.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
END;
/