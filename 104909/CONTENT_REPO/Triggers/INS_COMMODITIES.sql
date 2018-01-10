CREATE OR REPLACE TRIGGER content_repo.INS_COMMODITIES
 BEFORE 
 INSERT
 ON content_repo.COMMODITIES
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW 
BEGIN
  IF (:new.nkid IS NULL) THEN
    :new.nkid := nkid_commodities.nextval;
    :new.id := pk_commodities.nextval;
    :new.rid := commodity.get_revision(entity_id_io=> :new.id, entity_nkid_i=> :new.nkid, entered_by_i=> :new.entered_by);
  END IF;

  :new.entered_date := SYSTIMESTAMP;
  :new.status_modified_date := SYSTIMESTAMP;

  :new.name := fnnlsconvert(pfield=>:new.name);
  :new.description := fnnlsconvert(pfield=>:new.description);
  
  INSERT INTO comm_chg_logs (table_name, primary_key, entered_by, rid, entity_id)
  VALUES ('COMMODITIES',:new.id,:new.entered_by,:new.rid, :new.id);
  INSERT INTO comm_qr (table_name, ref_nkid, ref_id, entered_by, ref_rid, qr)
  VALUES ('COMMODITIES', :new.nkid, :new.id,:new.entered_by,:new.rid, :new.name||' '||:new.commodity_code);

  -- Rebuild commodity tree using scheduler
  COMMODITY_TREE_EXEC;

END;
/