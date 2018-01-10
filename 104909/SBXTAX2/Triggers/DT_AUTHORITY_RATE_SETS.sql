CREATE OR REPLACE TRIGGER sbxtax2."DT_AUTHORITY_RATE_SETS" 
after insert or update or delete on sbxtax2.TB_AUTHORITY_RATE_SETS
for each row
declare
  old TB_AUTHORITY_RATE_SETS%rowtype;
  v_merchant_id number;
begin
  old.AUTHORITY_RATE_SET_ID := :old.AUTHORITY_RATE_SET_ID;
  old.AUTHORITY_ID := :old.AUTHORITY_ID;
  old.NAME := :old.NAME;
  old.MERCHANT_ID := :old.MERCHANT_ID;
  /* get merchant_id */

  v_merchant_id := nvl(:new.MERCHANT_ID, :old.MERCHANT_ID);

  if inserting then
    add_content_journal_entries.p_AUTHORITY_RATE_SETS('A', :new.AUTHORITY_RATE_SET_ID, v_merchant_id, old);
  elsif updating then
      add_content_journal_entries.p_AUTHORITY_RATE_SETS('U', :new.AUTHORITY_RATE_SET_ID, v_merchant_id, old);
  elsif deleting then
    add_content_journal_entries.p_AUTHORITY_RATE_SETS('D', :old.AUTHORITY_RATE_SET_ID, v_merchant_id, old);
  end if;
end dt_AUTHORITY_RATE_SETS;
/