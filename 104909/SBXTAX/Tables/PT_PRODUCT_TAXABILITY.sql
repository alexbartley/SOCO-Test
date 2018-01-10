CREATE TABLE sbxtax.pt_product_taxability (
  primary_key NUMBER NOT NULL,
  authority_id NUMBER NOT NULL,
  tax_type VARCHAR2(100 BYTE),
  product_group_id NUMBER NOT NULL,
  merchant_id NUMBER NOT NULL,
  effective_rule_order NUMBER NOT NULL,
  rate_code VARCHAR2(10 BYTE),
  "EXEMPT" VARCHAR2(1 BYTE) NOT NULL,
  no_tax VARCHAR2(1 BYTE) NOT NULL,
  analyzed_date DATE NOT NULL
) 
TABLESPACE ositax;