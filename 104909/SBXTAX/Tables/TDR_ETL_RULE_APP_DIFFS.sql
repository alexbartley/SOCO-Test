CREATE TABLE sbxtax.tdr_etl_rule_app_diffs (
  jta_nkid NUMBER,
  app_type VARCHAR2(50 CHAR),
  rate_code VARCHAR2(50 CHAR),
  commodity_nkid NUMBER,
  inv_desc VARCHAR2(100 CHAR),
  start_date DATE,
  end_date DATE,
  "ACTION" VARCHAR2(50 CHAR),
  ref_rule_order NUMBER,
  tat_id NUMBER,
  tat_nkid NUMBER,
  tax_type VARCHAR2(10 BYTE),
  default_taxability VARCHAR2(1 BYTE)
) 
TABLESPACE ositax;