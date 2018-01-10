CREATE TABLE sbxtax.tdr_etl_product_categories (
  "NAME" VARCHAR2(500 CHAR),
  description VARCHAR2(1000 CHAR),
  prodcode VARCHAR2(100 CHAR),
  sort_key VARCHAR2(128 CHAR),
  nkid NUMBER,
  product_tree VARCHAR2(100 CHAR),
  extract_id NUMBER,
  rid NUMBER
) 
TABLESPACE ositax;