CREATE OR REPLACE TRIGGER sbxtax."INS_TB_COMP_AREA_AUTHS_PK"
 BEFORE
  INSERT
 ON sbxtax.tb_comp_area_authorities
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    IF (:new.compliance_area_auth_id IS NULL) THEN
        :new.compliance_area_auth_id := pk_tb_comp_area_authorities.nextval;
    END IF;
END;
/