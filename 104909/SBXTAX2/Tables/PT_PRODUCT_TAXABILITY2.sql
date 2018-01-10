CREATE TABLE sbxtax2.pt_product_taxability2 (
  primary_key NUMBER,
  start_date DATE,
  end_date DATE,
  tax_type VARCHAR2(100 BYTE),
  product_group_id NUMBER,
  effective_rule_order NUMBER,
  merchant_id NUMBER,
  rate_code VARCHAR2(50 BYTE),
  "EXEMPT" VARCHAR2(1 BYTE),
  no_tax VARCHAR2(1 BYTE)
) 
TABLESPACE ositax;