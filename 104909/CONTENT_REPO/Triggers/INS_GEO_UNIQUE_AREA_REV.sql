CREATE OR REPLACE TRIGGER content_repo."INS_GEO_UNIQUE_AREA_REV" 
 BEFORE
  INSERT
 ON content_repo.geo_unique_area_revisions
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    IF (:new.nkid IS NULL) THEN
        :new.nkid := nkid_geo_unique_area_rev.nextval;
    END IF;

    :new.id := pk_geo_unique_area_rev.nextval;
    :new.entered_date := SYSTIMESTAMP;
    :new.status_modified_date := SYSTIMESTAMP;
END;
/