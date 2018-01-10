CREATE OR REPLACE TRIGGER content_repo.ins_geo_polygons
 BEFORE
  INSERT
 ON content_repo.geo_polygons
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

    IF (:new.nkid IS NULL) THEN
        :new.nkid := nkid_geo_polygons.nextval;
        :new.id   := pk_geo_polygons.nextval;
        :new.rid  := gis.get_revision(entity_id_io => :new.id, entity_nkid_i => :new.nkid, entered_by_i => :new.entered_by);
    END IF;

    -- 11/02/15 crapp-2145
    IF (:new.start_date IS NULL) THEN
        :new.start_date := TO_DATE('01/01/2000', 'mm/dd/yyyy');
    END IF;

    :new.entered_date := SYSTIMESTAMP;
    :new.status_modified_date := SYSTIMESTAMP;

	-- crapp-2532 --
	:new.geo_area_key := REPLACE(UPPER(:new.geo_area_key),CHR(39),'');  -- crapp-3854, removing apostrophes

    INSERT INTO geo_poly_ref_chg_logs (table_name, primary_key, entered_by, rid, entity_id)
    VALUES ('GEO_POLYGONS', :new.id, :new.entered_by, :new.rid, :new.id);

END;
/