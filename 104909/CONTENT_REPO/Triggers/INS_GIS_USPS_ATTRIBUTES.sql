CREATE OR REPLACE TRIGGER content_repo."INS_GIS_USPS_ATTRIBUTES" 
 BEFORE
  INSERT
 ON content_repo.gis_usps_attributes
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

:new.id := pk_gis_usps_attributes.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;

END;
/