CREATE OR REPLACE TRIGGER sbxtax4."INS_TB_RATE_TIERS_PK" 
 BEFORE
  INSERT
 ON sbxtax4.tb_rate_tiers
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    IF (:new.rate_tier_id IS NULL) THEN
        :new.rate_tier_id := pk_tb_rate_tiers.nextval;
    END IF;
END;
/