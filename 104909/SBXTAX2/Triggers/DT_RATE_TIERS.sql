CREATE OR REPLACE TRIGGER sbxtax2."DT_RATE_TIERS" 
  after insert or update or delete on sbxtax2.TB_RATE_TIERS
  for each row
declare
  old TB_RATE_TIERS%rowtype;
  v_merchant_id number;
begin
  old.RATE_TIER_ID := :old.RATE_TIER_ID;
  old.RATE_ID := :old.RATE_ID;
  old.AMOUNT_LOW := :old.AMOUNT_LOW;

  /* get merchant_id */
select
TB_RATES.MERCHANT_ID
 into v_merchant_id
 from TB_RATES
 where TB_RATES.RATE_ID = nvl(:new.rate_id, :old.rate_id)
;

  if inserting then
    add_content_journal_entries.p_RATE_TIERS('A', :new.RATE_TIER_ID, v_merchant_id, old);
  elsif updating then
    add_content_journal_entries.p_RATE_TIERS('U', :new.RATE_TIER_ID, v_merchant_id, old);
  elsif deleting then
    add_content_journal_entries.p_RATE_TIERS('D', :old.RATE_TIER_ID, v_merchant_id, old);
  end if;

end dt_RATE_TIERS;
/