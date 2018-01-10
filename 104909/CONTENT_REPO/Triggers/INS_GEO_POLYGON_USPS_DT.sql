CREATE OR REPLACE TRIGGER content_repo.ins_geo_polygon_usps_dt
 BEFORE
  INSERT
 ON content_repo.geo_polygon_usps
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

    :new.id := pk_geo_polygon_usps.nextval;
    :new.entered_date := SYSTIMESTAMP;
    :new.status_modified_date := SYSTIMESTAMP;

	-- crapp-2532 --
	:new.county_name := REPLACE(UPPER(:new.county_name),CHR(39),'');  -- crapp-3854, removing apostrophes
	:new.city_name   := REPLACE(UPPER(:new.city_name),CHR(39),'');    -- crapp-3854, removing apostrophes

END;
/