CREATE OR REPLACE TRIGGER content_repo."INS_GEO_UNIQUE_AREA_CHG_VLDS" 
 BEFORE
 INSERT
 ON content_repo.GEO_UNIQUE_AREA_CHG_VLDS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
BEGIN
:new.id := pk_geo_unique_area_chg_vlds.nextval;
:new.assignment_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;

UPDATE geo_unique_area_revisions
SET summ_ass_status = 4
WHERE id = :new.rid
AND summ_ass_status = 0;

END;
/