CREATE OR REPLACE TRIGGER sbxtax4.dt_COMPLIANCE_AREAS
 AFTER INSERT OR DELETE OR UPDATE ON sbxtax4.tb_compliance_areas
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
DECLARE
  old TB_COMPLIANCE_AREAS%rowtype;
  v_merchant_id NUMBER;
BEGIN
  old.COMPLIANCE_AREA_ID := :old.COMPLIANCE_AREA_ID;
  old.COMPLIANCE_AREA_UUID := :old.COMPLIANCE_AREA_UUID;
  old.MERCHANT_ID := :old.MERCHANT_ID;
  old.START_DATE  := :old.START_DATE;
  --old.NAME := :old.NAME;
  
  /* get merchant_id */
  v_merchant_id := NVL(:new.MERCHANT_ID, :old.MERCHANT_ID);

  IF inserting THEN
    add_content_journal_entries.p_COMPLIANCE_AREAS('A', :new.COMPLIANCE_AREA_ID, v_merchant_id, old);
  ELSIF updating THEN
    add_content_journal_entries.p_COMPLIANCE_AREAS('U', :new.COMPLIANCE_AREA_ID, v_merchant_id, old);
  ELSIF deleting THEN
    add_content_journal_entries.p_COMPLIANCE_AREAS('D', :old.COMPLIANCE_AREA_ID, v_merchant_id, old);
  END IF;
END dt_COMPLIANCE_AREAS;
/