CREATE OR REPLACE TRIGGER sbxtax2.ins_tb_contributing_auths_pk
 BEFORE
  INSERT
 ON sbxtax2.tb_contributing_authorities
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    IF (:new.contributing_authority_id IS NULL) THEN
        :new.contributing_authority_id := pk_tb_contributing_auths.nextval;
    END IF;
END;
/