CREATE OR REPLACE TRIGGER content_repo."DEL_TAX_APPLICABILITY_TAXES" 
 AFTER
  DELETE
 ON content_repo.tax_applicability_taxes
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    DELETE FROM juris_tax_app_chg_logs WHERE rid = :old.rid and primary_key = :old.id AND table_name = 'TAX_APPLICABILITY_TAXES';
END;
/