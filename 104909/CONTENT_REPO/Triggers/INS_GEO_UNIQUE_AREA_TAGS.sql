CREATE OR REPLACE TRIGGER content_repo.ins_geo_unique_area_tags
 BEFORE
  INSERT
 ON content_repo.geo_unique_area_tags
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

    :new.id := pk_geo_unique_area_tags.nextval;
    :new.entered_date := SYSTIMESTAMP;
    :new.status_modified_date := SYSTIMESTAMP;

END;
/