CREATE TABLE sbxtax.pvw_tb_product_categories (
  product_category_id NUMBER,
  parent_product_category_id NUMBER,
  product_group_id NUMBER,
  "NAME" VARCHAR2(100 CHAR),
  description VARCHAR2(250 CHAR),
  prodcode VARCHAR2(50 CHAR),
  nkid NUMBER
) 
TABLESPACE ositax;