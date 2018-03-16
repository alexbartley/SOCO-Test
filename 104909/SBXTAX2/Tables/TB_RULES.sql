CREATE TABLE sbxtax2.tb_rules (
  rule_id NUMBER NOT NULL,
  rule_order NUMBER(31,10) NOT NULL,
  auth_report_group_id NUMBER,
  "ACTIVE" VARCHAR2(1 BYTE),
  product_category_id NUMBER,
  authority_id NUMBER NOT NULL,
  code VARCHAR2(50 BYTE),
  exempt_reason_code VARCHAR2(50 BYTE),
  calculation_method VARCHAR2(50 BYTE),
  invoice_description VARCHAR2(100 BYTE),
  "EXEMPT" VARCHAR2(1 BYTE),
  start_date DATE NOT NULL,
  end_date DATE,
  deleted VARCHAR2(1 BYTE),
  merchant_id NUMBER NOT NULL,
  created_by NUMBER(10) NOT NULL,
  creation_date DATE NOT NULL,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  rate_code VARCHAR2(50 BYTE),
  basis_percent NUMBER(31,10),
  rule_comment VARCHAR2(2000 BYTE),
  tax_type VARCHAR2(100 BYTE),
  is_local VARCHAR2(1 BYTE),
  local_authority_type_id NUMBER,
  input_recovery_amount NUMBER(31,5),
  input_recovery_percent NUMBER(31,10),
  unit_of_measure VARCHAR2(100 BYTE),
  is_dependent_product VARCHAR2(1 BYTE) DEFAULT '.' NOT NULL,
  no_tax VARCHAR2(1 BYTE),
  reporting_category VARCHAR2(100 BYTE),
  tax_treatment VARCHAR2(100 BYTE),
  material_set_list_id NUMBER(10),
  authority_rate_set_id NUMBER(10),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  allocated_charge VARCHAR2(1 BYTE)
) 
TABLESPACE ositax;