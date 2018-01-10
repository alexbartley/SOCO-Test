CREATE OR REPLACE TRIGGER content_repo."DEL_REF_GRP_CHG_VLDS" 
 AFTER
 DELETE
 ON content_repo.REF_GRP_CHG_VLDS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
BEGIN

UPDATE ref_group_revisions
SET summ_ass_status = 4
WHERE id = :new.rid
AND summ_ass_status = 5;

END;
/