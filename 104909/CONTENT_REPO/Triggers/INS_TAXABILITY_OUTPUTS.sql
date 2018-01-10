CREATE OR REPLACE TRIGGER content_repo.INS_TAXABILITY_OUTPUTS
 BEFORE 
 INSERT
 ON content_repo.TAXABILITY_OUTPUTS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW 
BEGIN

  IF (:new.nkid IS NULL) THEN
    :new.nkid := nkid_taxability_outputs.nextval;
    :new.id   := pk_taxability_outputs.nextval;
    :new.rid  := tax_applicability.get_revision(entity_id_io => :new.juris_tax_applicability_id, entity_nkid_i => null, entered_by_i => :new.entered_by);
  END IF;

  :new.entered_date := SYSTIMESTAMP;
  :new.status_modified_date := SYSTIMESTAMP;
  :new.short_text := fnnlsconvert(pfield=>:new.short_text);
  :new.full_text := fnnlsconvert(pfield=>:new.full_text);
  
  INSERT INTO juris_tax_app_chg_logs (table_name, primary_key, entered_by, rid, entity_id)
  VALUES ('TAXABILITY_OUTPUTS',:new.id,:new.entered_by,:new.rid, :new.juris_tax_applicability_id);

  INSERT INTO juris_tax_app_qr (table_name, ref_nkid, ref_id, entered_by, ref_rid, qr)
  VALUES ('TAXABILITY_OUTPUTS', :new.nkid, :new.id,:new.entered_by,:new.rid,:NEW.short_text);
END;
/