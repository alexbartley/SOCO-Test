CREATE OR REPLACE TRIGGER sbxtax."DT_ZONES" 
after insert or update or delete on sbxtax.TB_ZONES
for each row
declare
  old TB_ZONES%rowtype;
  v_merchant_id number;
begin
  old.ZONE_ID := :old.ZONE_ID;
  old.NAME := :old.NAME;
  old.PARENT_ZONE_ID := :old.PARENT_ZONE_ID;
  old.MERCHANT_ID := :old.MERCHANT_ID;
  old.ZONE_LEVEL_ID := :old.ZONE_LEVEL_ID;
  /* get merchant_id */

  v_merchant_id := nvl(:new.MERCHANT_ID, :old.MERCHANT_ID);

  if inserting then
    add_content_journal_entries.p_ZONES('A', :new.ZONE_ID, v_merchant_id, old);
  elsif updating then
    add_content_journal_entries.p_ZONES('U', :new.ZONE_ID, v_merchant_id, old);
  elsif deleting then
    add_content_journal_entries.p_ZONES('D', :old.ZONE_ID, v_merchant_id, old);
  end if;
end dt_ZONES;
/