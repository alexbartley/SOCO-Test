CREATE OR REPLACE TRIGGER sbxtax4."DT_DELIVERY_TERMS" 
after insert or update or delete on sbxtax4.TB_DELIVERY_TERMS
for each row
declare
  old TB_DELIVERY_TERMS%rowtype;
  v_merchant_id number;
begin
  old.DELIVERY_TERM_ID := :old.DELIVERY_TERM_ID;
  old.MERCHANT_ID := :old.MERCHANT_ID;
  old.DELIVERY_TERM_CODE := :old.DELIVERY_TERM_CODE;
  old.START_DATE := :old.START_DATE;
  /* get merchant_id */

  v_merchant_id := nvl(:new.MERCHANT_ID, :old.MERCHANT_ID);

  if inserting then
    add_content_journal_entries.p_DELIVERY_TERMS('A', :new.DELIVERY_TERM_ID, v_merchant_id, old);
  elsif updating then
    add_content_journal_entries.p_DELIVERY_TERMS('U', :new.DELIVERY_TERM_ID, v_merchant_id, old);
  elsif deleting then
    add_content_journal_entries.p_DELIVERY_TERMS('D', :old.DELIVERY_TERM_ID, v_merchant_id, old);
  end if;
end dt_DELIVERY_TERMS;
/