CREATE OR REPLACE TRIGGER sbxtax2.ins_tb_product_categories_pk
 BEFORE
  INSERT
 ON sbxtax2.tb_product_categories
REFERENCING NEW AS NEW OLD AS OLD
 FOR EACH ROW
BEGIN
    IF (:new.product_category_id IS NULL) THEN
        :new.product_category_id := pk_tb_product_categories.nextval;
    END IF;
END;
/