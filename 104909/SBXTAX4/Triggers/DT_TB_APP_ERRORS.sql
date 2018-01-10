CREATE OR REPLACE TRIGGER sbxtax4."DT_TB_APP_ERRORS" 
after insert or update or delete on sbxtax4.TB_APP_ERRORS
for each row
declare
  old TB_APP_ERRORS%rowtype;
  v_merchant_id number;
begin
  old.ERROR_ID := :old.ERROR_ID;
  old.AUTHORITY_ID := :old.AUTHORITY_ID;
  old.ERROR_NUM := :old.ERROR_NUM;
  old.MERCHANT_ID := :old.MERCHANT_ID;
  old.ERROR_SEVERITY := old.ERROR_SEVERITY;
  /* get merchant_id */

  v_merchant_id := nvl(:new.MERCHANT_ID, :old.MERCHANT_ID);

  if inserting then
    add_content_journal_entries.p_APP_ERRORS('A', :new.ERROR_ID, v_merchant_id, old);
  elsif updating then
      add_content_journal_entries.p_APP_ERRORS('U', :new.ERROR_ID, v_merchant_id, old);
  elsif deleting then
    add_content_journal_entries.p_APP_ERRORS('D', :old.ERROR_ID, v_merchant_id, old);
  end if;
end dt_APP_ERRORS;
/