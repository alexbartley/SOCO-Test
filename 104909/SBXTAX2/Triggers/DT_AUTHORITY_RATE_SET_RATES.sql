CREATE OR REPLACE TRIGGER sbxtax2."DT_AUTHORITY_RATE_SET_RATES" 
after insert or update or delete on sbxtax2.TB_AUTHORITY_RATE_SET_RATES
for each row
declare
  old TB_AUTHORITY_RATE_SET_RATES%rowtype;
  v_merchant_id number;
begin
  old.AUTHORITY_RATE_SET_RATE_ID := :old.AUTHORITY_RATE_SET_RATE_ID;
  old.AUTHORITY_RATE_SET_ID := :old.AUTHORITY_RATE_SET_ID;
  old.PROCESS_ORDER := :old.PROCESS_ORDER;
  old.START_DATE := :old.START_DATE;
  /* get merchant_id */

select
TB_AUTHORITY_RATE_SETS.MERCHANT_ID
 into v_merchant_id
 from tb_authority_rate_sets
 where TB_AUTHORITY_RATE_SETS.AUTHORITY_RATE_SET_ID = nvl(:new.authority_rate_set_id, :old.authority_rate_set_id)
;

  if inserting then
    add_content_journal_entries.p_AUTHORITY_RATE_SET_RATES('A', :new.AUTHORITY_RATE_SET_RATE_ID, v_merchant_id, old);
  elsif updating then
      add_content_journal_entries.p_AUTHORITY_RATE_SET_RATES('U', :new.AUTHORITY_RATE_SET_RATE_ID, v_merchant_id, old);
  elsif deleting then
    add_content_journal_entries.p_AUTHORITY_RATE_SET_RATES('D', :old.AUTHORITY_RATE_SET_RATE_ID, v_merchant_id, old);
  end if;
end dt_AUTHORITY_RATE_SET_RATES;
/