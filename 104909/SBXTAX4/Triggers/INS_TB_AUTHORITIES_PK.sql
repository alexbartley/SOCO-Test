CREATE OR REPLACE TRIGGER sbxtax4."INS_TB_AUTHORITIES_PK" 
 BEFORE
  INSERT
 ON sbxtax4.tb_authorities
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    IF (:new.authority_id IS NULL) THEN
        :new.authority_id := pk_tb_authorities.nextval;
    END IF;
END;
/