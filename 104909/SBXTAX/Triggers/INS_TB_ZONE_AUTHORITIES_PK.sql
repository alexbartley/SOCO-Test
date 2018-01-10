CREATE OR REPLACE TRIGGER sbxtax."INS_TB_ZONE_AUTHORITIES_PK"
 BEFORE
  INSERT
 ON sbxtax.tb_zone_authorities
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    IF (:new.zone_authority_id IS NULL) THEN
        :new.zone_authority_id := pk_tb_zone_authorities.nextval;
    END IF;
END;
/