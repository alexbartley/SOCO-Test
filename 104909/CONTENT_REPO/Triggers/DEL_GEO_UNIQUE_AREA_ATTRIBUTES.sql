CREATE OR REPLACE TRIGGER content_repo."DEL_GEO_UNIQUE_AREA_ATTRIBUTES"
 AFTER
 DELETE
 ON content_repo.GEO_UNIQUE_AREA_ATTRIBUTES
 FOR EACH ROW
BEGIN
    DELETE FROM geo_unique_area_chg_logs WHERE rid = :old.rid and primary_key = :old.id AND table_name = 'GEO_UNIQUE_AREA_ATTRIBUTES';
END;
/