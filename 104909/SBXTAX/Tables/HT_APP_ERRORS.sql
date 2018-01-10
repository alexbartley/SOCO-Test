CREATE TABLE sbxtax.ht_app_errors (
  "ACTION" VARCHAR2(2000 BYTE),
  authority_id NUMBER(10),
  "CATEGORY" VARCHAR2(40 BYTE),
  cause VARCHAR2(2000 BYTE),
  created_by NUMBER(10),
  creation_date DATE,
  description VARCHAR2(2000 BYTE),
  error_id NUMBER(10),
  error_num VARCHAR2(240 BYTE),
  error_severity VARCHAR2(25 BYTE),
  last_updated_by NUMBER(10),
  last_update_date DATE,
  merchant_id NUMBER(10),
  synchronization_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  title VARCHAR2(80 BYTE),
  aud_error_id NUMBER(10) NOT NULL,
  audit_event_id NUMBER(10) NOT NULL,
  operation_type VARCHAR2(200 BYTE) NOT NULL,
  entity_owner_id NUMBER(10)
) 
TABLESPACE ositax;