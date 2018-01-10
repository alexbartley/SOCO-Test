CREATE OR REPLACE TRIGGER sbxtax3."DT_MERCHANTS" 
after insert or update or delete on sbxtax3.TB_MERCHANTS
for each row
declare
  old TB_MERCHANTS%rowtype;
  v_merchant_id number;
begin
  old.MERCHANT_ID := :old.MERCHANT_ID;
  old.NAME := :old.NAME;
  /* get merchant_id */

  v_merchant_id := nvl(:new.MERCHANT_ID, :old.MERCHANT_ID);

  if inserting then
    add_content_journal_entries.p_MERCHANTS('A', :new.MERCHANT_ID, v_merchant_id, old);
  elsif updating then
    add_content_journal_entries.p_MERCHANTS('U', :new.MERCHANT_ID, v_merchant_id, old);
  elsif deleting then
    add_content_journal_entries.p_MERCHANTS('D', :old.MERCHANT_ID, v_merchant_id, old);
  end if;
end dt_MERCHANTS;
/