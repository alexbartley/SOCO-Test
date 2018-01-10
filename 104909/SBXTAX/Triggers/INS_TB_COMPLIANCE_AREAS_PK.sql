CREATE OR REPLACE TRIGGER sbxtax."INS_TB_COMPLIANCE_AREAS_PK"
 BEFORE
  INSERT
 ON sbxtax.tb_compliance_areas
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    IF (:new.compliance_area_id IS NULL) THEN
        :new.compliance_area_id := pk_tb_compliance_areas.nextval;
    END IF;
END;
/