CREATE OR REPLACE TRIGGER sbxtax."DT_AUTHORITY_LOGIC_ELEMENTS" 
after insert or update or delete on sbxtax.TB_AUTHORITY_LOGIC_ELEMENTS
for each row
declare
  old TB_AUTHORITY_LOGIC_ELEMENTS%rowtype;
  v_merchant_id number;
begin
  old.AUTHORITY_LOGIC_ELEMENT_ID := :old.AUTHORITY_LOGIC_ELEMENT_ID;
  old.AUTHORITY_LOGIC_GROUP_ID := :old.AUTHORITY_LOGIC_GROUP_ID;
  old.CONDITION := :old.CONDITION;
  old.SELECTOR := :old.SELECTOR;
  old.START_DATE := :old.START_DATE;
  old.VALUE := :old.VALUE;
  /* get merchant_id */

select
      MERCHANT_ID
 into v_merchant_id
 from tb_authority_logic_groups
 where AUTHORITY_LOGIC_GROUP_ID = nvl(:new.authority_logic_group_id, :old.authority_logic_group_id)
;
  if inserting then
    add_content_journal_entries.p_AUTHORITY_LOGIC_ELEMENTS('A', :new.AUTHORITY_LOGIC_ELEMENT_ID, v_merchant_id, old);
  elsif updating then
    add_content_journal_entries.p_AUTHORITY_LOGIC_ELEMENTS('U', :new.AUTHORITY_LOGIC_ELEMENT_ID, v_merchant_id, old);
  elsif deleting then
    add_content_journal_entries.p_AUTHORITY_LOGIC_ELEMENTS('D', :old.AUTHORITY_LOGIC_ELEMENT_ID, v_merchant_id, old);
  end if;
end dt_AUTHORITY_LOGIC_ELEMENTS;
/