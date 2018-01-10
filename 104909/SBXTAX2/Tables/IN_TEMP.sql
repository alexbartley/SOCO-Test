CREATE TABLE sbxtax2.in_temp (
  rule_order VARCHAR2(20 BYTE),
  code VARCHAR2(20 BYTE),
  rate_code VARCHAR2(10 BYTE),
  "EXEMPT" VARCHAR2(2 BYTE),
  product_id NUMBER
) 
TABLESPACE ositax;