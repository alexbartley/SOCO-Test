CREATE OR REPLACE TRIGGER sbxtax2.ins_tb_authorities_pk
 BEFORE
  INSERT
 ON sbxtax2.tb_authorities
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    IF (:new.authority_id IS NULL) THEN
        :new.authority_id := pk_tb_authorities.nextval;
    END IF;
END;
/