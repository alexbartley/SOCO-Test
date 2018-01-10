CREATE OR REPLACE TRIGGER content_repo.del_jurisdiction_types
 AFTER
  DELETE
 ON content_repo.jurisdiction_types
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    DELETE FROM juris_type_chg_logs WHERE rid = :old.rid and primary_key = :old.id AND table_name = 'JURISDICTION_TYPES';
END;
/