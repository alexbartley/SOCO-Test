CREATE OR REPLACE TRIGGER sbxtax."INS_TB_ZONES_PK"
 BEFORE
  INSERT
 ON sbxtax.tb_zones
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    IF (:new.zone_id IS NULL) THEN
        :new.zone_id := pk_tb_zones.nextval;
    END IF;
END;
/