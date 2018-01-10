CREATE TABLE sbxtax.ht_delivery_terms (
  created_by NUMBER(10),
  creation_date DATE,
  delivery_term_code VARCHAR2(100 BYTE),
  delivery_term_id NUMBER(10),
  description VARCHAR2(1000 BYTE),
  end_date DATE,
  last_updated_by NUMBER(10),
  last_update_date DATE,
  lookup_id NUMBER(10),
  merchant_id NUMBER(10),
  start_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  aud_delivery_term_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;