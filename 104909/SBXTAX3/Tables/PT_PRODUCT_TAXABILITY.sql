CREATE TABLE sbxtax3.pt_product_taxability (
  primary_key NUMBER NOT NULL,
  authority_id NUMBER NOT NULL,
  tax_type VARCHAR2(100 BYTE),
  product_group_id NUMBER NOT NULL,
  rule_order NUMBER NOT NULL,
  updated_date DATE NOT NULL,
  merchant_id NUMBER NOT NULL
) 
TABLESPACE ositax;