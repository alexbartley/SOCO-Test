CREATE OR REPLACE TRIGGER content_repo."DEL_ADMIN_CHG_VLDS" 
 AFTER
 DELETE
 ON content_repo.ADMIN_CHG_VLDS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
BEGIN

UPDATE administrator_revisions
SET summ_ass_status = 4
WHERE id = :new.rid
AND summ_ass_status = 5;


END;
/