CREATE OR REPLACE TRIGGER content_repo.del_juris_type_chg_vlds
 AFTER
  DELETE
 ON content_repo.juris_type_chg_vlds
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

UPDATE jurisdiction_type_revisions
SET summ_ass_status = 4
WHERE id = :new.rid
AND summ_ass_status = 5;

END;
/