CREATE TABLE sbxtax4.tmp_taxabilities (
  rule_id NUMBER,
  product_category_id NUMBER,
  tax_type VARCHAR2(4 CHAR),
  start_date DATE,
  end_date DATE,
  rule_qualifier_set VARCHAR2(16 CHAR),
  rate_code VARCHAR2(32 CHAR),
  specific_applicability VARCHAR2(32 CHAR),
  rule_order NUMBER
) 
TABLESPACE ositax;