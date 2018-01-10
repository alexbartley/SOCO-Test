CREATE TABLE sbxtax4.tmp_jira_qae_1827 (
  authority_name VARCHAR2(200 CHAR),
  rule_order NUMBER,
  rate_code VARCHAR2(50 CHAR),
  "EXEMPT" VARCHAR2(10 CHAR),
  no_tax VARCHAR2(10 CHAR),
  related_charge VARCHAR2(10 CHAR),
  allocated_charge VARCHAR2(10 CHAR),
  tax_type VARCHAR2(200 CHAR),
  commodity_code VARCHAR2(100 CHAR),
  product_name VARCHAR2(300 CHAR),
  material_list VARCHAR2(10 CHAR),
  rate_set VARCHAR2(10 CHAR),
  start_date VARCHAR2(50 CHAR),
  end_date VARCHAR2(50 CHAR),
  calculation_method VARCHAR2(100 CHAR),
  tax_code VARCHAR2(50 CHAR),
  exempt_reason VARCHAR2(20 CHAR),
  basis_percent VARCHAR2(100 CHAR),
  input_recovery_amount NUMBER,
  input_recovery_percent VARCHAR2(10 CHAR),
  tax_treatment VARCHAR2(20 CHAR),
  unit_measure VARCHAR2(20 CHAR),
  invoice_description VARCHAR2(30 CHAR),
  cascading VARCHAR2(20 CHAR),
  reporting_category VARCHAR2(20 CHAR),
  qualifier_type VARCHAR2(50 CHAR),
  "ELEMENT" VARCHAR2(100 CHAR),
  authority VARCHAR2(200 CHAR),
  "OPERATOR" VARCHAR2(50 CHAR),
  "VALUE" VARCHAR2(200 CHAR),
  reference_list VARCHAR2(200 CHAR),
  rq_start_date VARCHAR2(50 CHAR),
  rq_end_date VARCHAR2(50 CHAR)
) 
TABLESPACE ositax;