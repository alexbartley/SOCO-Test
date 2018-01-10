CREATE OR REPLACE TRIGGER content_repo."INS_REFERENCE_GROUPS"
 BEFORE
  INSERT
 ON content_repo.reference_groups
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
IF (:new.nkid IS NULL) THEN
    :new.nkid := nkid_reference_groups.nextval;
    :new.id := pk_reference_groups.nextval;
    :new.rid := reference_group.get_revision(:new.id,:new.nkid,:new.entered_by);
END IF;

:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;

INSERT INTO ref_grp_chg_logs (table_name, primary_key, entered_by, rid, entity_id)
VALUES ('REFERENCE_GROUPS',:new.id,:new.entered_by,:new.rid, :new.id);
INSERT INTO ref_grp_qr (table_name, ref_nkid, ref_id, entered_by, ref_rid, qr)
VALUES ('REFERENCE_GROUPS', :new.nkid, :new.id,:new.entered_by,:new.rid,:new.name);
END;
/