CREATE TABLE sbxtax3.ht_product_cross_ref (
  created_by NUMBER(10),
  creation_date DATE,
  input_recovery_type VARCHAR2(2 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  output_recovery_type VARCHAR2(2 BYTE),
  product_category_id NUMBER(10),
  product_cross_ref_group_id NUMBER(10),
  product_cross_ref_id NUMBER(10),
  source_product_code VARCHAR2(100 BYTE),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  aud_product_cross_ref_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10),
  end_date DATE,
  start_date DATE
) 
TABLESPACE ositax;