CREATE OR REPLACE TRIGGER sbxtax4."INS_TB_PRODUCT_CATEGORIES_PK" 
 BEFORE
  INSERT
 ON sbxtax4.tb_product_categories
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    IF (:new.product_category_id IS NULL) THEN
        :new.product_category_id := pk_tb_product_categories.nextval;
    END IF;
END;
/