CREATE OR REPLACE TRIGGER content_repo."DEL_JURIS_GEO_AREAS" 
 AFTER
  DELETE
 ON content_repo.juris_geo_areas
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    DELETE FROM geo_poly_ref_chg_logs WHERE rid = :old.rid AND primary_key = :old.id AND table_name = 'JURIS_GEO_AREAS';
END;
/