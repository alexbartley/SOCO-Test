CREATE TABLE sbxtax2.letter_verify_rules (
  authority VARCHAR2(100 BYTE),
  rule_order NUMBER,
  rate_code VARCHAR2(20 BYTE),
  product VARCHAR2(250 BYTE)
) 
TABLESPACE ositax;