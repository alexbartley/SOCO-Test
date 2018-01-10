CREATE OR REPLACE TRIGGER content_repo."INS_JURIS_TAX_DESCRIPTIONS"
 BEFORE
  INSERT
 ON content_repo.juris_tax_descriptions
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
IF (:new.nkid IS NULL) THEN
    :new.id := pk_juris_tax_descriptions.nextval;
    :new.nkid := nkid_juris_tax_descriptions.nextval;
    :new.rid := jurisdiction.get_revision(entity_id_io => :new.jurisdiction_id, entity_nkid_i => NULL, entered_by_i => :new.entered_by);
END IF;

:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
INSERT INTO juris_chg_logs (table_name, primary_key, entered_by, rid, entity_id)
VALUES ('JURIS_TAX_DESCRIPTIONS',:new.id,:new.entered_by,:new.rid, :new.jurisdiction_id);

INSERT INTO juris_qr (table_name, ref_nkid, ref_id, entered_by, ref_rid, qr)
VALUES ('JURIS_TAX_DESCRIPTIONS', :new.nkid, :new.id,:new.entered_by,:new.rid,(select taxation_Type||' '||transaction_type||' '||specific_applicability_Type from vtax_descriptions where id = :new.tax_description_id));
END ins_juris_tax_descriptions;
/