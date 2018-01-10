CREATE OR REPLACE TRIGGER sbxtax3."DT_DATE_DETERMINATION_RULES" 
after insert or update or delete on sbxtax3.TB_DATE_DETERMINATION_RULES
for each row
declare
  old TB_DATE_DETERMINATION_RULES%rowtype;
  v_merchant_id number;
begin
  old.RULE_ORDER := :old.RULE_ORDER;
  old.MERCHANT_ID := :old.MERCHANT_ID;
  old.DATE_TYPE := :old.DATE_TYPE;
  old.START_DATE := :old.START_DATE;
  /* get merchant_id */

  v_merchant_id := nvl(:new.MERCHANT_ID, :old.MERCHANT_ID);

  if inserting then
    add_content_journal_entries.p_DATE_DETERMINATION_RULES('A', :new.DATE_DETERMINATION_RULE_ID, v_merchant_id, old);
  elsif updating then
    add_content_journal_entries.p_DATE_DETERMINATION_RULES('U', :new.DATE_DETERMINATION_RULE_ID, v_merchant_id, old);
  elsif deleting then
    add_content_journal_entries.p_DATE_DETERMINATION_RULES('D', :old.DATE_DETERMINATION_RULE_ID, v_merchant_id, old);
  end if;
end dt_DATE_DETERMINATION_RULES;
/