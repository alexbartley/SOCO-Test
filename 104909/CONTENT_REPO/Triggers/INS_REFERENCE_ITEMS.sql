CREATE OR REPLACE TRIGGER content_repo."INS_REFERENCE_ITEMS"
 BEFORE
  INSERT
 ON content_repo.reference_items
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
IF (:new.nkid IS NULL) THEN
    :new.nkid := nkid_reference_items.nextval;
    :new.id := pk_reference_items.nextval;
    :new.rid := reference_group.get_revision(:new.reference_group_id,null,:new.entered_by);
END IF;

:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;

INSERT INTO ref_grp_chg_logs (table_name, primary_key, entered_by, rid, entity_id)
VALUES ('REFERENCE_ITEMS',:new.id,:new.entered_by,:new.rid, :new.reference_group_id);
INSERT INTO ref_grp_qr (table_name, ref_nkid, ref_id, entered_by, ref_rid, qr)
VALUES ('REFERENCE_ITEMS', :new.nkid, :new.id,:new.entered_by,:new.rid,:new.value);
END;
/