CREATE OR REPLACE TRIGGER sbxtax2.ins_tb_algx_pk
 BEFORE
  INSERT
 ON sbxtax2.tb_authority_logic_group_xref
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    IF (:new.authority_logic_group_xref_id IS NULL) THEN
        :new.authority_logic_group_xref_id := pk_tb_algx_id.nextval;
    END IF;
END;
/