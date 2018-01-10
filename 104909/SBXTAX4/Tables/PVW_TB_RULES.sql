CREATE TABLE sbxtax4.pvw_tb_rules (
  rule_id NUMBER,
  authority_id NUMBER,
  rule_order NUMBER,
  rate_code VARCHAR2(200 CHAR),
  "EXEMPT" VARCHAR2(4 CHAR),
  no_tax VARCHAR2(4 CHAR),
  product_category_id NUMBER,
  input_recovery_percent NUMBER,
  basis_percent NUMBER,
  start_date DATE,
  end_date DATE,
  code VARCHAR2(200 CHAR),
  tax_type VARCHAR2(400 CHAR),
  calculation_method VARCHAR2(200 CHAR),
  authority_uuid VARCHAR2(144 CHAR),
  invoice_description VARCHAR2(1600 CHAR),
  is_local VARCHAR2(16 CHAR),
  reporting_category VARCHAR2(1600 CHAR),
  rule_comment VARCHAR2(4000 CHAR),
  rule_qualifier_set VARCHAR2(512 CHAR),
  unit_of_measure VARCHAR2(1600 CHAR),
  allocated_charge VARCHAR2(1 CHAR),
  related_charge VARCHAR2(1 CHAR),
  input_recovery_amount NUMBER
) 
TABLESPACE ositax
LOB (invoice_description) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (reporting_category) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (rule_comment) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW)
LOB (unit_of_measure) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);