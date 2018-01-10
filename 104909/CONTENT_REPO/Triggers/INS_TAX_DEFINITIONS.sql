CREATE OR REPLACE TRIGGER content_repo.ins_tax_definitions
 BEFORE
  INSERT
 ON content_repo.tax_definitions
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
/* OLD TRIGGER
IF (:new.nkid IS NULL) THEN
    :new.nkid := nkid_TAX_DEFINITIONS.nextval;
END IF;
:new.id := pk_TAX_DEFINITIONS.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
*/
/*
--Two types of inserts can occur: 
--a) as a new revision to an existing nkid- 
    will have ID, NKID, RID, 
    because the upd_jurisdictions trigger sets RID and ID 
--b) as a brand new nkid- needs ID, RID, NKID
*/
IF (:new.nkid IS NULL) THEN
    :new.id := pk_TAX_DEFINITIONS.nextval;
    :new.nkid := nkid_TAX_DEFINITIONS.nextval;
    :new.rid := tax.get_revision_taxout(entity_id_i => :new.tax_outline_id, entered_by_i => :new.entered_by);
END IF;

:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;

INSERT INTO juris_tax_chg_logs (table_name, primary_key, entered_by, rid, entity_id)
VALUES ('TAX_DEFINITIONS',:new.id,:new.entered_by,:new.rid, :new.tax_outline_id);
INSERT INTO tax_qr (table_name, ref_nkid, ref_id, entered_by, ref_rid, qr)
VALUES ('TAX_DEFINITIONS', :new.nkid, :new.id,:new.entered_by,:new.rid,nvl(to_char(:new.value),'...')||' '||:NEW.value_type);

END;
/