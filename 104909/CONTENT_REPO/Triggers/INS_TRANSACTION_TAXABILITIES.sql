CREATE OR REPLACE TRIGGER content_repo."INS_TRANSACTION_TAXABILITIES" 
 BEFORE
  INSERT
 ON content_repo.TRANSACTION_taxabilities
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
IF (:new.nkid IS NULL) THEN
    :new.id := pk_TRANSACTION_taxabilities.nextval;
    :new.nkid := nkid_TRANSACTION_taxabilities.nextval;
    :new.rid := tax_applicability.get_revision(entity_id_io => :new.juris_tax_applicability_id, entity_nkid_i => NULL, entered_by_i => :new.entered_by);
END IF;

:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;
INSERT INTO juris_tax_app_chg_logs (table_name, primary_key, entered_by, rid, entity_id)
VALUES ('TRANSACTION_TAXABILITIES',:new.id,:new.entered_by,:new.rid, :new.juris_tax_applicability_id);
END INS_TRANSACTION_TAXABILITIES;
/