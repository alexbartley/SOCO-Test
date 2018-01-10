CREATE TABLE sbxtax3.ht_exempt_cert_authorities (
  authority_id NUMBER(10),
  created_by NUMBER(10),
  creation_date DATE,
  "EXEMPT" VARCHAR2(1 BYTE),
  exempt_cert_authority_id NUMBER(10),
  exempt_cert_authority_type_id NUMBER(10),
  exempt_cert_id NUMBER(10),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  aud_exempt_cert_authority_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;