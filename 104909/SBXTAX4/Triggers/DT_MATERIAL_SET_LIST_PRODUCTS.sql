CREATE OR REPLACE TRIGGER sbxtax4."DT_MATERIAL_SET_LIST_PRODUCTS" 
after insert or update or delete on sbxtax4.TB_MATERIAL_SET_LIST_PRODUCTS
for each row
declare
  old TB_MATERIAL_SET_LIST_PRODUCTS%rowtype;
  v_merchant_id number;
begin
  old.MATERIAL_SET_LIST_PRODUCT_ID := :old.MATERIAL_SET_LIST_PRODUCT_ID;
  old.MATERIAL_SET_LIST_ID := :old.MATERIAL_SET_LIST_ID;
  old.PRODUCT_CATEGORY_ID := :old.PRODUCT_CATEGORY_ID;
  old.START_DATE := :old.START_DATE;

  /* get merchant_id */

select
TB_MATERIAL_SET_LISTS.MERCHANT_ID
 into v_merchant_id
 from tb_material_set_lists
 where TB_MATERIAL_SET_LISTS.MATERIAL_SET_LIST_ID = nvl(:new.material_set_list_id, :old.material_set_list_id)
;

  if inserting then
    add_content_journal_entries.p_MATERIAL_SET_LIST_PRODUCTS('A', :new.MATERIAL_SET_LIST_PRODUCT_ID, v_merchant_id, old);
  elsif updating then
      add_content_journal_entries.p_MATERIAL_SET_LIST_PRODUCTS('U', :new.MATERIAL_SET_LIST_PRODUCT_ID, v_merchant_id, old);
  elsif deleting then
    add_content_journal_entries.p_MATERIAL_SET_LIST_PRODUCTS('D', :old.MATERIAL_SET_LIST_PRODUCT_ID, v_merchant_id, old);
  end if;
end dt_MATERIAL_SET_LIST_PRODUCTS;
/