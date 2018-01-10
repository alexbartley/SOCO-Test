CREATE OR REPLACE TRIGGER content_repo.INS_GEO_POLY_ATTRIBUTES
 BEFORE 
 INSERT
 ON content_repo.GEO_POLY_ATTRIBUTES
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW 
BEGIN

IF (:new.nkid IS NULL) THEN
    :new.nkid := nkid_geo_poly_attributes.nextval;
    :new.id   := pk_geo_poly_attributes.nextval;
END IF;

:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;

IF (:new.rid IS NULL) THEN
    --:new.rid := gis.get_revision(entity_id_io => :new.id, entity_nkid_i => :new.nkid, entered_by_i => :new.entered_by);
    :new.rid := gis.get_revision(entity_id_io => :new.geo_polygon_id, entity_nkid_i => NULL, entered_by_i => :new.entered_by);
END IF;

INSERT INTO geo_poly_ref_chg_logs (table_name, primary_key, entered_by, rid, entity_id)
VALUES ('GEO_POLY_ATTRIBUTES', :new.id, :new.entered_by, :new.rid, :new.id);

END;
/