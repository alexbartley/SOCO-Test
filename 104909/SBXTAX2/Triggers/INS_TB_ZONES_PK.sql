CREATE OR REPLACE TRIGGER sbxtax2.ins_tb_zones_pk
 BEFORE
  INSERT
 ON sbxtax2.tb_zones
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    IF (:new.zone_id IS NULL) THEN
        :new.zone_id := pk_tb_zones.nextval;
    END IF;
END;
/