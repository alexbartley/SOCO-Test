CREATE OR REPLACE TRIGGER sbxtax."DT_AUTHORITY_TYPES" 
after insert or update or delete on sbxtax.TB_AUTHORITY_TYPES
for each row
declare
  old TB_AUTHORITY_TYPES%rowtype;
  v_merchant_id number;
begin
  old.AUTHORITY_TYPE_ID := :old.AUTHORITY_TYPE_ID;
  old.MERCHANT_ID := :old.MERCHANT_ID;
  old.NAME := :old.NAME;
  /* get merchant_id */

  v_merchant_id := nvl(:new.MERCHANT_ID, :old.MERCHANT_ID);

  if inserting then
    add_content_journal_entries.p_AUTHORITY_TYPES('A', :new.AUTHORITY_TYPE_ID, v_merchant_id, old);
  elsif updating then
    add_content_journal_entries.p_AUTHORITY_TYPES('U', :new.AUTHORITY_TYPE_ID, v_merchant_id, old);
  elsif deleting then
    add_content_journal_entries.p_AUTHORITY_TYPES('D', :old.AUTHORITY_TYPE_ID, v_merchant_id, old);
  end if;
end dt_AUTHORITY_TYPES;
/