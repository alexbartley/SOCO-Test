CREATE OR REPLACE TRIGGER content_repo.del_taxability_outputs
 AFTER
  DELETE
 ON content_repo.taxability_outputs
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    DELETE FROM juris_tax_app_chg_logs WHERE rid = :old.rid and primary_key = :old.id AND table_name = 'TAXABILITY_OUTPUTS';
END;
/