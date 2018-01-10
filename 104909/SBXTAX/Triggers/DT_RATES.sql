CREATE OR REPLACE TRIGGER sbxtax."DT_RATES" 
after insert or update or delete on sbxtax.TB_RATES
for each row
declare
  old TB_RATES%rowtype;
  v_merchant_id number;
begin
  old.RATE_ID := :old.RATE_ID;
  old.RATE_CODE := :old.RATE_CODE;
  old.AUTHORITY_ID := :old.AUTHORITY_ID;
  old.START_DATE := :old.START_DATE;
  old.MERCHANT_ID := :old.MERCHANT_ID;
  old.IS_LOCAL := :old.IS_LOCAL;
  /* get merchant_id */

  v_merchant_id := nvl(:new.MERCHANT_ID, :old.MERCHANT_ID);

  if inserting then
    add_content_journal_entries.p_RATES('A', :new.RATE_ID, v_merchant_id, old);
  elsif updating then
    add_content_journal_entries.p_RATES('U', :new.RATE_ID, v_merchant_id, old);
  elsif deleting then
    add_content_journal_entries.p_RATES('D', :old.RATE_ID, v_merchant_id, old);
  end if;
end dt_RATES;
/