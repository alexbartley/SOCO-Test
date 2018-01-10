CREATE OR REPLACE TRIGGER sbxtax."DT_RULES" 
after insert or update or delete on sbxtax.TB_RULES
for each row
declare
  old TB_RULES%rowtype;
  v_merchant_id number;
begin
  old.RULE_ID := :old.RULE_ID;
  old.RULE_ORDER := :old.RULE_ORDER;
  old.START_DATE := :old.START_DATE;
  old.AUTHORITY_ID := :old.AUTHORITY_ID;
  old.MERCHANT_ID := :old.MERCHANT_ID;
  old.IS_LOCAL := :old.IS_LOCAL;
  /* get merchant_id */

  v_merchant_id := nvl(:new.MERCHANT_ID, :old.MERCHANT_ID);

  if inserting then
    add_content_journal_entries.p_RULES('A', :new.RULE_ID, v_merchant_id, old);
  elsif updating then
    add_content_journal_entries.p_RULES('U', :new.RULE_ID, v_merchant_id, old);
  elsif deleting then
    add_content_journal_entries.p_RULES('D', :old.RULE_ID, v_merchant_id, old);
  end if;
end dt_RULES;
/