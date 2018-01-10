CREATE OR REPLACE TRIGGER content_repo."INS_TRAN_TAX_QUALIFIERS" 
 BEFORE
  INSERT
 ON content_repo.tran_tax_qualifiers
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN

  IF (:new.nkid IS NULL) THEN
    :new.id   := pk_tran_tax_qualifiers.nextval;
    :new.nkid := nkid_tran_tax_qualifiers.nextval;
    :new.rid  := tax_applicability.get_revision(entity_id_io=> :new.juris_tax_applicability_id, entity_nkid_i=> null, entered_by_i=> :new.entered_by);
  END IF;

  :new.entered_date := SYSTIMESTAMP;
  :new.status_modified_date := SYSTIMESTAMP;

  INSERT INTO juris_tax_app_chg_logs (table_name, primary_key, entered_by, rid, entity_id)
  VALUES ('TRAN_TAX_QUALIFIERS',:new.id,:new.entered_by,:new.rid, :new.juris_tax_applicability_id);

  IF :new.taxability_element_id IS NULL THEN
    INSERT INTO juris_tax_app_qr (table_name, ref_nkid, ref_id, entered_by, ref_rid, qr)
    VALUES ('TRAN_TAX_QUALIFIERS', :new.nkid, :new.id,:new.entered_by,:new.rid,(select official_name from jurisdictions where id = :new.jurisdiction_id));
  ELSE
    INSERT INTO juris_tax_app_qr (table_name, ref_nkid, ref_id, entered_by, ref_rid, qr)
    VALUES ('TRAN_TAX_QUALIFIERS', :new.nkid, :new.id,:new.entered_by,:new.rid,(select element_name from taxability_elements where id = :new.taxability_element_id));
  END IF;
END;
/