CREATE TABLE sbxtax4.tmp_product_taxabilities (
  product_id NUMBER,
  authority_id NUMBER,
  tax_type VARCHAR2(16 CHAR),
  product_group_id NUMBER,
  rate_code VARCHAR2(32 CHAR),
  "EXEMPT" VARCHAR2(1 CHAR),
  no_tax VARCHAR2(1 CHAR),
  start_date DATE,
  end_date DATE,
  input_recovery NUMBER,
  basis_percent NUMBER,
  calculation_method NUMBER,
  rule_order NUMBER,
  invoice_description VARCHAR2(256 CHAR)
) 
TABLESPACE ositax;