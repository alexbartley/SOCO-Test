CREATE OR REPLACE TRIGGER sbxtax."DT_DATE_DETERMINATION_LOGIC" 
after insert or update or delete on sbxtax.TB_DATE_DETERMINATION_LOGIC
for each row
declare
  old TB_DATE_DETERMINATION_LOGIC%rowtype;
  v_merchant_id number;
begin
  old.NAME := :old.NAME;
  old.MERCHANT_ID := :old.MERCHANT_ID;
  /* get merchant_id */

  v_merchant_id := nvl(:new.MERCHANT_ID, :old.MERCHANT_ID);

  if inserting then
    add_content_journal_entries.p_DATE_DETERMINATION_LOGIC('A', :new.DATE_DETERMINATION_LOGIC_ID, v_merchant_id, old);
  elsif updating then
    add_content_journal_entries.p_DATE_DETERMINATION_LOGIC('U', :new.DATE_DETERMINATION_LOGIC_ID, v_merchant_id, old);
  elsif deleting then
    add_content_journal_entries.p_DATE_DETERMINATION_LOGIC('D', :old.DATE_DETERMINATION_LOGIC_ID, v_merchant_id, old);
  end if;
end dt_DATE_DETERMINATION_LOGIC;
/