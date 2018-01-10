CREATE OR REPLACE TRIGGER content_repo."DEL_TAX_DEFINITIONS" 
 AFTER
  DELETE
 ON content_repo.TAX_DEFINITIONS
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    DELETE FROM juris_tax_chg_logs WHERE rid = :old.rid and primary_key = :old.id AND table_name = 'TAX_DEFINITIONS';
END;
/