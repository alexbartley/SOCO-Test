CREATE TABLE sbxtax3.ht_exempt_reasons (
  created_by NUMBER(10),
  creation_date DATE,
  customer_group_id NUMBER(10),
  description VARCHAR2(200 BYTE),
  exempt_reason_id NUMBER(10),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  long_code VARCHAR2(20 BYTE),
  short_code VARCHAR2(2 BYTE),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  aud_exempt_reason_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;