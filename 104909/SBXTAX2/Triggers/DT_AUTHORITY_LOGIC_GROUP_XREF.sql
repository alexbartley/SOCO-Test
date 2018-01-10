CREATE OR REPLACE TRIGGER sbxtax2."DT_AUTHORITY_LOGIC_GROUP_XREF" 
after insert or update or delete on sbxtax2.TB_AUTHORITY_LOGIC_GROUP_XREF
for each row
declare
  old TB_AUTHORITY_LOGIC_GROUP_XREF%rowtype;
  aold TB_AUTHORITIES%rowtype;
  v_merchant_id number;
begin
  old.AUTHORITY_LOGIC_GROUP_XREF_ID := :old.AUTHORITY_LOGIC_GROUP_XREF_ID;
  old.AUTHORITY_ID := :old.AUTHORITY_ID;
  old.AUTHORITY_LOGIC_GROUP_ID := :old.AUTHORITY_LOGIC_GROUP_ID;
  old.START_DATE := :old.START_DATE;
  old.PROCESS_ORDER := :old.PROCESS_ORDER;

  /* get merchant_id */

select MERCHANT_ID, NAME, authority_id
  into v_merchant_id, aold.NAME, aold.AUTHORITY_ID
  from tb_authorities
 where AUTHORITY_ID = nvl(:new.authority_id, :old.authority_id);

  aold.MERCHANT_ID := v_merchant_id;

  if inserting then
    add_content_journal_entries.p_AUTHORITY_LOGIC_GROUP_XREF('A', :new.AUTHORITY_LOGIC_GROUP_XREF_ID, v_merchant_id, old);
  elsif updating then
    add_content_journal_entries.p_AUTHORITY_LOGIC_GROUP_XREF('U', :new.AUTHORITY_LOGIC_GROUP_XREF_ID, v_merchant_id, old);
  elsif deleting then
    add_content_journal_entries.p_AUTHORITY_LOGIC_GROUP_XREF('D', :old.AUTHORITY_LOGIC_GROUP_XREF_ID, v_merchant_id, old);
  end if;
  add_content_journal_entries.p_AUTHORITIES('U', aold.authority_id, v_merchant_id, aold);
end dt_AUTHORITY_LOGIC_GROUP_XREF;
/