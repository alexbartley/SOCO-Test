CREATE OR REPLACE TRIGGER sbxtax2."DT_CONTRIBUTING_AUTHORITIES" 
after insert or update or delete on sbxtax2.TB_CONTRIBUTING_AUTHORITIES
for each row
declare
  old TB_CONTRIBUTING_AUTHORITIES%rowtype;
  v_merchant_id number;
begin
  old.CONTRIBUTING_AUTHORITY_ID := :old.CONTRIBUTING_AUTHORITY_ID;
  old.AUTHORITY_ID := :old.AUTHORITY_ID;
  old.THIS_AUTHORITY_ID := :old.THIS_AUTHORITY_ID;
  old.MERCHANT_ID := :old.MERCHANT_ID;
  old.START_DATE := :old.START_DATE;
  /* get merchant_id */

  v_merchant_id := nvl(:new.MERCHANT_ID, :old.MERCHANT_ID);

  if inserting then
    add_content_journal_entries.p_CONTRIBUTING_AUTHORITIES('A', :new.CONTRIBUTING_AUTHORITY_ID, v_merchant_id, old);
  elsif updating then
    add_content_journal_entries.p_CONTRIBUTING_AUTHORITIES('U', :new.CONTRIBUTING_AUTHORITY_ID, v_merchant_id, old);
  elsif deleting then
    add_content_journal_entries.p_CONTRIBUTING_AUTHORITIES('D', :old.CONTRIBUTING_AUTHORITY_ID, v_merchant_id, old);
  end if;
end dt_CONTRIBUTING_AUTHORITIES;
/