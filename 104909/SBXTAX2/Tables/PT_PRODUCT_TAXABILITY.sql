CREATE TABLE sbxtax2.pt_product_taxability (
  primary_key NUMBER NOT NULL,
  authority_id NUMBER NOT NULL,
  tax_type VARCHAR2(100 BYTE),
  product_group_id NUMBER NOT NULL,
  effective_rule_order NUMBER NOT NULL,
  merchant_id NUMBER NOT NULL,
  no_tax VARCHAR2(1 BYTE),
  analyzed_date DATE,
  "EXEMPT" VARCHAR2(1 BYTE),
  rate_code VARCHAR2(10 BYTE)
) 
TABLESPACE ositax;