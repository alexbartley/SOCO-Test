CREATE OR REPLACE TRIGGER sbxtax."INS_TB_CONTRIBUTING_AUTHS_PK"
 BEFORE
  INSERT
 ON sbxtax.tb_contributing_authorities
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    IF (:new.contributing_authority_id IS NULL) THEN
        :new.contributing_authority_id := pk_tb_contributing_auths.nextval;
    END IF;
END;
/