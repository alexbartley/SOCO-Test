CREATE OR REPLACE TRIGGER content_repo."DEL_JURISDICTIONS" 
 AFTER
  DELETE
 ON content_repo.JURISDICTIONS
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    DELETE FROM juris_chg_logs WHERE rid = :old.rid and primary_key = :old.id AND table_name = 'JURISDICTIONS';
END;
/