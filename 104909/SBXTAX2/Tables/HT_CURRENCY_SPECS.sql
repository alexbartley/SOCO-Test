CREATE TABLE sbxtax2.ht_currency_specs (
  authority_id NUMBER(10),
  created_by NUMBER(10),
  creation_date DATE,
  currency_id NUMBER(10),
  currency_spec_id NUMBER(10),
  end_date DATE,
  exchange_rate_source_id NUMBER(10),
  is_default VARCHAR2(1 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  merchant_id NUMBER(10),
  min_accountable_unit NUMBER(31,5),
  rounding_precision NUMBER(31,5),
  rounding_rule VARCHAR2(10 BYTE),
  start_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  aud_currency_spec_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;