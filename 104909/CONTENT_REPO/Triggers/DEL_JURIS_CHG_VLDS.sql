CREATE OR REPLACE TRIGGER content_repo."DEL_JURIS_CHG_VLDS" 
 AFTER
 DELETE
 ON content_repo.JURIS_CHG_VLDS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
BEGIN

UPDATE jurisdiction_revisions
SET summ_ass_status = 4
WHERE id = :new.rid
AND summ_ass_status = 5;

END;
/