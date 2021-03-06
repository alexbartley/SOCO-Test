CREATE OR REPLACE TRIGGER sbxtax4."INS_TB_REFERENCE_LISTS_PK" 
 BEFORE
  INSERT
 ON sbxtax4.tb_reference_lists
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    IF (:new.reference_list_id IS NULL) THEN
        :new.reference_list_id := pk_tb_reference_lists.nextval;
    END IF;
END;
/