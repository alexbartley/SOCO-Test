CREATE OR REPLACE TRIGGER sbxtax3.ins_tb_rules_pk
 BEFORE
  INSERT
 ON sbxtax3.tb_rules
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    IF (:new.rule_id IS NULL) THEN
        :new.rule_id := pk_tb_rules.nextval;
    END IF;
END;
/