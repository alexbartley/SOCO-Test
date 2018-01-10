CREATE OR REPLACE TRIGGER sbxtax3."DT_RULE_OUTPUTS" 
after insert or update or delete on sbxtax3.TB_RULE_OUTPUTS
for each row
declare
  old TB_RULE_OUTPUTS%rowtype;
  v_merchant_id number;
begin
  old.RULE_OUTPUT_ID := :old.RULE_OUTPUT_ID;
  old.RULE_ID := :old.RULE_ID;
  old.NAME := :old.NAME;
  old.START_DATE := :old.START_DATE;

  /* get merchant_id */

select
TB_RULES.MERCHANT_ID
 into v_merchant_id
 from tb_rules
 where TB_RULES.RULE_ID = nvl(:new.rule_id, :old.rule_id)
;

  if inserting then
    add_content_journal_entries.p_RULE_OUTPUTS('A', :new.RULE_OUTPUT_ID, v_merchant_id, old);
  elsif updating then
      add_content_journal_entries.p_RULE_OUTPUTS('U', :new.RULE_OUTPUT_ID, v_merchant_id, old);
  elsif deleting then
    add_content_journal_entries.p_RULE_OUTPUTS('D', :old.RULE_OUTPUT_ID, v_merchant_id, old);
  end if;
end dt_RULE_OUTPUTS;
/