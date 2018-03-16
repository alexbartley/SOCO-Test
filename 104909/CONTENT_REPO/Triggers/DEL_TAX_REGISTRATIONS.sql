CREATE OR REPLACE TRIGGER content_repo."DEL_TAX_REGISTRATIONS" 
 AFTER
  DELETE
 ON content_repo.TAX_REGISTRATIONS
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    DELETE FROM admin_chg_logs WHERE rid = :old.rid and primary_key = :old.id AND table_name = 'TAX_REGISTRATIONS';
END;
/