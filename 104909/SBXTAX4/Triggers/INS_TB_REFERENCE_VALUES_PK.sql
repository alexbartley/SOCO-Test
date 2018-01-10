CREATE OR REPLACE TRIGGER sbxtax4."INS_TB_REFERENCE_VALUES_PK" 
 BEFORE
  INSERT
 ON sbxtax4.tb_reference_values
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    IF (:new.reference_value_id IS NULL) THEN
        :new.reference_value_id := pk_tb_reference_values.nextval;
    END IF;
END;
/