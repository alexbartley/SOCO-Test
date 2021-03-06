CREATE TABLE sbxtax.ht_rates (
  authority_id NUMBER(10),
  created_by NUMBER(10),
  creation_date DATE,
  currency_id NUMBER(10),
  description VARCHAR2(100 BYTE),
  end_date DATE,
  flat_fee NUMBER(31,5),
  is_local VARCHAR2(1 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  merchant_id NUMBER(10),
  rate NUMBER(31,10),
  rate_code VARCHAR2(50 BYTE),
  rate_id NUMBER(10),
  split_amount_type VARCHAR2(1 BYTE),
  split_type VARCHAR2(2 BYTE),
  start_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  unit_of_measure_code VARCHAR2(25 BYTE),
  use_default_qty VARCHAR2(1 BYTE),
  aud_rate_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10),
  min_amount NUMBER(31,5)
) 
TABLESPACE ositax;