CREATE OR REPLACE TRIGGER content_repo."DEL_COMMODITIES"
 AFTER
  DELETE
 ON content_repo.commodities
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
  DELETE FROM comm_chg_logs WHERE rid = :old.rid and primary_key = :old.id AND table_name = 'COMMODITIES';

  -- Rebuild commodity tree using scheduler
  COMMODITY_TREE_EXEC;
END;
/