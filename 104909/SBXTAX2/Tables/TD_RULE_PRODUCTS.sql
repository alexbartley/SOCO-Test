CREATE TABLE sbxtax2.td_rule_products (
  rule_id NUMBER(10) NOT NULL,
  rule_product_id NUMBER NOT NULL,
  official_commodity_code VARCHAR2(100 BYTE),
  sabrix_commodity_code VARCHAR2(100 BYTE)
) 
TABLESPACE ositax;