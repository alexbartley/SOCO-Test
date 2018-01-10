CREATE OR REPLACE TRIGGER sbxtax3."DT_MATERIAL_SET_LISTS" 
after insert or update or delete on sbxtax3.TB_MATERIAL_SET_LISTS
for each row
declare
  old TB_MATERIAL_SET_LISTS%rowtype;
  v_merchant_id number;
begin
  old.MATERIAL_SET_LIST_ID := :old.MATERIAL_SET_LIST_ID;
  old.NAME := :old.NAME;
  old.MERCHANT_ID := :old.MERCHANT_ID;

  /* get merchant_id */

  v_merchant_id := nvl(:new.MERCHANT_ID, :old.MERCHANT_ID);

  if inserting then
    add_content_journal_entries.p_MATERIAL_SET_LISTS('A', :new.MATERIAL_SET_LIST_ID, v_merchant_id, old);
  elsif updating then
      add_content_journal_entries.p_MATERIAL_SET_LISTS('U', :new.MATERIAL_SET_LIST_ID, v_merchant_id, old);
  elsif deleting then
    add_content_journal_entries.p_MATERIAL_SET_LISTS('D', :old.MATERIAL_SET_LIST_ID, v_merchant_id, old);
  end if;
end dt_MATERIAL_SET_LISTS;
/