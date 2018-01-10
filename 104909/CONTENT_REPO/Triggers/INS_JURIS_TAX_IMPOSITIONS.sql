CREATE OR REPLACE TRIGGER content_repo."INS_JURIS_TAX_IMPOSITIONS"
 BEFORE
  INSERT
 ON content_repo.juris_tax_impositions
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
DECLARE

BEGIN


/*
--Two types of inserts can occur:
--a) as a new revision to an existing nkid-
    will have ID, NKID, RID,
    because the upd_jurisdictions trigger sets RID and ID
--b) as a brand new nkid- needs ID, RID, NKID
*/
IF (:new.nkid IS NULL) THEN
    :new.nkid := nkid_juris_tax_impositions.nextval;
    :new.id := pk_juris_tax_impositions.nextval;
    :new.rid := tax.get_revision(entity_id_io => :new.id, entity_nkid_i => :new.nkid, entered_by_i => :new.entered_by);
END IF;

IF (:new.reference_code IS NULL) THEN
    :new.reference_code := 'NONE';
END IF;

:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
INSERT INTO juris_tax_chg_logs (table_name, primary_key, entered_by, rid, entity_id)
VALUES ('JURIS_TAX_IMPOSITIONS',:new.id,:new.entered_by,:new.rid, :new.id);
INSERT INTO tax_qr (table_name, ref_nkid, ref_id, entered_by, ref_rid, qr)
VALUES ('JURIS_TAX_IMPOSITIONS', :new.nkid, :new.id,:new.entered_by,:new.rid,:new.reference_code);
END;
/