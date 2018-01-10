CREATE OR REPLACE TRIGGER sbxtax2."DT_PRODUCT_ZONES" 
after insert or update or delete on sbxtax2.TB_PRODUCT_ZONES
for each row
declare
  old TB_PRODUCT_ZONES%rowtype;
  v_merchant_id number;
begin
  old.PRODUCT_ZONE_ID := :old.PRODUCT_ZONE_ID;
  old.PRODUCT_CATEGORY_ID := :old.PRODUCT_CATEGORY_ID;
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
    add_content_journal_entries.p_PRODUCT_ZONES('A', :new.PRODUCT_ZONE_ID, v_merchant_id, old);
  elsif updating then
    add_content_journal_entries.p_PRODUCT_ZONES('U', :new.PRODUCT_ZONE_ID, v_merchant_id, old);
  elsif deleting then
    add_content_journal_entries.p_PRODUCT_ZONES('D', :old.PRODUCT_ZONE_ID, v_merchant_id, old);
  end if;
end dt_PRODUCT_ZONES;
/