CREATE TABLE sbxtax.tdr_etl_rule_products (
  product_tree VARCHAR2(100 CHAR),
  rid NUMBER,
  nkid NUMBER,
  rule_qual_order NUMBER,
  product_tree_id NUMBER,
  h_code VARCHAR2(128 CHAR),
  is_local VARCHAR2(1 CHAR),
  extract_id NUMBER,
  rule_qualifier_set VARCHAR2(1000 CHAR),
  authority_uuid VARCHAR2(36 CHAR),
  rate_code VARCHAR2(32 CHAR),
  lowest_level NUMBER,
  sibling_order NUMBER,
  highest_level NUMBER,
  "EXEMPT" VARCHAR2(1 CHAR),
  no_tax VARCHAR2(1 CHAR),
  tran_tax_id NUMBER,
  hierarchy_level NUMBER,
  rule_order NUMBER,
  end_date DATE,
  start_date DATE,
  commodity_nkid NUMBER,
  tax_type VARCHAR2(10 CHAR)
) 
TABLESPACE ositax;