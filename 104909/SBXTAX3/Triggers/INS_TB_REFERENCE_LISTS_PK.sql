CREATE OR REPLACE TRIGGER sbxtax3.ins_tb_reference_lists_pk
 BEFORE
  INSERT
 ON sbxtax3.tb_reference_lists
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    IF (:new.reference_list_id IS NULL) THEN
        :new.reference_list_id := pk_tb_reference_lists.nextval;
    END IF;
END;
/