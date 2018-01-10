CREATE OR REPLACE TRIGGER sbxtax3.ins_tb_rate_tiers_pk
 BEFORE
  INSERT
 ON sbxtax3.tb_rate_tiers
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    IF (:new.rate_tier_id IS NULL) THEN
        :new.rate_tier_id := pk_tb_rate_tiers.nextval;
    END IF;
END;
/