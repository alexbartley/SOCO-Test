CREATE OR REPLACE TRIGGER sbxtax4."INS_TB_RULES_PK" 
 BEFORE
  INSERT
 ON sbxtax4.tb_rules
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    IF (:new.rule_id IS NULL) THEN
        :new.rule_id := pk_tb_rules.nextval;
    END IF;
END;
/