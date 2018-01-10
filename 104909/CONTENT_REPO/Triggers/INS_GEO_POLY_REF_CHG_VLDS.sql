CREATE OR REPLACE TRIGGER content_repo."INS_GEO_POLY_REF_CHG_VLDS" 
 BEFORE
 INSERT
 ON content_repo.GEO_POLY_REF_CHG_VLDS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
BEGIN
:new.id := pk_geo_poly_ref_chg_vlds.nextval;
:new.assignment_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;

UPDATE geo_poly_ref_revisions
SET summ_ass_status = 4
WHERE id = :new.rid
AND summ_ass_status = 0;

END;
/