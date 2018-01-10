CREATE OR REPLACE TRIGGER content_repo."DEL_JURIS_TAX_IMPOSITIONS" 
 AFTER
  DELETE
 ON content_repo.JURIS_TAX_IMPOSITIONS
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    DELETE FROM juris_tax_chg_logs WHERE rid = :old.rid and primary_key = :old.id AND table_name = 'JURIS_TAX_IMPOSITIONS';
END;
/