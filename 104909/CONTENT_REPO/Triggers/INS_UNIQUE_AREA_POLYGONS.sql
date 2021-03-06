CREATE OR REPLACE TRIGGER content_repo."INS_UNIQUE_AREA_POLYGONS" 
 BEFORE
  INSERT
 ON content_repo.unique_area_polygons
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

:new.id := pk_unique_area_polygons.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;

END;
/