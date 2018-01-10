CREATE TABLE sbxtax.tdr_etl_product_exceptions (
  rate_code VARCHAR2(100 CHAR),
  hierarchy_level NUMBER,
  product_category_id NUMBER,
  tas_nkid NUMBER,
  authority_uuid VARCHAR2(36 CHAR),
  start_date DATE,
  end_date DATE,
  sibling_order NUMBER,
  no_tax VARCHAR2(1 CHAR),
  "EXEMPT" VARCHAR2(1 CHAR),
  nkid NUMBER,
  rid NUMBER,
  is_local VARCHAR2(1 CHAR)
) 
TABLESPACE ositax;