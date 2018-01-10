CREATE OR REPLACE TRIGGER content_repo."INS_GEO_UNIQUE_AREAS" 
 BEFORE
  INSERT
 ON content_repo.geo_unique_areas
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

IF (:new.nkid IS NULL) THEN
    :new.nkid := nkid_geo_unique_areas.nextval;
    :new.id   := pk_geo_unique_areas.nextval;
    :new.rid  := gis.get_area_revision(entity_id_io => :new.id, entity_nkid_i => :new.nkid, entered_by_i => :new.entered_by);
END IF;

:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;

INSERT INTO geo_unique_area_chg_logs (table_name, primary_key, entered_by, rid, entity_id)
VALUES ('GEO_UNIQUE_AREAS', :new.id, :new.entered_by, :new.rid, :new.id);

END;
/