CREATE OR REPLACE TRIGGER sbxtax2."DT_REFERENCE_VALUES" 
after insert or update or delete on sbxtax2.TB_REFERENCE_VALUES
for each row
declare
  old TB_REFERENCE_VALUES%rowtype;
  v_merchant_id number;
begin
  old.REFERENCE_VALUE_ID := :old.REFERENCE_VALUE_ID;
  old.VALUE := :old.VALUE;
  old.REFERENCE_LIST_ID := :old.REFERENCE_LIST_ID;
  old.START_DATE := :old.START_DATE;

  /* get merchant_id */

select
TB_REFERENCE_LISTS.MERCHANT_ID
 into v_merchant_id
 from tb_reference_lists
 where TB_REFERENCE_LISTS.REFERENCE_LIST_ID = nvl(:new.reference_list_id, :old.reference_list_id)
;

  if inserting then
    add_content_journal_entries.p_REFERENCE_VALUES('A', :new.REFERENCE_VALUE_ID, v_merchant_id, old);
  elsif updating then
      add_content_journal_entries.p_REFERENCE_VALUES('U', :new.REFERENCE_VALUE_ID, v_merchant_id, old);
  elsif deleting then
    add_content_journal_entries.p_REFERENCE_VALUES('D', :old.REFERENCE_VALUE_ID, v_merchant_id, old);
  end if;
end dt_REFERENCE_VALUES;
/