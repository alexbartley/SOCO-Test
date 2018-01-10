CREATE OR REPLACE TRIGGER sbxtax3."DT_PRODUCT_CATEGORIES" 
after insert or update or delete on sbxtax3.TB_PRODUCT_CATEGORIES
for each row
declare
  old TB_PRODUCT_CATEGORIES%rowtype;
  v_merchant_id number;
begin
  old.PRODUCT_CATEGORY_ID := :old.PRODUCT_CATEGORY_ID;
  old.PRODUCT_GROUP_ID := :old.PRODUCT_GROUP_ID;
  old.NAME := :old.NAME;
  old.PARENT_PRODUCT_CATEGORY_ID := :old.PARENT_PRODUCT_CATEGORY_ID;
  old.MERCHANT_ID := :old.MERCHANT_ID;
  old.PRODCODE := :old.PRODCODE;
  /* get merchant_id */

  v_merchant_id := nvl(:new.MERCHANT_ID, :old.MERCHANT_ID);

  if inserting then
    add_content_journal_entries.p_PRODUCT_CATEGORIES('A', :new.PRODUCT_CATEGORY_ID, v_merchant_id, old);
  elsif updating then
    add_content_journal_entries.p_PRODUCT_CATEGORIES('U', :new.PRODUCT_CATEGORY_ID, v_merchant_id, old);
  elsif deleting then
    add_content_journal_entries.p_PRODUCT_CATEGORIES('D', :old.PRODUCT_CATEGORY_ID, v_merchant_id, old);
  end if;
end dt_PRODUCT_CATEGORIES;
/