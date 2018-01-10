CREATE OR REPLACE TRIGGER sbxtax4."INS_TB_RATES_PK" 
 BEFORE
  INSERT
 ON sbxtax4.tb_rates
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    IF (:new.rate_id IS NULL) THEN
        :new.rate_id := pk_tb_rates.nextval;
    END IF;
END;
/