CREATE TABLE sbxtax3.ht_date_determination_rules (
  authority_id NUMBER(10),
  authority_type_id NUMBER(10),
  created_by NUMBER(10),
  creation_date DATE,
  customer_name VARCHAR2(100 BYTE),
  customer_number VARCHAR2(100 BYTE),
  date_determination_logic_id NUMBER(10),
  date_determination_rule_id NUMBER(10),
  date_type VARCHAR2(50 BYTE),
  document_type VARCHAR2(50 BYTE),
  end_date DATE,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  merchant_id NUMBER(10),
  movement_type VARCHAR2(100 BYTE),
  product_category_id NUMBER(10),
  rule_order NUMBER(31,10),
  start_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  aud_date_determination_rule_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;