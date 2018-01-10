CREATE OR REPLACE TRIGGER content_repo.ins_juris_type_chg_vlds
 BEFORE
  INSERT
 ON content_repo.juris_type_chg_vlds
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
:new.id := pk_juris_type_chg_vlds.nextval;
:new.assignment_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
UPDATE jurisdiction_type_revisions
SET summ_ass_status = 4
WHERE id = :new.rid
AND summ_ass_status = 0;
END;
/