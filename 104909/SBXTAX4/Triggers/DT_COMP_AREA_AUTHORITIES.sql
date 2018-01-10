CREATE OR REPLACE TRIGGER sbxtax4.dt_COMP_AREA_AUTHORITIES
 AFTER INSERT OR UPDATE OR DELETE ON sbxtax4.TB_COMP_AREA_AUTHORITIES
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
DECLARE
  old TB_COMP_AREA_AUTHORITIES%rowtype;
  v_merchant_id NUMBER;
BEGIN
  old.COMPLIANCE_AREA_AUTH_ID := :old.COMPLIANCE_AREA_AUTH_ID;
  old.COMPLIANCE_AREA_ID := :old.COMPLIANCE_AREA_ID;
  old.AUTHORITY_ID := :old.AUTHORITY_ID;

  /* get merchant_id */
  SELECT merchant_id
  INTO   v_merchant_id
  FROM   tb_authorities
  WHERE  authority_id = nvl(:new.authority_id, :old.authority_id);

  IF inserting THEN
    add_content_journal_entries.p_COMP_AREA_AUTHORITIES('A', :new.COMPLIANCE_AREA_AUTH_ID, v_merchant_id, old);
  ELSIF updating THEN
    add_content_journal_entries.p_COMP_AREA_AUTHORITIES('U', :new.COMPLIANCE_AREA_AUTH_ID, v_merchant_id, old);
  ELSIF deleting THEN
    add_content_journal_entries.p_COMP_AREA_AUTHORITIES('D', :old.COMPLIANCE_AREA_AUTH_ID, v_merchant_id, old);
  END IF;
END dt_COMP_AREA_AUTHORITIES;
/