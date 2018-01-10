CREATE OR REPLACE TRIGGER sbxtax."INS_TB_RATE_TIERS_PK"
 BEFORE
  INSERT
 ON sbxtax.tb_rate_tiers
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    IF (:new.rate_tier_id IS NULL) THEN
        :new.rate_tier_id := pk_tb_rate_tiers.nextval;
    END IF;
END;
/