CREATE OR REPLACE TRIGGER sbxtax."DT_AUTHORITIES" 
after insert or update or delete on sbxtax.TB_AUTHORITIES
for each row
declare
  old TB_AUTHORITIES%rowtype;
  v_merchant_id number;
begin
  old.AUTHORITY_ID := :old.AUTHORITY_ID;
  old.NAME := :old.NAME;
  old.MERCHANT_ID := :old.MERCHANT_ID;
  /* get merchant_id */

  v_merchant_id := nvl(:new.MERCHANT_ID, :old.MERCHANT_ID);

  if inserting then
    add_content_journal_entries.p_AUTHORITIES('A', :new.AUTHORITY_ID, v_merchant_id, old);
  elsif updating then
    add_content_journal_entries.p_AUTHORITIES('U', :new.AUTHORITY_ID, v_merchant_id, old);
  elsif deleting then
    add_content_journal_entries.p_AUTHORITIES('D', :old.AUTHORITY_ID, v_merchant_id, old);
  end if;
end dt_AUTHORITIES;
/