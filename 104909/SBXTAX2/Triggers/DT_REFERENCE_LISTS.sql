CREATE OR REPLACE TRIGGER sbxtax2."DT_REFERENCE_LISTS" 
after insert or update or delete on sbxtax2.TB_REFERENCE_LISTS
for each row
declare
  old TB_REFERENCE_LISTS%rowtype;
  v_merchant_id number;
begin
  old.REFERENCE_LIST_ID := :old.REFERENCE_LIST_ID;
  old.NAME := :old.NAME;
  old.MERCHANT_ID := :old.MERCHANT_ID;
  old.START_DATE := :old.START_DATE;

  /* get merchant_id */

  v_merchant_id := nvl(:new.MERCHANT_ID, :old.MERCHANT_ID);

  if inserting then
    add_content_journal_entries.p_REFERENCE_LISTS('A', :new.REFERENCE_LIST_ID, v_merchant_id, old);
  elsif updating then
      add_content_journal_entries.p_REFERENCE_LISTS('U', :new.REFERENCE_LIST_ID, v_merchant_id, old);
  elsif deleting then
    add_content_journal_entries.p_REFERENCE_LISTS('D', :old.REFERENCE_LIST_ID, v_merchant_id, old);
  end if;
end dt_REFERENCE_LISTS;
/