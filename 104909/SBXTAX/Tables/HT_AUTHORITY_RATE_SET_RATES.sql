CREATE TABLE sbxtax.ht_authority_rate_set_rates (
  authority_rate_set_id NUMBER(10),
  authority_rate_set_rate_id NUMBER(10),
  created_by NUMBER(10),
  creation_date DATE,
  end_date DATE,
  erp_tax_code VARCHAR2(200 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  material_set_list_id NUMBER(10),
  process_order NUMBER(31,10),
  product_category_id NUMBER(10),
  rate_code VARCHAR2(50 BYTE),
  start_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  aud_authority_rate_set_rate_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;