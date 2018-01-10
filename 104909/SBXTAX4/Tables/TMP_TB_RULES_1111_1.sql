CREATE TABLE sbxtax4.tmp_tb_rules_1111_1 (
  rule_id NUMBER,
  rule_order NUMBER NOT NULL,
  auth_report_group_id NUMBER,
  "ACTIVE" VARCHAR2(1 CHAR),
  product_category_id NUMBER,
  authority_id NUMBER,
  code VARCHAR2(50 CHAR),
  exempt_reason_code VARCHAR2(50 CHAR),
  calculation_method VARCHAR2(50 CHAR),
  invoice_description VARCHAR2(100 CHAR),
  "EXEMPT" VARCHAR2(1 CHAR),
  start_date DATE NOT NULL,
  end_date DATE,
  deleted VARCHAR2(1 CHAR),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  rate_code VARCHAR2(50 CHAR),
  basis_percent NUMBER,
  rule_comment VARCHAR2(2000 CHAR),
  tax_type VARCHAR2(100 CHAR),
  is_local VARCHAR2(1 CHAR),
  local_authority_type_id NUMBER,
  input_recovery_amount NUMBER,
  input_recovery_percent NUMBER,
  unit_of_measure VARCHAR2(100 CHAR),
  no_tax VARCHAR2(1 CHAR),
  reporting_category VARCHAR2(100 CHAR),
  tax_treatment VARCHAR2(100 CHAR),
  material_set_list_id NUMBER(10),
  authority_rate_set_id NUMBER(10),
  rule_qualifier_set VARCHAR2(1000 CHAR),
  "INHERITED" NUMBER,
  authority_uuid VARCHAR2(144 CHAR),
  nkid NUMBER,
  rid NUMBER,
  tat_nkid NUMBER,
  allocated_charge VARCHAR2(1 CHAR),
  related_charge VARCHAR2(1 CHAR)
) 
TABLESPACE ositax
LOB (rule_comment) STORE AS SECUREFILE (
  ENABLE STORAGE IN ROW);