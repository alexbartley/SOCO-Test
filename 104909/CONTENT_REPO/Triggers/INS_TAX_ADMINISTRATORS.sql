CREATE OR REPLACE TRIGGER content_repo."INS_TAX_ADMINISTRATORS"
 BEFORE
  INSERT
 ON content_repo.tax_administrators
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
/*
--Two types of inserts can occur:
--a) as a new revision to an existing nkid-
    will have ID, NKID, RID,
    because the upd_jurisdictions trigger sets RID and ID
--b) as a brand new nkid- needs ID, RID, NKID
*/
IF (:new.nkid IS NULL) THEN
    :new.id := pk_tax_administrators.nextval;
    :new.nkid := nkid_tax_administrators.nextval;
    :new.rid := tax.get_revision(entity_id_io => :new.juris_tax_imposition_id, entity_nkid_i => null, entered_by_i => :new.entered_by);
END IF;

:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;

INSERT INTO juris_tax_chg_logs (table_name, primary_key, entered_by, rid, entity_id)
VALUES ('TAX_ADMINISTRATORS',:new.id,:new.entered_by,:new.rid, :new.juris_tax_imposition_id);
INSERT INTO tax_qr (table_name, ref_nkid, ref_id, entered_by, ref_rid, qr)
VALUES ('TAX_ADMINISTRATORS', :new.nkid, :new.id,:new.entered_by,:new.rid,(select name from administrators where id = :new.administrator_id));
END;
/