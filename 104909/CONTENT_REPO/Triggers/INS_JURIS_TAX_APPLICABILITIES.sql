CREATE OR REPLACE TRIGGER content_repo."INS_JURIS_TAX_APPLICABILITIES" 
 BEFORE 
 INSERT
 ON content_repo.JURIS_TAX_APPLICABILITIES
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW 
BEGIN

  IF (:new.nkid IS NULL) THEN
    :new.id   := pk_juris_tax_applicabilities.nextval;
    :new.nkid := nkid_juris_tax_applicabilities.nextval;
    :new.rid  := tax_applicability.get_revision(entity_id_io => :new.id, entity_nkid_i => :new.nkid, entered_by_i => :new.entered_by);
  END IF;

  dbms_output.put_line(:new.rid);

  IF (:new.ref_rule_order IS NULL) THEN
  -- If this is the creation, there won't be any record available and ref_rule_ordre should be set to null
  begin
    SELECT ref_rule_order
    INTO   :new.ref_rule_order
    FROM   juris_tax_applicabilities
    WHERE nkid = :new.nkid
        AND next_rid IS NULL
        AND ref_rule_order IS NOT NULL;
    exception
    when others then :new.ref_rule_order := null;
    end;
    
  END IF;

  :new.reference_code := ' '; -- This would be always a space as we are currently not using reference_code columkn any more.

  :new.entered_date := SYSTIMESTAMP;
  :new.status_modified_date := SYSTIMESTAMP;

  INSERT INTO juris_tax_app_chg_logs (table_name, primary_key, entered_by, rid, entity_id)
  VALUES ('JURIS_TAX_APPLICABILITIES',:new.id,:new.entered_by,:new.rid, :new.id);

  INSERT INTO juris_tax_app_qr (table_name, ref_nkid, ref_id, entered_by, ref_rid, qr)
  VALUES ('JURIS_TAX_APPLICABILITIES', :new.nkid, :new.id,:new.entered_by,:new.rid,:new.reference_code);
END;
/