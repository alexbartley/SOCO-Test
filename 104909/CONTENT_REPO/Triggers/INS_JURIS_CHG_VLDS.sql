CREATE OR REPLACE TRIGGER content_repo."INS_JURIS_CHG_VLDS" 
 BEFORE
 INSERT
 ON content_repo.JURIS_CHG_VLDS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
BEGIN
:new.id := pk_juris_chg_vlds.nextval;
:new.assignment_date := coalesce(:new.assignment_date,SYSTIMESTAMP);
:new.status_modified_date := SYSTIMESTAMP;

UPDATE jurisdiction_revisions
SET summ_ass_status = 4
WHERE id = :new.rid
AND summ_ass_status = 0;

END;
/