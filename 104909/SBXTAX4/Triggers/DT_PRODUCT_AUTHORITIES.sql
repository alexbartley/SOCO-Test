CREATE OR REPLACE TRIGGER sbxtax4."DT_PRODUCT_AUTHORITIES" 
after insert or update or delete on sbxtax4.TB_PRODUCT_AUTHORITIES
for each row
declare
  old TB_PRODUCT_AUTHORITIES%rowtype;
  v_merchant_id number;
begin
  old.PRODUCT_AUTHORITY_ID := :old.PRODUCT_AUTHORITY_ID;
  old.PRODUCT_CATEGORY_ID := :old.PRODUCT_CATEGORY_ID;
  old.AUTHORITY_TYPE_ID := :old.AUTHORITY_TYPE_ID;
  old.AUTHORITY_ID := :old.AUTHORITY_ID;
  old.ZONE_ID := :old.ZONE_ID;
  old.START_DATE := :old.START_DATE;
  /* get merchant_id */

select
TB_PRODUCT_CATEGORIES.MERCHANT_ID
 into v_merchant_id
 from tb_product_categories
 where TB_PRODUCT_CATEGORIES.PRODUCT_CATEGORY_ID = nvl(:new.product_category_id, :old.product_category_id)
;

  if inserting then
    add_content_journal_entries.p_PRODUCT_AUTHORITIES('A', :new.PRODUCT_AUTHORITY_ID, v_merchant_id, old);
  elsif updating then
    add_content_journal_entries.p_PRODUCT_AUTHORITIES('U', :new.PRODUCT_AUTHORITY_ID, v_merchant_id, old);
  elsif deleting then
    add_content_journal_entries.p_PRODUCT_AUTHORITIES('D', :old.PRODUCT_AUTHORITY_ID, v_merchant_id, old);
  end if;
end dt_PRODUCT_AUTHORITIES;
/