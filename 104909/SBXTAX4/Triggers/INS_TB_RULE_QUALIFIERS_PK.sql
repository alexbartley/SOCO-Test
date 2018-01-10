CREATE OR REPLACE TRIGGER sbxtax4."INS_TB_RULE_QUALIFIERS_PK" 
 BEFORE
  INSERT
 ON sbxtax4.tb_rule_qualifiers
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    IF (:new.rule_qualifier_id IS NULL) THEN
        :new.rule_qualifier_id := pk_tb_rule_qualifiers.nextval;
    END IF;
END;
/