CREATE OR REPLACE TRIGGER sbxtax2.ins_tb_rates_pk
 BEFORE
  INSERT
 ON sbxtax2.tb_rates
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    IF (:new.rate_id IS NULL) THEN
        :new.rate_id := pk_tb_rates.nextval;
    END IF;
END;
/