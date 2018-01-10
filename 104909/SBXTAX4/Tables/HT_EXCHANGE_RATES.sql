CREATE TABLE sbxtax4.ht_exchange_rates (
  created_by NUMBER(10),
  creation_date DATE,
  end_date DATE,
  exchange_rate_id NUMBER(10),
  exchange_rate_source_id NUMBER(10),
  from_currency_id NUMBER(10),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  rate NUMBER(31,10),
  start_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  to_currency_id NUMBER(10),
  aud_exchange_rate_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;