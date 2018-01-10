CREATE OR REPLACE TRIGGER content_repo."INS_GEO_UPDATE_AREA_LOG" 
 BEFORE
  INSERT
 ON content_repo.geo_update_area_log
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

:new.id := pk_geo_update_area_log.nextval;
:new.status_modified_date := SYSTIMESTAMP;

END;
/