CREATE TABLE sbxtax4.mp_tas_rq (
  juris_nkid NUMBER,
  jta_nkid NUMBER,
  tas_nkid NUMBER,
  rule_qualifier_set VARCHAR2(4000 CHAR),
  start_date DATE,
  end_date DATE
) 
TABLESPACE ositax
LOB (rule_qualifier_set) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);