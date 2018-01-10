CREATE OR REPLACE TRIGGER content_repo."INS_ADMIN_CHG_VLDS" 
 BEFORE
 INSERT
 ON content_repo.ADMIN_CHG_VLDS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
BEGIN
:new.id := pk_admin_chg_vlds.nextval;
:new.assignment_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
--/*
UPDATE administrator_revisions
SET summ_ass_status = 4
WHERE id = :new.rid
AND summ_ass_status = 0;
--*/
END;
/