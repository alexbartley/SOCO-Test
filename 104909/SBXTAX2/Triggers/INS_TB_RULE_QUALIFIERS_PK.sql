CREATE OR REPLACE TRIGGER sbxtax2.ins_tb_rule_qualifiers_pk
 BEFORE
  INSERT
 ON sbxtax2.tb_rule_qualifiers
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    IF (:new.rule_qualifier_id IS NULL) THEN
        :new.rule_qualifier_id := pk_tb_rule_qualifiers.nextval;
    END IF;
END;
/