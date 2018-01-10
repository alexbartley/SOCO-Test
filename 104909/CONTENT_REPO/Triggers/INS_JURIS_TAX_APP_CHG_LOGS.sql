CREATE OR REPLACE TRIGGER content_repo."INS_JURIS_TAX_APP_CHG_LOGS" 
 BEFORE
 INSERT
 ON content_repo.JURIS_TAX_APP_CHG_LOGS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
BEGIN
:new.id := pk_juris_tax_app_chg_logs.nextval;
:new.entered_date := SYSTIMESTAMP;
:new.status_modified_date := SYSTIMESTAMP;

  /*IF(:new.table_name = 'TAX_APPLICABILITY_TAXES') THEN
      SELECT juris_tax_applicability_id
      INTO :new.entity_id
      FROM tax_applicability_sets
      WHERE id = :new.entity_id;
  END IF;*/

  /* 5/30/2014 -- transaction_taxabilities level removed
  IF(:new.table_name = 'TRAN_TAX_QUALIFIERS') THEN
      SELECT juris_tax_applicability_id
      INTO :new.entity_id
      FROM transaction_taxabilities
      WHERE id = :new.entity_id;
  END IF;*/


END;
/