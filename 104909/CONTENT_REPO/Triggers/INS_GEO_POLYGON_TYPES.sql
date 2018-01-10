CREATE OR REPLACE TRIGGER content_repo."INS_GEO_POLYGON_TYPES" 
 BEFORE
  INSERT
 ON content_repo.geo_polygon_types
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

:new.id := pk_geo_polygon_types.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;

END;
/