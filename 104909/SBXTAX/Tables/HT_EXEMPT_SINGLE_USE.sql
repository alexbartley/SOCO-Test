CREATE TABLE sbxtax.ht_exempt_single_use (
  created_by NUMBER(10),
  creation_date DATE,
  exempt_cert_id NUMBER(10),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  use_criteria_id NUMBER(10),
  "VALUE" VARCHAR2(200 BYTE),
  xml_element VARCHAR2(100 BYTE),
  aud_exempt_single_use_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;