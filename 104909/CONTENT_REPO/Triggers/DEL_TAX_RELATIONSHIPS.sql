CREATE OR REPLACE TRIGGER content_repo."DEL_TAX_RELATIONSHIPS" 
 AFTER
  DELETE
 ON content_repo.tax_relationships
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    DELETE FROM juris_chg_logs WHERE rid = :old.jurisdiction_rid and primary_key = :old.id AND table_name = 'TAX_RELATIONSHIPS';
END;
/