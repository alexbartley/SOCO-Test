CREATE OR REPLACE TRIGGER sbxtax2.ins_tb_reference_values_pk
 BEFORE
  INSERT
 ON sbxtax2.tb_reference_values
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    IF (:new.reference_value_id IS NULL) THEN
        :new.reference_value_id := pk_tb_reference_values.nextval;
    END IF;
END;
/