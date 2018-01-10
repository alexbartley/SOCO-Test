CREATE OR REPLACE TRIGGER sbxtax2."DT_MATERIAL_SETS" 
after insert or update or delete on sbxtax2.TB_MATERIAL_SETS
for each row
declare
  old TB_MATERIAL_SETS%rowtype;
  v_merchant_id number;
begin
  old.MATERIAL_SET_ID := :old.MATERIAL_SET_ID;
  old.NAME := :old.NAME;
  old.MERCHANT_ID := :old.MERCHANT_ID;

  /* get merchant_id */

  v_merchant_id := nvl(:new.MERCHANT_ID, :old.MERCHANT_ID);

  if inserting then
    add_content_journal_entries.p_MATERIAL_SETS('A', :new.MATERIAL_SET_ID, v_merchant_id, old);
  elsif updating then
      add_content_journal_entries.p_MATERIAL_SETS('U', :new.MATERIAL_SET_ID, v_merchant_id, old);
  elsif deleting then
    add_content_journal_entries.p_MATERIAL_SETS('D', :old.MATERIAL_SET_ID, v_merchant_id, old);
  end if;
end dt_MATERIAL_SETS;
/