CREATE TABLE sbxtax3.ht_exempt_cert_products (
  created_by NUMBER(10),
  creation_date DATE,
  exempt_cert_id NUMBER(10),
  exempt_cert_product_id NUMBER(10),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  prod_code_match VARCHAR2(100 BYTE),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  aud_exempt_cert_product_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;