CREATE OR REPLACE TRIGGER content_repo.ins_jurisdiction_types
 BEFORE
  INSERT
 ON content_repo.jurisdiction_types
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
IF (:new.nkid IS NULL) THEN
    :new.nkid := nkid_jurisdiction_types.nextval;
    :new.id := pk_jurisdiction_types.nextval;
    :new.rid := jurisdiction_type.get_revision(entity_id_io => :new.id, entity_nkid_i => :new.nkid, entered_by_i => :new.entered_by);
END IF;

:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
:new.name := fnnlsconvert(pfield=>:new.name);
:new.description := fnnlsconvert(pfield=>:new.description);

INSERT INTO juris_type_chg_logs (table_name, primary_key, entered_by, rid, entity_id)
VALUES ('JURISDICTION_TYPES',:new.id,:new.entered_by,:new.rid, :new.id);
INSERT INTO juris_type_qr (table_name, ref_nkid, ref_id, entered_by, ref_rid, qr)
VALUES ('JURISDICTION_TYPES', :new.nkid, :new.id,:new.entered_by,:new.rid,:new.name);
END;
/