CREATE OR REPLACE TRIGGER sbxtax3.ins_tb_zone_authorities_pk
 BEFORE
  INSERT
 ON sbxtax3.tb_zone_authorities
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    IF (:new.zone_authority_id IS NULL) THEN
        :new.zone_authority_id := pk_tb_zone_authorities.nextval;
    END IF;
END;
/