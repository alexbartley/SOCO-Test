CREATE OR REPLACE TRIGGER content_repo."INS_JURIS_GEO_AREAS"
 BEFORE
  INSERT
 ON content_repo.juris_geo_areas
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
/*
--Two types of inserts can occur:
--a) as a new revision to an existing nkid - will have ID, NKID, RID,
     because the upd_jurisdictions trigger sets RID and ID
--b) as a brand new nkid- needs ID, RID, NKID
*/
dbms_output.put_line('entered into the trigger'||:new.geo_polygon_id);
IF (:new.nkid IS NULL) THEN
    :new.nkid := nkid_juris_geo_areas.nextval;
    :new.id   := pk_juris_geo_areas.nextval;
    --:new.rid  := gis.get_revision(entity_id_io => :new.id, entity_nkid_i => :new.nkid, entered_by_i => :new.entered_by);
    :new.rid  := gis.get_revision(entity_id_io => :new.geo_polygon_id, entity_nkid_i => null, entered_by_i => :new.entered_by);
END IF;

:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;

INSERT INTO geo_poly_ref_chg_logs (table_name, primary_key, entered_by, rid, entity_id)
VALUES ('JURIS_GEO_AREAS', :new.id, :new.entered_by, :new.rid, :new.id);
INSERT INTO geo_poly_ref_qr (table_name, ref_nkid, ref_id, entered_by, ref_rid, qr)
VALUES ('JURIS_GEO_AREAS', :new.nkid, :new.id,:new.entered_by,:new.rid,(select official_name from jurisdictions where id = :new.jurisdiction_id and next_Rid is null));
END;
/