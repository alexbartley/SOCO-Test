CREATE OR REPLACE TRIGGER content_repo."DEL_JURIS_TAX_APP_CHG_VLDS" 
 AFTER
 DELETE
 ON content_repo.JURIS_TAX_APP_CHG_VLDS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
BEGIN

UPDATE juris_tax_app_revisions
SET summ_ass_status = 4
WHERE id = :new.rid
AND summ_ass_status = 5;

END;
/