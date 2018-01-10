CREATE TABLE sbxtax3.ht_exchange_rate_sources (
  created_by NUMBER(10),
  creation_date DATE,
  description VARCHAR2(1200 BYTE),
  exchange_rate_source_id NUMBER(10),
  intermediate_currency_id NUMBER(10),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  merchant_id NUMBER(10),
  service_location VARCHAR2(380 BYTE),
  service_type VARCHAR2(100 BYTE),
  source_name VARCHAR2(100 BYTE),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  update_frequency VARCHAR2(10 BYTE),
  aud_exchange_rate_source_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;