CREATE TABLE sbxtax2.ht_currencies (
  created_by NUMBER(10),
  creation_date DATE,
  currency_code VARCHAR2(3 BYTE),
  currency_id NUMBER(10),
  description VARCHAR2(200 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  min_accountable_unit NUMBER(31,5),
  "NAME" VARCHAR2(100 BYTE),
  rounding_precision NUMBER(31,5),
  rounding_rule VARCHAR2(10 BYTE),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  aud_currency_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;