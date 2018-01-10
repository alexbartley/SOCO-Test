CREATE OR REPLACE TRIGGER sbxtax."DT_TB_AUTHORITY_MATERIAL_SETS" 
after insert or update or delete on sbxtax.TB_AUTHORITY_MATERIAL_SETS
for each row
declare
  old TB_AUTHORITY_MATERIAL_SETS%rowtype;
  v_merchant_id number;
begin
  old.AUTHORITY_MATERIAL_SET_ID := :old.AUTHORITY_MATERIAL_SET_ID;
  old.AUTHORITY_ID := :old.AUTHORITY_ID;
  old.MATERIAL_SET_ID := :old.MATERIAL_SET_ID;
  old.START_DATE := :old.START_DATE;
  old.MERCHANT_ID := :old.MERCHANT_ID;
  /* get merchant_id */

  v_merchant_id := nvl(:new.MERCHANT_ID, :old.MERCHANT_ID);

  if inserting then
    add_content_journal_entries.p_AUTHORITY_MATERIAL_SETS('A', :new.AUTHORITY_MATERIAL_SET_ID, v_merchant_id, old);
  elsif updating then
      add_content_journal_entries.p_AUTHORITY_MATERIAL_SETS('U', :new.AUTHORITY_MATERIAL_SET_ID, v_merchant_id, old);
  elsif deleting then
    add_content_journal_entries.p_AUTHORITY_MATERIAL_SETS('D', :old.AUTHORITY_MATERIAL_SET_ID, v_merchant_id, old);
  end if;
end dt_AUTHORITY_MATERIAL_SETS;
/