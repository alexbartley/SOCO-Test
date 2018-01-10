CREATE TABLE sbxtax2.ht_exempt_cert_commodity_code (
  commodity_code_match VARCHAR2(100 BYTE),
  created_by NUMBER(10),
  creation_date DATE,
  exempt_cert_commodity_code_id NUMBER(10),
  exempt_cert_id NUMBER(10),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  aud_exempt_cert_cmd_code_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;