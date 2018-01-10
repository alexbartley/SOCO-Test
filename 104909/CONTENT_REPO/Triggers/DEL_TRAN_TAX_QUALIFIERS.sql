CREATE OR REPLACE TRIGGER content_repo."DEL_TRAN_TAX_QUALIFIERS" 
 AFTER
  DELETE
 ON content_repo.tran_tax_qualifiers
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    DELETE FROM juris_tax_app_chg_logs WHERE rid = :old.rid and primary_key = :old.id AND table_name = 'TRAN_TAX_QUALIFIERS';
END;
/