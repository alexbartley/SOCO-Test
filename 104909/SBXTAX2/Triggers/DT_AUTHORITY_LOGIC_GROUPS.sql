CREATE OR REPLACE TRIGGER sbxtax2."DT_AUTHORITY_LOGIC_GROUPS" 
after insert or update or delete on sbxtax2.TB_AUTHORITY_LOGIC_GROUPS
for each row
declare
  old TB_AUTHORITY_LOGIC_GROUPS%rowtype;
  v_merchant_id number;
begin
  old.AUTHORITY_LOGIC_GROUP_ID := :old.AUTHORITY_LOGIC_GROUP_ID;
  old.MERCHANT_ID := :old.MERCHANT_ID;
  old.NAME := :old.NAME;
  /* get merchant_id */

  v_merchant_id := nvl(:old.merchant_id, :new.merchant_id);

  if inserting then
    add_content_journal_entries.p_AUTHORITY_LOGIC_GROUPS('A', :new.AUTHORITY_LOGIC_GROUP_ID, v_merchant_id, old);
  elsif updating then
    add_content_journal_entries.p_AUTHORITY_LOGIC_GROUPS('U', :new.AUTHORITY_LOGIC_GROUP_ID, v_merchant_id, old);
  elsif deleting then
    add_content_journal_entries.p_AUTHORITY_LOGIC_GROUPS('D', :old.AUTHORITY_LOGIC_GROUP_ID, v_merchant_id, old);
  end if;
end dt_AUTHORITY_LOGIC_GROUPS;
/