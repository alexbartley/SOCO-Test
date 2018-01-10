CREATE OR REPLACE TRIGGER content_repo."INS_TAX_REGISTRATIONS"
 BEFORE
  INSERT
 ON content_repo.tax_registrations
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
IF (:new.nkid IS NULL) THEN
    :new.nkid := nkid_TAX_REGISTRATIONS.nextval;
    :new.id := pk_TAX_REGISTRATIONS.nextval;
    :new.rid := administrator.get_revision(entity_id_io => :new.administrator_id, entity_nkid_i => NULL, entered_by_i => :new.entered_by);
END IF;

:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
INSERT INTO admin_chg_logs (table_name, primary_key, entered_by, rid, entity_id)
VALUES ('TAX_REGISTRATIONS',:new.id,:new.entered_by,:new.rid, :new.administrator_id);
INSERT INTO admin_qr (table_name, ref_nkid, ref_id, entered_by, ref_rid, qr)
VALUES ('TAX_REGISTRATIONS', :new.nkid, :new.id,:new.entered_by,:new.rid,:NEW.REGISTRATION_MASK);

END;
/