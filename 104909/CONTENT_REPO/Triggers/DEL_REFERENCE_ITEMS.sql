CREATE OR REPLACE TRIGGER content_repo."DEL_REFERENCE_ITEMS" 
 AFTER
  DELETE
 ON content_repo.reference_items
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    DELETE FROM ref_grp_chg_logs WHERE rid = :old.rid and primary_key = :old.id AND table_name = 'REFERENCE_ITEMS';
END;
/