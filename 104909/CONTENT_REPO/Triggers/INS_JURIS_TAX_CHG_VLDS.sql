CREATE OR REPLACE TRIGGER content_repo."INS_JURIS_TAX_CHG_VLDS" 
 BEFORE
 INSERT
 ON content_repo.JURIS_TAX_CHG_VLDS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
BEGIN

:new.id := pk_juris_tax_chg_vlds.nextval;
:new.assignment_Date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;

UPDATE jurisdiction_tax_revisions
SET summ_ass_status = 4
WHERE id = :new.rid
AND summ_ass_status = 0;

END;
/