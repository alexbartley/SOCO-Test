CREATE TABLE sbxtax4.ht_rules (
  "ACTIVE" VARCHAR2(1 BYTE),
  authority_id NUMBER(10),
  authority_rate_set_id NUMBER(10),
  auth_report_group_id NUMBER(10),
  basis_percent NUMBER(31,10),
  calculation_method VARCHAR2(50 BYTE),
  code VARCHAR2(50 BYTE),
  created_by NUMBER(10),
  creation_date DATE,
  deleted VARCHAR2(1 BYTE),
  end_date DATE,
  "EXEMPT" VARCHAR2(1 BYTE),
  exempt_reason_code VARCHAR2(50 BYTE),
  input_recovery_amount NUMBER(31,5),
  input_recovery_percent NUMBER(31,10),
  invoice_description VARCHAR2(100 BYTE),
  is_dependent_product VARCHAR2(1 BYTE),
  is_local VARCHAR2(1 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  local_authority_type_id NUMBER(10),
  material_set_list_id NUMBER(10),
  merchant_id NUMBER(10),
  no_tax VARCHAR2(1 BYTE),
  product_category_id NUMBER(10),
  rate_code VARCHAR2(50 BYTE),
  reporting_category VARCHAR2(100 BYTE),
  rule_comment VARCHAR2(2000 BYTE),
  rule_id NUMBER(10),
  rule_order NUMBER(31,10),
  start_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  tax_treatment VARCHAR2(100 BYTE),
  tax_type VARCHAR2(100 BYTE),
  unit_of_measure VARCHAR2(100 BYTE),
  aud_rule_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10),
  allocated_charge VARCHAR2(1 CHAR)
) 
TABLESPACE ositax;