CREATE OR REPLACE TRIGGER sbxtax3."DT_ZONE_AUTHORITIES" 
after insert or update or delete on sbxtax3.TB_ZONE_AUTHORITIES
for each row
declare
  old TB_ZONE_AUTHORITIES%rowtype;
  v_merchant_id number;
begin
  old.ZONE_AUTHORITY_ID := :old.ZONE_AUTHORITY_ID;
  old.ZONE_ID := :old.ZONE_ID;
  old.AUTHORITY_ID := :old.AUTHORITY_ID;
  /* get merchant_id */

select
TB_AUTHORITIES.MERCHANT_ID
 into v_merchant_id
 from tb_authorities
 where TB_AUTHORITIES.AUTHORITY_ID = nvl(:new.authority_id, :old.authority_id)
;

  if inserting then
    add_content_journal_entries.p_ZONE_AUTHORITIES('A', :new.ZONE_AUTHORITY_ID, v_merchant_id, old);
  elsif updating then
    add_content_journal_entries.p_ZONE_AUTHORITIES('U', :new.ZONE_AUTHORITY_ID, v_merchant_id, old);
  elsif deleting then
    add_content_journal_entries.p_ZONE_AUTHORITIES('D', :old.ZONE_AUTHORITY_ID, v_merchant_id, old);
  end if;
end dt_ZONE_AUTHORITIES;
/