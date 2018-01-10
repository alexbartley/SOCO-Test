CREATE OR REPLACE TRIGGER content_repo."INS_TAX_APP_ATTRIBUTES" 
 BEFORE
  INSERT
 ON content_repo.juris_tax_app_attributes
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

IF (:new.nkid IS NULL) THEN
    :new.nkid := nkid_juris_TAX_APP_ATTRIBUTES.nextval;
    --:new.id := pk_juris_TAX_APP_ATTRIBUTES.nextval;
    :new.rid := tax_applicability.get_revision(entity_id_io => :new.JURIS_TAX_APPLICABILITY_ID, entity_nkid_i => NULL, entered_by_i => :new.entered_by);
END IF;

IF (:new.id IS NULL) THEN
 :new.id := pk_juris_TAX_APP_ATTRIBUTES.nextval;
END IF;

:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;

--will need to update to use specific entity change log
INSERT INTO juris_tax_app_chg_logs (table_name, primary_key, entered_by, rid, entity_id)
VALUES ('JURIS_TAX_APP_ATTRIBUTES',:new.id,:new.entered_by,:new.rid, :new.JURIS_TAX_APPLICABILITY_ID);
INSERT INTO juris_tax_app_qr (table_name, ref_nkid, ref_id, entered_by, ref_rid, qr)
VALUES ('JURIS_TAX_APP_ATTRIBUTES', :new.nkid, :new.id,:new.entered_by,:new.rid,to_char(:new.start_date,'MM/DD/YYYY')||'-'||to_char(:new.end_date,'MM/DD/YYYY')||' '||(select name from additional_attributes where id = :new.attribute_id));
END;
/