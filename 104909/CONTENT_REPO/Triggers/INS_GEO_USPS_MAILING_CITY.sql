CREATE OR REPLACE TRIGGER content_repo.ins_geo_usps_mailing_city
 BEFORE
  INSERT
 ON content_repo.geo_usps_mailing_city
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

    -- crapp-3854 -- removing apostrophes
    :new.county_name := REPLACE(UPPER(:new.county_name), CHR(39),'');
    :new.city_name   := REPLACE(UPPER(:new.city_name), CHR(39),'');

END;
/