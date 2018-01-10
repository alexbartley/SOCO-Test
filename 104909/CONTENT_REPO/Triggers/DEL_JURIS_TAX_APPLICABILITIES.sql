CREATE OR REPLACE TRIGGER content_repo."DEL_JURIS_TAX_APPLICABILITIES" 
 AFTER
  DELETE
 ON content_repo.juris_tax_applicabilities
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    DELETE FROM juris_tax_app_chg_logs WHERE rid = :old.rid AND primary_key = :old.id AND table_name = 'JURIS_TAX_APPLICABILITIES';
END;
/