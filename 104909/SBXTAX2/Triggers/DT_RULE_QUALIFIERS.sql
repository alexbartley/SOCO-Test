CREATE OR REPLACE TRIGGER sbxtax2.dt_RULE_QUALIFIERS
after insert or update or delete on sbxtax2.TB_RULE_QUALIFIERS
for each row
declare
  old TB_RULE_QUALIFIERS%rowtype;
  v_merchant_id number;
begin
  old.RULE_QUALIFIER_ID := :old.RULE_QUALIFIER_ID;
  old.RULE_QUALIFIER_TYPE := :old.RULE_QUALIFIER_TYPE;
  old.RULE_ID := :old.RULE_ID;
  old.START_DATE := :old.START_DATE;
  old.ELEMENT := :old.ELEMENT;
  old.VALUE := :old.VALUE;
  old.OPERATOR := :old.OPERATOR;
  old.AUTHORITY_ID := :old.AUTHORITY_ID;
  old.REFERENCE_LIST_ID := :old.REFERENCE_LIST_ID;
  /* get merchant_id */

select
TB_RULES.MERCHANT_ID
 into v_merchant_id
 from tb_rules
 where TB_RULES.RULE_ID = nvl(:new.rule_id, :old.rule_id)
;
  if inserting then
    add_content_journal_entries.p_RULE_QUALIFIERS('A', :new.RULE_QUALIFIER_ID, v_merchant_id, old);
  elsif updating then
    add_content_journal_entries.p_RULE_QUALIFIERS('U', :new.RULE_QUALIFIER_ID, v_merchant_id, old);
  elsif deleting then
    add_content_journal_entries.p_RULE_QUALIFIERS('D', :old.RULE_QUALIFIER_ID, v_merchant_id, old);
  end if;
end dt_RULE_QUALIFIERS;
/