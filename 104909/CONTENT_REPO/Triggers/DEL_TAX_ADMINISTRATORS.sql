CREATE OR REPLACE TRIGGER content_repo."DEL_TAX_ADMINISTRATORS" 
 AFTER
  DELETE
 ON content_repo.TAX_ADMINISTRATORS
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    DELETE FROM juris_tax_chg_logs WHERE rid = :old.rid and primary_key = :old.id AND table_name = 'TAX_ADMINISTRATORS';
END;
/