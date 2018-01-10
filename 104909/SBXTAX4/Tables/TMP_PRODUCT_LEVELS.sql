CREATE TABLE sbxtax4.tmp_product_levels (
  product_category_id NUMBER NOT NULL,
  prodcode VARCHAR2(50 BYTE),
  hlevel NUMBER,
  parent_product_category_id NUMBER,
  product_group_id NUMBER NOT NULL
) 
TABLESPACE ositax;