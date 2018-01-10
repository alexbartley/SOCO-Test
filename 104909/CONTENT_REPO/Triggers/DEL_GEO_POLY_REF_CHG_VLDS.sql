CREATE OR REPLACE TRIGGER content_repo."DEL_GEO_POLY_REF_CHG_VLDS" 
 AFTER
 DELETE
 ON content_repo.GEO_POLY_REF_CHG_VLDS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
BEGIN

UPDATE geo_poly_ref_revisions
SET summ_ass_status = 4
WHERE id = :new.rid
AND summ_ass_status = 5;

END;
/