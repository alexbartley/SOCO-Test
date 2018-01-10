CREATE TABLE sbxtax4.tdr_etl_rule_taxes (
  nkid NUMBER,
  rate_code VARCHAR2(32 CHAR),
  start_date DATE,
  end_date DATE,
  extract_id NUMBER,
  rid NUMBER
) 
TABLESPACE ositax;