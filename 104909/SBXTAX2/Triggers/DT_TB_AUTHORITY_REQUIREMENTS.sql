CREATE OR REPLACE TRIGGER sbxtax2."DT_TB_AUTHORITY_REQUIREMENTS" 
 AFTER 
 INSERT OR DELETE OR UPDATE
 ON sbxtax2.TB_AUTHORITY_REQUIREMENTS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW 
declare
  old TB_AUTHORITY_REQUIREMENTS%rowtype;
  v_merchant_id number;
begin
  old.AUTHORITY_REQUIREMENT_ID := :old.AUTHORITY_REQUIREMENT_ID;
  old.AUTHORITY_ID := :old.AUTHORITY_ID;
  old.NAME := :old.NAME;
  old.START_DATE := :old.START_DATE;
  old.MERCHANT_ID := :old.MERCHANT_ID;
  /* get merchant_id */

  v_merchant_id := nvl(:new.MERCHANT_ID, :old.MERCHANT_ID);

  if inserting then
    add_content_journal_entries.p_AUTHORITY_REQUIREMENTS('A', :new.AUTHORITY_REQUIREMENT_ID, v_merchant_id, old);
  elsif updating then
    if (:new.name != :old.name or
       (:new.condition is not null and (:old.condition is null or :new.condition != :old.condition)) or
       (:new.value is not null and (:old.value is null or :new.value != :old.value)) or
        (:new.end_date is not null and (:old.end_Date is null or :new.end_Date != :old.end_Date)) or
        (:new.start_date is not null and (:old.start_Date is null or :new.start_Date != :old.start_Date))
       ) then
      add_content_journal_entries.p_AUTHORITY_REQUIREMENTS('U', :new.AUTHORITY_REQUIREMENT_ID, v_merchant_id, old);
    end if;
  elsif deleting then
    add_content_journal_entries.p_AUTHORITY_REQUIREMENTS('D', :old.AUTHORITY_REQUIREMENT_ID, v_merchant_id, old);
  end if;
end dt_AUTHORITY_REQUIREMENTS;
/